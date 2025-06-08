import 'package:MOLLILE/Dartpages/sighUpIn/LoginPage.dart';
import 'package:MOLLILE/Dartpages/simple_functions/star_menu_button.dart';
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
  String? resident;
  int _rating = 0;
  String userComment = "none";
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchRatings();
  }

  bool isUserInRatings(String currentUserId) {
    return ratings.any((rating) => (rating['userUid'] ?? '') == currentUserId);
  }

  Future<void> fetchUserData() async {
    final userId = widget.projectList['user_id'];
    if (userId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
        });
      }
    }
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

  Future<void> reportProjectIfNotAlreadyReported(
      BuildContext context, int projectNumber, String ownerUserId) async {
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
            content: Text("Project not found."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final projectDoc = querySnapshot.docs.first;

      final reportsSnapshot = await projectDoc.reference
          .collection('reports')
          .where('userUid', isEqualTo: currentUserId)
          .get();

      if (reportsSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You have already reported this project."),
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
                      ? "none"
                      : reasonController.text.trim();

                  Navigator.of(context).pop();

                  try {
                    await projectDoc.reference.collection('reports').add({
                      'userUid': currentUserId,
                      'reason': reason,
                      'timeOfReport': Timestamp.now(),
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
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const LoginPage()));
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
                      ? "none"
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
                        'comment': comment.isEmpty ? 'none' : comment,
                        'timeOfRating': Timestamp.now(),
                        'Starnumber': ratingnumber
                      });
                    } else {
                      await projectDoc.reference.collection('ratings').add({
                        'userUid': currentUserId,
                        'comment': comment.isEmpty ? 'none' : comment,
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

  void _reportProjectWithReason(String userId, int numberProject) async {
    try {
      await reportProjectIfNotAlreadyReported(context, numberProject, userId);
    } catch (e) {
      print(e);
    }
  }

  void _rateProjectWithcommant(
      String userId, int numberProject, int ratingnumber) async {
    try {
      await ratingProjectsIfNotAlreadyRated(
          context, numberProject, userId, ratingnumber);
    } catch (e) {
      print(e);
    }
  }

  void _chatWithUser() {
    // final userId = widget.projectList['user_id'];
    // if (userId != null) {
    //   Navigator.of(context).push(
    //     MaterialPageRoute(
    //       builder: (_) => masseges(userId: userId),
    //     ),
    //   );
    // }
  }
  Widget _buildDefaultAvatar() {
    return Image.asset(
      'lib/img/person1.png',
      fit: BoxFit.cover,
      width: 40,
      height: 40,
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.projectList;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff012C19),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: _userData?['image_url'] != null
                          ? NetworkImage(_userData!['image_url'])
                          : null,
                      backgroundColor: Colors.grey[300],
                      child: _userData?['image_url'] == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userData?['username'] ?? "Unknown User",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            project['name'] ?? "No Title",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _chatWithUser,
                      icon: const Icon(Icons.chat, color: Colors.teal),
                      tooltip: "Chat with user",
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    for (String image in project['image_urls'])
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          image,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  project['description'] ?? "No description",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildField(Icons.category, 'Category', project['category']),
                _buildField(Icons.monetization_on, 'Investment',
                    formatter.format(project['investment_amount'] ?? 0)),
                _buildField(
                    Icons.calendar_today,
                    'Created At',
                    dateFormatter.format(
                        (project['created_at'] as Timestamp?)?.toDate() ??
                            DateTime.now())),
                const Divider(height: 32),
                Column(
                  children: [
                    if (!isUserInRatings(currentUserId!))
                      Container(
                        //...........
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.transparent,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text("Rate this project:",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Row(
                              children: List.generate(5, (index) {
                                return Expanded(
                                  child: Center(
                                    child: IconButton(
                                      icon: Icon(
                                        index < _rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                      ),
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
                                      iconSize: 50,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
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
                              'userUid': userUid,
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
                            final isCurrentUser = item['isCurrentUser'] as bool;
                            final userUid = item['userUid'] as String;
                            final timestamp = item['timestamp'] as Timestamp?;
                            final time = timestamp != null
                                ? timeago.format(timestamp.toDate())
                                : 'No time';

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: Align(
                                alignment: isCurrentUser
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.75,
                                  ),
                                  child: Material(
                                    elevation: 2,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: Radius.circular(
                                          isCurrentUser ? 0 : 18),
                                      bottomRight: Radius.circular(
                                          isCurrentUser ? 18 : 0),
                                    ),
                                    color: isCurrentUser
                                        ? Colors.blue.shade50
                                        : Colors.grey.shade100,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: FutureBuilder(
                                        future: Future.wait([
                                          fetchUsername(userUid),
                                          fetchUserImagurl(userUid),
                                        ]),
                                        builder: (context,
                                            AsyncSnapshot<List<dynamic>>
                                                snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          }
                                          final username =
                                              snapshot.data?[0] as String? ??
                                                  'Unknown user';
                                          final userUrl =
                                              snapshot.data?[1] as String?;

                                          int ratingNumber =
                                              ratingItem['Starnumber'] ?? 0;
                                          final comment =
                                              ratingItem['comment'] ??
                                                  ""; //2222222

                                          return Column(
                                            crossAxisAlignment: isCurrentUser
                                                ? CrossAxisAlignment.start
                                                : CrossAxisAlignment.end,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (isCurrentUser) ...[
                                                    SizedBox(
                                                      width: 40,
                                                      height: 40,
                                                      child: ClipOval(
                                                        child: (userUrl !=
                                                                    null &&
                                                                userUrl
                                                                    .toString()
                                                                    .isNotEmpty)
                                                            ? Image.network(
                                                                userUrl
                                                                    .toString(),
                                                                fit: BoxFit
                                                                    .cover,
                                                                width: 40,
                                                                height: 40,
                                                                errorBuilder: (context,
                                                                        error,
                                                                        stackTrace) =>
                                                                    _buildDefaultAvatar(),
                                                                loadingBuilder:
                                                                    (context,
                                                                        child,
                                                                        loadingProgress) {
                                                                  if (loadingProgress ==
                                                                      null)
                                                                    return child;
                                                                  return Center(
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      value: loadingProgress.expectedTotalBytes !=
                                                                              null
                                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                                              loadingProgress.expectedTotalBytes!
                                                                          : null,
                                                                    ),
                                                                  );
                                                                },
                                                              )
                                                            : _buildDefaultAvatar(),
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        "  $username  ",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: isCurrentUser
                                                              ? Colors
                                                                  .blue.shade800
                                                              : Colors.grey
                                                                  .shade800,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    StarMenuButton(
                                                      items: [
                                                        Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 8),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Color.fromARGB(
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
                                                                offset: Offset(
                                                                    0, 2),
                                                                blurRadius: 4,
                                                              ),
                                                            ],
                                                          ),
                                                          child: Text(
                                                            "Remove",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              letterSpacing:
                                                                  1.2,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 8),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Color.fromARGB(
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
                                                                offset: Offset(
                                                                    0, 2),
                                                                blurRadius: 4,
                                                              ),
                                                            ],
                                                          ),
                                                          child: Text(
                                                            "Edit",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              letterSpacing:
                                                                  1.2,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 8),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Color.fromARGB(
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
                                                                offset: Offset(
                                                                    0, 2),
                                                                blurRadius: 4,
                                                              ),
                                                            ],
                                                          ),
                                                          child: Text(
                                                            "close",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              letterSpacing:
                                                                  1.2,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                      onItemTapped: (index) {
                                                        if (index == 0) {
                                                          // removeRating(index, rating),
                                                        }
                                                      },
                                                    ),
                                                  ] else ...[
                                                    StarMenuButton(
                                                      items: [
                                                        CircleAvatar(
                                                          backgroundColor:
                                                              Colors.red,
                                                          child: Text('1'),
                                                        ),
                                                        CircleAvatar(
                                                          backgroundColor:
                                                              Colors.blue,
                                                          child: Text('2'),
                                                        ),
                                                        Icon(Icons.star),
                                                      ],
                                                      onItemTapped: (index) {
                                                        print(
                                                            'You tapped item $index');
                                                      },
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        "  $username  ",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: isCurrentUser
                                                              ? Colors
                                                                  .blue.shade800
                                                              : Colors.grey
                                                                  .shade800,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 40,
                                                      height: 40,
                                                      child: ClipOval(
                                                        child: (userUrl !=
                                                                    null &&
                                                                userUrl
                                                                    .toString()
                                                                    .isNotEmpty)
                                                            ? Image.network(
                                                                userUrl
                                                                    .toString(),
                                                                fit: BoxFit
                                                                    .cover,
                                                                width: 40,
                                                                height: 40,
                                                                errorBuilder: (context,
                                                                        error,
                                                                        stackTrace) =>
                                                                    _buildDefaultAvatar(),
                                                                loadingBuilder:
                                                                    (context,
                                                                        child,
                                                                        loadingProgress) {
                                                                  if (loadingProgress ==
                                                                      null)
                                                                    return child;
                                                                  return Center(
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      value: loadingProgress.expectedTotalBytes !=
                                                                              null
                                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                                              loadingProgress.expectedTotalBytes!
                                                                          : null,
                                                                    ),
                                                                  );
                                                                },
                                                              )
                                                            : _buildDefaultAvatar(),
                                                      ),
                                                    ),
                                                  ]
                                                ],
                                              ),

                                              const SizedBox(height: 6),

                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: List.generate(5,
                                                      (starIndex) {
                                                    return Icon(
                                                      starIndex < ratingNumber
                                                          ? Icons.star_rounded
                                                          : Icons
                                                              .star_outline_rounded,
                                                      color:
                                                          Colors.amber.shade700,
                                                      size: 18,
                                                    );
                                                  }),
                                                ),
                                              ),

                                              if (comment.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    comment,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],

                                              const SizedBox(height: 6),

                                              // Time
                                              Text(
                                                time,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade600,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
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
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      _reportProjectWithReason(
                        widget.projectList['user_id'],
                        widget.projectList['projectNumber'],
                      );
                    },
                    icon: const Icon(Icons.flag, color: Colors.red),
                    label: const Text("Report",
                        style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal[700]),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
