import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:eduscan_ai/models/class_model.dart';
import 'dart:ui';

class AddClassPopup extends StatefulWidget {
  final ClassModel? existingClass;

  const AddClassPopup({super.key, this.existingClass});

  @override
  State<AddClassPopup> createState() => _AddClassPopupState();
}

class _AddClassPopupState extends State<AddClassPopup>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late TextEditingController _instructorController;
  late TextEditingController _locationController;
  late String _selectedDay;
  late String _selectedCategory;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _selectedColorHex;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _categories = ['Lecture', 'Practical'];
  final List<Color> _colors = [
    const Color(0xFFFF6B6B), // Modern red
    const Color(0xFFFF8E92), // Pink
    const Color(0xFFA8E6CF), // Mint green
    const Color(0xFF88D8C0), // Teal
    const Color(0xFF78C6FF), // Sky blue
    const Color(0xFF9B59B6), // Purple
    const Color(0xFFFFD93D), // Yellow
    const Color(0xFFFF9F43), // Orange
    const Color(0xFF6C5CE7), // Indigo
    const Color(0xFF74B9FF), // Light blue
    const Color(0xFFFD79A8), // Rose
    const Color(0xFF55A3FF), // Blue
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    final now = TimeOfDay.now();
    if (widget.existingClass != null) {
      final existing = widget.existingClass!;
      _subjectController = TextEditingController(text: existing.subject);
      _instructorController = TextEditingController(text: existing.instructor);
      _locationController = TextEditingController(text: existing.location);
      _selectedDay = existing.day;
      _selectedCategory = existing.category;
      _startTime = _timeOfDayFromString(existing.startTime);
      _endTime = _timeOfDayFromString(existing.endTime);
      _selectedColorHex = existing.colorHex;
    } else {
      _subjectController = TextEditingController();
      _instructorController = TextEditingController();
      _locationController = TextEditingController();
      _selectedDay = _days[DateTime.now().weekday - 1];
      _selectedCategory = _categories.first;
      _startTime = now;
      _endTime = TimeOfDay(hour: now.hour + 1, minute: now.minute);
      _selectedColorHex = _colors.first.value;
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  TimeOfDay _timeOfDayFromString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white.withOpacity(0.95),
              hourMinuteTextColor: const Color(0xFF2D3748),
              dialBackgroundColor: const Color(0xFFF7FAFC),
              dialHandColor: const Color(0xFF667EEA),
              dialTextColor: const Color(0xFF2D3748),
              entryModeIconColor: const Color(0xFF667EEA),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveClass() {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<ClassModel>('classes');
      final newClass = ClassModel(
        subject: _subjectController.text,
        courseCode: '',
        instructor: _instructorController.text,
        location: _locationController.text,
        category: _selectedCategory,
        day: _selectedDay,
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
        colorHex: _selectedColorHex,
        repeatWeekly: true,
      );

      if (widget.existingClass != null) {
        widget.existingClass!.subject = newClass.subject;
        widget.existingClass!.instructor = newClass.instructor;
        widget.existingClass!.location = newClass.location;
        widget.existingClass!.category = newClass.category;
        widget.existingClass!.day = newClass.day;
        widget.existingClass!.startTime = newClass.startTime;
        widget.existingClass!.endTime = newClass.endTime;
        widget.existingClass!.colorHex = newClass.colorHex;
        widget.existingClass!.save();
      } else {
        box.add(newClass);
      }
      Navigator.of(context).pop();
    }
  }

  Widget _buildGlassMorphicContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withOpacity(0.1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: GoogleFonts.inter(
          color: const Color(0xFF2D3748),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
          labelStyle: GoogleFonts.inter(
            color: const Color(0xFF718096),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: GoogleFonts.inter(
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        style: GoogleFonts.inter(color: const Color(0xFF2D3748)),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
          labelStyle: GoogleFonts.inter(
            color: const Color(0xFF718096),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF667EEA)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF718096),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time.format(context),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF2D3748),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Color Theme',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _colors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final color = _colors[index];
              final isSelected = color.value == _selectedColorHex;
              return GestureDetector(
                onTap: () => setState(() => _selectedColorHex = color.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saveClass,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  widget.existingClass == null ? 'Save Class' : 'Update Class',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 40,
              ),
              child: _buildGlassMorphicContainer(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.existingClass == null
                                          ? 'Add New Class'
                                          : 'Edit Class',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2D3748),
                                      ),
                                    ),
                                    Text(
                                      'Fill in the details below',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF718096),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Subject and Type Row
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildModernTextField(
                                  controller: _subjectController,
                                  label: 'Subject Name',
                                  icon: Icons.book_rounded,
                                  validator: (value) => value!.isEmpty
                                      ? 'Please enter a subject'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _buildModernDropdown(
                                  value: _selectedCategory,
                                  label: 'Type',
                                  icon: Icons.category_rounded,
                                  items: _categories,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedCategory = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Instructor
                          _buildModernTextField(
                            controller: _instructorController,
                            label: 'Instructor (Optional)',
                            icon: Icons.person_rounded,
                          ),
                          const SizedBox(height: 20),

                          // Location
                          _buildModernTextField(
                            controller: _locationController,
                            label: 'Location (Optional)',
                            icon: Icons.location_on_rounded,
                          ),
                          const SizedBox(height: 24),

                          // Day and Time Row
                          _buildModernDropdown(
                            value: _selectedDay,
                            label: 'Day',
                            icon: Icons.calendar_today_rounded,
                            items: _days,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedDay = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeSelector(
                                  label: 'Start Time',
                                  time: _startTime,
                                  icon: Icons.schedule_rounded,
                                  onTap: () => _selectTime(context, true),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTimeSelector(
                                  label: 'End Time',
                                  time: _endTime,
                                  icon: Icons.schedule_rounded,
                                  onTap: () => _selectTime(context, false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Color Selector
                          _buildColorSelector(),
                          const SizedBox(height: 32),

                          // Save Button
                          _buildGradientButton(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
