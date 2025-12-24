import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:eduscan_ai/models/journal_model.dart';

class JournalEntryScreen extends StatefulWidget {
  final JournalEntry? entry;
  const JournalEntryScreen({super.key, this.entry});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen>
    with TickerProviderStateMixin {
  late TextEditingController _textController;
  late DateTime _entryDate;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  bool _hasUnsavedChanges = false;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.entry?.text ?? '');
    _entryDate = widget.entry?.date ?? DateTime.now();
    _wordCount = _textController.text
        .split(' ')
        .where((word) => word.isNotEmpty)
        .length;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _pulseController.repeat(reverse: true);

    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final newWordCount = _textController.text
        .split(' ')
        .where((word) => word.isNotEmpty)
        .length;
    setState(() {
      _hasUnsavedChanges =
          _textController.text.trim() != (widget.entry?.text ?? '').trim();
      _wordCount = newWordCount;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    HapticFeedback.lightImpact();
    final text = _textController.text.trim();
    if (text.isEmpty) {
      if (widget.entry != null) {
        widget.entry!.delete();
      }
      Navigator.of(context).pop();
      return;
    }

    final box = Hive.box<JournalEntry>('journal_entries');
    if (widget.entry != null) {
      widget.entry!.text = text;
      widget.entry!.save();
    } else {
      final newEntry = JournalEntry(text: text, date: _entryDate);
      box.add(newEntry);
    }
    Navigator.of(context).pop();
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.delete_rounded,
                  color: Colors.red[400],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Entry',
                style: GoogleFonts.dancingScript(
                  fontSize: 24,
                  color: const Color(0xFF8B7355),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this journal entry?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This action cannot be undone.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.red[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: const Color(0xFF8B7355).withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (widget.entry != null) {
                  widget.entry!.delete();
                }
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to journal screen
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[600],
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.white,
                title: Text(
                  'Unsaved Changes',
                  style: GoogleFonts.dancingScript(
                    fontSize: 24,
                    color: const Color(0xFF8B7355),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Text(
                  'You have unsaved changes. Do you want to save before leaving?',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF5D4037),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: Text(
                      'Discard',
                      style: GoogleFonts.inter(
                        color: Colors.red[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      _saveEntry();
                    },
                    child: Text(
                      'Save',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF8B7355),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ) ??
          false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F7),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B7355).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Color(0xFF8B7355),
                size: 20,
              ),
            ),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (widget.entry != null)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_rounded,
                          size: 18,
                          color: Colors.red[400],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete Entry',
                          style: GoogleFonts.inter(color: Colors.red[400]),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B7355).withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: const Color(0xFF8B7355),
                    size: 20,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                color: Colors.white,
              ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: _saveEntry,
                style: TextButton.styleFrom(
                  backgroundColor: _hasUnsavedChanges
                      ? const Color(0xFF8B7355)
                      : const Color(0xFF8B7355).withOpacity(0.7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _hasUnsavedChanges ? _pulseAnimation.value : 1.0,
                      child: Icon(
                        _hasUnsavedChanges
                            ? Icons.save_rounded
                            : Icons.check_rounded,
                        size: 18,
                      ),
                    );
                  },
                ),
                label: Text(
                  _hasUnsavedChanges ? 'Save' : 'Done',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFAF9F7), Color(0xFFF5F3F0)],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF8B7355).withOpacity(0.08),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B7355).withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                child: TextField(
                                  controller: _textController,
                                  autofocus:
                                      widget.entry ==
                                      null, // Only autofocus for new entries
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: GoogleFonts.eduNswActFoundation(
                                    fontSize: 20,
                                    height: 1.8,
                                    color: const Color(0xFF5D4037),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: widget.entry == null
                                        ? 'Dear diary...\n\nWhat\'s on your mind today?'
                                        : 'Tap to start editing...',
                                    hintStyle: GoogleFonts.eduNswActFoundation(
                                      fontSize: 20,
                                      height: 1.8,
                                      color: const Color(
                                        0xFF8B7355,
                                      ).withOpacity(0.4),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  cursorColor: const Color(0xFF8B7355),
                                  cursorWidth: 2,
                                  cursorRadius: const Radius.circular(1),
                                ),
                              ),
                            ),
                            _buildBottomBar(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B7355).withOpacity(0.1),
                  const Color(0xFFA0845C).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFF8B7355).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: const Color(0xFF8B7355),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMM d').format(_entryDate),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF8B7355),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7).withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF8B7355).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B7355).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.text_fields_rounded,
                  size: 14,
                  color: const Color(0xFF8B7355),
                ),
                const SizedBox(width: 6),
                Text(
                  '$_wordCount words',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF8B7355),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Unsaved',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
