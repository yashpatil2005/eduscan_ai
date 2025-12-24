import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:eduscan_ai/screens/add_notes/LoadingScreen.dart';

class ImagePreviewScreen extends StatefulWidget {
  final List<File> images;
  const ImagePreviewScreen({Key? key, required this.images}) : super(key: key);

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late List<File> _images;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing =
      false; // To show a loading indicator on the "Done" button

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the image list
    _images = List.from(widget.images);
  }

  /// Adds an image taken from the camera to the list.
  Future<void> _addMoreImagesFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  /// Adds images selected from the gallery to the list.
  Future<void> _addMoreImagesFromGallery() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((e) => File(e.path)));
      });
    }
  }

  /// This is the main function that gets called when the user is finished.
  Future<void> _onDonePressed() async {
    if (_images.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Step 1: Convert the list of images into a single PDF file.
      final pdfFile = await _createPdfFromImages();

      // Step 2: Navigate to the LoadingScreen, passing the generated PDF.
      // The LoadingScreen will handle the API call and navigation to the SummaryScreen.
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoadingScreen(
              subjectName: 'New Scanned Note',
              pdfFile: pdfFile,
            ),
          ),
        );
      }
    } catch (e) {
      // If something goes wrong, show an error message.
      debugPrint('Error during PDF creation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to process images. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Creates a PDF document from the list of selected images.
  Future<File> _createPdfFromImages() async {
    final pdf = pw.Document();

    for (final imageFile in _images) {
      final imageBytes = await imageFile.readAsBytes();
      final image = pw.MemoryImage(imageBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(image));
          },
        ),
      );
    }

    // Save the PDF to a temporary file.
    final outputDir = await getTemporaryDirectory();
    final outputFile = File("${outputDir.path}/scanned_notes.pdf");
    await outputFile.writeAsBytes(await pdf.save());

    return outputFile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Preview Scanned Notes (${_images.length})',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _images.isEmpty
          ? const Center(child: Text("No images selected."))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
              ), // Padding for bottom bar
              itemCount: _images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                return _buildImageTile(index);
              },
            ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  /// Builds a single image tile with a delete button.
  Widget _buildImageTile(int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_images[index], fit: BoxFit.cover),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _images.removeAt(index)),
              child: const CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 14,
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the action bar at the bottom of the screen.
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: Icons.camera_alt_outlined,
            label: 'Scan More',
            onTap: _addMoreImagesFromCamera,
          ),
          _buildActionButton(
            icon: Icons.photo_library_outlined,
            label: 'Add More',
            onTap: _addMoreImagesFromGallery,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing || _images.isEmpty
                  ? null
                  : _onDonePressed,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle, color: Colors.white),
              label: Text(
                'Done',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
