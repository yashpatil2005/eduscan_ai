import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:eduscan_ai/models/note_model.dart';
import 'package:eduscan_ai/services/google_drive_service.dart';

/// A service class to handle all interactions with Firebase services (Firestore and Auth).
class FirebaseService {
  // Using a private constant for the collection name is a good practice to avoid typos.
  static const String _notesCollection = 'notes';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final GoogleDriveService _driveService;

  /// **REFACTORED**: Using dependency injection.
  /// The required services are passed in, making the class more testable.
  FirebaseService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleDriveService? driveService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _driveService = driveService ?? GoogleDriveService();

  /// Saves the metadata of a note to Cloud Firestore for the currently logged-in user.
  Future<void> saveNoteMetadata(Note note) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in. Cannot save note.");
      }
      final noteToSave = note.copyWith(
        userId: user.uid,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection(_notesCollection)
          .doc(note.id)
          .set(noteToSave.toJson());
    } catch (e) {
      // Provide more specific error feedback.
      debugPrint("Error saving note metadata: $e");
      throw Exception("Could not save note. Please try again.");
    }
  }

  /// Returns a real-time stream of a list of notes for the currently logged-in user.
  Stream<List<Note>> getNotesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      // If no user is logged in, return an empty stream to avoid errors.
      return Stream.value([]);
    }
    return _firestore
        .collection(_notesCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Note.fromJson(doc.data())).toList(),
        );
  }

  /// Updates the title of a specific note in Firestore.
  Future<void> renameNote(String noteId, String newTitle) async {
    try {
      await _firestore.collection(_notesCollection).doc(noteId).update({
        'title': newTitle,
      });
    } catch (e) {
      debugPrint("Error renaming note: $e");
      throw Exception("Could not rename note. Please try again.");
    }
  }

  /// Deletes a note's data from Firestore and its associated file from Google Drive.
  Future<void> deleteNote(Note note) async {
    try {
      // First, delete the document from Firestore.
      await _firestore.collection(_notesCollection).doc(note.id).delete();

      // Then, if there's a file in Google Drive, attempt to delete it.
      if (note.googleDriveFileId != null &&
          note.googleDriveFileId!.isNotEmpty) {
        // We don't re-throw an error here, as we want the note metadata to be
        // deleted even if the Drive file deletion fails.
        await _driveService.deleteFile(note.googleDriveFileId!);
      }
    } catch (e) {
      debugPrint("Error deleting note: $e");
      throw Exception("Could not delete note. Please try again.");
    }
  }
}
