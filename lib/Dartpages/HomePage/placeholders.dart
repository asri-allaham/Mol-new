import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Placeholders extends StatefulWidget {
  final Map<String, dynamic> projectList;

  const Placeholders(this.projectList, {super.key});

  @override
  State<Placeholders> createState() => _PlaceholdersState();
}

class _PlaceholdersState extends State<Placeholders> {
  final formatter = NumberFormat.currency(symbol: "\$");
  final dateFormatter = DateFormat('yMMMd');
  Map<String, dynamic>? _userData;

  @override
  Widget build(BuildContext context) {
    final project = widget.projectList;
    Future<void> fetchUserData() async {
      if (project['user_id'] != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(project['user_id'])
            .get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data();
          });
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Details"),
        backgroundColor: const Color(0xff012C19),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(Icons.business, 'Name', project['name']),
                _buildField(Icons.person, 'User Name', project['user_id']),
                _buildField(
                    Icons.monetization_on,
                    'Investment Amount',
                    project['investment_amount'] != null
                        ? formatter.format(project['investment_amount'])
                        : 'N/A'),
                _buildField(
                    Icons.description, 'Description', project['description']),
                _buildField(Icons.category, 'Category', project['category']),
                _buildField(
                    Icons.calendar_today,
                    'Created At',
                    project['created_at'] != null
                        ? dateFormatter.format(
                            (project['created_at'] as Timestamp).toDate(),
                          )
                        : 'N/A'),
                const SizedBox(height: 20),
                const Text(
                  'Images:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (project['image_urls'] is List)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: (project['image_urls'] as List)
                        .map<Widget>((url) => ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                url,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ))
                        .toList(),
                  )
                else
                  const Text("No images available"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal[700]),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
