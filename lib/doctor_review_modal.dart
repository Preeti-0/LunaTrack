// 📄 File: review_modal.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewModal extends StatefulWidget {
  final int appointmentId;
  final int doctorId;

  const ReviewModal({
    super.key,
    required this.appointmentId,
    required this.doctorId,
  });

  @override
  State<ReviewModal> createState() => _ReviewModalState();
}

class _ReviewModalState extends State<ReviewModal> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _submitting = false;

  Future<void> _submitReview() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    setState(() => _submitting = true);

    final response = await http.post(
      Uri.parse('http://192.168.1.70:8000/api/submit-review/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'appointment': widget.appointmentId,
        'doctor': widget.doctorId,
        'rating': _rating,
        'comment': _commentController.text,
      }),
    );

    setState(() => _submitting = false);

    if (response.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to submit review')));
    }
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () => setState(() => _rating = index + 1),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate Your Doctor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStars(),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'Leave a comment (optional)',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _rating > 0 && !_submitting ? _submitReview : null,
          child:
              _submitting
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Submit'),
        ),
      ],
    );
  }
}
