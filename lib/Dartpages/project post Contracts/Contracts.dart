import 'package:Mollni/Dartpages/Communicate%20with%20investor/business%20owners/messages_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Contracts extends StatefulWidget {
  final Map<String, dynamic> Information_about_us;

  const Contracts(this.Information_about_us, {super.key});

  @override
  State<Contracts> createState() => _ContractsState();
}

class _ContractsState extends State<Contracts> {
  List<Map<String, dynamic>> projects = [], project =[ ];
  List<Map<String, dynamic>> filteredProjects = [];
  bool _isLoading = true;
  final user = FirebaseAuth.instance.currentUser;
  String? selectedProjectName;
  int? selectedProjectNumber;
  final TextEditingController Date_Signed = TextEditingController();
  List<bool> Actions = [false, false, false];
  final TextEditingController investorCommitmentController =
      TextEditingController();
  final TextEditingController ownerCommitmentController =
      TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController paymentMethodController = TextEditingController();
  final TextEditingController percentageController = TextEditingController();
  final TextEditingController paymentPeriodController = TextEditingController();
  final TextEditingController dispute_resolutionController =
      TextEditingController();
  late String projectID;
  bool _isSubmitting = false;
  @override
  void initState() {
    super.initState();
    fetchProjectsAndOwners(
        widget.Information_about_us['_currentOtherUserEmail']);
  }

