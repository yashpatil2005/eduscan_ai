import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  Future<auth.AuthClient?> _getAuthenticatedClient() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final headers = await googleUser.authHeaders;
    final accessToken = headers['Authorization']!.replaceAll('Bearer ', '');

    return auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        _googleSignIn.scopes,
      ),
    );
  }

  Future<String?> uploadFile(File file, String fileName) async {
    final client = await _getAuthenticatedClient();
    if (client == null) return null;
    final driveApi = drive.DriveApi(client);
    String? folderId = await _findOrCreateFolder(driveApi, "EduScanAI");
    if (folderId == null) return null;
    final driveFile = drive.File()
      ..name = fileName
      ..parents = [folderId];
    final media = drive.Media(file.openRead(), file.lengthSync());
    final result = await driveApi.files.create(driveFile, uploadMedia: media);
    return result.id;
  }

  Future<File?> downloadFile(String fileId) async {
    final client = await _getAuthenticatedClient();
    if (client == null) return null;
    final driveApi = drive.DriveApi(client);
    final media =
        await driveApi.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileId.pdf');
    final fileStream = file.openWrite();
    await media.stream.pipe(fileStream);
    await fileStream.close();
    return file;
  }

  /// **NEW**: Deletes a file from Google Drive using its ID.
  Future<void> deleteFile(String fileId) async {
    final client = await _getAuthenticatedClient();
    if (client == null) {
      print("Authentication failed. Could not delete file.");
      return;
    }
    final driveApi = drive.DriveApi(client);
    try {
      await driveApi.files.delete(fileId);
      print("File deleted successfully from Google Drive. File ID: $fileId");
    } catch (e) {
      print("Error deleting file from Google Drive: $e");
      // Don't throw an error, just log it. The note can still be deleted from Firestore.
    }
  }

  Future<String?> _findOrCreateFolder(
    drive.DriveApi driveApi,
    String folderName,
  ) async {
    try {
      final response = await driveApi.files.list(
        q: "mimeType='application/vnd.google-apps.folder' and name='$folderName' and trashed=false",
        spaces: 'drive',
      );
      if (response.files != null && response.files!.isNotEmpty) {
        return response.files!.first.id;
      } else {
        final folder = drive.File()
          ..name = folderName
          ..mimeType = 'application/vnd.google-apps.folder';
        final createdFolder = await driveApi.files.create(folder);
        return createdFolder.id;
      }
    } catch (e) {
      print("Error finding or creating folder: $e");
      return null;
    }
  }
}
