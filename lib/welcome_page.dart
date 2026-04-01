import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'styled_page_scaffold.dart';
import 'booking_detail_page.dart';

class WelcomePage extends StatefulWidget {
  final String username;
  final VoidCallback onLogout;

  WelcomePage({required this.username, required this.onLogout});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final Map<String, IconData> hallIcons = {
    'Seminar Room': Icons.meeting_room,
    'Community Hall': Icons.groups,
    'Studio Space': Icons.music_video,
    'Rooftop Venue': Icons.terrain,
    'Ballroom': Icons.cake,
  };

  @override
  Widget build(BuildContext context) {
    return StyledPageScaffold(
      title: 'EventWize',
      actions: [
        if (widget.username.isNotEmpty)
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white),
            tooltip: 'Update Profile',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/profile',
                arguments: {'username': widget.username},
              );
            },
          ),
        IconButton(
          icon: Icon(
            widget.username.isEmpty ? Icons.login : Icons.logout,
            color: Colors.white,
          ),
          tooltip: widget.username.isEmpty ? 'Login' : 'Logout',
          onPressed: () {
            if (widget.username.isEmpty) {
              Navigator.pushNamed(context, '/login');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Logged out successfully')),
              );

              // Navigate after a short delay to avoid setState on unmounted widget
              Future.delayed(Duration(milliseconds: 300), () {
                if (mounted) {
                  widget.onLogout();
                  Navigator.pushReplacementNamed(context, '/login');
                }
              });
            }
          },
        ),
      ],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Halls').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          final halls = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: halls.length,
            itemBuilder: (context, index) {
              final hall = halls[index].data() as Map<String, dynamic>;
              final title = hall['title'] ?? '';
              final price = (hall['price'] as num).toDouble();

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.lightBlue.shade50,
                child: ListTile(
                  leading: Icon(
                    hallIcons[title] ?? Icons.event,
                    color: Colors.lightBlue,
                    size: 32,
                  ),
                  title: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('RM ${price.toStringAsFixed(2)}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => BookingDetailsPage(
                              username: widget.username,
                              hallData: hall,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
