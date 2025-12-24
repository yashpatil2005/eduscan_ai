import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eduscan_ai/screens/discover_screen.dart';

class ArticleViewerScreen extends StatefulWidget {
  final Article article;
  const ArticleViewerScreen({super.key, required this.article});

  @override
  State<ArticleViewerScreen> createState() => _ArticleViewerScreenState();
}

class _ArticleViewerScreenState extends State<ArticleViewerScreen>
    with TickerProviderStateMixin {
  String? _fullContent;
  String? _summaryContent;
  bool _isLoadingFullArticle = true;
  bool _isSummarizing = false;
  late ScrollController _scrollController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScale;

  final String _fetchUrl = "https://eduscan-backend.onrender.com/fetch-article";
  final String _summarizeUrl = "https://eduscan-backend.onrender.com/ask-sakhi";

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _fetchFullArticle();

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _fetchFullArticle() async {
    setState(() => _isLoadingFullArticle = true);
    try {
      final response = await http.post(
        Uri.parse(_fetchUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'url': widget.article.link}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _fullContent = json.decode(response.body)['content'];
        });
      } else {
        throw Exception('Failed to fetch the full article.');
      }
    } catch (e) {
      debugPrint("Error fetching full article: $e");
      setState(() {
        _fullContent = widget.article.description;
      });
    } finally {
      setState(() => _isLoadingFullArticle = false);
    }
  }

  Future<void> _askSakhiToSummarize() async {
    if (_fullContent == null) return;

    // Button press animation
    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });

    setState(() => _isSummarizing = true);

    final prompt =
        "Please summarize the following article for a student in a clear and simple way:\n\n$_fullContent";

    try {
      final summarizeResponse = await http.post(
        Uri.parse(_summarizeUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'prompt': prompt}),
      );

      if (summarizeResponse.statusCode == 200) {
        final data = json.decode(summarizeResponse.body);
        setState(() {
          _summaryContent =
              data['response'] ?? 'Sorry, I could not summarize that.';
        });

        // Scroll to top to show summary
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        throw Exception('Failed to get response from Sakhi.');
      }
    } catch (e) {
      debugPrint("API Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error processing article. Please try again."),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => _isSummarizing = false);
    }
  }

  Widget _buildShimmerLoader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        8,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 1000 + (index * 100)),
            height: index % 3 == 0 ? 16 : 20,
            width: index % 2 == 0
                ? double.infinity
                : MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  Colors.grey[300]!,
                  Colors.grey[100]!,
                  Colors.grey[300]!,
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ScaleTransition(
            scale: _buttonScale,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [const Color(0xFF1A1A1A), const Color(0xFF333333)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _isLoadingFullArticle || _isSummarizing
                      ? null
                      : _askSakhiToSummarize,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Ask ",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (_isSummarizing)
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        else
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.auto_awesome, // Replace with your logo
                              color: Color(0xFF1A1A1A),
                              size: 18,
                            ),
                            // Replace the Icon above with your logo:
                            // child: Image.asset(
                            //   'assets/images/your_logo.png', // Your logo path here
                            //   width: 20,
                            //   height: 20,
                            //   color: Color(0xFF1A1A1A),
                            // ),
                          ),
                        Text(
                          "to Summarize",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          // MODERN HEADER WITH HERO IMAGE
          Hero(
            tag: 'article_${widget.article.title}',
            child: Container(
              height: 320,
              child: Stack(
                children: [
                  // Background Image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.article.thumbnail,
                      height: 320,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[400]!, Colors.grey[600]!],
                          ),
                        ),
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ),

                  // Gradient Overlay
                  Container(
                    height: 320,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),

                  // Back Button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CONTENT SECTION
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Article Title
                        Text(
                          widget.article.title,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Author Info
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.grey[600],
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "By ${widget.article.author}",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Summary Badge (when available)
                        if (_summaryContent != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "AI Summary",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Content
                        if (_isLoadingFullArticle)
                          _buildShimmerLoader()
                        else
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              key: ValueKey(_summaryContent),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                _summaryContent ??
                                    _fullContent ??
                                    widget.article.description,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  height: 1.8,
                                  color: const Color(0xFF2A2A2A),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // FLOATING ACTION BUTTON
      bottomNavigationBar: _summaryContent == null
          ? _buildModernButton()
          : null,
    );
  }
}
