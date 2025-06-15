import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<DashBoard> {
  Map<String, List<Map<String, dynamic>>> sortedReports = {
    'postReports': [],
    'commentReports': [],
    'projectReports': [],
  };

  bool loading = true;
  late String loadingMessage;
  final List<String> investmentMessages = [
    "Geting reports...",
    "feel like a king?",
    "Loading bad people?",
    "Scanning reports...",
    "Getting Ui ready...",
    "Smart decisions ahead...Get ready!",
    "Optimizing environment...",
    "Preparing tools...",
    "loading...",
    'any one reading this?'
  ];
  bool _isButtonDisabled = false;

  @override
  void initState() {
    super.initState();
    loadReports();
    loadingMessage =
        investmentMessages[Random().nextInt(investmentMessages.length)];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadReports() async {
    final reports = await getAllReportsSortedByCount();
    setState(() {
      sortedReports = reports;
      loading = false;
    });
  }

  Future<Map<String, List<Map<String, dynamic>>>>
      getAllReportsSortedByCount() async {
    List<Map<String, dynamic>> postReportList = [];
    List<Map<String, dynamic>> commentReportList = [];
    List<Map<String, dynamic>> projectReportList = [];

    final postsSnapshot =
        await FirebaseFirestore.instance.collection('post').get();

    for (var postDoc in postsSnapshot.docs) {
      final postId = postDoc.id;

      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('post')
          .doc(postId)
          .collection('reports')
          .get();

      final reportCount = reportsSnapshot.docs.length;

      if (reportCount > 0) {
        postReportList.add({
          'postId': postId,
          'reportCount': reportCount,
          'reports': reportsSnapshot.docs.map((doc) => doc.data()).toList(),
        });
      }
    }

    final projectsSnapshot =
        await FirebaseFirestore.instance.collection('projects').get();

    for (var projectDoc in projectsSnapshot.docs) {
      final projectId = projectDoc.id;

      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('reports')
          .get();

      if (reportsSnapshot.docs.isEmpty) continue;

      final commentReports = reportsSnapshot.docs
          .where((doc) => doc.data()['reporttype'] == 'comment')
          .map((doc) => doc.data())
          .toList();

      final projectReports = reportsSnapshot.docs
          .where((doc) => doc.data()['reporttype'] == 'Project')
          .map((doc) => doc.data())
          .toList();

      if (commentReports.isNotEmpty) {
        commentReportList.add({
          'projectId': projectId,
          'reportCount': commentReports.length,
          'reports': commentReports,
        });
      }

      if (projectReports.isNotEmpty) {
        projectReportList.add({
          'projectId': projectId,
          'reportCount': projectReports.length,
          'reports': projectReports,
        });
      }
    }

    postReportList.sort((a, b) => b['reportCount'].compareTo(a['reportCount']));
    commentReportList
        .sort((a, b) => b['reportCount'].compareTo(a['reportCount']));
    projectReportList
        .sort((a, b) => b['reportCount'].compareTo(a['reportCount']));

    return {
      'postReports': postReportList,
      'commentReports': commentReportList,
      'projectReports': projectReportList,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                loadingMessage,
                style:
                    const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      );
    }

    final postReports = sortedReports['postReports']!;
    final commentReports = sortedReports['commentReports']!;
    final projectReports = sortedReports['projectReports']!;

    return Scaffold(
      appBar: AppBar(title: const Text("Reports Overview")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (postReports.isNotEmpty) ...[
            const Text('Post Reports',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...postReports.map((entry) {
              final postId = entry['postId'];
              final count = entry['reportCount'];
              final reports = entry['reports'] as List;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ExpansionTile(
                  title: Text('Post ID: $postId'),
                  subtitle: Text('Reports: $count'),
                  children: reports.map<Widget>((r) {
                    return ListTile(
                      title: Text("Reason: ${r['reason'] ?? 'N/A'}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Type: ${r['reporttype'] ?? 'N/A'}"),
                          Text("User: ${r['userUid'] ?? 'N/A'}"),
                          Text("Time: ${r['timeOfReport']?.toDate() ?? 'N/A'}"),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
            const Divider(height: 24),
          ],
          if (commentReports.isNotEmpty) ...[
            const Text('Project Comment Reports',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...commentReports.map((entry) {
              final projectId = entry['projectId'];
              final count = entry['reportCount'];
              final reports = entry['reports'] as List;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ExpansionTile(
                  title: Text('Project ID: $projectId'),
                  subtitle: Text('Reports: $count'),
                  children: reports.map<Widget>((r) {
                    return ListTile(
                      title: Text("Reason: ${r['reason'] ?? 'N/A'}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Type: ${r['reporttype'] ?? 'N/A'}"),
                          Text("User: ${r['userUid'] ?? 'N/A'}"),
                          Text("Time: ${r['timeOfReport']?.toDate() ?? 'N/A'}"),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
            const Divider(height: 24),
          ],
          if (projectReports.isNotEmpty) ...[
            const Text('Project Reports',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...projectReports.map((entry) {
              final projectId = entry['projectId'];
              final count = entry['reportCount'];
              final reports = entry['reports'] as List;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ExpansionTile(
                  title: Text('Project ID: $projectId'),
                  subtitle: Text('Reports: $count'),
                  children: reports.map<Widget>((r) {
                    return ListTile(
                      title: Text("Reason: ${r['reason'] ?? 'N/A'}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Type: ${r['reporttype'] ?? 'N/A'}"),
                          Text("User: ${r['userUid'] ?? 'N/A'}"),
                          Text("Time: ${r['timeOfReport']?.toDate() ?? 'N/A'}"),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Reject Confirmation"),
                                  content: const Text(
                                      "Rejecting this item will increase its warning count. Are you sure?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        _isButtonDisabled = false;
                                        Navigator.of(context).pop();

                                        final projectDocRef = FirebaseFirestore
                                            .instance
                                            .collection('projects')
                                            .doc(projectId);

                                        final projectDoc =
                                            await projectDocRef.get();

                                        if (projectDoc.exists) {
                                          final projectData = projectDoc.data();
                                          final currentWarnings =
                                              projectData?['warningCount'] ?? 0;
                                          print(projectData?['name']);

                                          await projectDocRef.update({
                                            'warningCount': currentWarnings + 1,
                                          });
                                          final reportsCollection =
                                              projectDocRef
                                                  .collection('reports');
                                          final reportsSnapshot =
                                              await reportsCollection.get();

                                          for (final doc
                                              in reportsSnapshot.docs) {
                                            await doc.reference.delete();
                                          }
                                          print(
                                              'warningCount $currentWarnings');
                                          if (currentWarnings > 3) {
                                            projectDocRef.update({
                                              "removed": true,
                                            });
                                          }
                                        } else {
                                          print('Project not found.');
                                        }
                                      },
                                      child: const Text("add Warnings"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text("add Warnings?"),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
