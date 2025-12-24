import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:eduscan_ai/models/class_model.dart';
import 'package:eduscan_ai/models/todo_model.dart';
import 'package:eduscan_ai/services/firebase_service.dart';
import 'package:eduscan_ai/models/note_model.dart';
import 'package:eduscan_ai/screens/ai_summary/ai_summary_screen.dart';
import 'package:eduscan_ai/screens/add_notes/add_notes_screen.dart';
import 'package:eduscan_ai/screens/todo_list_screen.dart';
import 'package:eduscan_ai/screens/timetable_screen.dart';
import 'package:eduscan_ai/screens/more_tools_screen.dart';
import 'package:eduscan_ai/screens/all_notes_screen.dart';
import 'package:eduscan_ai/screens/settings_screen.dart';
import 'package:eduscan_ai/screens/story_viewer_screen.dart';
import 'package:eduscan_ai/utils/constants.dart';
import 'package:eduscan_ai/screens/journal_screen.dart';
import 'package:eduscan_ai/screens/discover_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseService _firebaseService = FirebaseService();
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = _now.hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.settings_outlined,
                  color: Colors.black54,
                ),
                title: Text('Settings', style: GoogleFonts.inter(fontSize: 16)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'Log-out',
                  style: GoogleFonts.inter(color: Colors.red, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLogoutDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.inter(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildGreetingSection(),
                    const SizedBox(height: 40),
                    _buildQuickSnippetsSection(),
                    const SizedBox(height: 32),
                    _buildAddNotesButton(),
                    const SizedBox(height: 32),
                    _buildRecentNotesSection(),
                    const SizedBox(height: 32),
                    _buildLiveLectureSection(),
                    const SizedBox(height: 32),
                    _buildBottomToolsGrid(),
                    const SizedBox(height: 32),
                    _buildFooter(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          _buildFloatingSakhiButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Just Logo
        Image.asset('assets/images/logo.png', height: 55),
        // Profile section
        GestureDetector(
          onTap: () => _showProfileMenu(context),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[100],
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Icon(Icons.person, color: Colors.grey[600], size: 20)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()}',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '${user?.displayName?.split(' ').first ?? 'User'}!',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('h:mm a').format(_now),
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  DateFormat('d\'th\' MMM yyyy EEEE').format(_now),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder(
          valueListenable: Hive.box<ClassModel>('classes').listenable(),
          builder: (context, classBox, _) {
            final today = [
              'Mon',
              'Tue',
              'Wed',
              'Thu',
              'Fri',
              'Sat',
              'Sun',
            ][_now.weekday - 1];
            final todayClasses = classBox.values
                .where((c) => c.day == today)
                .toList();
            final ongoing = todayClasses
                .where(
                  (c) => _isTimeBetween(
                    TimeOfDay.fromDateTime(_now),
                    _timeOfDayFromString(c.startTime),
                    _timeOfDayFromString(c.endTime),
                  ),
                )
                .toList();

            return ValueListenableBuilder(
              valueListenable: Hive.box<TodoModel>('todos').listenable(),
              builder: (context, todoBox, _) {
                // Get upcoming assignments and exams from todos
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                final upcomingTodos = todoBox.values
                    .where(
                      (todo) =>
                          !todo.isCompleted &&
                          (todo.category.toLowerCase().contains('assignment') ||
                              todo.category.toLowerCase().contains('exam') ||
                              todo.title.toLowerCase().contains('assignment') ||
                              todo.title.toLowerCase().contains('exam')),
                    )
                    .toList();

                String summaryText =
                    "You have a clear schedule today. Enjoy your free time!";

                if (ongoing.isNotEmpty) {
                  if (upcomingTodos.isNotEmpty) {
                    upcomingTodos.sort(
                      (a, b) => a.taskDateTime.compareTo(b.taskDateTime),
                    );
                    final nextTodo = upcomingTodos.first;
                    final taskDate = DateTime(
                      nextTodo.taskDateTime.year,
                      nextTodo.taskDateTime.month,
                      nextTodo.taskDateTime.day,
                    );
                    final daysUntil = taskDate.difference(today).inDays;
                    String todoInfo = "";

                    if (daysUntil == 0) {
                      todoInfo = "you have ${nextTodo.title} today";
                    } else if (daysUntil == 1) {
                      todoInfo = "you have ${nextTodo.title} tomorrow";
                    } else {
                      todoInfo =
                          "you have ${nextTodo.title} in $daysUntil days";
                    }

                    summaryText =
                        "Ongoing lecture: - ${ongoing.first.subject}, ${todayClasses.length - ongoing.length} more coming\n$todoInfo.";
                  } else {
                    summaryText =
                        "Ongoing lecture: - ${ongoing.first.subject}, ${todayClasses.length - ongoing.length} more coming.";
                  }
                } else if (todayClasses.isNotEmpty) {
                  if (upcomingTodos.isNotEmpty) {
                    upcomingTodos.sort(
                      (a, b) => a.taskDateTime.compareTo(b.taskDateTime),
                    );
                    final nextTodo = upcomingTodos.first;
                    final taskDate = DateTime(
                      nextTodo.taskDateTime.year,
                      nextTodo.taskDateTime.month,
                      nextTodo.taskDateTime.day,
                    );
                    final daysUntil = taskDate.difference(today).inDays;
                    String todoInfo = "";

                    if (daysUntil == 0) {
                      todoInfo = "you have ${nextTodo.title} today";
                    } else if (daysUntil == 1) {
                      todoInfo = "you have ${nextTodo.title} tomorrow";
                    } else {
                      todoInfo =
                          "you have ${nextTodo.title} in $daysUntil days";
                    }

                    summaryText =
                        "You have ${todayClasses.length} classes today and $todoInfo.";
                  } else {
                    summaryText =
                        "You have ${todayClasses.length} classes today.";
                  }
                } else if (upcomingTodos.isNotEmpty) {
                  upcomingTodos.sort(
                    (a, b) => a.taskDateTime.compareTo(b.taskDateTime),
                  );
                  final nextTodo = upcomingTodos.first;
                  final taskDate = DateTime(
                    nextTodo.taskDateTime.year,
                    nextTodo.taskDateTime.month,
                    nextTodo.taskDateTime.day,
                  );
                  final daysUntil = taskDate.difference(today).inDays;

                  if (daysUntil == 0) {
                    summaryText =
                        "You have ${nextTodo.title} today. Good luck!";
                  } else if (daysUntil == 1) {
                    summaryText =
                        "You have ${nextTodo.title} tomorrow. Time to prepare!";
                  } else {
                    summaryText =
                        "You have ${nextTodo.title} in $daysUntil days.";
                  }
                }

                return Text(
                  summaryText,
                  style: GoogleFonts.crimsonText(
                    fontSize: 21,
                    color: const Color.fromARGB(255, 90, 90, 90),
                    height: 1.4,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickSnippetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Snippets',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildStorySection(),
      ],
    );
  }

  // Keep your original story section logic exactly as it was
  Widget _buildStorySection() {
    return StreamBuilder<List<Note>>(
      stream: _firebaseService.getNotesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox.shrink();
        final notesWithFlashcards = snapshot.data!
            .where((note) => note.flashcards.isNotEmpty)
            .toList();
        if (notesWithFlashcards.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 100,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: notesWithFlashcards.length,
            itemBuilder: (context, index) {
              return _buildStoryCircle(notesWithFlashcards, index);
            },
          ),
        );
      },
    );
  }

  // Keep your original story circle logic exactly as it was
  Widget _buildStoryCircle(List<Note> notes, int index) {
    final note = notes[index];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              StoryViewerScreen(notes: notes, initialNoteIndex: index),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: storyGradients[index % storyGradients.length],
              ),
              child: const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.school, size: 28, color: Colors.black),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 70,
              child: Text(
                note.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNotesButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddNotesScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.black, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              'Add New Notes',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent notes',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: StreamBuilder<List<Note>>(
            stream: _firebaseService.getNotesStream(),
            builder: (context, snapshot) {
              // Handle all states without showing loading indicator
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      "No recent notes found.",
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              final notes = snapshot.data!.take(3).toList();
              return Column(
                children: [
                  ...notes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final note = entry.value;
                    return _buildNoteTile(note, index == notes.length - 1);
                  }),
                  _buildViewAllNotesButton(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoteTile(Note note, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(bottom: BorderSide(color: Colors.grey[200]!))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          note.title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            DateFormat.yMMMd().format(note.createdAt),
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey[400],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SummaryScreen(
              subjectName: note.title,
              summaryText: note.summary,
              youtubeLinks: note.youtubeLinks,
              conceptDiagramUrl: note.conceptDiagramUrl,
              flashcards: note.flashcards,
              googleDriveFileId: note.googleDriveFileId,
              isViewingSavedNote: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllNotesButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AllNotesScreen()),
        ),
        child: Text(
          'View All Notes',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLiveLectureSection() {
    final today = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][_now.weekday - 1];

    return ValueListenableBuilder<Box<ClassModel>>(
      valueListenable: Hive.box<ClassModel>('classes').listenable(),
      builder: (context, box, _) {
        final todayClasses = box.values
            .where((cls) => cls.day == today)
            .toList();
        todayClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

        ClassModel? ongoingClass;
        List<ClassModel> upcomingClasses = [];
        final currentTime = TimeOfDay.fromDateTime(_now);

        for (var cls in todayClasses) {
          final startTime = _timeOfDayFromString(cls.startTime);
          final endTime = _timeOfDayFromString(cls.endTime);
          if (_isTimeBetween(currentTime, startTime, endTime)) {
            ongoingClass = cls;
          } else if (_isTimeBefore(currentTime, startTime)) {
            upcomingClasses.add(cls);
          }
        }

        if (ongoingClass == null && upcomingClasses.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            // Ongoing lecture (if any)
            if (ongoingClass != null) ...[
              _buildOngoingLectureCard(ongoingClass),
              const SizedBox(height: 16),
            ],

            // Upcoming lectures carousel (if any)
            if (upcomingClasses.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Upcoming',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: upcomingClasses.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < upcomingClasses.length - 1 ? 12.0 : 0,
                      ),
                      child: SizedBox(
                        width: 200,
                        child: _buildUpcomingLectureCard(
                          upcomingClasses[index],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildOngoingLectureCard(ClassModel cls) {
    final startTime = _timeOfDayFromString(cls.startTime);
    final endTime = _timeOfDayFromString(cls.endTime);
    final startDateTime = DateTime(
      _now.year,
      _now.month,
      _now.day,
      startTime.hour,
      startTime.minute,
    );
    final endDateTime = DateTime(
      _now.year,
      _now.month,
      _now.day,
      endTime.hour,
      endTime.minute,
    );
    final totalDuration = endDateTime.difference(startDateTime);
    final durationPassed = _now.difference(startDateTime);
    final progress = (durationPassed.inSeconds / totalDuration.inSeconds).clamp(
      0.0,
      1.0,
    );
    final timeRemaining = endDateTime.difference(_now);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${timeRemaining.inMinutes}min remaining',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            cls.subject,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cls.instructor,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                cls.location,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${cls.startTime} - ${cls.endTime}',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingLectureCard(ClassModel cls) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming',
            style: GoogleFonts.inter(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            cls.subject,
            style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            cls.instructor,
            style: GoogleFonts.inter(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '${cls.startTime} - ${cls.endTime}',
            style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildToolButton(
                'Reminders',
                Icons.notifications_none,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TodoListScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToolButton('Journal', Icons.book_outlined, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JournalScreen()),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToolButton(
                'TimeTable',
                Icons.calendar_today_outlined,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TimetableScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildExploreCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildToolButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.black54),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DiscoverScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.explore_outlined,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'EXPLORE +',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSakhiButton() {
    return Positioned(
      bottom: 24,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MoreToolsScreen()),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Image.asset(
              'assets/images/ask_sakhi_avatar.png',
              width: 40,
              height: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Crafted with ",
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 17),
          ),
          Icon(Icons.favorite, color: Colors.red, size: 12),
          Text(
            " by ",
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 17),
          ),
          Text(
            "SyntaxSpace.",
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods remain the same
  TimeOfDay _timeOfDayFromString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final now = current.hour * 60 + current.minute;
    final startTime = start.hour * 60 + start.minute;
    final endTime = end.hour * 60 + end.minute;
    return now >= startTime && now < endTime;
  }

  bool _isTimeBefore(TimeOfDay current, TimeOfDay time) {
    final now = current.hour * 60 + current.minute;
    final targetTime = time.hour * 60 + time.minute;
    return now < targetTime;
  }
}
