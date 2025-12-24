import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_selector/file_selector.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eduscan_ai/screens/add_notes/LoadingScreen.dart';
import 'package:dotted_border/dotted_border.dart'; // Add this package to your pubspec.yaml

class AddNotesScreen extends StatefulWidget {
  const AddNotesScreen({Key? key}) : super(key: key);

  @override
  State<AddNotesScreen> createState() => _AddNotesScreenState();
}

class _AddNotesScreenState extends State<AddNotesScreen> {
  /// Opens the device storage to select a single PDF file.
  Future<void> _pickPdfFromStorage() async {
    const typeGroup = XTypeGroup(label: 'PDFs', extensions: ['pdf']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file != null && mounted) {
      final pickedPdf = File(file.path);
      final hasInternet = await _checkInternet();

      if (hasInternet) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LoadingScreen(subjectName: 'New PDF Note', pdfFile: pickedPdf),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No internet connection. Please try again later."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Checks for an active internet connection (Wi-Fi or mobile data).
  Future<bool> _checkInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Create New Note',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // **REDESIGNED**: A new minimal, rectangular "dropzone" style button.
              GestureDetector(
                onTap: _pickPdfFromStorage,
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(16),
                  color: Colors.grey.shade400,
                  strokeWidth: 2,
                  dashPattern: const [8, 4],
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file_outlined,
                            size: 60,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Upload a PDF',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap here to select a document',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Opacity(
                opacity: 0.5,
                child: Image.asset(
                  'assets/images/moretools.png', // A more relevant illustration
                  height: 180,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
