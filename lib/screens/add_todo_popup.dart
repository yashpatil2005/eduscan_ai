import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:eduscan_ai/models/todo_model.dart';
import 'package:eduscan_ai/main.dart';

class AddTodoPopup extends StatefulWidget {
  final TodoModel? existingTodo;
  final DateTime selectedDate;

  const AddTodoPopup({
    super.key,
    this.existingTodo,
    required this.selectedDate,
  });

  @override
  State<AddTodoPopup> createState() => _AddTodoPopupState();
}

class _AddTodoPopupState extends State<AddTodoPopup> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _taskDateTime;
  late String _selectedCategory;
  late int _selectedColorHex;
  late bool _isCompleted;
  late bool _reminderEnabled;
  int? _selectedReminderDays;

  final List<String> _categories = [
    'Assignment',
    'Exam',
    'Personal',
    'Write up',
  ];
  final List<Color> _colors = [
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
  ];
  final Map<int, String> _reminderOptions = {
    1: '1 day before',
    2: '2 days before',
    3: '3 days before',
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingTodo != null) {
      final todo = widget.existingTodo!;
      _titleController = TextEditingController(text: todo.title);
      _descriptionController = TextEditingController(text: todo.description);
      _taskDateTime = todo.taskDateTime;
      _selectedCategory = todo.category;
      _selectedColorHex = todo.colorHex;
      _isCompleted = todo.isCompleted;
      _reminderEnabled = todo.reminderEnabled;
      _selectedReminderDays = todo.reminderDaysBefore;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _taskDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        TimeOfDay.now().hour,
        TimeOfDay.now().minute,
      );
      _selectedCategory = _categories.first;
      _selectedColorHex = _colors.first.value;
      _isCompleted = false;
      _reminderEnabled = true;
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _taskDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_taskDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          _taskDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveTodo() {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<TodoModel>('todos');
      final newTodo = TodoModel(
        title: _titleController.text,
        description: _descriptionController.text,
        taskDateTime: _taskDateTime,
        category: _selectedCategory,
        colorHex: _selectedColorHex,
        isCompleted: _isCompleted,
        reminderDaysBefore: _selectedReminderDays,
        reminderEnabled: _reminderEnabled,
      );

      final taskId = widget.existingTodo?.key ?? newTodo.hashCode;
      notificationService.cancelTaskNotifications(taskId);

      if (_reminderEnabled) {
        notificationService.scheduleTaskNotifications(
          taskId: taskId,
          title: newTodo.title,
          taskDateTime: newTodo.taskDateTime,
          reminderDaysBefore: newTodo.reminderDaysBefore,
        );
      }

      if (widget.existingTodo != null) {
        widget.existingTodo!.title = newTodo.title;
        widget.existingTodo!.description = newTodo.description;
        widget.existingTodo!.taskDateTime = newTodo.taskDateTime;
        widget.existingTodo!.category = newTodo.category;
        widget.existingTodo!.colorHex = newTodo.colorHex;
        widget.existingTodo!.isCompleted = newTodo.isCompleted;
        widget.existingTodo!.reminderDaysBefore = newTodo.reminderDaysBefore;
        widget.existingTodo!.reminderEnabled = newTodo.reminderEnabled;
        widget.existingTodo!.save();
      } else {
        box.add(newTodo);
      }
      Navigator.of(context).pop();
    }
  }

  void _deleteTodo() {
    if (widget.existingTodo != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Delete Task?"),
          content: Text(
            "Are you sure you want to delete '${widget.existingTodo!.title}'?",
          ),
          actions: [
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(ctx),
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                notificationService.cancelTaskNotifications(
                  widget.existingTodo!.key,
                );
                widget.existingTodo!.delete();
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingTodo == null ? 'Add New Task' : 'Edit Task',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.existingTodo != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _deleteTodo,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () => _selectDateTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date & Time'),
                  child: Text(
                    DateFormat.yMMMd().add_jm().format(_taskDateTime),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedReminderDays,
                decoration: const InputDecoration(labelText: 'Reminder'),
                hint: const Text('No reminder'),
                items: _reminderOptions.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedReminderDays = v),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enable Reminder'),
                value: _reminderEnabled,
                onChanged: (value) => setState(() => _reminderEnabled = value),
                activeColor: Colors.black,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTodo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Task',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
