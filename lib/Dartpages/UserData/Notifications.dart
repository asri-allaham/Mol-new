import 'package:flutter/material.dart';
import 'switch.dart';
import 'profile_information.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<Notifications> {
  // حالات جميع أزرار التبديل
  bool _generalNotification = true;
  bool _soundEnabled = true;
  bool _vibrateEnabled = true;
  bool _appUpdates = true;
  bool _billReminder = true;
  bool _promotion = true;
  bool _discountAvailable = true;
  bool _paymentRequest = true;
  bool _newServiceAvailable = true;
  bool _newTipsAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffECECEC),
      appBar: AppBar(
        backgroundColor: const Color(0xffECECEC),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff002114)),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileInformation(
                    // sound: _soundEnabled ? 'on' : 'off', not used yet
                    ),
              ),
            );
          },
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
            value: _generalNotification,
            onChanged: (value) => setState(() => _generalNotification = value),
          ),
          PrivacySection(
            title: "Sound",
            value: _soundEnabled,
            onChanged: (value) => setState(() => _soundEnabled = value),
          ),
          PrivacySection(
            title: "Vibrate",
            value: _vibrateEnabled,
            onChanged: (value) => setState(() => _vibrateEnabled = value),
          ),

          // خط فاصل بين القوائم الرئيسية
          const SizedBox(height: 12),
          Container(color: const Color(0xffBDBDBD), height: 1),
          const SizedBox(height: 12),

          // قسم System & services update
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
            value: _appUpdates,
            onChanged: (value) => setState(() => _appUpdates = value),
          ),
          PrivacySection(
            title: "Bill Reminder",
            value: _billReminder,
            onChanged: (value) => setState(() => _billReminder = value),
          ),
          PrivacySection(
            title: "Promotion",
            value: _promotion,
            onChanged: (value) => setState(() => _promotion = value),
          ),
          PrivacySection(
            title: "Discount Available",
            value: _discountAvailable,
            onChanged: (value) => setState(() => _discountAvailable = value),
          ),
          PrivacySection(
            title: "Payment Request",
            value: _paymentRequest,
            onChanged: (value) => setState(() => _paymentRequest = value),
          ),

          // خط فاصل بين القوائم الرئيسية
          const SizedBox(height: 12),
          Container(color: const Color(0xffBDBDBD), height: 1),
          const SizedBox(height: 12),

          // قسم Others
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
            value: _newServiceAvailable,
            onChanged: (value) => setState(() => _newServiceAvailable = value),
          ),
          PrivacySection(
            title: "New Tips Available",
            value: _newTipsAvailable,
            onChanged: (value) => setState(() => _newTipsAvailable = value),
          ),
        ],
      ),
    );
  }
}
