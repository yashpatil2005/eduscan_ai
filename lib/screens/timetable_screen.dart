import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:eduscan_ai/models/class_model.dart';
import 'package:eduscan_ai/screens/add_class_popup.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;
  ClassModel? _ongoingClass;
  String _timeRemaining = '';
  double _progress = 0.0;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Consistent design tokens
  static const Color _primaryColor = Color(0xFF6C63FF);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _cardBackgroundColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF1A1A1A);
  static const Color _textSecondaryColor = Color(0xFF6B7280);
  static const Color _surfaceColor = Color(0xFFF3F4F6);
  static const Color _dangerColor = Color(0xFFEF4444);

  static const double _borderRadiusSmall = 12.0;
  static const double _borderRadiusMedium = 16.0;
  static const double _borderRadiusLarge = 20.0;
  static const double _borderRadiusXLarge = 24.0;

  static const double _paddingSmall = 12.0;
  static const double _paddingMedium = 16.0;
  static const double _paddingLarge = 20.0;
  static const double _paddingXLarge = 24.0;

  @override
  void initState() {
    super.initState();
    int initialIndex = (DateTime.now().weekday - 1) % 7;
    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateOngoingClass();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _updateOngoingClass() {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final currentDay = _days[now.weekday - 1];
    final box = Hive.box<ClassModel>('classes');

    ClassModel? currentClass;
    for (var cls in box.values) {
      if (cls.day == currentDay) {
        final startTime = _timeOfDayFromString(cls.startTime);
        final endTime = _timeOfDayFromString(cls.endTime);
        if (_isTimeBetween(currentTime, startTime, endTime)) {
          currentClass = cls;
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        _ongoingClass = currentClass;
        if (currentClass != null) {
          final startTime = _timeOfDayFromString(currentClass.startTime);
          final endTime = _timeOfDayFromString(currentClass.endTime);

          final startDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            startTime.hour,
            startTime.minute,
          );
          final endDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            endTime.hour,
            endTime.minute,
          );

          final totalDuration = endDateTime.difference(startDateTime);
          final durationPassed = now.difference(startDateTime);
          final durationRemaining = endDateTime.difference(now);

          _timeRemaining = _formatDuration(durationRemaining);
          _progress = (durationPassed.inSeconds / totalDuration.inSeconds)
              .clamp(0.0, 1.0);
        }
      });
    }
  }

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

  String _formatDuration(Duration d) {
    d = d + const Duration(seconds: 1);
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    } else {
      return '${minutes}m remaining';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: _cardBackgroundColor,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(
                  left: _paddingXLarge,
                  bottom: _paddingMedium,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  color: _cardBackgroundColor,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: _primaryColor,
                    unselectedLabelColor: _textSecondaryColor,
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(color: _primaryColor, width: 3),
                      insets: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                    tabs: _days
                        .map((day) => Tab(text: day, height: 45))
                        .toList(),
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: _days.map((day) => _buildDaySchedule(day)).toList(),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showAddClassPopup(context),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadiusMedium),
        ),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text(
          'Add Class',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildDaySchedule(String day) {
    return ValueListenableBuilder<Box<ClassModel>>(
      valueListenable: Hive.box<ClassModel>('classes').listenable(),
      builder: (context, box, _) {
        final classes = box.values.where((cls) => cls.day == day).toList();
        classes.sort((a, b) => a.startTime.compareTo(b.startTime));
        final isToday = day == _days[DateTime.now().weekday - 1];

        return CustomScrollView(
          slivers: [
            if (isToday && _ongoingClass != null) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _paddingLarge,
                    _paddingXLarge,
                    _paddingLarge,
                    _paddingMedium,
                  ),
                  child: _buildOngoingClassCard(
                    _ongoingClass!,
                    _timeRemaining,
                    _progress,
                  ),
                ),
              ),
            ],
            if (classes.isEmpty && !(isToday && _ongoingClass != null))
              SliverFillRemaining(child: _buildEmptyState(day))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  _paddingLarge,
                  0,
                  _paddingLarge,
                  100,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: _paddingMedium),
                      child: _buildClassCard(classes[index]),
                    ),
                    childCount: classes.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOngoingClassCard(
    ClassModel cls,
    String timeRemaining,
    double progress,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(cls.colorHex), Color(cls.colorHex).withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_borderRadiusXLarge),
        boxShadow: [
          BoxShadow(
            color: Color(cls.colorHex).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(_paddingXLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusBadge(),
                const Spacer(),
                _buildOngoingIcon(),
              ],
            ),
            const SizedBox(height: _paddingLarge),
            Text(
              cls.subject,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 28,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cls.category,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: _paddingXLarge),
            _buildProgressRow(progress, timeRemaining),
            const SizedBox(height: _paddingLarge),
            _buildClassDetails(cls),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(_paddingLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "ONGOING NOW",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(_borderRadiusSmall),
      ),
      child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 20),
    );
  }

  Widget _buildProgressRow(double progress, String timeRemaining) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white.withOpacity(0.3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: _paddingMedium),
        Text(
          timeRemaining,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildClassDetails(ClassModel cls) {
    return Row(
      children: [
        if (cls.instructor.isNotEmpty) ...[
          const Icon(Icons.person_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            cls.instructor,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (cls.instructor.isNotEmpty && cls.location.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _paddingMedium),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        if (cls.location.isNotEmpty) ...[
          const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            cls.location,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClassCard(ClassModel cls) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(_borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(_paddingLarge),
        child: Row(
          children: [
            _buildColorIndicator(cls.colorHex),
            const SizedBox(width: 18),
            _buildTimeColumn(cls),
            const SizedBox(width: 18),
            Expanded(child: _buildClassInfo(cls)),
            const SizedBox(width: _paddingSmall),
            _buildActionButtons(cls),
          ],
        ),
      ),
    );
  }

  Widget _buildColorIndicator(int colorHex) {
    return Container(
      width: 6,
      height: 85,
      decoration: BoxDecoration(
        color: Color(colorHex),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildTimeColumn(ClassModel cls) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _paddingMedium,
        vertical: _paddingMedium,
      ),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            cls.startTime,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: _textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 2,
            height: 14,
            decoration: BoxDecoration(
              color: _textSecondaryColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cls.endTime,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: _textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfo(ClassModel cls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cls.subject,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _textPrimaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          cls.category,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _textSecondaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        if (cls.instructor.isNotEmpty || cls.location.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cls.instructor.isNotEmpty)
                _buildInfoRow(Icons.person_rounded, cls.instructor),
              if (cls.instructor.isNotEmpty && cls.location.isNotEmpty)
                const SizedBox(height: 6),
              if (cls.location.isNotEmpty)
                _buildInfoRow(Icons.location_on_rounded, cls.location),
            ],
          ),
      ],
    );
  }

  Widget _buildActionButtons(ClassModel cls) {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.edit_rounded,
          backgroundColor: _surfaceColor,
          iconColor: const Color(0xFF374151),
          onPressed: () => _showAddClassPopup(context, existingClass: cls),
        ),
        const SizedBox(height: 10),
        _buildActionButton(
          icon: Icons.delete_rounded,
          backgroundColor: _dangerColor.withOpacity(0.1),
          iconColor: _dangerColor,
          onPressed: () => _showDeleteDialog(cls),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_borderRadiusSmall),
      ),
      child: IconButton(
        icon: Icon(icon, size: 22, color: iconColor),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF374151)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String day) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(_paddingXLarge),
            decoration: BoxDecoration(
              color: _surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: _paddingXLarge),
          Text(
            'No classes today',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy your free time or add a new class',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddClassPopup(BuildContext context, {ClassModel? existingClass}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _cardBackgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_borderRadiusXLarge),
          ),
        ),
        child: AddClassPopup(existingClass: existingClass),
      ),
    );
  }

  void _showDeleteDialog(ClassModel cls) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadiusLarge),
        ),
        title: Text(
          "Delete Class?",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        content: Text(
          "Are you sure you want to delete '${cls.subject}'?",
          style: GoogleFonts.inter(fontSize: 16, color: _textSecondaryColor),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: _paddingLarge,
                vertical: _paddingSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadiusSmall),
              ),
            ),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                color: _textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: _dangerColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: _paddingLarge,
                vertical: _paddingSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadiusSmall),
              ),
            ),
            child: Text(
              "Delete",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            onPressed: () async {
              await cls.delete();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
