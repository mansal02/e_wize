import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Future<void> _deleteUser(String docId, String username) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(docId).delete();

      // Delete all bookings by this user
      final bookings =
          await FirebaseFirestore.instance
              .collection('hallbook')
              .where('UserID', isEqualTo: docId)
              .get();

      for (var booking in bookings.docs) {
        await booking.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User and their bookings deleted')),
      );

    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
    }
  }

  Future<Map<String, int>> _fetchSummaryCounts() async {
    final users = await FirebaseFirestore.instance.collection('Users').get();
    final bookings =
        await FirebaseFirestore.instance.collection('hallbook').get();
    final halls = await FirebaseFirestore.instance.collection('Halls').get();

    return {
      'users': users.size,
      'bookings': bookings.size,
      'halls': halls.size,
    };
  }

  Future<void> _deleteBooking(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('hallbook')
          .doc(docId)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting booking: $e')));
    }
  }

  Widget _buildSummaryTile(String label, int count) {
    return Card(
      color: Colors.lightBlue.shade100,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagementTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Users').snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
          return Center(child: Text('No users found.'));
        }

        final users = userSnapshot.data!.docs;

        return ListView(
          padding: EdgeInsets.all(12),
          children:
              users.map((userDoc) {
                final user = userDoc.data() as Map<String, dynamic>;
                final username = user['username'];
                final userId = userDoc.id;

                return FutureBuilder<QuerySnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('hallbook')
                          .where('UserID', isEqualTo: username)
                          .get(),
                  builder: (context, bookingSnapshot) {
                    final bookings = bookingSnapshot.data?.docs ?? [];

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ExpansionTile(
                        title: Text('$username (${user['name'] ?? 'No Name'})'),
                        subtitle: Text(
                          'Email: ${user['email'] ?? 'N/A'}, Phone: ${user['phone'] ?? 'N/A'}',
                        ),
                        children: [
                          ...bookings.map((bookingDoc) {
                            final booking =
                                bookingDoc.data() as Map<String, dynamic>;
                            return ListTile(
                              title: Text('${booking['HallType']}'),
                              subtitle: Text(
                                'Date: ${booking['EventDate']} - ${booking['EventTime']}\nFacilities: ${booking['AddItem'] ?? '-'} | RM ${booking['Price']}',
                              ),
                            );
                          }).toList(),
                          ButtonBar(
                            alignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                child: Text(
                                  'Delete Account',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () => _deleteUser(userId, username),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildBookingManagementTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('hallbook')
              .orderBy('BookTime', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No bookings found.'));
        }

        final bookings = snapshot.data!.docs;

        return ListView.builder(
          itemCount: bookings.length,
          padding: EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final booking = bookings[index].data() as Map<String, dynamic>;
            final docId = bookings[index].id;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.event, color: Colors.lightBlue),
                title: Text('${booking['HallType']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text('User: ${booking['UserID']}'),
                    Text('Date: ${booking['EventDate']}'),
                    Text('Time: ${booking['EventTime']}'),
                    Text('Facilities: ${booking['AddItem'] ?? '-'}'),
                    Text('Price: RM ${booking['Price']}'),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteBooking(docId),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHallManagementTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Halls').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No halls found.'));
        }

        final halls = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: halls.length,
          itemBuilder: (context, index) {
            final hallDoc = halls[index];
            final hall = hallDoc.data() as Map<String, dynamic>;
            final title = hall['title'] ?? 'Untitled';
            final price = (hall['price'] as num).toDouble();
            final facilities = List<String>.from(hall['facilities'] ?? []);

            final priceController = TextEditingController(
              text: price.toStringAsFixed(2),
            );

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Price (RM)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Facilities: ${facilities.join(', ')}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final newPrice = double.tryParse(
                              priceController.text,
                            );
                            if (newPrice == null) {
                              throw Exception('Invalid price format');
                            }

                            await FirebaseFirestore.instance
                                .collection('Halls')
                                .doc(hallDoc.id)
                                .update({'price': newPrice});

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$title price updated')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        },
                        icon: Icon(Icons.save),
                        label: Text('Update'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('EventWize Admin'),
          actions: [
            // Summary counts use FutureBuilder; this re-triggers it after changes
            // Tab StreamBuilders auto-update without this button
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // 🔹 Summary section on top
            FutureBuilder(
              future: _fetchSummaryCounts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final counts = snapshot.data as Map<String, int>;
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSummaryTile('Users', counts['users']!),
                      _buildSummaryTile('Bookings', counts['bookings']!),
                      _buildSummaryTile('Halls', counts['halls']!),
                    ],
                  ),
                );
              },
            ),
            TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black54,
              tabs: [
                Tab(text: 'Users'),
                Tab(text: 'Bookings'),
                Tab(text: 'Halls'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUserManagementTab(),
                  _buildBookingManagementTab(),
                  _buildHallManagementTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
