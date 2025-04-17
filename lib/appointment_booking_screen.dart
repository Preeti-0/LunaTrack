import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'doctor_model.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final Doctor doctor;
  const AppointmentBookingScreen({super.key, required this.doctor});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  DateTime? selectedDate;
  String? selectedTime;
  List<String> bookedTimes = [];
  final TextEditingController _reasonController = TextEditingController();

  final List<String> allTimeSlots = [
    "10:00",
    "11:00",
    "12:00",
    "13:00",
    "14:00",
    "15:00",
    "16:00",
    "17:00",
    "18:00",
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedTime = null;
      });
      _fetchBookedSlots();
    }
  }

  Future<void> _fetchBookedSlots() async {
    if (selectedDate == null) return;
    final result = await ApiService.getBookedTimes(
      widget.doctor.id,
      selectedDate!,
    );
    setState(() {
      bookedTimes = result;
    });
  }

  Future<void> _bookAppointment() async {
    if (selectedDate == null ||
        selectedTime == null ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    final success = await ApiService.bookAppointment(
      doctorId: widget.doctor.id,
      date: selectedDate!,
      time: selectedTime!,
      reason: _reasonController.text,
    );

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Appointment booked successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Booking failed. Please try again.")),
      );
    }
  }

  Widget _buildTimeChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          allTimeSlots.map((time) {
            final isBooked = bookedTimes.contains(time);
            final isSelected = selectedTime == time;
            return ChoiceChip(
              label: Text(time),
              selected: isSelected,
              onSelected:
                  isBooked
                      ? null
                      : (_) {
                        setState(() {
                          selectedTime = time;
                        });
                      },
              selectedColor: Colors.pink.shade100,
              disabledColor: Colors.grey.shade300,
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color:
                    isBooked
                        ? Colors.grey
                        : isSelected
                        ? Colors.pinkAccent
                        : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Appointment"),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(widget.doctor.imageUrl ?? ''),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.doctor.name,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.doctor.specialization,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Select a Date",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate != null
                          ? DateFormat('EEE, MMM d, yyyy').format(selectedDate!)
                          : "Tap to choose a date",
                    ),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Available Time Slots",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildTimeChips(),
            const SizedBox(height: 20),
            const Text(
              "Reason for Visit",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Describe your reason for visit...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _bookAppointment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.pinkAccent,
                ),
                child: const Text(
                  "Book Appointment",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
