import 'package:MOLLILE/Dartpages/HomePage/Home_page.dart';
import 'package:MOLLILE/project%20post/ProjectAdd.dart';
import 'package:MOLLILE/Dartpages/UserData/profile_information.dart';
import 'package:MOLLILE/Dartpages/sighUpIn/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

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

  List<DocumentSnapshot> filteredUsers = [];
  List<DocumentSnapshot> allUsers = [];
  int _selectedIndex = 2;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _showChatPage = false;
  String _currentChatId = "";
  String _currentOtherUserEmail = "";
  String _currentOtherUserName = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser!;
    fetchUsers();
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

  String _generateChatId(String email1, String email2) {
    final sorted = [email1, email2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<String> _getOrCreateChat(String otherUserEmail) async {
    final chatId = _generateChatId(_currentUser.email!, otherUserEmail);

    try {
      final chatSnapshot =
          await _firestore.collection('chats').doc(chatId).get();

      if (!chatSnapshot.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'createdAt': FieldValue.serverTimestamp(),
          'participants': [_currentUser.uid, otherUserEmail],
          'participantEmails': [_currentUser.email, otherUserEmail],
        });
      }
      return chatId;
    } catch (e) {
      print('[ERROR] Error in _getOrCreateChat: $e');
      rethrow;
    }
  }

  void _openChat(String otherUserEmail, String username) async {
    try {
      final chatId = await _getOrCreateChat(otherUserEmail);

      setState(() {
        _currentChatId = chatId;
        _currentOtherUserEmail = otherUserEmail;
        _currentOtherUserName = username;
        _showChatPage = true;
      });
    } catch (e) {
      print('[ERROR] Failed to open chat: $e');
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

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAttachmentOption(Icons.camera_alt, "Camera", context),
              _buildAttachmentOption(
                  Icons.insert_drive_file, "Documents", context),
              _buildAttachmentOption(Icons.poll, "Create a poll", context),
              _buildAttachmentOption(Icons.image, "Media", context),
              _buildAttachmentOption(Icons.contacts, "Contact", context),
              _buildAttachmentOption(Icons.location_on, "Location", context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(
      IconData icon, String title, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      onTap: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showChatPage) {
      return Scaffold(
        backgroundColor: const Color(0xffEBF5F0),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          title: Row(
            children: [
              IconButton(
                onPressed: _closeChat,
                icon: const Icon(Icons.arrow_back_outlined,
                    size: 20, color: Color(0xff002114)),
              ),
              const CircleAvatar(
                backgroundImage:
                    AssetImage("lib/img/person1.png"), // get back here
              ),
              const SizedBox(width: 8),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.call), onPressed: () {}),
            IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
          ],
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 25),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search,
                                size: 35, color: Color(0xff51826E)),
                            onPressed: () {},
                          ),
                          const Spacer(),
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xffEBF5F0),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: AssetImage(
                                  "lib/img/person1.png"), // get back here
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
                          return _buildStatusItem(
                              userData['username'] ?? 'User',
                              isMe: false,
                              borderColor: const Color(0xffEBF5F0), onTap: () {
                            _openChat(userData['email'], userData['username']);
                          });
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
                                background: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  alignment: Alignment.centerRight,
                                  color: Colors.red,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: const [
                                      Icon(Icons.delete, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        "Delete",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Confirm Deletion"),
                                          content: Text(
                                              "Delete chat with ${userData['username']}?"),
                                          actions: [
                                            TextButton(
                                              child: const Text("Cancel"),
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                            ),
                                            TextButton(
                                              child: const Text("Delete",
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                },
                                onDismissed: (_) {
                                  // Delete chat logic here
                                },
                                child: GestureDetector(
                                  onTap: () => _openChat(
                                      userData['email'], userData['username']),
                                  child: _buildMessageItem(
                                    name: userData['username'],
                                    message: "Tap to start chatting",
                                    time: "Just now",
                                    imagePath: "lib/img/person1.png",
                                    isUnread: false,
                                    isOnline: userData['isOnline'] ?? false,
                                    showTime: true,
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
            GestureDetector(
              onTap: () => _showAttachmentOptions(context),
              child: const Icon(Icons.attach_file, color: Colors.grey),
            ),
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
                child: const Icon(Icons.send, color: Colors.white, size: 20),
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
    required String imagePath,
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
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey[300],
              backgroundImage: AssetImage(imagePath),
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
            if (isUnread)
              const Icon(Icons.circle, color: Colors.green, size: 10),
          ],
        ),
        subtitle: Text(message),
        trailing: showTime
            ? Text(
                time,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              )
            : const Text(
                "Online",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const Homepage()));
          } else {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()));
          }
        } else if (_selectedIndex == 1) {
          if (user != null) {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProjectAdd()));
          } else {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()));
          }
        } else if (_selectedIndex == 3) {
          if (user != null) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ProfileInformation()));
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

  Widget _buildStatusItem(String name,
      {bool isMe = false, required Color borderColor, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 7.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                    ? const Icon(Icons.add, size: 30, color: Color(0xff362F34))
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(fontSize: 14, color: Color(0xff002C1A)),
            ),
          ],
        ),
      ),
    );
  }
}
