// notification_service.dart (Enhanced Version - Fixed)
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:eduscan_ai/models/class_model.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Timer? _lectureUpdateTimer;
  static const int _ongoingLectureNotificationId = 2001;

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Requests notification permissions from the user.
  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // ========== EXISTING TASK NOTIFICATION METHODS ==========
  Future<void> scheduleTaskNotifications({
    required int taskId,
    required String title,
    required DateTime taskDateTime,
    int? reminderDaysBefore,
  }) async {
    await _scheduleNotification(
      id: taskId,
      title: 'Reminder: $title',
      body:
          'Your task is scheduled for today at ${DateFormat.jm().format(taskDateTime)}.',
      scheduledTime: taskDateTime,
    );

    if (reminderDaysBefore != null && reminderDaysBefore > 0) {
      final upcomingTime = taskDateTime.subtract(
        Duration(days: reminderDaysBefore),
      );
      final upcomingId = taskId + 1000000;

      await _scheduleNotification(
        id: upcomingId,
        title: 'Upcoming Task: $title',
        body: 'This task is due on ${DateFormat.yMMMd().format(taskDateTime)}.',
        scheduledTime: upcomingTime,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint(
        "Attempted to schedule a notification for a past time. Skipping.",
      );
      return;
    }

    debugPrint(
      "Scheduling notification '$title' for $scheduledTime with ID $id",
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'eduscan_ai_channel_id',
          'EduScanAI Reminders',
          channelDescription: 'Channel for EduScanAI task reminders',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('reminder_sound'),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTaskNotifications(int taskId) async {
    await flutterLocalNotificationsPlugin.cancel(taskId);
    await flutterLocalNotificationsPlugin.cancel(taskId + 1000000);
  }

  // ========== NEW ONGOING LECTURE NOTIFICATION METHODS ==========

  /// Start monitoring and showing ongoing lecture notifications
  Future<void> startOngoingLectureMonitoring() async {
    _lectureUpdateTimer?.cancel();

    // Update every 30 seconds
    _lectureUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateOngoingLectureNotification();
    });

    // Initial update
    _updateOngoingLectureNotification();
  }

  /// Stop monitoring ongoing lectures
  Future<void> stopOngoingLectureMonitoring() async {
    _lectureUpdateTimer?.cancel();
    await flutterLocalNotificationsPlugin.cancel(_ongoingLectureNotificationId);
  }

  /// Update the ongoing lecture notification
  Future<void> _updateOngoingLectureNotification() async {
    final ongoingClass = _getCurrentOngoingClass();

    if (ongoingClass != null) {
      await _showOngoingLectureNotification(ongoingClass);
    } else {
      // Cancel notification if no ongoing class
      await flutterLocalNotificationsPlugin.cancel(
        _ongoingLectureNotificationId,
      );
    }
  }

  /// Get current ongoing class
  ClassModel? _getCurrentOngoingClass() {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final currentDay = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][now.weekday - 1];

    try {
      final box = Hive.box<ClassModel>('classes');

      for (var cls in box.values) {
        if (cls.day == currentDay) {
          final startTime = _timeOfDayFromString(cls.startTime);
          final endTime = _timeOfDayFromString(cls.endTime);
          if (_isTimeBetween(currentTime, startTime, endTime)) {
            return cls;
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting ongoing class: $e');
    }

    return null;
  }

  /// Show the ongoing lecture notification with progress and custom style
  Future<void> _showOngoingLectureNotification(ClassModel cls) async {
    try {
      final now = DateTime.now();
      final startTime = _timeOfDayFromString(cls.startTime);
      final endTime = _timeOfDayFromString(cls.endTime);

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

      final progress = (durationPassed.inSeconds / totalDuration.inSeconds)
          .clamp(0.0, 1.0);
      final progressPercentage = (progress * 100).round();

      String timeRemainingText;
      if (durationRemaining.inHours > 0) {
        timeRemainingText =
            '${durationRemaining.inHours}h ${durationRemaining.inMinutes.remainder(60)}m remaining';
      } else {
        timeRemainingText = '${durationRemaining.inMinutes}m remaining';
      }

      // Create notification with rich content
      final androidDetails = AndroidNotificationDetails(
        'ongoing_lecture_channel',
        'Ongoing Lectures',
        channelDescription: 'Shows current ongoing lecture with progress',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: progressPercentage,
        color: Color(cls.colorHex),
        colorized: true,
        playSound: false, // Don't play sound for updates
        enableVibration: false, // Don't vibrate for updates
        styleInformation: BigTextStyleInformation(
          '${cls.subject}\n'
          '📍 ${cls.location}\n'
          '👨‍🏫 ${cls.instructor}\n'
          '⏰ ${cls.startTime} - ${cls.endTime}\n'
          '📊 ${progressPercentage}% complete\n'
          '⏳ $timeRemainingText',
          contentTitle: '📚 Ongoing Lecture',
          summaryText: timeRemainingText,
        ),
        category: AndroidNotificationCategory.event,
        visibility: NotificationVisibility.public,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        _ongoingLectureNotificationId,
        '📚 ${cls.subject}',
        '$timeRemainingText • ${progressPercentage}% complete',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing ongoing lecture notification: $e');
    }
  }

  /// Utility methods for time handling
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

  /// Schedule a notification before class starts (optional feature)
  Future<void> scheduleClassReminder(
    ClassModel cls, {
    int minutesBefore = 5,
  }) async {
    try {
      final now = DateTime.now();
      final startTime = _timeOfDayFromString(cls.startTime);

      // Calculate reminder time
      final classDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );

      final reminderTime = classDateTime.subtract(
        Duration(minutes: minutesBefore),
      );

      // Only schedule if reminder time is in the future
      if (reminderTime.isAfter(now)) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          cls.hashCode, // Use hashCode as unique ID
          '⏰ Class Starting Soon',
          '${cls.subject} starts in $minutesBefore minutes at ${cls.location}',
          tz.TZDateTime.from(reminderTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'class_reminders',
              'Class Reminders',
              channelDescription: 'Reminders before classes start',
              importance: Importance.high,
              priority: Priority.high,
              color: Color(cls.colorHex),
              colorized: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling class reminder: $e');
    }
  }

  /// Cancel class reminder
  Future<void> cancelClassReminder(ClassModel cls) async {
    await flutterLocalNotificationsPlugin.cancel(cls.hashCode);
  }
}
