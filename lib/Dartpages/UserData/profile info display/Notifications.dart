import 'package:Mollni/Dartpages/UserData/profile%20info%20display/NotificationService.dart';
import 'package:flutter/material.dart';
import '../switch.dart';
import '../profile_information.dart';
import 'NotificationsSiting.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<Notifications> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffECECEC),
      appBar: AppBar(
        backgroundColor: const Color(0xffECECEC),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff002114)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: const IconThemeData(color: Color(0xff002114)),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Color(0xff002114),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 21),
        children: [
          // قسم Common
          const Text(
            "Common",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff002114),
            ),
          ),
          const SizedBox(height: 10),
          PrivacySection(
            title: "General Notification",
            value: generalNotification,
            onChanged: (value) => setState(() => generalNotification = value),
          ),
          PrivacySection(
            title: "Sound",
            value: soundEnabled,
            onChanged: (value) => setState(() => soundEnabled = value),
          ),
          PrivacySection(
            title: "Vibrate",
            value: vibrateEnabled,
            onChanged: (value) => setState(() => vibrateEnabled = value),
          ),

          const SizedBox(height: 12),
          Container(color: const Color(0xffBDBDBD), height: 1),
          const SizedBox(height: 12),

          const Text(
            "System & services update",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff002114),
            ),
          ),
          const SizedBox(height: 10),
          PrivacySection(
            title: "App updates",
            value: appUpdates,
            onChanged: (value) async {
              setState(() => appUpdates = value);
              if (value) {
                await NotificationService.showNotification(
                  id: 2,
                  title: 'appUpdates Reminder Enabled',
                  body:
                      'You will now receive reminders about your app Updates.',
                );
              }
            },
          ),
          PrivacySection(
            title: "mesages",
            value: billReminder,
            onChanged: (value) async {
              setState(() => billReminder = value);
              if (value) {
                await NotificationService.showNotification(
                  id: 1,
                  title: 'mesages Reminder Enabled',
                  body: 'You will now receive reminders about your mesages.',
                );
              }
            },
          ),

          const SizedBox(height: 12),
          Container(color: const Color(0xffBDBDBD), height: 1),
          const SizedBox(height: 12),

          const Text(
            "Others",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff002114),
            ),
          ),
          const SizedBox(height: 10),
          PrivacySection(
            title: "New Service Available",
            value: newServiceAvailable,
            onChanged: (value) => setState(() => newServiceAvailable = value),
          ),
          PrivacySection(
            title: "New Tips Available",
            value: newTipsAvailable,
            onChanged: (value) => setState(() => newTipsAvailable = value),
          ),
        ],
      ),
    );
  }
}
