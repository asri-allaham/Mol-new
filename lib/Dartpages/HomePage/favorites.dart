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

  Future<void> removeFavorite(int projectNumber, String userId) async {
    final uid = user?.uid;
    if (uid != null) {
      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('currentUserId', isEqualTo: uid)
          .where('numberProject', isEqualTo: projectNumber)
          .where('userID_owner', isEqualTo: userId)
          .get();

      for (var doc in favoritesSnapshot.docs) {
        await doc.reference.delete();
      }
      await fetchUserFavorites();
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
        title: const Text(
          'My Favorite Projects',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xff387752),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() => fetchUserFavorites()),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffF0F4F1), Color(0xffE8ECEA)],
          ),
        ),
        child: Projects.isEmpty
            ? const Center(
                child: Text(
                  'Add some projects to favorites !',
                  style: TextStyle(
                    color: Color(0xff2E5D4F),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => await fetchUserFavorites(),
                color: const Color(0xff387752),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: Projects.length,
                  itemBuilder: (context, index) {
                    final project = Projects[index];
                    final List<dynamic>? urls = project['image_urls'];
                    final hasImage = urls != null && urls.isNotEmpty;
                    final investmentAmount =
                        project['investment_amount'] ?? 'N/A';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        shadowColor: Colors.black26,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => Placeholders(project),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Colors.green.withOpacity(0.3),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: hasImage
                                      ? Image.network(
                                          urls.first,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.broken_image,
                                              size: 40,
                                              color: Colors.grey,
                                            );
                                          },
                                        )
                                      : Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project['name'] ?? 'No Name',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Color(0xff2E5D4F),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        project['description'] ??
                                            'No Description',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Investment: \$${investmentAmount.toString()}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xff387752),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.heart_broken,
                                    color: Color(0xffEF0000),
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    removeFavorite(project['projectNumber'],
                                        project['user_id']);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
