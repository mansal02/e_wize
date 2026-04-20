import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Adjust these imports based on your exact folder names in e_wize
import '../details/comments.dart'; 
import '../details/message.dart';

class EventChatSection extends StatelessWidget {
  final String discussionId;
  final bool isLoggedIn;

  const EventChatSection({
    super.key,
    required this.discussionId,
    required this.isLoggedIn,
  });

  Future<void> _addMessage(BuildContext context, String message) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('discussions')
        .doc(discussionId)
        .collection('messages')
        .add({
      'message': message,
      'sender': user.displayName ?? user.email ?? 'Anonymous',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Reviews and Discussion', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Divider(),
        SizedBox(
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('discussions')
                .doc(discussionId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView(
                reverse: true,
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return MessageCard(
                    message: data['message'],
                    sender: data['sender'],
                    timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  );
                }).toList(),
              );
            },
          ),
        ),
        Comments(
          addMessage: (msg) => _addMessage(context, msg),
          canComment: isLoggedIn,
        ),
      ],
    );
  }
}