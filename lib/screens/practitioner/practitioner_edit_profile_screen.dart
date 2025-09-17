import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/practitioner_model.dart';

class PractitionerEditProfileScreen extends StatefulWidget {
  final PractitionerModel practitioner;

  const PractitionerEditProfileScreen({Key? key, required this.practitioner}) : super(key: key);

  @override
  _PractitionerEditProfileScreenState createState() => _PractitionerEditProfileScreenState();
}

class _PractitionerEditProfileScreenState extends State<PractitionerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  // Form field controllers
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _qualificationController;
  late TextEditingController _experienceController;
  late TextEditingController _bioController;
  late List<String> _specialties;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController(text: widget.practitioner.fullName);
    _phoneController = TextEditingController(text: widget.practitioner.phoneNumber ?? '');
    _qualificationController = TextEditingController(text: widget.practitioner.qualification ?? '');
    _experienceController = TextEditingController(text: widget.practitioner.experience ?? '');
    _bioController = TextEditingController(text: widget.practitioner.bio ?? '');
    _specialties = List<String>.from(widget.practitioner.specialties);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() {
        _isLoading = true;
      });

      // Create updated data map
      final Map<String, dynamic> updatedData = {
        'fullName': _fullNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'experience': _experienceController.text.trim(),
        'bio': _bioController.text.trim(),
        'specialties': _specialties,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update firestore document
      await _firestore
          .collection('practitioners')
          .doc(widget.practitioner.uid)
          .update(updatedData);
      
      setState(() {
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );

      // Return true to indicate the profile was updated
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile. Please try again.')),
      );
    }
  }

  void _addSpecialty(String specialty) {
    if (specialty.isNotEmpty && !_specialties.contains(specialty)) {
      setState(() {
        _specialties.add(specialty);
      });
    }
  }

  void _removeSpecialty(String specialty) {
    setState(() {
      _specialties.remove(specialty);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF2E7D32), // Green theme
        elevation: 0,
        actions: [
          _isLoading
              ? Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : TextButton(
                  onPressed: _saveProfile,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
              ),
            )
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileImageSection(),
            SizedBox(height: 24),
            _buildTextFormField(
              controller: _fullNameController,
              label: 'Full Name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            _buildTextFormField(
              controller: _phoneController,
              label: 'Phone Number',
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            _buildTextFormField(
              controller: _qualificationController,
              label: 'Qualification',
            ),
            SizedBox(height: 16),
            _buildTextFormField(
              controller: _experienceController,
              label: 'Experience',
            ),
            SizedBox(height: 16),
            _buildTextFormField(
              controller: _bioController,
              label: 'Bio',
              maxLines: 4,
            ),
            SizedBox(height: 24),
            _buildSpecialtiesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              image: widget.practitioner.profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.practitioner.profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.practitioner.profileImageUrl == null
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey[800],
                  )
                : null,
          ),
          SizedBox(height: 8),
          TextButton.icon(
            icon: Icon(Icons.camera_alt),
            label: Text('Change Photo'),
            onPressed: () {
              // TODO: Implement image upload functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Photo upload feature coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildSpecialtiesSection() {
    final TextEditingController _specialtyController = TextEditingController();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specialties',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _specialtyController,
                decoration: InputDecoration(
                  hintText: 'Add a specialty',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                _addSpecialty(_specialtyController.text.trim());
                _specialtyController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text('Add'),
            ),
          ],
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _specialties.map((specialty) => Chip(
            label: Text(specialty),
            deleteIcon: Icon(Icons.close, size: 18),
            onDeleted: () => _removeSpecialty(specialty),
            backgroundColor: Colors.grey[200],
          )).toList(),
        ),
      ],
    );
  }
}