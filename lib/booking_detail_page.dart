import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'review_section.dart';
import 'utils/price_utils.dart';

class BookingDetailsPage extends StatefulWidget {
  final String username;
  final Map<String, dynamic> hallData;

  const BookingDetailsPage({
    required this.username,
    required this.hallData,
    Key? key,
  }) : super(key: key);

  @override
  _BookingDetailsPageState createState() => _BookingDetailsPageState();
}

Map<String, dynamic>? pendingBooking;

class _BookingDetailsPageState extends State<BookingDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> selectedFacilities = [];
  DateTime? startDate;
  DateTime? endDate;

  double _calculateTotalPrice() {
    final basePrice = (widget.hallData['price'] as num).toDouble();
    if (startDate == null || endDate == null) {
      return basePrice + (selectedFacilities.length * 50);
    }
    return calculateTotalPrice(
      basePrice: basePrice,
      facilities: selectedFacilities,
      startDate: startDate!,
      endDate: endDate!,
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Saves form details
    if (widget.username.isNotEmpty && pendingBooking != null) {
      final data = pendingBooking!;
      selectedFacilities.addAll(List<String>.from(data['facilities']));
      startDate = data['startDate'];
      endDate = data['endDate'];
      pendingBooking = null;
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  void _showConfirmationDialog(Map<String, dynamic> booking) {
    final start = booking['startDate'] as DateTime;
    final end = booking['endDate'] as DateTime;
    final hallTitle = booking['hall']['title'];
    final duration = end.difference(start).inDays + 1;
    final facilityCost = (booking['facilities'] as List<String>).length * 50;
    final durationCost = duration * 130;
    final basePrice = (booking['hall']['price'] as num).toDouble();
    final total = basePrice + facilityCost + durationCost;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.check_circle,
                        color: Colors.lightBlue,
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Booking Confirmed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    '$hallTitle is booked from ${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('yyyy-MM-dd').format(end)}.',
                    style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Total: RM ${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.lightBlue,
                    ),
                  ),
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // close dialog
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/welcome', (route) => false);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.lightBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _confirmBooking() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please state how long you will use the hall.')),
      );
      return;
    }

    final bookingData = {
      'username': widget.username,
      'hall': widget.hallData,
      'facilities': selectedFacilities,
      'startDate': startDate,
      'endDate': endDate,
    };

    if (widget.username.isEmpty) {
      //not logged in
      pendingBooking = bookingData;
      Navigator.pushNamed(
        context,
        '/login',
        arguments: {'redirected': true},
      ); // redirect pass
    } else {
      final success = await _saveBookingToFirestore(bookingData);
      if (success) {
        _showConfirmationDialog(bookingData);
      }
    }
  }

  Widget _buildFacilitiesTabStyled() {
    final facilities = List<String>.from(widget.hallData['facilities'] ?? []);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          facilities.map((facility) {
            final selected = selectedFacilities.contains(facility);
            return FilterChip(
              label: Text(facility),
              selected: selected,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
              ),
              selectedColor: Color(0xFF42A5F5),
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey[200],
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) {
                    selectedFacilities.add(facility);
                  } else {
                    selectedFacilities.remove(facility);
                  }
                });
              },
            );
          }).toList(),
    );
  }

  Widget _buildDateTimeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickDateRange,
          icon: Icon(Icons.date_range),
          label: Text('Reserve Date'),
        ),
        if (startDate != null && endDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Booking from ${DateFormat('yyyy-MM-dd').format(startDate!)} to ${DateFormat('yyyy-MM-dd').format(endDate!)}',
            ),
          ),
        SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text('Confirm and pay'),
          ),
        ),
      ],
    );
  }

  Future<bool> _saveBookingToFirestore(Map<String, dynamic> booking) async {
    try {
      final username = booking['username'];

      // get the user doc from collection
      final userQuery =
          await FirebaseFirestore.instance
              .collection('Users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User not found')));
        return false;
      }

      final userId = userQuery.docs.first.id;

      final start = booking['startDate'] as DateTime;
      final end = booking['endDate'] as DateTime;

      final hallPrice = (booking['hall']['price'] as num).toDouble();
      final facilities = booking['facilities'] as List<String>;
      final total = calculateTotalPrice(
        basePrice: hallPrice,
        facilities: facilities,
        startDate: start,
        endDate: end,
      );

      await FirebaseFirestore.instance.collection('hallbook').add({
        'UserID': userId,
        'BookTime': Timestamp.now(),
        'EventDate': DateFormat('yyyy-MM-dd').format(start),
        'EventTime':
            '${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('yyyy-MM-dd').format(end)}',
        'HallType': booking['hall']['title'],
        'AddItem': facilities,
        'Price': total,
      });

      return true;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hall = widget.hallData;
    final discussionId =
        (hall['id'] ?? hall['title'] ?? 'general-hall-discussion').toString();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Hall image with overlay and logo
          Stack(
            children: [
              hall['image'] != null
                  ? Image.asset(
                    'assets/images/${hall['image']}',
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                  )
                  : Container(height: 240, color: Colors.grey[300]),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Image.asset('assets/images/LogoSpazio.png', height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Hall content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hall['title'] ?? '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    hall['description'] ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Total: RM ${_calculateTotalPrice().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF42A5F5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  EventChatSection(
                    discussionId: discussionId,
                    isLoggedIn: widget.username.isNotEmpty,
                  ),

                  const SizedBox(height: 24),

                  // TabBar
                  DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: Color(0xFF42A5F5),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Color(0xFF42A5F5),
                          tabs: [
                            Tab(text: 'Facilities'),
                            Tab(text: 'Time/Date'),
                          ],
                        ),
                        SizedBox(
                          height: 300,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildFacilitiesTabStyled(),
                              _buildDateTimeTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
