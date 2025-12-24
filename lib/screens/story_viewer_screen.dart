import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eduscan_ai/models/note_model.dart';
import 'package:eduscan_ai/utils/constants.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Note> notes;
  final int initialNoteIndex;
  const StoryViewerScreen({
    super.key,
    required this.notes,
    required this.initialNoteIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialNoteIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.notes.length,
      itemBuilder: (context, index) {
        final note = widget.notes[index];
        final gradient = storyGradients[index % storyGradients.length];
        return SingleStoryView(
          key: ValueKey(note.id),
          note: note,
          gradient: gradient,
        );
      },
    );
  }
}

class SingleStoryView extends StatefulWidget {
  final Note note;
  final Gradient gradient;
  const SingleStoryView({
    super.key,
    required this.note,
    required this.gradient,
  });

  @override
  State<SingleStoryView> createState() => _SingleStoryViewState();
}

class _SingleStoryViewState extends State<SingleStoryView> {
  int _currentFlashcardIndex = 0;

  void _nextFlashcard() {
    if (_currentFlashcardIndex < widget.note.flashcards.length - 1) {
      setState(() => _currentFlashcardIndex++);
    } else {
      // This is the last flashcard, pop the screen.
      // In a multi-story view, this would go to the next story.
      Navigator.of(context).pop();
    }
  }

  void _previousFlashcard() {
    if (_currentFlashcardIndex > 0) {
      setState(() => _currentFlashcardIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flashcards = widget.note.flashcards;
    if (flashcards.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "No flashcards in this note.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    final currentFlashcard = flashcards[_currentFlashcardIndex];

    return GestureDetector(
      onTapDown: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dx = details.globalPosition.dx;
        if (dx < screenWidth * 0.25) {
          _previousFlashcard();
        } else if (dx > screenWidth * 0.75) {
          _nextFlashcard();
        }
      },
      // **REMOVED**: The onLongPress gestures are no longer needed as the timer is gone.
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: widget.gradient),
          child: SafeArea(
            child: Column(
              children: [
                _buildProgressBars(flashcards.length),
                _buildStoryHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        Text(
                          currentFlashcard.question,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              const Shadow(
                                blurRadius: 10,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          flex: 4,
                          child: RevealAnswerCard(
                            key: ValueKey(_currentFlashcardIndex),
                            answer: currentFlashcard.answer,
                          ),
                        ),
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBars(int storyCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Row(
        children: List.generate(storyCount, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              // **REMOVED**: The AnimatedBuilder is no longer needed.
              child: LinearProgressIndicator(
                value: index < _currentFlashcardIndex ? 1.0 : 0.0,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStoryHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white24,
            child: Text(
              widget.note.title.substring(0, 1).toUpperCase(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.note.title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class RevealAnswerCard extends StatefulWidget {
  final String answer;
  const RevealAnswerCard({super.key, required this.answer});

  @override
  State<RevealAnswerCard> createState() => _RevealAnswerCardState();
}

class _RevealAnswerCardState extends State<RevealAnswerCard>
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
            child: isFrontSideVisible
                ? _buildCardFace(isFront: true)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildCardFace(isFront: false),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardFace({required bool isFront}) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 100,
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isFront
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(
                        'Reveal Answer',
                        style: GoogleFonts.amaticSc(
                          fontWeight: FontWeight.bold,
                          fontSize: 35,
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Text(
                      widget.answer,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
