import 'package:Mollni/Dartpages/Admin/AdminTapsSystem.dart';
import 'package:Mollni/Dartpages/project%20post%20Contracts/TapsSystem.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:Mollni/Dartpages/HomePage/Home_page.dart';
import 'package:Mollni/Dartpages/UserData/profile_information.dart';
import 'package:Mollni/Dartpages/project%20post%20Contracts/Contracts.dart';
import 'package:Mollni/Dartpages/sighUpIn/LoginPage.dart';
import 'package:Mollni/main.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesPage extends StatefulWidget {
  String? projectID;

  MessagesPage({
    this.userId,
    super.key,
    this.projectID,
  });
  final String? userId;
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final List<Color> borderColors = [
    const Color(0xffD49D31),
    const Color(0xffF7B7BE),
    const Color(0xff9D9DED),
    const Color(0xffFADF9B),
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User _currentUser;
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userData;
  bool showButtons = false;
  List<DocumentSnapshot> filteredUsers = [];
  List<DocumentSnapshot> allUsers = [];
  int _selectedIndex = 2;
  Timer? _chatPollingTimer;
  Timer? _refreshTimer;

  Map<String, String> _lastSeenMessages = {};
  List<Map<String, dynamic>> projects = [], posts = [];

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showChatPage = false;
  String _currentChatId = "";
  String _currentOtherUserEmail = "";
  String _currentOtherUserID = "";
  String _currentOtherUserName = "";
  DocumentSnapshot? maxContractDoc;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  void initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  bool _isLoading = true;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatPollingTimer?.cancel();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser!;
    fetchUsers();
    fetchUserData();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.userId != null) {
        await _autoOpenChat(widget.userId!);
      }
    });
    print("Current User Email: ${_currentUser.email}");
    print("_currentChatId:$_currentChatId ");
    _listenToAllChatsRealTime();
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (_) {
      setState(() {});
    });
  }

  Future<void> fetchProjectsAndOwners([String? category, String? name]) async {
    try {
      final query = FirebaseFirestore.instance.collection('projects');
      final snapshot = category == null
          ? await query.get()
          : await query.where('category', isEqualTo: category).get();

      List<Map<String, dynamic>> loadedProjects = [];
      List<Future<DocumentSnapshot>> userFutures = [];

      for (var doc in snapshot.docs) {
        final projectData = doc.data();

        final adminAccepted = projectData['Adminacceptance'] ?? false;
        if (adminAccepted != true) {
          continue;
        }

        if (name != null &&
            !projectData['name']
                .toString()
                .toLowerCase()
                .contains(name.toLowerCase())) {
          continue;
        }

        final userId = projectData['user_id'];
        userFutures.add(
            FirebaseFirestore.instance.collection('users').doc(userId).get());

        loadedProjects.add(projectData);
      }

      final userSnapshots = await Future.wait(userFutures);

      for (int i = 0; i < loadedProjects.length; i++) {
        final userSnapshot = userSnapshots[i];
        final ownerImage = userSnapshot.exists
            ? (userSnapshot.data() as Map<String, dynamic>)['urlImage'] ?? ''
            : '';

        loadedProjects[i]['owner_image'] = ownerImage;
      }

      loadedProjects.sort((a, b) {
        int nameCmp = a['name'].compareTo(b['name']);
        if (nameCmp != 0) return nameCmp;
        int descCmp = a['description'].compareTo(b['description']);
        if (descCmp != 0) return descCmp;
        return a['investment_amount'].compareTo(b['investment_amount']);
      });

      setState(() {
        projects = loadedProjects;
        _isLoading = false;
      });

      print("✅ Projects filtered by name '${name ?? "All"}' loaded!");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("❌ Error fetching projects: $e");
    }
  }

  Future<void> fetchPostsAndOwners([String? category, String? name]) async {
    try {
      final query = FirebaseFirestore.instance.collection('post');
      final snapshot = await query.get();
      List<Map<String, dynamic>> loadedPosts = [];
      List<Future<DocumentSnapshot>> userFutures = [];

      for (var doc in snapshot.docs) {
        final postsData = doc.data();
        final userId = postsData['user_id'];
        final adminAccepted = postsData['Adminacceptance'] ?? false;
        if (adminAccepted != true) {
          continue;
        }
        userFutures.add(
            FirebaseFirestore.instance.collection('users').doc(userId).get());

        loadedPosts.add(postsData);
      }

      final userSnapshots = await Future.wait(userFutures);

      for (int i = 0; i < loadedPosts.length; i++) {
        final userSnapshot = userSnapshots[i];
        final ownerImage = userSnapshot.exists
            ? (userSnapshot.data() as Map<String, dynamic>)['urlImage'] ?? ''
            : '';

        loadedPosts[i]['owner_image'] = ownerImage;
      }

      loadedPosts.sort((a, b) {
        int nameCmp = a['name'].compareTo(b['name']);
        if (nameCmp != 0) return nameCmp;
        int descCmp = a['description'].compareTo(b['description']);
        if (descCmp != 0) return descCmp;
        return a['investment_amount'].compareTo(b['investment_amount']);
      });

      setState(() {
        posts = loadedPosts;
        _isLoading = false;
      });

      print("✅ Projects filtered by name '${name ?? "All"}' loaded!");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("❌ Error fetching projects: $e");
    }
  }

  void _listenToAllChatsRealTime() {
    FirebaseFirestore.instance
        .collection('chats')
        .snapshots()
        .forEach((chatSnapshot) {
      for (var chatDoc in chatSnapshot.docs) {
        final chatId = chatDoc.id;
        print("object" * 10);
        FirebaseFirestore.instance
            .collection('chats/$chatId/messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots()
            .listen((messageSnapshot) {
          if (messageSnapshot.docs.isEmpty) return;

          final messageData =
              messageSnapshot.docs.first.data() as Map<String, dynamic>;
          final senderEmail = messageData['senderEmail'] ?? '';
          final messageText = messageData['text'] ?? '';
          print("$senderEmail senderEmail");
          print("${_currentUser.email} _currentUser.email");

          if (senderEmail != _currentUser.email &&
              _lastSeenMessages[chatId] != messageText) {
            _lastSeenMessages[chatId] = messageText;
            print("Showing notification: $senderEmail - $messageText");

            showLocalNotification(title: senderEmail, body: messageText);
          }
        });
      }
    });
  }

  Future<bool?> isItsSender(String docId) async {
    try {
      final String? projectId = widget.projectID;
      if (projectId == null) {
        print('Project ID not available');
        return false;
      }

      final DocumentReference contractRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('Contracts')
          .doc(docId);

      final DocumentSnapshot contractDoc = await contractRef.get();

      if (!contractDoc.exists) {
        print('Contract document not found');
        return null;
      }

      final data = contractDoc.data() as Map<String, dynamic>;
      final ownerId = data['Information about us']?['Contract owner ID'];

      if (ownerId == null) {
        print('Contract owner ID not found');
        return false;
      }

      final isOwner = ownerId == user!.uid;

      print('Is owner: $isOwner');
      return isOwner;
    } catch (e, stackTrace) {
      print('Error checking owner: $e');
      print(stackTrace);
      return null;
    }
  }

  Future<void> fetchUserData() async {
    await FirebaseAuth.instance.currentUser?.reload();
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

  Stream<Map<String, dynamic>?> getLastMessageStream(
      String currentUserEmail, String userEmail) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(_generateChatId(currentUserEmail, userEmail))
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      } else {
        return null;
      }
    });
  }

  Stream<Map<String, dynamic>?> streamLastMessage(
      String currentUserEmail, String otherUserEmail) {
    final chatId = _generateChatId(currentUserEmail, otherUserEmail);

    return FirebaseFirestore.instance
        .collection('chats/$chatId/messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()
          ..addAll({
            'id': snapshot.docs.first.id,
          });
      }
      return null;
    });
  }

  Future<String?> getUserIdByEmail(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      } else {
        print('No user found with email: $email');
        return null;
      }
    } catch (e) {
      print('Error getting user ID by email: $e');
      return null;
    }
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

  Future<void> _autoOpenChat(String targetUserId) async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(targetUserId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final otherUserEmail = userData['email'];
      final otherUserName = userData['username'];
      final otherUserID = userDoc.id;

      final chatId = _generateChatId(_currentUser.email!, otherUserEmail);

      setState(() {
        _currentChatId = chatId;
        _currentOtherUserEmail = otherUserEmail;
        _currentOtherUserName = otherUserName;
        _currentOtherUserID = otherUserID;
        _showChatPage = true;
        _sendContract();
      });
    } catch (e) {
      print('[ERROR] Failed to auto-open chat: $e');
    }
  }

  Future<String> getUsername() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .get();

    final userData = userDoc.data();

    if (userData == null || !userData.containsKey('username')) {
      return 'User';
    }

    return userData['username'];
  }

  Future<void> fetchUsers() async {
    final snapshot = await _firestore.collection('users').get();
    setState(() {
      allUsers = snapshot.docs;
      filteredUsers = allUsers;
    });
  }

  Future<String?> fetchUserID() async {
    DocumentSnapshot? matchingUser;
    try {
      matchingUser = allUsers.firstWhere(
        (doc) => doc['email'] == _currentOtherUserEmail,
      );
    } catch (e) {
      matchingUser = null;
    }

    if (matchingUser != null) {
      final userID = matchingUser.id;
      return userID;
    } else {
      return null;
    }
  }

  String _generateChatId(String email1, String email2) {
    final sorted = [email1, email2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return "Just now";

    try {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return "Just now";
      if (difference.inHours < 1) return "${difference.inMinutes}m ago";
      if (difference.inDays < 1) return DateFormat('h:mm a').format(date);
      if (difference.inDays < 7) return DateFormat('EEE').format(date);
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return "Just now";
    }
  }

  Future<void> _openChat(
      {String? userId, String? userEmail, String? username}) async {
    try {
      String otherUserEmail;
      String otherUserName;

      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (!userDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User not found")),
          );
          return;
        }
        final userData = userDoc.data() as Map<String, dynamic>;
        otherUserEmail = userData['email'];
        otherUserName = userData['username'];
        setState(() {
          _currentOtherUserID = userDoc.id;
        });
      } else if (userEmail != null && username != null) {
        otherUserEmail = userEmail;
        otherUserName = username;
      } else {
        throw Exception(
            "Either userId or userEmail & username must be provided.");
      }

      final chatId = _generateChatId(_currentUser.email!, otherUserEmail);

      setState(() {
        _currentChatId = chatId;
        _currentOtherUserEmail = otherUserEmail;
        _currentOtherUserName = otherUserName;
        _showChatPage = true;
        _sendContract();
      });
    } catch (e) {
      print('[ERROR] Failed to open chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to open chat")),
      );
    }
  }

  void _closeChat() {
    setState(() {
      _showChatPage = false;
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentChatId.isEmpty) return;

    try {
      await _firestore
          .collection('chats')
          .doc(_currentChatId)
          .collection('messages')
          .add({
        'senderId': _currentUser.uid,
        'senderEmail': _currentUser.email,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'Message'
      });
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print('[ERROR] Failed to send message: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // void _showAttachmentOptions(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) {
  //       return Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             _buildAttachmentOption(Icons.camera_alt, "Camera", context),
  //             _buildAttachmentOption(
  //                 Icons.insert_drive_file, "Documents", context),
  //             _buildAttachmentOption(Icons.poll, "Create a poll", context),
  //             _buildAttachmentOption(Icons.image, "Media", context),
  //             _buildAttachmentOption(Icons.contacts, "Contact", context),
  //             _buildAttachmentOption(Icons.location_on, "Location", context),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // Widget _buildAttachmentOption(
  //     IconData icon, String title, BuildContext context) {
  //   return ListTile(
  //     leading: Icon(icon, color: Colors.green),
  //     title: Text(title),
  //     onTap: () => Navigator.pop(context),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    if (_showChatPage) {
      print("befor:$_currentOtherUserID");
      final imageUrl = fetchUserImagurl(_currentOtherUserID);
      print("after:$_currentOtherUserID");

      return Scaffold(
        backgroundColor: const Color(0xffEBF5F0),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _closeChat,
                    icon: Icon(Icons.arrow_back_outlined,
                        color: Color.fromARGB(255, 7, 162, 100)),
                  ),
                  FutureBuilder<String?>(
                    future: imageUrl,
                    builder: (context, snapshot) {
                      final url = snapshot.data;
                      return CircleAvatar(
                        child: ClipOval(
                          child: snapshot.connectionState ==
                                      ConnectionState.done &&
                                  url != null
                              ? Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  width: 40,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      "lib/img/person1.png",
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  "lib/img/person1.png",
                                  fit: BoxFit.cover,
                                ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Row(
                    children: [
                      Text(
                        _currentOtherUserName,
                        style: TextStyle(
                          color: const Color.fromARGB(255, 36, 69, 39),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () async {
                  if (_userData == null) {
                    await fetchUserData();
                  }

                  Map<String, dynamic> Information_about_us = {
                    '_currentChatId': _currentChatId,
                    '_currentOtherUserEmail': _currentOtherUserEmail,
                    '_currentOtherUserName': _currentOtherUserName,
                    'CurntName': _userData!['username'],
                    'CurntEmail': _userData!['email'],
                    'time of Contract': Timestamp.now(),
                    'Contreact owner ID': user!.uid,
                    'other side user': _currentOtherUserID
                  };
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => Contracts(Information_about_us)));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(248, 87, 137, 73),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    "Form a Contract",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chats')
                    .doc(_currentChatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['senderEmail'] == _currentUser.email;

                      final msgData = msg.data() as Map<String, dynamic>;
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.7),
                          decoration: BoxDecoration(
                            color:
                                isMe ? const Color(0xff03361F) : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<String>(
                                future: getUsername(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator(
                                        color: Colors.white);
                                  }

                                  if (snapshot.hasError) {
                                    return const Text('Error');
                                  }

                                  final username = snapshot.data ?? 'User';
                                  return Text(username,
                                      style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : const Color(0xff03361F),
                                          fontSize: 10));
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg['text'],
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(msg['timestamp']?.toDate()),
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                              if (msgData.containsKey('type'))
                                if (msg['type'] == 'contract') ...[
                                  FutureBuilder<bool?>(
                                    future: isItsSender(msg['docId']),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      }

                                      final isOwner = snapshot.data ?? false;
                                      final isSender = msg['senderEmail'] ==
                                          _currentUser.email;
                                      print(
                                          "isOwner:$isOwner iissender $isSender");

                                      if (isOwner || isSender) {
                                        return Container();
                                      }

                                      return Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () =>
                                                _showConfirmationDialog(
                                              context: context,
                                              title: 'Accept Contract',
                                              content:
                                                  'Are you sure you want to accept this contract?',
                                              onConfirm: () => _acceptContract(
                                                  context, msg['docId']),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      255, 47, 211, 91),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                            ),
                                            child: const Text("Accept"),
                                          ),
                                          const SizedBox(width: 40),
                                          ElevatedButton(
                                            onPressed: () =>
                                                _showConfirmationDialog(
                                              context: context,
                                              title: 'Reject Contract',
                                              content:
                                                  'Are you sure you want to reject this contract?',
                                              onConfirm: () => _rejectContract(
                                                  context, msg['docId']),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.red.shade700,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                            ),
                                            child: const Text("Reject"),
                                          ),
                                        ],
                                      );
                                    },
                                  )
                                ]
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      );
    }
    bool isadmin = false;
    if (_userData?['admin'] == true) isadmin = true;
    return Scaffold(
      backgroundColor: const Color(0xFFEBF5F0),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 210,
                color: Colors.white,
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 11, right: 11, top: 25),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.search, //get back here
                                color: Color(0xff51826E)),
                            onPressed: () {},
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              if (user != null) {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => const Profile()));
                              } else {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => const LoginPage()));
                              }
                            },
                            child: SizedBox(
                              width: 70,
                              height: 70,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        const Color.fromARGB(255, 43, 90, 32),
                                    width: 2.0,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(100),
                                  ),
                                ),
                                child: FutureBuilder<String?>(
                                  future: fetchUserImagurl(user!.uid),
                                  builder: (context, snapshot) {
                                    final imageUrl = snapshot.data;
                                    return ClipRRect(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(100),
                                      ),
                                      child: imageUrl != null
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.asset(
                                                  "lib/img/person1.png",
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            )
                                          : Image.asset(
                                              "lib/img/person1.png",
                                              fit: BoxFit.cover,
                                            ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final userData = filteredUsers[index].data()
                              as Map<String, dynamic>;
                          final userId = filteredUsers[index].id;

                          return Container(
                            margin: EdgeInsets.only(right: 8),
                            child: _buildStatusItem(
                              userData['username'] ?? 'User',
                              isMe: false,
                              borderColor: const Color(0xffEBF5F0),
                              avatarWidget: FutureBuilder<String?>(
                                future: fetchUserImagurl(userId),
                                builder: (context, snapshot) {
                                  final imageUrl = snapshot.data;
                                  return SizedBox(
                                    width: 54,
                                    height: 54,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: imageUrl != null
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.asset(
                                                  "lib/img/person1.png",
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            )
                                          : Image.asset(
                                              "lib/img/person1.png",
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  );
                                },
                              ),
                              onTap: () {
                                _openChat(
                                  userEmail: userData['email'],
                                  username: userData['username'],
                                );
                              },
                            ),
                          );
                        },
                        scrollDirection: Axis.horizontal,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                    child: Container(
                      color: const Color(0xFFEBF5F0),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('users').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final users = snapshot.data!.docs;
                          return ListView.builder(
                            itemCount: users.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Center(
                                  child: Container(
                                    height: 3,
                                    width: 35,
                                    margin: const EdgeInsets.only(bottom: 3),
                                    color: const Color(0xffAACBBD),
                                  ),
                                );
                              }

                              final userData = users[index - 1].data()
                                  as Map<String, dynamic>;
                              if (userData['email'] == _currentUser.email) {
                                return const SizedBox();
                              }

                              return Dismissible(
                                key: Key(userData['email']),
                                direction: DismissDirection.endToStart,
                                child: GestureDetector(
                                  onTap: () {
                                    _openChat(
                                        userEmail: userData['email'],
                                        username: userData['username']);
                                  },
                                  child: StreamBuilder<Map<String, dynamic>?>(
                                    stream: getLastMessageStream(
                                        _currentUser.email!, userData['email']),
                                    builder: (context, snapshot) {
                                      String messageText = "";
                                      String timeText = "Just now.";

                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        final message = snapshot.data!;
                                        messageText =
                                            message['text'] ?? "Attachment";
                                        timeText = _formatMessageTime(
                                            message['timestamp']);
                                        if (timeText == "Just now.") {
                                          timeText = "new!";
                                        }
                                      }
                                      if (messageText == "") {
                                        return SizedBox();
                                      }
                                      return _buildMessageItem(
                                        name: userData['username'],
                                        message: messageText,
                                        time: timeText,
                                        userEmail: userData['email'],
                                        isUnread: false,
                                        isOnline: userData['isOnline'] ?? false,
                                        showTime: true,
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 60,
              color: const Color(0xff03361F),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, 0),
                  if (isadmin) ...[
                    _buildNavItem(Icons.admin_panel_settings, 1),
                  ] else
                    _buildNavItem(Icons.add, 1),
                  _buildNavItem(Icons.message, 2),
                  _buildNavItem(Icons.person, 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            // GestureDetector(
            //   onTap: () => _showAttachmentOptions(context),
            //   child: Icon(Icons.attach_file, color: Colors.grey),
            // ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Write your message",
                  filled: true,
                  fillColor: const Color(0xffF0F0F0),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xff03361F),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem({
    required String name,
    required String message,
    required String time,
    required String userEmail,
    required bool isUnread,
    required bool isOnline,
    required bool showTime,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xffEBF5F0),
        borderRadius: BorderRadius.circular(50),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            FutureBuilder<String?>(
              future: getUserIdByEmail(userEmail).then((userId) {
                if (userId != null) {
                  return fetchUserImagurl(userId);
                }
                return null;
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey[300],
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  );
                }

                final imagePath = snapshot.data;
                return CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: imagePath != null
                      ? NetworkImage(imagePath)
                      : const AssetImage("lib/img/person1.png"),
                  child: imagePath == null
                      ? Icon(Icons.person, color: Colors.white)
                      : null,
                );
              },
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xffEBF5F0),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isUnread) Icon(Icons.circle, color: Colors.green),
          ],
        ),
        subtitle: Text(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isUnread ? Colors.black : Colors.grey[600],
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: showTime
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      color: isUnread ? Colors.blue : Colors.grey[600],
                      fontSize: 12,
                      fontWeight:
                          isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isUnread)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              )
            : Text(
                isOnline ? "Online" : "Offline",
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (_selectedIndex == 0) {
          if (user != null) {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const Homepage()));
          } else {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()));
          }
        } else if (index == 1) {
          if (user != null && (_userData?['admin'] ?? false)) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => Admintapssystem(projects, posts)));
          } else {
            user != null
                ? Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => BottomTabs()))
                : Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => LoginPage()));
          }
        } else if (_selectedIndex == 3) {
          if (user != null) {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const Profile()));
          } else {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()));
          }
        }
      },
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatusItem(
    String username, {
    bool isMe = false,
    Color borderColor = const Color(0xffEBF5F0),
    Widget? avatarWidget,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 7.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            avatarWidget ??
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: borderColor,
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        isMe ? null : const AssetImage("lib/img/person1.png"),
                    child: isMe
                        ? const Icon(Icons.add,
                            size: 30, color: Color(0xff362F34))
                        : null,
                  ),
                ),
            const SizedBox(height: 6),
            Text(
              username,
              style: const TextStyle(fontSize: 14, color: Color(0xff002C1A)),
            ),
          ],
        ),
      ),
    );
  }

  void _sendContract() async {
    if (widget.projectID == null ||
        _currentChatId == null ||
        _currentUser == null) return;

    try {
      final contractsRef = FirebaseFirestore.instance.collection('Contracts');

      // 🔍 Only get contracts related to this project and not yet sent
      final querySnapshot = await contractsRef
          .where('projectId', isEqualTo: widget.projectID)
          .where('sended?', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('ℹ️ No unsent contracts for this project.');
        return;
      }

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final String contractText =
            data['formatContractText'] ?? 'No contract text';

        // ✅ Mark as sent
        await doc.reference.update({'sended?': true});

        // ✉️ Send contract message to chat
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(_currentChatId)
            .collection('messages')
            .add({
          'senderId': _currentUser.uid,
          'senderEmail': _currentUser.email,
          'text': contractText,
          'type': 'contract',
          'timestamp': FieldValue.serverTimestamp(),
          'docId': doc.id,
          'projectId': widget.projectID,
        });
        print("✅ Contract sent: ${doc.id}");
      }

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending contract: ${e.toString()}')),
      );
    }
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _acceptContract(BuildContext context, String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ You must be logged in')),
      );
      return;
    }

    final contractDocRef =
        FirebaseFirestore.instance.collection('Contracts').doc(docId);

    try {
      final contractSnapshot = await contractDocRef.get();

      if (!contractSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Contract not found')),
        );
        return;
      }

      final contractData = contractSnapshot.data()!;
      final effectiveProjectId = contractData['projectId'];

      if (effectiveProjectId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Project ID not found in contract')),
        );
        return;
      }

      await contractDocRef.update({
        'adminAcceptance': true,
        'Curnt accepted sides': [user.uid, _currentOtherUserID]
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Contract accepted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error accepting contract: $e')),
      );
    }
  }

  void _rejectContract(BuildContext context, String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    final contractDocRef =
        FirebaseFirestore.instance.collection('Contracts').doc(docId);

    try {
      final contractSnapshot = await contractDocRef.get();

      if (!contractSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Contract not found')),
        );
        return;
      }

      await contractDocRef.update({
        'status': 'rejected',
        'Adminacceptance': false,
      });

      final currentChatId =
          contractSnapshot.data()?['chatId'] ?? 'defaultChatId';

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(currentChatId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderEmail': user.email,
        'text': "The offer has been rejected.",
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Contract rejected successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error rejecting contract: $e')),
      );
    }
  }
}
