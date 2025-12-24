import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eduscan_ai/models/note_model.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:eduscan_ai/utils/constants.dart';

class FlashcardStoryScreen extends StatefulWidget {
  final List<Flashcard> flashcards;

  const FlashcardStoryScreen({super.key, required this.flashcards});

  @override
  State<FlashcardStoryScreen> createState() => _FlashcardStoryScreenState();
}

class _FlashcardStoryScreenState extends State<FlashcardStoryScreen> {
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'No flashcards available.',
            style: GoogleFonts.inter(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: storyGradients[2]),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Trending Questions',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Swipe left/right to check more',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              Expanded(
                child: CardSwiper(
                  controller: _swiperController,
                  cardsCount: widget.flashcards.length,
                  cardBuilder:
                      (context, index, percentThresholdX, percentThresholdY) {
                        // Use a Key to ensure the state is reset when swiping
                        return FlashcardWidget(
                          key: ValueKey(widget.flashcards[index].question),
                          flashcard: widget.flashcards[index],
                        );
                      },
                  isLoop: false,
                  allowedSwipeDirection: AllowedSwipeDirection.symmetric(
                    horizontal: true,
                  ),
                ),
              ),
              _buildNavigationControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Icon(Icons.more_vert, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _swiperController.swipeLeft,
          ),
          const SizedBox(width: 40),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: _swiperController.swipeRight,
          ),
        ],
      ),
    );
  }
}

class FlashcardWidget extends StatefulWidget {
  final Flashcard flashcard;

  const FlashcardWidget({super.key, required this.flashcard});

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_controller.isAnimating) return;
    if (_controller.status != AnimationStatus.forward) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * pi;
          final isFrontSideVisible = _controller.value < 0.5;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            // **THE FIX IS HERE**: This new logic correctly handles the reverse animation.
            child: isFrontSideVisible
                ? _buildCardFace(content: widget.flashcard.question)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildCardFace(content: widget.flashcard.answer),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardFace({required String content}) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            // Makes the content scrollable if it's too long
            child: Text(
              content,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
