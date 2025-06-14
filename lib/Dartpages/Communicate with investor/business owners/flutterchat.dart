import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatPage extends StatefulWidget {
  static String IDPushName = "ChatPage";

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  final user = FirebaseAuth.instance.currentUser!;
  late types.User _chatUser;

  @override
  void initState() {
    super.initState();
    _chatUser = types.User(id: user.uid);
    _loadMessages();
  }

  void _loadMessages() {
    FirebaseFirestore.instance
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data.containsKey('uid') &&
                data.containsKey('text') &&
                data.containsKey('createdAt')) {
              return types.TextMessage(
                author: types.User(id: data['uid']),
                createdAt: data['createdAt'],
                id: doc.id,
                text: data['text'],
              );
            } else {
              print('Error: Invalid Firestore document: ${doc.id}');
              return null;
            }
          })
          .whereType<types.TextMessage>()
          .toList();
      setState(() {
        _messages = messages;
      });
    });
  }

  void _handleSendPressed(types.PartialText message) {
    try {
      if (message.text.isNotEmpty && user.uid.isNotEmpty) {
        FirebaseFirestore.instance.collection('messages').add({
          'uid': user.uid,
          'text': message.text,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'type': "Message"
        });
      } else {
        print('Error: Invalid message data');
      }
    } catch (e) {
      print("error line 58: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _chatUser,
      ),
    );
  }
}
