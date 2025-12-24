import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eduscan_ai/screens/legal_screen.dart';
import 'package:eduscan_ai/models/class_model.dart';
import 'package:eduscan_ai/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final NotificationService _notificationService = NotificationService();

  bool _isDarkMode = false; // Placeholder for dark mode logic
  bool _ongoingLectureNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  // Load notification preference from SharedPreferences
  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ongoingLectureNotifications =
          prefs.getBool('ongoing_lecture_notifications') ?? true;
    });
  }

  // Save notification preference to SharedPreferences
  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ongoing_lecture_notifications', value);
  }

  // --- Logic for Exporting/Sharing the Timetable ---
  Future<void> _exportTimetable() async {
    final box = Hive.box<ClassModel>('classes');
    if (box.values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your timetable is empty. Nothing to share.'),
        ),
      );
      return;
    }
    final List<Map<String, dynamic>> timetableJson = box.values
        .map((cls) => cls.toJson())
        .toList();
    final String jsonString = jsonEncode(timetableJson);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/timetable.json');
    await file.writeAsString(jsonString);
    Share.shareXFiles([
      XFile(file.path),
    ], text: 'Here is my class timetable for EduScanAI!');
  }

  // --- Logic for Importing a Timetable ---
  Future<void> _importTimetable() async {
    const typeGroup = XTypeGroup(
      label: 'Timetable Files',
      extensions: ['json'],
    );
    final xFile = await openFile(acceptedTypeGroups: [typeGroup]);

    if (xFile != null) {
      final file = File(xFile.path);
      final jsonString = await file.readAsString();
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Timetable?'),
          content: const Text(
            'This will replace your current timetable. Are you sure?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              child: const Text('Import'),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          final List<dynamic> timetableJson = jsonDecode(jsonString);
          final List<ClassModel> newClasses = timetableJson
              .map((json) => ClassModel.fromJson(json as Map<String, dynamic>))
              .toList();
          final box = Hive.box<ClassModel>('classes');
          await box.clear();
          await box.addAll(newClasses);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Timetable imported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error importing file: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _launchEmail(String subject) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'akshrlab@gmail.com',
      queryParameters: {'subject': subject},
    );
    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      debugPrint("Error launching email: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileCard(),
          const SizedBox(height: 24),
          _buildSettingsSection(
            title: "General",
            children: [
              SwitchListTile(
                title: Text('Dark Mode', style: GoogleFonts.inter()),
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() => _isDarkMode = value);
                  // TODO: Implement theme switching logic
                },
                secondary: const Icon(Icons.dark_mode_outlined),
                activeColor: Colors.black,
              ),
            ],
          ),
          _buildSettingsSection(
            title: "Timetable",
            children: [
              SwitchListTile(
                title: Text(
                  'Ongoing Lecture Notifications',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Show notifications with progress for ongoing lectures',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                value: _ongoingLectureNotifications,
                onChanged: (value) async {
                  setState(() {
                    _ongoingLectureNotifications = value;
                  });

                  // Save preference
                  await _saveNotificationPreference(value);

                  // Start or stop notifications based on toggle
                  if (value) {
                    await _notificationService.startOngoingLectureMonitoring();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Ongoing lecture notifications enabled',
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else {
                    await _notificationService.stopOngoingLectureMonitoring();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Ongoing lecture notifications disabled',
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                secondary: const Icon(Icons.notifications_outlined),
                activeColor: Colors.black,
              ),
              _buildSettingsTile(
                icon: Icons.file_upload_outlined,
                title: 'Share Timetable',
                onTap: _exportTimetable,
              ),
              _buildSettingsTile(
                icon: Icons.file_download_outlined,
                title: 'Import Timetable',
                onTap: _importTimetable,
              ),
            ],
          ),
          _buildSettingsSection(
            title: "Feedback & Support",
            children: [
              _buildSettingsTile(
                icon: Icons.lightbulb_outline,
                title: 'Request a Feature',
                onTap: () => _launchEmail('EduScanAI Feature Request'),
              ),
              _buildSettingsTile(
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug',
                onTap: () => _launchEmail('EduScanAI Bug Report'),
              ),
            ],
          ),
          _buildSettingsSection(
            title: "About & Legal",
            children: [
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'About EduScanAI',
                onTap: () => _showAboutDialog(context),
              ),
              _buildSettingsTile(
                icon: Icons.code,
                title: 'Open-Source Licenses',
                onTap: () => showLicensePage(context: context),
              ),
              _buildSettingsTile(
                icon: Icons.gavel_outlined,
                title: 'Terms & Conditions',
                onTap: () => _navigateToLegal(
                  context,
                  'Terms & Conditions',
                  'assets/legal/terms.md',
                ),
              ),
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => _navigateToLegal(
                  context,
                  'Privacy Policy',
                  'assets/legal/privacy.md',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: _currentUser?.photoURL != null
                  ? NetworkImage(_currentUser!.photoURL!)
                  : null,
              child: _currentUser?.photoURL == null
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser?.displayName ?? 'Guest User',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser?.email ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 16.0),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: GoogleFonts.inter()),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'EduScanAI',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 akshr LAB',
      children: [
        const Text(
          'EduScanAI is a smart study assistant powered by SyntaxSpace, a subsidiary of akshr LAB.',
        ),
      ],
    );
  }

  void _navigateToLegal(
    BuildContext context,
    String title,
    String markdownFile,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LegalScreen(title: title, markdownFile: markdownFile),
      ),
    );
  }
}
