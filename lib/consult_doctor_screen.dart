import 'package:flutter/material.dart';
import 'doctor_model.dart';
import '../services/api_service.dart';

class ConsultDoctorScreen extends StatefulWidget {
  const ConsultDoctorScreen({Key? key}) : super(key: key);

  @override
  State<ConsultDoctorScreen> createState() => _ConsultDoctorScreenState();
}

class _ConsultDoctorScreenState extends State<ConsultDoctorScreen> {
  late Future<List<Doctor>> _doctors;

  @override
  void initState() {
    super.initState();
    _doctors = ApiService.fetchDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Consult Doctor")),
      body: FutureBuilder<List<Doctor>>(
        future: _doctors,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading doctors"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No doctors available."));
          }

          final doctors = snapshot.data!;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doc = doctors[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage:
                            doc.imageUrl != null && doc.imageUrl!.isNotEmpty
                                ? NetworkImage(doc.imageUrl!)
                                : const AssetImage(
                                      'assets/icons/doctor_placeholder.png',
                                    )
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
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              doc.specialization,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Fee: Rs. ${doc.consultationFee.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  doc.rating != null
                                      ? "${doc.rating!.toStringAsFixed(1)} / 5.0"
                                      : "No rating",
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (doc.location != null &&
                                doc.location!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      doc.location!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 6),
                            Text(
                              "Available: ${doc.availableDays?.join(', ') ?? 'Mon - Fri'}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "Time: ${doc.availableTime?.join(', ') ?? '10:00 AM - 5:00 PM'}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/book_appointment',
                            arguments: doc,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade100,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Book"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
