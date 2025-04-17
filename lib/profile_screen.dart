import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'edit_profile.dart';
import 'login.dart';
import '../constants/api_constants.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "";
  String email = "";
  String? profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      print("⚠️ No access token found");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawImage = data['profile_image'];

        String? safeUrl;
        if (rawImage != null && rawImage.isNotEmpty) {
          final fullImageUrl =
              rawImage.startsWith('http') ? rawImage : '$baseUrl$rawImage';
          safeUrl = '$fullImageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        }

        if (!mounted) return;
        setState(() {
          name = data['first_name'] ?? '';
          email = data['email'] ?? '';
          profileImageUrl = safeUrl;
        });
      } else {
        print(
          "⚠️ Failed to fetch profile: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print("❌ Exception: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF0F5),
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.pinkAccent,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    SizedBox(height: 20),

                    /// Profile Image or Initial
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.pink.shade200,
                      backgroundImage:
                          profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : null,
                      child:
                          profileImageUrl == null
                              ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '',
                                style: TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                ),
                              )
                              : null,
                    ),
                    SizedBox(height: 16),

                    /// Name & Email
                    Text(
                      name.isNotEmpty ? name : 'No Name',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(email, style: TextStyle(color: Colors.grey[700])),
                    SizedBox(height: 30),

                    /// Edit Profile
                    ListTile(
                      leading: Icon(Icons.edit, color: Colors.pink),
                      title: Text("Edit Profile"),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(),
                          ),
                        );
                        fetchUserProfile(); // Refresh profile after editing
                      },
                    ),
                    Divider(),

                    /// Logout
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.redAccent),
                      title: Text("Logout"),
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),
    );
  }
}
