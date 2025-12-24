import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:eduscan_ai/services/google_drive_service.dart';

class PDFViewerScreen extends StatefulWidget {
  final File? file; // For new, unsaved notes
  final String? googleDriveFileId; // For saved notes

  const PDFViewerScreen({super.key, this.file, this.googleDriveFileId})
    : assert(
        file != null || googleDriveFileId != null,
        'Either a file or a Google Drive ID must be provided.',
      );

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? _localFilePath;
  bool _isLoading = true;
  String? _errorMessage;
  final GoogleDriveService _driveService = GoogleDriveService();

  @override
  void initState() {
    super.initState();
    if (widget.file != null) {
      // If it's a local file, display it directly.
      setState(() {
        _localFilePath = widget.file!.path;
        _isLoading = false;
      });
    } else if (widget.googleDriveFileId != null) {
      // If it's a Drive ID, download the file.
      _loadPdfFromGoogleDrive(widget.googleDriveFileId!);
    }
  }

  /// Downloads a PDF from Google Drive and prepares it for viewing.
  Future<void> _loadPdfFromGoogleDrive(String fileId) async {
    try {
      final downloadedFile = await _driveService.downloadFile(fileId);
      if (downloadedFile != null) {
        setState(() {
          _localFilePath = downloadedFile.path;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to download file from Google Drive.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading PDF: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "PDF Viewer",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_localFilePath != null) {
      return PDFView(
        filePath: _localFilePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: true,
      );
    }
    return const Center(child: Text("No PDF available to display."));
  }
}
