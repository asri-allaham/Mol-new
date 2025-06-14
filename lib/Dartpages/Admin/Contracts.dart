import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContractsManage extends StatefulWidget {
  const ContractsManage({super.key});

  @override
  State<ContractsManage> createState() => _ContractsManageState();
}

class _ContractsManageState extends State<ContractsManage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _contracts = [];

  Future<void> fetchContracts() async {
    final query = FirebaseFirestore.instance.collection('Contracts');
    final snapshot = await query.get();

    List<Map<String, dynamic>> loadedContracts = [];

    for (var doc in snapshot.docs) {
      final projectData = doc.data();
      final adminAccepted = projectData['Adminacceptance'] ?? false;
      if (adminAccepted == true) continue;

      loadedContracts.add(projectData);
    }

    setState(() {
      _contracts = loadedContracts;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchContracts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Contracts'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _contracts.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                itemCount: _contracts.length,
                itemBuilder: (context, index) {
                  final contract = _contracts[index];
                  final projectId = contract['projectId'] ?? 'Unknown ID';
                  final projectName = contract['Information about Project'][0]
                          ['name'] ??
                      'Unknown Project';
                  final projectDescription =
                      contract['Information about Project'][0]['description'] ??
                          'No description';
                  final adminAcceptance = contract['Information about Project']
                          [0]['Adminacceptance'] ??
                      false;
                  final imageUrls = contract['Information about Project'][0]
                          ['image_urls'] ??
                      [];
                  final imageUrl = imageUrls.isNotEmpty ? imageUrls[0] : null;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 50,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.image_not_supported_outlined,
                              size: 50,
                            ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contract #${contract['id']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Project: $projectName',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Description: $projectDescription',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Admin Acceptance: ${adminAcceptance ? 'Accepted' : 'Not Accepted'}',
                        style: TextStyle(
                          color: adminAcceptance ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
