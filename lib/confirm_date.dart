import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'duplicate_date.dart'; 

class BookingPage extends StatefulWidget {
  @override
  _ConfirmDateState createState() => _ConfirmDateState();
}

class _ConfirmDateState extends State<BookingPage> {
  // 1. VARIABLES MUST BE HERE (Inside the State class)
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;

        // Formats the date for the Textbox
        _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate!);

        // Logic to calculate duration if end date already exists
        if (_endDate != null && _startDate!.isBefore(_endDate!)) {
          int calculatedDays = _endDate!.difference(_startDate!).inDays + 1;
          _daysController.text = calculatedDays.toString();
        } else {
          _daysController.text = "1";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Confirm Booking Date")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _startDateController,
              decoration: InputDecoration(
                labelText: "Start Date",
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectStartDate(context),
                ),
              ),
              readOnly: true,
            ),
            TextField(
              controller: _daysController,
              decoration: InputDecoration(labelText: "Total Days"),
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }
}