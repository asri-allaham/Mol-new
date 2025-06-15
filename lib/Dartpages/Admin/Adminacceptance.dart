import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserOverview extends StatefulWidget {
  const UserOverview({super.key});

  @override
  State<UserOverview> createState() => _UserOverviewState();
}

class _UserOverviewState extends State<UserOverview>
    with TickerProviderStateMixin {
  bool _loading = true;
  List<DocumentSnapshot> _projects = [];
  List<DocumentSnapshot> _posts = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final projectSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('Adminacceptance', isEqualTo: false)
          .where('removed', isEqualTo: false)
          .get();

      final postSnapshot = await FirebaseFirestore.instance
          .collection('post')
          .where('Adminacceptance', isEqualTo: false)
          .where('removed', isEqualTo: false)
          .get();

      setState(() {
        _projects = projectSnapshot.docs;
        _posts = postSnapshot.docs;
        _loading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildProjectList() {
    if (_projects.isEmpty) {
      return const Center(
        child: Text(
          'No pending projects found',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Pending Projects:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ..._projects.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final List<String> imageUrls =
              (data['image_urls'] as List?)?.cast<String>() ?? [];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: SizedBox(
                    width: 100,
                    child: imageUrls.isEmpty
                        ? const Icon(Icons.image_not_supported)
                        : Row(
                            children: imageUrls.map((url) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Image.network(
                                  url,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  title: Text(data['name'] ?? 'Unnamed Project'),
                  subtitle: Text(
                    'Category: ${data['category'] ?? 'N/A'}\nInvestment: \$${data['investment_amount'] ?? 0}',
                  ),
                ),
                // Buttons Section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          _acceptProject(doc.id);
                          fetchData();
                        },
                        icon: const Icon(Icons.check, color: Colors.green),
                        label: const Text('Accept'),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.green),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          _rejectProject(doc.id);
                          fetchData();
                        },
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject'),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPostList() {
    if (_posts.isEmpty) {
      return const Center(
        child: Text(
          'No pending projects found',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Pending Projects:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ..._posts.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final List<String> imageUrls =
              (data['image_urls'] as List?)?.cast<String>() ?? [];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: SizedBox(
                    width: 100,
                    child: imageUrls.isEmpty
                        ? const Icon(Icons.image_not_supported)
                        : Row(
                            children: imageUrls.map((url) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Image.network(
                                  url,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  title: Text(data['name'] ?? 'Unnamed Project'),
                  subtitle: Text(
                    'description: ${data['description'] ?? 'N/A'}}',
                  ),
                ),
                // Buttons Section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          _acceptPost(doc.id);
                          fetchData();
                        },
                        icon: const Icon(Icons.check, color: Colors.green),
                        label: const Text('Accept'),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.green),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          _rejectPost(doc.id);
                          fetchData();
                        },
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject'),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_projects.isEmpty && _posts.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: const Center(
          child: Text(
            'None were found for the posts and project',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.green[50],
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.green[800],
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.green,
              tabs: const [
                Tab(text: 'Posts'),
                Tab(text: 'Projects'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostList(),
                _buildProjectList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _acceptProject(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(docId)
          .update({
        'Adminacceptance': true,
      });
      print("✅ Project accepted and status updated!");
    } catch (e) {
      print("❌ Error updating document: $e");
    }
  }

  void _rejectProject(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(docId)
          .update({
        'removed': true,
      });
      print("✅ Project rejected and status updated!");
    } catch (e) {
      print("❌ Error updating document: $e");
    }
  }

  void _acceptPost(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('post').doc(docId).update({
        'Adminacceptance': true,
      });
      print("✅ Project accepted and status updated!");
    } catch (e) {
      print("❌ Error updating document: $e");
    }
  }

  void _rejectPost(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('post').doc(docId).update({
        'removed': true,
      });
      print("✅ Project rejected and status updated!");
    } catch (e) {
      print("❌ Error updating document: $e");
    }
  }
}
