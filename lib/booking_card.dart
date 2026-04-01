import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingCard extends StatefulWidget {
  final String hallName;
  final String eventTime;
  final double basePrice;
  final List<String> bookedFacilities;
  final String hallType;
  final Timestamp bookTime;
  final void Function(List<String> selectedFacilities, double updatedPrice)
  onEdit;
  final VoidCallback onDelete;

  const BookingCard({
    super.key,
    required this.hallName,
    required this.eventTime,
    required this.basePrice,
    required this.bookedFacilities,
    required this.hallType,
    required this.bookTime,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  bool isExpanded = false;
  bool isEditing = false;
  List<String> availableFacilities = [];
  List<String> selectedFacilities = [];
  bool isLoadingFacilities = true;

  @override
  void initState() {
    super.initState();
    selectedFacilities = List.from(widget.bookedFacilities);
    _loadFacilities();
  }

  Future<void> _loadFacilities() async {
    try {
      print("Looking up facilities for hallType: '${widget.hallType}'");

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('Halls')
              .where('title', isEqualTo: widget.hallType)
              .get();

      if (querySnapshot.docs.isNotEmpty && mounted) {
        final data = querySnapshot.docs.first.data();
        print("Fetched document: $data");

        final facilities = List<String>.from(data['facilities'] ?? []);
        print("Parsed facilities list: $facilities");

        setState(() {
          availableFacilities = facilities;
          isLoadingFacilities = false;
        });
      } else {
        print("No matching hall with title '${widget.hallType}'");
        setState(() {
          availableFacilities = [];
          isLoadingFacilities = false;
        });
      }
    } catch (e) {
      print("Error loading facilities: $e");
      if (mounted) {
        setState(() {
          availableFacilities = [];
          isLoadingFacilities = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Edit preview: basePrice from Firestore + currently selected facilities at RM50 each
    final totalPrice = widget.basePrice + selectedFacilities.length * 50;

    String _formatTimestamp(Timestamp timestamp) {
      final date = timestamp.toDate();
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.hallName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Price: RM${(widget.basePrice + widget.bookedFacilities.length * 50).toStringAsFixed(2)}",
                ),
                Text("Booked on: ${_formatTimestamp(widget.bookTime)}"),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () {
                    setState(() {
                      if (isExpanded && isEditing) {
                        // Collapse card
                        isExpanded = false;
                        isEditing = false;
                      } else {
                        // Expand card
                        isExpanded = true;
                        isEditing = true;
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
          if (isExpanded) const Divider(thickness: 1),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Facilities:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (isLoadingFacilities)
                    const Center(child: Text("Loading facilities..."))
                  else if (availableFacilities.isEmpty)
                    Text("No facilities found for '${widget.hallType}'.")
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          availableFacilities.map((facility) {
                            final isSelected = selectedFacilities.contains(
                              facility,
                            );
                            return FilterChip(
                              label: Text(facility),
                              selected: isSelected,
                              onSelected:
                                  isEditing
                                      ? (selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedFacilities.add(facility);
                                          } else {
                                            selectedFacilities.remove(facility);
                                          }
                                        });
                                      }
                                      : null,
                              selectedColor: Colors.lightBlueAccent.withOpacity(
                                0.3,
                              ),
                              backgroundColor: Colors.grey[200],
                              checkmarkColor: Colors.blueAccent,
                              labelStyle: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.blueAccent
                                        : Colors.black,
                              ),
                            );
                          }).toList(),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    "Event Dates:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(widget.eventTime),
                  const SizedBox(height: 16),
                  Text(
                    "Total Price: RM${totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (isEditing)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onEdit(selectedFacilities, totalPrice);
                          setState(() {
                            isEditing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Save Changes"),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
