import 'package:MOLLILE/Dartpages/Communicate%20with%20investor/business%20owners/ChatPageOldV.dart';
import 'package:MOLLILE/Dartpages/CustomWidget/SearchBox.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController searchController = TextEditingController();

  List<DocumentSnapshot> allUsers = [];
  List<DocumentSnapshot> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      allUsers = snapshot.docs;
      filteredUsers = allUsers;
    });
  }

  void onSearchChanged(String query) {
    query = query.toLowerCase();
    setState(() {
      filteredUsers = allUsers.where((user) {
        final name = user['name']?.toString().toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          CustomSearchBox(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final isCurrentUser = user.id == currentUser?.uid;

                return Card(
                  color: isCurrentUser ? Colors.blue.shade100 : Colors.white,
                  child: ListTile(
                    leading: Icon(
                        isCurrentUser ? Icons.person : Icons.account_circle),
                    title: Text(user['username'] ?? 'No Name'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['email'] ?? ''),
                        const SizedBox(height: 8),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            otherUserId: user.id,
                            otherUserEmail: user['email'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
