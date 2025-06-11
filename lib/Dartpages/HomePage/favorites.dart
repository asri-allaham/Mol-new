import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  User? user;
  List<Map<String, dynamic>> Projects = [];

  Future<void> fetchUserFavorites() async {
    await FirebaseAuth.instance.currentUser?.reload();
    user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid != null) {
      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userID_owner', isEqualTo: uid)
          .get();

      final favoriteList =
          favoritesSnapshot.docs.map((doc) => doc.data()).toList();

      List<Map<String, dynamic>> fetchedProjects = [];

      for (var favorite in favoriteList) {
        final projectNumber = favorite['numberProject'];
        final projectOwner = favorite['currentUserId'];

        final projectsSnapshot = await FirebaseFirestore.instance
            .collection('projects')
            .where('projectNumber', isEqualTo: projectNumber)
            .where('user_id', isEqualTo: projectOwner)
            .get();

        for (var doc in projectsSnapshot.docs) {
          fetchedProjects.add(doc.data());
        }
      }

      setState(() {
        Projects = fetchedProjects;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorite Projects'),
      ),
      body: Projects.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: Projects.length,
              itemBuilder: (context, index) {
                final project = Projects[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  child: ListTile(
                    title: Text(project['title'] ?? 'No Title'),
                    subtitle: Text(project['description'] ?? 'No Description'),
                    trailing: Text('Project #: ${project['projectNumber']}'),
                  ),
                );
              },
            ),
    );
  }
}
