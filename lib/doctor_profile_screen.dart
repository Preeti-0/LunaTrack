import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'doctor_model.dart';
import 'edit_doctor_profile_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({Key? key}) : super(key: key);

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  Doctor? doctor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDoctorProfile();
  }

  Future<void> loadDoctorProfile() async {
    try {
      final fetchedDoctor = await ApiService.fetchLoggedInDoctor();
      setState(() {
        doctor = fetchedDoctor;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading profile: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.pinkAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (doctor == null) return;

              final updatedData = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => EditDoctorProfileScreen(
                        currentProfile: {
                          'name': doctor!.name,
                          'specialization': doctor!.specialization,
                          'location': doctor!.location ?? '',
                          'experience': doctor!.experience ?? '',
                          'phone': doctor!.phone ?? '',
                          'education': doctor!.education ?? '',
                          'about': doctor!.about ?? '',
                          'available_days': doctor!.availableDays ?? [],
                          'available_time': doctor!.availableTime ?? [],
                          'consultation_fee': doctor!.consultationFee
                              .toStringAsFixed(2),
                          'image': doctor!.imageUrl ?? '',
                        },
                      ),
                ),
              );

              if (updatedData != null) {
                await loadDoctorProfile(); // Refresh profile
              }
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : doctor == null
              ? const Center(child: Text("Doctor profile not found."))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            doctor!.imageUrl != null
                                ? NetworkImage(doctor!.imageUrl!)
                                : null,
                        child:
                            doctor!.imageUrl == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfo("Name", doctor!.name),
                    _buildInfo("Specialization", doctor!.specialization),
                    _buildInfo("Phone", doctor!.phone ?? 'Not available'),
                    _buildInfo("Location", doctor!.location ?? 'Not available'),
                    _buildInfo(
                      "Experience",
                      doctor!.experience != null
                          ? "${doctor!.experience} yrs"
                          : 'Not available',
                    ),
                    _buildInfo(
                      "Education",
                      doctor!.education ?? 'Not available',
                    ),
                    _buildInfo(
                      "Consultation Fee",
                      "Rs. ${doctor!.consultationFee.toStringAsFixed(2)}",
                    ),
                    _buildInfo("About", doctor!.about ?? 'Not available'),
                    _buildInfo(
                      "Working Days",
                      doctor!.availableDays != null
                          ? doctor!.availableDays!.join(', ')
                          : 'Not available',
                    ),
                    _buildInfo(
                      "Working Time",
                      doctor!.availableTime != null
                          ? doctor!.availableTime!.join(', ')
                          : 'Not available',
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final updatedData = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => EditDoctorProfileScreen(
                                    currentProfile: {
                                      'name': doctor?.name ?? '',
                                      'specialization':
                                          doctor?.specialization ?? '',
                                      'location': doctor?.location ?? '',
                                      'experience': doctor?.experience ?? '',
                                      'phone': doctor?.phone ?? '',
                                      'education': doctor?.education ?? '',
                                      'about': doctor?.about ?? '',
                                      'available_days':
                                          doctor?.availableDays ?? [],
                                      'available_time':
                                          doctor?.availableTime ?? [],
                                      'consultation_fee': doctor!
                                          .consultationFee
                                          .toStringAsFixed(2),
                                      'image': doctor?.imageUrl ?? '',
                                    },
                                  ),
                            ),
                          );

                          if (updatedData != null) {
                            await loadDoctorProfile();
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit Profile"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
