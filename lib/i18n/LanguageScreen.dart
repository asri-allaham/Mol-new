import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageScreen extends StatelessWidget {
  final List<String> languages = [
    "English(US)",
    "English(UK)",
    "Chinese",
    "Hindi",
    "Spanish",
    "French",
    "Arabic",
    "Russian",
    "Indonesian",
    "Vietnamese"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Language").tr()),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(languages[index]),
            onTap: () {
              Navigator.pop(context, index);
            },
          );
        },
      ),
    );
  }
}