  Future<void> GetProjectByuserIDNumber(String otherUserId) async {
    try {
      final query = FirebaseFirestore.instance.collection('projects');

      if (Actions[1]) {
        final snapshot = await query
            .where('user_id', isEqualTo: user!.uid)
            .where('projectNumber', isEqualTo: selectedProjectNumber)
            .get();
        for (var doc in snapshot.docs) {
          final projectData = doc.data();
          final adminAccepted = projectData['Adminacceptance'] ?? false;

          if (adminAccepted != true) {
            continue;
          }
          setState(() {
            project = [projectData];
            projectID = doc.id;
          });
        }
      } else {
        final snapshot = await query
            .where('user_id', isEqualTo: otherUserId)
            .where('projectNumber', isEqualTo: selectedProjectNumber)
            .get();
        for (var doc in snapshot.docs) {
          final projectData = doc.data();
          final adminAccepted = projectData['Adminacceptance'] ?? false;

          if (adminAccepted != true) {
            continue;
          }
          setState(() {
            project = [projectData];
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchProjectsAndOwners(String otheruserID) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final query = FirebaseFirestore.instance.collection('projects');
      final snapshot =
          await query.where('user_id', whereIn: [user!.uid, otheruserID]).get();
      List<Map<String, dynamic>> loadedProjects = [];

      for (var doc in snapshot.docs) {
        final projectData = doc.data();
        final adminAccepted = projectData['Adminacceptance'] ?? false;

        if (adminAccepted != true) {
          continue;
        }

        loadedProjects.add({
          'id': doc.id,
          ...projectData,
        });
      }

      setState(() {
        projects = loadedProjects;
        filteredProjects = loadedProjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching projects: $e');
    }
  }

  TimeOfDay? selectedTime;
  TextEditingController dateController = TextEditingController();
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateController.text = "${picked.year}-${picked.month}-${picked.day}";
      });
    }
  }

  String formatContractText(Map<String, dynamic> data) {
    final infoAboutUs =
        data['Information about us'] as Map<String, dynamic>? ?? {};
    final currentName = infoAboutUs['CurntName'] ?? 'N/A';
    final currentEmail = infoAboutUs['CurntEmail'] ?? 'N/A';
    final currentChatId = infoAboutUs['_currentChatId'] ?? 'N/A';

    final contractInfo =
        data['Contract Information'] as Map<String, dynamic>? ?? {};
    final amount = contractInfo['amount'] ?? 'N/A';
    final dateSigned = contractInfo['date_signed'] ?? 'N/A';
    final disputeResolution = contractInfo['dispute_resolution'] ?? 'N/A';
    final investorCommitment = contractInfo['investor_commitment'] ?? 'N/A';
    final ownerCommitment = contractInfo['owner_commitment'] ?? 'N/A';
    final paymentMethod = contractInfo['payment_method'] ?? 'N/A';
    final paymentPeriod = contractInfo['payment_period'] ?? 'N/A';
    final percentage = contractInfo['percentage'] ?? 'N/A';

    final projectList =
        data['Information about Project'] as List<dynamic>? ?? [];

    final projectInfo =
        projectList.isNotEmpty ? projectList.first as Map<String, dynamic> : {};

    final projectName = projectInfo['name'] ?? 'N/A';
    final projectDescription = projectInfo['description'] ?? 'N/A';
    final projectCategory = projectInfo['category'] ?? 'N/A';
    final projectCreatedAt = projectInfo['created_at'] ?? 'N/A';
    final projectUserId = projectInfo['user_id'] ?? 'N/A';
    final warningCount = projectInfo['warningCount']?.toString() ?? 'N/A';

    final contractNumber = data['docId']?.toString() ?? 'N/A';

    return '''
 Contract Number: $contractNumber
 *Contract Agreement Summary* 

 Contract Number: $contractNumber
 Amount: $amount
 Date Signed: $dateSigned
 Dispute Resolution: $disputeResolution
 Percentage: $percentage
 Payment Method: $paymentMethod
 Payment Period: $paymentPeriod

 Commitments:
- Investor: $investorCommitment
- Owner: $ownerCommitment

 Current User Info:
- Name: $currentName
- Email: $currentEmail
- Chat ID: $currentChatId

 Project Information:
- Name: $projectName
- Description: $projectDescription
- Category: $projectCategory
- Created At: $projectCreatedAt
- Owner ID: $projectUserId
- Warning Count: $warningCount
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Contract'),
        backgroundColor: const Color.fromARGB(255, 46, 123, 30),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Select a Project:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _isLoading
                  ? const CircularProgressIndicator()
                  : DropdownButton<String>(
                      hint: Text("select a Project"),
                      value: selectedProjectName,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedProjectName = newValue!;
                          final selectedProject = projects.firstWhere(
                            (project) => project['name'] == selectedProjectName,
                            orElse: () => {},
                          );

                          if (selectedProject.isNotEmpty) {
                            selectedProjectNumber =
                                selectedProject['projectNumber'];
                            Actions[0] = true;
                            Actions[1] =
                                selectedProject['user_id'] == user!.uid;
                            GetProjectByuserIDNumber(
                                selectedProject['user_id']);
                          }
                        });
                      },
                      items: projects.map((project) {
                        return DropdownMenuItem<String>(
                          value: project['name'],
                          child: Text(project['name'] ?? 'No Name'),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 20),
              if (Actions[0]) ...[
                const Text(
                  "Actions:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Date Signed:",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: Date_Signed,
                  maxLength: 20,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                    hintText: 'Date Signed here(not required)',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "end contract time?",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  onTap: () {
                    _selectDate(context);
                    setState(() {
                      Actions[2] = true;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Select Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                if (Actions[2]) ...[
                  const Text(
                    "What will the investor commit to?",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: investorCommitmentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Enter investor's commitment",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "What will the project owner commit to?",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: ownerCommitmentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Enter owner's commitment",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Amount of the investment or support",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: "Enter amount",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Payment Method (one-time payment, in installments)",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: paymentMethodController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Describe payment method",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Is there a percentage? How is it calculated?",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: percentageController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Enter percentage and calculation",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Payment Periods (if applicable)",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: paymentPeriodController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Specify payment periods",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const Text(
                    "What is the dispute resolution process?",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dispute_resolutionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          " (For example, through a mediator from the Molni administration or through an independent agency)",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setState(() {
                              _isSubmitting = true;
                            });

                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null)
                                throw Exception("User not logged in");

                              final contractData = {
                                'Information about us':
                                    widget.Information_about_us,
                                'Information about Project': project,
                                'projectId': projectID,
                                'Contract Information': {
                                  'dispute_resolution':
                                      dispute_resolutionController.text,
                                  'payment_period':
                                      paymentPeriodController.text,
                                  'percentage': percentageController.text,
                                  'payment_method':
                                      paymentMethodController.text,
                                  'amount': amountController.text,
                                  'owner_commitment':
                                      ownerCommitmentController.text,
                                  'investor_commitment':
                                      investorCommitmentController.text,
                                  'date_signed': Date_Signed.text,
                                },
                                'Curnt accepted sides': {
                                  '1': user.uid,
                                  '2': 'Not yet',
                                },
                              };

                              final docRef = await FirebaseFirestore.instance
                                  .collection('Contracts')
                                  .add(contractData);

                              final String docId = docRef.id;
                              print("✅ Contract added with ID: $docId");

                              final allContracts = await FirebaseFirestore
                                  .instance
                                  .collection('Contracts')
                                  .get();
                              final int contractsCount =
                                  allContracts.docs.length;

                              final fullData = {
                                ...contractData,
                                'docId': docId,
                              };
                              final contractText = formatContractText(fullData);

                              await docRef.update({
                                'docId': docId,
                                'formatContractText': contractText,
                                'sended?': false,
                                'Contract number': contractsCount,
                              });

                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MessagesPage(projectID: projectID),
                                ),
                              );

                              // Debug
                              print(
                                  "📄 Final formatted contract:\n$contractText");
                            } catch (e) {
                              print("❌ Error while submitting contract: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error: ${e.toString()}')),
                              );
                            } finally {
                              setState(() {
                                _isSubmitting = false;
                              });
                            }
                          },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      "Submit Contract",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
