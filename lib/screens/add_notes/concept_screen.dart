import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';

class ConceptDiagramScreen extends StatelessWidget {
  final String imageUrl;

  const ConceptDiagramScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A dark background is better for focusing on the diagram
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Concept Diagram',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        // The PhotoView widget provides pinch-to-zoom, panning, and rotation.
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          // Set min and max scale for zooming
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 2.5,
          // A loading indicator while the image is being fetched
          loadingBuilder: (context, event) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          },
          // An error widget if the image fails to load
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                  SizedBox(height: 8),
                  Text(
                    'Could not load diagram.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
