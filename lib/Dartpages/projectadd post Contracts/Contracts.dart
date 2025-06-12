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
  List<Map<String, dynamic>> projects = [];
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

  @override
  void initState() {
    super.initState();
    fetchProjectsAndOwners(
        widget.Information_about_us['_currentOtherUserEmail']);
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// 	•	ما الذي سيلتزم به المستثمر (مثلاً: تحويل مبلغ معين، المشاركة في التوجيه، إلخ)
// 	•	ما الذي سيلتزم به صاحب المشروع (مثلاً: تسليم تقارير، تحديثات منتظمة، استخدام الأموال في الغرض المتفق عليه، إلخ
