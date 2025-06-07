import 'package:flutter/material.dart';

class Viewproject extends StatefulWidget {
  final Map<String, dynamic> projectData;

  const Viewproject({
    super.key,
    required this.projectData,
  });

  @override
  State<Viewproject> createState() => _ViewprojectState();
}

class _ViewprojectState extends State<Viewproject> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectData['title'] ?? 'Project Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${widget.projectData['title']}'),
            Text('Description: ${widget.projectData['description']}'),
            Text('Start Date: ${widget.projectData['startDate']}'),
            Text('Status: ${widget.projectData['status']}'),
            // Add more fields as needed
          ],
        ),
      ),
    );
  }
}
