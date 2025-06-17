import 'package:Mollni/Dartpages/Communicate%20with%20investor/business%20owners/messages_page.dart';
import 'package:Mollni/Dartpages/HomePage/Home_page.dart';
import 'package:Mollni/Dartpages/HomePage/ProjectImagesCarousel.dart';
import 'package:Mollni/Dartpages/sighUpIn/LoginPage.dart';
import 'package:Mollni/simple_functions/star_menu_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

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
  List<Map<String, dynamic>> ratings = [];
  bool? isFavorited;
  String? resident;
  int _rating = 0;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  User? user = FirebaseAuth.instance.currentUser;
  late bool lodingDone;

  @override
  void initState() {
    super.initState();
    lodingDone = false;
    fetchUserData();
    fetchRatings();
    checkIfFavorited();
  }

  Future<void> fetchUserData() async {
    await FirebaseAuth.instance.currentUser?.reload();
    user = FirebaseAuth.instance.currentUser;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
        });
      }
    }
  }

  bool isUserInRatings(String currentUserId) {
    return ratings.any((rating) => (rating['userUid'] ?? '') == currentUserId);
  }

  Future<String> fetchUsername(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('username')) {
          return data['username'] as String;
        }
      }
    } catch (e) {
      print('Error fetching username for $userId: $e');
    }
    return 'Unknown user';
  }

  Future<String?> fetchUserImagurl(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.data()?['imageUrl'] as String?;
    } catch (e) {
      debugPrint('Error fetching image URL for $userId: $e');
      return null;
    }
  }

  Future<void> fetchRatings() async {
    final userId = widget.projectList['user_id'];
    final projectNumber = widget.projectList['projectNumber'];
    try {
      final projectQuery = await FirebaseFirestore.instance
          .collection('projects')
          .where('user_id', isEqualTo: userId)
          .where('projectNumber', isEqualTo: projectNumber)
          .get();
      if (projectQuery.docs.isEmpty) return;
      final projectDoc = projectQuery.docs.first;
      final ratingsSnapshot =
          await projectDoc.reference.collection('ratings').get();
      setState(() {
        ratings = ratingsSnapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print("Error fetching ratings: $e");
    }
  }

  Future<void> reportProjectIfNotAlreadyReported(BuildContext context,
      int projectNumber, String ownerUserId, String reporttype) async {
    final TextEditingController reasonController = TextEditingController();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must be logged in to report."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('projectNumber', isEqualTo: projectNumber)
          .where('user_id', isEqualTo: ownerUserId)
          .get();
      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("error ,not found."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final projectDoc = querySnapshot.docs.first;
      final reportsSnapshot = await projectDoc.reference
          .collection('reports')
          .where('userUid', isEqualTo: currentUserId)
          .where('reporttype', isEqualTo: reporttype)
          .get();
      if (reportsSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You have already reported this!"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Report Project"),
            content: TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Enter reason for reporting",
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text("Submit"),
                onPressed: () async {
                  final reason = reasonController.text.trim().isEmpty
                      ? ""
                      : reasonController.text.trim();
                  Navigator.of(context).pop();
                  try {
                    await projectDoc.reference.collection('reports').add({
                      'userUid': currentUserId,
                      'reason': reason,
                      'timeOfReport': Timestamp.now(),
                      'reporttype': reporttype
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Thanks for reporting!"),
                        backgroundColor: Color.fromARGB(255, 117, 43, 38),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> ratingProjectsIfNotAlreadyRated(BuildContext context,
      int projectNumber, String ownerUserId, int ratingnumber) async {
    final TextEditingController commentController = TextEditingController();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()));
    }
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('projectNumber', isEqualTo: projectNumber)
          .where('user_id', isEqualTo: ownerUserId)
          .get();
      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Project not found."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final projectDoc = querySnapshot.docs.first;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Rate Project"),
            content: TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: "Enter a comment (optional)",
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text("Submit"),
                onPressed: () async {
                  final comment = commentController.text.trim().isEmpty
                      ? ""
                      : commentController.text.trim();
                  Navigator.of(context).pop();
                  try {
                    final ratingsSnapshot = await projectDoc.reference
                        .collection('ratings')
                        .where('userUid', isEqualTo: currentUserId)
                        .get();
                    if (ratingsSnapshot.docs.isNotEmpty) {
                      final ratingDoc = ratingsSnapshot.docs.first;
                      await ratingDoc.reference.update({
                        'comment': comment.isEmpty ? '' : comment,
                        'timeOfRating': Timestamp.now(),
                        'Starnumber': ratingnumber
                      });
                    } else {
                      await projectDoc.reference.collection('ratings').add({
                        'userUid': currentUserId,
                        'comment': comment.isEmpty ? '' : comment,
                        'timeOfRating': Timestamp.now(),
                        'Starnumber': ratingnumber
                      });
                    }
                    fetchRatings();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Thanks for the rating!"),
                        backgroundColor: Color.fromARGB(255, 117, 43, 38),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _reportWithReason(
      String userIdOwner, int numberProject, String reporttype) async {
    try {
      await reportProjectIfNotAlreadyReported(
          context, numberProject, userIdOwner, reporttype);
    } catch (e) {
      print(e);
    }
  }

  void _rateProjectWithcommant(
      String userIdOwner, int numberProject, int ratingnumber) async {
    try {
      await ratingProjectsIfNotAlreadyRated(
          context, numberProject, userIdOwner, ratingnumber);
    } catch (e) {
      print(e);
    }
  }

  void _chatWithUser() {
    final userId = widget.projectList['user_id'];
    if (userId != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => MessagesPage(userId: userId)));
    }
  }

  Widget _buildDefaultAvatar() {
    return FutureBuilder<String?>(
      future: fetchUserImagurl(user!.uid),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data;
        return ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(100)),
          child: imageUrl != null
              ? Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                  return Image.asset("lib/img/person1.png", fit: BoxFit.cover);
                })
              : Image.asset("lib/img/person1.png", fit: BoxFit.cover),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.projectList;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff012C19),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Project Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffF0F4F8), Color(0xffE0E7F0)],
          ),
        ),
        child: lodingDone
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: _userData?['imageUrl'] != null
                                  ? NetworkImage(_userData!['imageUrl'])
                                  : null,
                              backgroundColor: Colors.grey[300],
                              child: _userData?['imageUrl'] == null
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_userData?['username'] ?? "Unknown User",
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff1A3C34)),
                                      overflow: TextOverflow.ellipsis),
                                  Text(project['name'] ?? "No Title",
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.grey)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _chatWithUser,
                              icon: const Icon(Icons.chat, color: Colors.teal),
                              iconSize: 28,
                              style: IconButton.styleFrom(
                                  backgroundColor: Colors.teal.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              tooltip: "Chat with user",
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ProjectImagesCarousel(
                          imageUrls: List<String>.from(project['image_urls']),
                        ),
                        const SizedBox(height: 20),
                        Text(project['description'] ?? "No description",
                            style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xff2E5D4F),
                                height: 1.5)),
                        const SizedBox(height: 20),
                        _buildField(
                            Icons.category, 'Category', project['category']),
                        _buildField(
                            Icons.monetization_on,
                            'Investment',
                            formatter
                                .format(project['investment_amount'] ?? 0)),
                        _buildField(
                            Icons.calendar_today,
                            'Created At',
                            dateFormatter.format(
                                (project['created_at'] as Timestamp?)
                                        ?.toDate() ??
                                    DateTime.now())),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: 120,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await toggleFavoriteProjectGlobal(
                                        context,
                                        widget.projectList['projectNumber'],
                                        widget.projectList['user_id'],
                                        user!.uid);
                                    setState(() {
                                      isFavorited = !(isFavorited ?? false);
                                    });
                                  },
                                  icon: Icon(
                                      isFavorited == true
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorited == true
                                          ? Colors.red
                                          : Colors.grey),
                                  label: Text(
                                      isFavorited == true ? "Remove" : "Add",
                                      style: const TextStyle(
                                          color: Color(0xff1A3C34),
                                          fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 4),
                                )),
                            if (user?.uid != null &&
                                user!.uid != widget.projectList['user_id'])
                              const SizedBox(width: 14),
                            if (user?.uid != null &&
                                user!.uid != widget.projectList['user_id'])
                              ElevatedButton.icon(
                                onPressed: () {
                                  _reportWithReason(
                                      widget.projectList['user_id'],
                                      widget.projectList['projectNumber'],
                                      "Project");
                                },
                                icon: const Icon(Icons.flag, color: Colors.red),
                                label: const Text("Report",
                                    style: TextStyle(color: Colors.red)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 4),
                              ),
                            const SizedBox(width: 10),
                          ],
                        ),
                        if (user?.uid != null &&
                            (user!.uid == widget.projectList['user_id'] ||
                                _userData!['admin'] == true))
                          Padding(
                            padding: const EdgeInsets.only(left: 100),
                            child: SizedBox(
                              width: 130,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  deleteProject(context, user!.uid,
                                      widget.projectList['projectNumber']);
                                },
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                label: const Text("Delete",
                                    style: TextStyle(color: Colors.red)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 4),
                              ),
                            ),
                          ),
                        const Divider(color: Color(0xffE0E7F0), thickness: 1),
                        const SizedBox(height: 16),
                        if (!isUserInRatings(currentUserId!))
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))
                                ]),
                            child: Column(
                              children: [
                                const Text("Rate this project:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff1A3C34))),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    return Expanded(
                                        child: IconButton(
                                      icon: Icon(
                                          index < _rating
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber),
                                      onPressed: () {
                                        setState(() {
                                          _rating = index + 1;
                                        });
                                        _rateProjectWithcommant(
                                            widget.projectList['user_id'],
                                            widget.projectList['projectNumber'],
                                            _rating);
                                      },
                                      padding: EdgeInsets.zero,
                                      iconSize: 40,
                                    ));
                                  }),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            ...(() {
                              final ratingData = ratings.map((ratingItem) {
                                final userUid =
                                    ratingItem['userUid'] ?? 'Unknown user';
                                final isCurrentUser = userUid ==
                                    FirebaseAuth.instance.currentUser?.uid;
                                return {
                                  'rating': ratingItem,
                                  'isCurrentUser': isCurrentUser,
                                  'timestamp':
                                      ratingItem['timeOfRating'] as Timestamp?,
                                  'userUid': userUid
                                };
                              }).toList();

                              ratingData.sort((a, b) {
                                if (a['isCurrentUser'] as bool &&
                                    !(b['isCurrentUser'] as bool)) return -1;
                                if (!(a['isCurrentUser'] as bool) &&
                                    (b['isCurrentUser'] as bool)) return 1;
                                final aTime =
                                    (a['timestamp'] as Timestamp?)?.toDate() ??
                                        DateTime(0);
                                final bTime =
                                    (b['timestamp'] as Timestamp?)?.toDate() ??
                                        DateTime(0);
                                return bTime.compareTo(aTime);
                              });

                              return ratingData.map((item) {
                                final ratingItem =
                                    item['rating'] as Map<String, dynamic>;
                                final isCurrentUser =
                                    item['isCurrentUser'] as bool;
                                final userUid = item['userUid'] as String;
                                final timestamp =
                                    item['timestamp'] as Timestamp?;
                                final time = timestamp != null
                                    ? timeago.format(timestamp.toDate())
                                    : 'No time';

                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Align(
                                    alignment: isCurrentUser
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.75),
                                      child: Card(
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(12),
                                            topRight: const Radius.circular(12),
                                            bottomLeft: Radius.circular(
                                                isCurrentUser ? 0 : 12),
                                            bottomRight: Radius.circular(
                                                isCurrentUser ? 12 : 0),
                                          ),
                                        ),
                                        color: isCurrentUser
                                            ? Colors.blue[50]
                                            : Colors.grey[100],
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: FutureBuilder(
                                            future: Future.wait([
                                              fetchUsername(userUid),
                                              fetchUserImagurl(userUid)
                                            ]),
                                            builder: (context,
                                                AsyncSnapshot<List<dynamic>>
                                                    snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const CircularProgressIndicator();
                                              }
                                              final username = snapshot.data?[0]
                                                      as String? ??
                                                  'Unknown user';
                                              final userUrl =
                                                  snapshot.data?[1] as String?;

                                              int ratingNumber =
                                                  ratingItem['Starnumber'] ?? 0;
                                              final comment =
                                                  ratingItem['comment'] ?? "";

                                              return Column(
                                                crossAxisAlignment:
                                                    isCurrentUser
                                                        ? CrossAxisAlignment
                                                            .start
                                                        : CrossAxisAlignment
                                                            .end,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (isCurrentUser ||
                                                          _userData!['admin'] ==
                                                              true) ...[
                                                        CircleAvatar(
                                                          radius: 20,
                                                          backgroundImage:
                                                              userUrl != null &&
                                                                      userUrl
                                                                          .isNotEmpty
                                                                  ? NetworkImage(
                                                                      userUrl)
                                                                  : null,
                                                          backgroundColor:
                                                              Colors.grey[300],
                                                          child: userUrl ==
                                                                      null ||
                                                                  userUrl
                                                                      .isEmpty
                                                              ? const Icon(
                                                                  Icons.person,
                                                                  color: Colors
                                                                      .white)
                                                              : null,
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Flexible(
                                                          child: Text(username,
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                  color: isCurrentUser
                                                                      ? Colors.blue[
                                                                          800]
                                                                      : Colors.grey[
                                                                          800]),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis),
                                                        ),
                                                        StarMenuButton(
                                                          items: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          6),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    103,
                                                                    90,
                                                                    89),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.2),
                                                                      offset:
                                                                          const Offset(
                                                                              0,
                                                                              2),
                                                                      blurRadius:
                                                                          4)
                                                                ],
                                                              ),
                                                              child: const Text(
                                                                  "Remove",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          14)),
                                                            ),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          6),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    103,
                                                                    90,
                                                                    89),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.2),
                                                                      offset:
                                                                          const Offset(
                                                                              0,
                                                                              2),
                                                                      blurRadius:
                                                                          4)
                                                                ],
                                                              ),
                                                              child: const Text(
                                                                  "Edit",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          14)),
                                                            ),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          6),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    103,
                                                                    90,
                                                                    89),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.2),
                                                                      offset:
                                                                          const Offset(
                                                                              0,
                                                                              2),
                                                                      blurRadius:
                                                                          4)
                                                                ],
                                                              ),
                                                              child: const Text(
                                                                  "Close",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          14)),
                                                            ),
                                                          ],
                                                          onItemTapped:
                                                              (index) {
                                                            if (index == 0) {
                                                              User? user =
                                                                  FirebaseAuth
                                                                      .instance
                                                                      .currentUser;
                                                              if (user !=
                                                                  null) {
                                                                removeRating(
                                                                    user.uid);
                                                              }
                                                              return;
                                                            }
                                                            if (index == 1) {
                                                              User? user =
                                                                  FirebaseAuth
                                                                      .instance
                                                                      .currentUser;
                                                              if (user !=
                                                                  null) {
                                                                removeRating(
                                                                    user.uid);
                                                              }
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  int tempRating =
                                                                      _rating;
                                                                  return AlertDialog(
                                                                    title: const Text(
                                                                        "Rate This Project"),
                                                                    content:
                                                                        Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children:
                                                                          List.generate(
                                                                              5,
                                                                              (index) {
                                                                        return IconButton(
                                                                          icon: Icon(
                                                                              index < tempRating ? Icons.star : Icons.star_border,
                                                                              color: Colors.amber),
                                                                          iconSize:
                                                                              40,
                                                                          onPressed:
                                                                              () {
                                                                            setState(() {
                                                                              _rating = index + 1;
                                                                              lodingDone = true;
                                                                            });
                                                                            Navigator.of(context).pop();
                                                                            _rateProjectWithcommant(
                                                                                widget.projectList['user_id'],
                                                                                widget.projectList['projectNumber'],
                                                                                _rating);
                                                                          },
                                                                        );
                                                                      }),
                                                                    ),
                                                                  );
                                                                },
                                                              );
                                                            }
                                                            return;
                                                          },
                                                        ),
                                                      ] else ...[
                                                        StarMenuButton(
                                                          items: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          6),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    103,
                                                                    90,
                                                                    89),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.2),
                                                                      offset:
                                                                          const Offset(
                                                                              0,
                                                                              2),
                                                                      blurRadius:
                                                                          4)
                                                                ],
                                                              ),
                                                              child: const Text(
                                                                  "Close",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          14)),
                                                            ),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          6),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    103,
                                                                    90,
                                                                    89),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.2),
                                                                      offset:
                                                                          const Offset(
                                                                              0,
                                                                              2),
                                                                      blurRadius:
                                                                          4)
                                                                ],
                                                              ),
                                                              child: const Text(
                                                                  "Report!",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          14)),
                                                            ),
                                                          ],
                                                          onItemTapped:
                                                              (index) {
                                                            print(
                                                                'You tapped item $index');
                                                            if (index == 1) {
                                                              _reportWithReason(
                                                                  widget.projectList[
                                                                      'user_id'],
                                                                  widget.projectList[
                                                                      'projectNumber'],
                                                                  'comment');
                                                            }
                                                          },
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Flexible(
                                                          child: Text(username,
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                  color: isCurrentUser
                                                                      ? Colors.blue[
                                                                          800]
                                                                      : Colors.grey[
                                                                          800]),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis),
                                                        ),
                                                        CircleAvatar(
                                                          radius: 20,
                                                          backgroundImage:
                                                              userUrl != null &&
                                                                      userUrl
                                                                          .isNotEmpty
                                                                  ? NetworkImage(
                                                                      userUrl)
                                                                  : null,
                                                          backgroundColor:
                                                              Colors.grey[300],
                                                          child: userUrl ==
                                                                      null ||
                                                                  userUrl
                                                                      .isEmpty
                                                              ? const Icon(
                                                                  Icons.person,
                                                                  color: Colors
                                                                      .white)
                                                              : null,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                        color: Colors.amber[50],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10)),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: List.generate(5,
                                                          (starIndex) {
                                                        return Icon(
                                                            starIndex <
                                                                    ratingNumber
                                                                ? Icons
                                                                    .star_rounded
                                                                : Icons
                                                                    .star_outline_rounded,
                                                            color: Colors
                                                                .amber[700],
                                                            size: 16);
                                                      }),
                                                    ),
                                                  ),
                                                  if (comment.isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                          color: Colors.white
                                                              .withOpacity(0.8),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8)),
                                                      child: Text(comment,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 14,
                                                                  height: 1.4)),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 6),
                                                  Text(time,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                          fontStyle: FontStyle
                                                              .italic)),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList();
                            })(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Center(
                child: CircularProgressIndicator(
                    color: const Color(0xff1A3C34).withOpacity(0.7))),
      ),
    );
  }

  Widget _buildField(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal[700], size: 20),
          const SizedBox(width: 12),
          Text("$label: ",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xff1A3C34))),
          Expanded(
              child: Text(value?.toString() ?? 'N/A',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2)),
        ],
      ),
    );
  }

  void removeRating(String uid) async {
    final userId = widget.projectList['user_id'];
    final projectNumber = widget.projectList['projectNumber'];
    try {
      final projectQuery = await FirebaseFirestore.instance
          .collection('projects')
          .where('user_id', isEqualTo: userId)
          .where('projectNumber', isEqualTo: projectNumber)
          .get();
      if (projectQuery.docs.isEmpty) {
        print("isEmpty");
        return;
      }
      final projectDoc = projectQuery.docs.first;
      final ratingsRef = projectDoc.reference.collection('ratings');
      final ratingsSnapshot = await ratingsRef.get();
      for (final doc in ratingsSnapshot.docs) {
        if (doc.data()['userUid'] == uid) {
          await doc.reference.delete();
          print('Rating deleted for uid: $uid');
          break;
        }
      }
      final updatedSnapshot = await ratingsRef.get();
      setState(() {
        ratings = updatedSnapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Error removing rating: $e');
    }
  }

  Future<void> deleteProject(
      BuildContext context, String uid, int projectNumber) async {
    final projectsCollection =
        FirebaseFirestore.instance.collection('projects');
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this project?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      late final querySnapshot;
      if (_userData!['admin']) {
        querySnapshot = await projectsCollection
            .where('projectNumber', isEqualTo: projectNumber)
            .limit(1)
            .get();
      } else {
        querySnapshot = await projectsCollection
            .where('user_id', isEqualTo: uid)
            .where('projectNumber', isEqualTo: projectNumber)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isEmpty) {
        print('No project found for user $uid with number $projectNumber');
        return;
      }
      final docId = querySnapshot.docs.first.id;
      final docRef = projectsCollection.doc(docId);
      await docRef.update({'removed': true});

      await docRef.update({'removed': true});
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Homepage()));
    } catch (e) {
      print('Error deleting project: $e');
    }
  }

  Future<void> toggleFavoriteProjectGlobal(BuildContext context,
      int numberProject, String userID_owner, String uid_current) async {
    try {
      final projectId = numberProject.toString() + userID_owner;
      final favQuery = await FirebaseFirestore.instance
          .collection('favorites')
          .where('projectId', isEqualTo: projectId)
          .where('currentUserId', isEqualTo: uid_current)
          .limit(1)
          .get();
      if (favQuery.docs.isNotEmpty) {
        await favQuery.docs.first.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Removed from favorites."),
            backgroundColor: Colors.orange));
      } else {
        await FirebaseFirestore.instance.collection('favorites').add({
          'currentUserId': uid_current,
          'timeofadding': Timestamp.now(),
          'numberProject': numberProject,
          'userID_owner': userID_owner,
          'projectId': projectId,
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Added to favorites."),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      print("Error toggling favorite: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red));
    }
  }

  Future<void> checkIfFavorited() async {
    try {
      print("Checking if project is favorited by ${user!.uid}");
      final querySnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('projectNumber',
              isEqualTo: widget.projectList['projectNumber'])
          .where('user_id', isEqualTo: widget.projectList['user_id'])
          .limit(1)
          .get();
      print("Project query returned: ${querySnapshot.docs.length} documents");
      if (querySnapshot.docs.isNotEmpty) {
        final projectDoc = querySnapshot.docs.first;
        print("Found project doc ID: ${projectDoc.id}");
        final favQuery = await projectDoc.reference
            .collection('favProjects')
            .where('currentUserId', isEqualTo: user!.uid)
            .limit(1)
            .get();
        print("Favorites query returned: ${favQuery.docs.length} documents");
        setState(() {
          isFavorited = favQuery.docs.isNotEmpty;
          lodingDone = true;
        });
        if (isFavorited != null || isFavorited == true) {
          print("Project is favorited by user.");
        } else {
          print("Project is not favorited.");
        }
      } else {
        print("No project found in checkIfFavorited.");
      }
    } catch (e) {
      print("Error in checkIfFavorited: $e");
    }
  }
}
