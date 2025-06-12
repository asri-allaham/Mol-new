import 'package:Mollni/Dartpages/HomePage/placeholders.dart';
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
    user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid != null) {
      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('currentUserId', isEqualTo: uid)
          .get();

      final favoriteList =
          favoritesSnapshot.docs.map((doc) => doc.data()).toList();

      List<Map<String, dynamic>> fetchedProjects = [];

      for (var favorite in favoriteList) {
        final projectNumber = favorite['numberProject'];
        final projectOwner = favorite['userID_owner'];

        final projectsSnapshot = await FirebaseFirestore.instance
            .collection('projects')
            .where('projectNumber', isEqualTo: projectNumber as int)
            .where('user_id', isEqualTo: projectOwner as String)
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

  Map<String, dynamic>? getProjectFromLocalList(
      String userId, int projectNumber) {
    try {
      return Projects.firstWhere(
        (project) =>
            project['user_id'] == userId &&
            project['projectNumber'] == projectNumber,
        orElse: () => {},
      );
    } catch (e) {
      print('Error finding project locally: $e');
      return null;
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
                final List<dynamic>? urls = project['image_urls'];
                final hasImage = urls != null && urls.isNotEmpty;

                return InkWell(
                  onTap: () {
                    Map<String, dynamic> Project;
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => Placeholders(project)));
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: hasImage
                          ? Image.network(
                              urls.first,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image);
                              },
                            )
                          : const Icon(Icons.image_not_supported),
                      title: Text(project['name'] ?? 'No Name'),
                      subtitle:
                          Text(project['description'] ?? 'No Description'),
                      trailing:
                          Text('Project #: ${project['projectNumber'] ?? "-"}'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
