import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class EditDoctorProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentProfile;
  const EditDoctorProfileScreen({Key? key, required this.currentProfile})
    : super(key: key);

  @override
  State<EditDoctorProfileScreen> createState() =>
      _EditDoctorProfileScreenState();
}

class _EditDoctorProfileScreenState extends State<EditDoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController specializationController;
  late TextEditingController locationController;
  late TextEditingController experienceController;
  late TextEditingController phoneController;
  late TextEditingController educationController;
  late TextEditingController aboutController;
  late TextEditingController workingDaysController;
  late TextEditingController workingTimeController;
  late TextEditingController feeController;

  File? _pickedImage;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.currentProfile['name'] ?? '',
    );
    specializationController = TextEditingController(
      text: widget.currentProfile['specialization'] ?? '',
    );
    locationController = TextEditingController(
      text: widget.currentProfile['location'] ?? '',
    );
    experienceController = TextEditingController(
      text: widget.currentProfile['experience']?.toString() ?? '',
    );
    phoneController = TextEditingController(
      text: widget.currentProfile['phone'] ?? '',
    );
    educationController = TextEditingController(
      text: widget.currentProfile['education'] ?? '',
    );
    aboutController = TextEditingController(
      text: widget.currentProfile['about'] ?? '',
    );

    final dynamic availableDays = widget.currentProfile['available_days'];
    workingDaysController = TextEditingController(
      text:
          availableDays is List
              ? availableDays.map((e) => e.toString()).join(', ')
              : (availableDays ?? ''),
    );

    final dynamic availableTime = widget.currentProfile['available_time'];
    workingTimeController = TextEditingController(
      text:
          availableTime is List
              ? availableTime.map((e) => e.toString()).join(', ')
              : (availableTime ?? ''),
    );

    feeController = TextEditingController(
      text:
          widget.currentProfile['consultation_fee'] != null
              ? double.tryParse(
                    widget.currentProfile['consultation_fee'].toString(),
                  )?.toStringAsFixed(2) ??
                  ''
              : '',
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _pickedImage = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);

    final updatedData = {
      'name': nameController.text,
      'specialization': specializationController.text,
      'location': locationController.text,
      'experience_years': int.tryParse(experienceController.text),
      'phone': phoneController.text,
      'education': educationController.text,
      'about': aboutController.text,
      'available_days':
          workingDaysController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
      'available_time':
          workingTimeController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
      'consultation_fee': double.tryParse(feeController.text) ?? 0.0,
    };

    final success = await ApiService.updateDoctorProfile(updatedData);

    setState(() => isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context, updatedData);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (widget.currentProfile['image'] != null &&
                              widget.currentProfile['image'] is String)
                          ? NetworkImage(widget.currentProfile['image'])
                              as ImageProvider
                          : null,
                  child:
                      _pickedImage == null &&
                              widget.currentProfile['image'] == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                ),
              ),
              const SizedBox(height: 20),
              _buildField("Full Name", nameController),
              _buildField("Specialization", specializationController),
              _buildField("Location", locationController),
              _buildField("Experience (in years)", experienceController),
              _buildField("Phone", phoneController),
              _buildField("Education", educationController),
              _buildField("About", aboutController, maxLines: 4),
              _buildField(
                "Working Days (comma-separated)",
                workingDaysController,
              ),
              _buildField(
                "Working Time (comma-separated)",
                workingTimeController,
              ),
              _buildField("Consultation Fee", feeController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child:
                    isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType:
            label.toLowerCase().contains('fee') ||
                    label.toLowerCase().contains('experience')
                ? TextInputType.number
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator:
            (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }
}
