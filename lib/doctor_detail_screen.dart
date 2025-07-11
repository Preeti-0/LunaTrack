import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../doctor_model.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'payment_confirmation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  DateTime selectedDate = DateTime.now();
  String? selectedTime;
  List<String> bookedTimes = [];
  final List<String> timeSlots = [
    "10:00",
    "11:00",
    "12:00",
    "14:00",
    "15:00",
    "16:00",
    "17:00",
  ];

  final TextEditingController reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBookedTimes();
  }

  Future<void> fetchBookedTimes() async {
    final times = await ApiService.getBookedTimes(
      widget.doctor.id,
      selectedDate,
    );
    setState(() {
      bookedTimes = times;
    });
  }

  void _handlePayLater() async {
    if (selectedTime == null || reasonController.text.isEmpty) {
      showSnack("Please select a time and enter a reason.");
      return;
    }

    final success = await ApiService.bookAppointmentWithoutPayment(
      doctorId: widget.doctor.id,
      date: selectedDate,
      time: selectedTime!,
      reason: reasonController.text,
    );

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PaymentConfirmationScreen()),
      );
    } else {
      showSnack("\u274C Failed to book appointment");
    }
  }

  void showConfirmationDialog() {
    if (selectedTime == null || reasonController.text.isEmpty) {
      showSnack("Please select time and enter reason");
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Payment"),
            content: Text(
              "You will be charged Rs. ${widget.doctor.consultationFee.toStringAsFixed(0)} to book an appointment with ${widget.doctor.name}. Proceed?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  startPayment();
                },
                child: const Text("Pay Now"),
              ),
            ],
          ),
    );
  }

  void startPayment() {
    final feeInPaisa = (widget.doctor.consultationFee * 100).toInt();

    KhaltiScope.of(context).pay(
      config: PaymentConfig(
        amount: feeInPaisa,
        productIdentity: 'doctor_${widget.doctor.id}',
        productName: widget.doctor.name,
        mobile: '9800000001',
      ),
      preferences: [PaymentPreference.khalti],
      onSuccess: (success) async {
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('access');

        if (accessToken == null) {
          showSnack(
            "\u26a0\ufe0f Access token not found. Please log in again.",
          );
          return;
        }

        final isVerified = await ApiService.verifyKhaltiPayment(
          success.token,
          success.amount,
          accessToken,
        );

        if (!isVerified) {
          showSnack("\u274C Payment verification failed. Try again.");
          return;
        }

        final successStatus = await ApiService.bookAppointmentWithPayment(
          doctorId: widget.doctor.id,
          date: selectedDate,
          time: selectedTime!,
          reason: reasonController.text,
          paymentToken: success.token,
        );

        if (successStatus) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const PaymentConfirmationScreen(),
            ),
          );
        } else {
          showSnack("\u274C Failed to save appointment");
        }
      },
      onFailure:
          (failure) => showSnack("\u274C Payment failed: ${failure.message}"),
      onCancel: () => showSnack("Payment cancelled"),
    );
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> getAvailableDayCodes() {
    return (widget.doctor.availableDays ?? [])
        .map((d) => d.trim().substring(0, 3))
        .toList();
  }

  bool isDayAvailable(DateTime date) {
    final dayCode = DateFormat('E').format(date);
    return getAvailableDayCodes().contains(dayCode);
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Specialist Details"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _doctorHeader(doc),
            const SizedBox(height: 24),
            _infoSection(doc),
            const SizedBox(height: 24),
            _dateSelector(),
            const SizedBox(height: 24),
            _timeSelector(),
            const SizedBox(height: 24),
            _reasonInput(),
            const SizedBox(height: 24),
            _bookNowButtons(),
          ],
        ),
      ),
    );
  }

  Widget _bookNowButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: showConfirmationDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Pay Now & Book", style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _handlePayLater,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Colors.pinkAccent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Book Now, Pay Later",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _doctorHeader(Doctor doc) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage:
              doc.imageUrl != null && doc.imageUrl!.isNotEmpty
                  ? NetworkImage(doc.imageUrl!)
                  : const AssetImage('assets/icons/doctor_placeholder.png')
                      as ImageProvider,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doc.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                doc.specialization,
                style: const TextStyle(color: Colors.grey),
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 18, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(doc.rating?.toStringAsFixed(1) ?? '4.5'),
                ],
              ),
              const SizedBox(height: 6),
              Text("Fee: Rs. ${doc.consultationFee.toStringAsFixed(0)}"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoSection(Doctor doc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Information",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _infoRow("Specialization", doc.specialization),
        _infoRow("Location", doc.location ?? "Not available"),
        _infoRow(
          "Experience",
          doc.experience != null ? "${doc.experience} years" : "Not available",
        ),
        _infoRow("Phone", doc.phone ?? "Not available"),
        _infoRow("Education", doc.education ?? "Not specified"),
        const SizedBox(height: 24),
        const Text(
          "About the Doctor",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(doc.about ?? "Experienced and compassionate specialist."),
        const SizedBox(height: 24),
        const Text(
          "Working Hours",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _infoRow("Days", doc.availableDays?.join(', ') ?? "Not available"),
        _infoRow("Time", doc.availableTime?.join(', ') ?? "Not available"),
      ],
    );
  }

  Widget _dateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Choose Appointment Date",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 14,
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected =
                  selectedDate.year == date.year &&
                  selectedDate.month == date.month &&
                  selectedDate.day == date.day;
              final isAvailable = isDayAvailable(date);

              return GestureDetector(
                onTap:
                    isAvailable
                        ? () {
                          setState(() {
                            selectedDate = date;
                            selectedTime = null;
                          });
                          fetchBookedTimes();
                        }
                        : null,
                child: Opacity(
                  opacity: isAvailable ? 1.0 : 0.3,
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.pinkAccent : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat.E().format(date),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black54,
                          ),
                        ),
                        Text(
                          "${date.day}",
                          style: TextStyle(
                            fontSize: 18,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _timeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Time",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              timeSlots.map((time) {
                final isBooked = bookedTimes.contains(time);
                final isSelected = time == selectedTime;
                return GestureDetector(
                  onTap:
                      isBooked
                          ? null
                          : () => setState(() => selectedTime = time),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isBooked
                              ? Colors.grey[300]
                              : isSelected
                              ? Colors.pinkAccent
                              : Colors.white,
                      border: Border.all(
                        color:
                            isBooked
                                ? Colors.grey
                                : isSelected
                                ? Colors.pinkAccent
                                : Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color:
                            isBooked
                                ? Colors.grey
                                : isSelected
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _reasonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Reason for Visit",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Enter your reason",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
