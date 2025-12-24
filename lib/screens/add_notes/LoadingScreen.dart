import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:eduscan_ai/screens/ai_summary/ai_summary_screen.dart';
import 'package:eduscan_ai/models/note_model.dart';

const String apiBaseUrl = "https://eduscan-backend.onrender.com";

class LoadingScreen extends StatefulWidget {
  final String subjectName;
  final File? pdfFile;
  final List<File>? imageFiles;

  const LoadingScreen({
    super.key,
    required this.subjectName,
    this.pdfFile,
    this.imageFiles,
  }) : assert(pdfFile != null || imageFiles != null);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _loadingMessage = "Preparing your document...";
  final List<String> _loadingSteps = [
    "Uploading document...",
    "Analyzing text...",
    "Crafting summary...",
    "Finding relevant videos...",
    "Building concept map...",
    "Generating flashcards...",
  ];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processDocument();
    });
    _startLoadingAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLoadingAnimation() {
    int currentStep = 0;
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        _loadingMessage = _loadingSteps[currentStep];
        currentStep = (currentStep + 1) % _loadingSteps.length;
      });
    });
  }

  Future<void> _processDocument() async {
    final endpoint = widget.pdfFile != null
        ? '/summarize-pdf'
        : '/summarize-images';
    final uri = Uri.parse("$apiBaseUrl$endpoint");
    final request = http.MultipartRequest('POST', uri);

    if (widget.pdfFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('pdf', widget.pdfFile!.path),
      );
    } else if (widget.imageFiles != null) {
      for (var imageFile in widget.imageFiles!) {
        request.files.add(
          await http.MultipartFile.fromPath('files', imageFile.path),
        );
      }
    }

    try {
      final response = await request.send();
      _timer?.cancel();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonResp = json.decode(respStr);

        final summary = jsonResp['summary'] ?? 'No summary provided.';
        final List<String> youtubeLinks = List<String>.from(
          jsonResp['youtube_links'] ?? [],
        );
        final conceptDiagramUrl = jsonResp['concept_diagram_url'] ?? '';

        final List<Flashcard> flashcards =
            (jsonResp['flashcards'] as List<dynamic>?)
                ?.map(
                  (cardJson) =>
                      Flashcard.fromJson(cardJson as Map<String, dynamic>),
                )
                .toList() ??
            [];

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SummaryScreen(
                subjectName: widget.subjectName,
                summaryText: summary,
                youtubeLinks: youtubeLinks,
                conceptDiagramUrl: conceptDiagramUrl,
                pdfFile: widget.pdfFile,
                flashcards: flashcards,
              ),
            ),
          );
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        _showError(
          "Failed to get summary. Code: ${response.statusCode}.\nDetails: $errorBody",
        );
      }
    } catch (e) {
      _timer?.cancel();
      _showError("An error occurred: $e");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // **THE CHANGE IS HERE**
            // Replaced the CircularProgressIndicator with your asset GIF.
            // Make sure the path 'assets/images/loading.gif' is correct.
            Image.asset(
              'assets/images/loading.gif',
              height: 120, // You can adjust the size as needed
              width: 120,
            ),
            const SizedBox(height: 40),
            Text(
              'Hang tight!',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                _loadingMessage,
                key: ValueKey<String>(_loadingMessage),
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
