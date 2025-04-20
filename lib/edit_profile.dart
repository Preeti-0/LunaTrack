import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  File? _imageFile;
  String? profileImageUrl;
  bool _isLoading = false;
  bool _isFetchingProfile = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    final response = await http.get(
      Uri.parse('$baseUrl/api/profile/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawImage = data['profile_image'];
      String? safeUrl;

      if (rawImage != null && rawImage.isNotEmpty) {
        safeUrl = rawImage.startsWith('http') ? rawImage : '$baseUrl$rawImage';
        safeUrl = '$safeUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      if (!mounted) return;
      setState(() {
        _nameController.text = data['first_name'] ?? "";
        _emailController.text = data['email'] ?? "";
        profileImageUrl = safeUrl;
        _isFetchingProfile = false;
      });
    } else {
      if (!mounted) return;
      setState(() => _isFetchingProfile = false);
      print("❌ Failed to fetch profile. Status: ${response.statusCode}");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _confirmRemovePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text("Remove Photo?"),
            content: Text(
              "Are you sure you want to remove your profile photo?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text("Remove"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() {
        _imageFile = null;
        profileImageUrl = null;
      });
    }
  }

  Future<void> saveChanges() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final uri = Uri.parse('$baseUrl/api/profile/');
    final request =
        http.MultipartRequest('PATCH', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['first_name'] = _nameController.text;

    if (_passwordController.text.isNotEmpty) {
      request.fields['password'] = _passwordController.text;
    }

    if (_imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profile_image', _imageFile!.path),
      );
    }

    if (_imageFile == null && profileImageUrl == null) {
      request.fields['profile_image'] = ""; // Signal backend to delete
    }

    final response = await request.send();
    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("✅ Profile updated")));
      Navigator.pop(context);
    } else {
      print("❌ Error updating profile. Status: ${response.statusCode}");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Failed to update profile")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile"), backgroundColor: Colors.pink),
      body:
          _isFetchingProfile
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.pink.shade200,
                          backgroundImage:
                              _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (profileImageUrl != null
                                      ? NetworkImage(profileImageUrl!)
                                      : null),
                          child:
                              _imageFile == null && profileImageUrl == null
                                  ? Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : '',
                                    style: TextStyle(
                                      fontSize: 36,
                                      color: Colors.white,
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                      TextButton(
                        onPressed: _confirmRemovePhoto,
                        child: Text(
                          "Remove Photo",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: "Full Name"),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: InputDecoration(labelText: "Email"),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "New Password (optional)",
                        ),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : saveChanges,
                        child:
                            _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text("Save Changes"),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
