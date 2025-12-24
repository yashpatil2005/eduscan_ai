import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
// **FIX**: Added missing package import.
import 'package:flutter_markdown/flutter_markdown.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String markdownFile;

  const LegalScreen({
    super.key,
    required this.title,
    required this.markdownFile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder(
        future: rootBundle.loadString(markdownFile),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Markdown(
              data: snapshot.data!,
              padding: const EdgeInsets.all(16.0),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
