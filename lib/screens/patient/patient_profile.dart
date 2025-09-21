import 'package:flutter/material.dart';
import '../../models/patient_model.dart';

class PatientProfileScreen extends StatefulWidget {
  final PatientModel? patientData;

  const PatientProfileScreen({Key? key, this.patientData}) : super(key: key);

  @override
  _PatientProfileScreenState createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  bool _isEditing = false;

  // Controllers for text fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicalHistoryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.patientData?.fullName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.patientData?.phoneNumber ?? '',
    );
    _addressController = TextEditingController(
      text: widget.patientData?.address ?? '',
    );
    _allergiesController = TextEditingController(
      text: widget.patientData?.allergies ?? '',
    );
    _medicalHistoryController = TextEditingController(
      text: widget.patientData?.medicalHistory ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _allergiesController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green.shade100,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.green.shade700,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  widget.patientData?.fullName ?? 'Patient Name',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  widget.patientData?.email ?? 'email@example.com',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditing = !_isEditing;
                        });
                      },
                      icon: Icon(
                        _isEditing ? Icons.close : Icons.edit,
                        color: Colors.green.shade700,
                      ),
                      label: Text(
                        _isEditing ? 'Cancel' : 'Edit Profile',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green.shade700),
                      ),
                    ),
                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: _saveProfile,
                          icon: Icon(Icons.save),
                          label: Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 40),

          // Profile Information
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          SizedBox(height: 16),

          _buildProfileItem(
            title: 'Full Name',
            value: widget.patientData?.fullName ?? 'Not provided',
            icon: Icons.person,
            isEditing: _isEditing,
            controller: _nameController,
          ),

          _buildProfileItem(
            title: 'Phone Number',
            value: widget.patientData?.phoneNumber ?? 'Not provided',
            icon: Icons.phone,
            isEditing: _isEditing,
            controller: _phoneController,
          ),

          _buildProfileItem(
            title: 'Date of Birth',
            value: widget.patientData?.dateOfBirth ?? 'Not provided',
            icon: Icons.calendar_today,
            isEditing: false, // DOB cannot be edited here
          ),

          _buildProfileItem(
            title: 'Gender',
            value: widget.patientData?.gender ?? 'Not provided',
            icon: Icons.person_outline,
            isEditing: false, // Gender cannot be edited here
          ),

          _buildProfileItem(
            title: 'Address',
            value: widget.patientData?.address ?? 'Not provided',
            icon: Icons.home,
            isEditing: _isEditing,
            controller: _addressController,
            maxLines: 3,
          ),

          Divider(height: 40),

          // Medical Information
          Text(
            'Medical Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          SizedBox(height: 16),

          _buildProfileItem(
            title: 'Dosha Type',
            value: widget.patientData?.doshaType ?? 'Not determined yet',
            icon: Icons.spa,
            isEditing: false, // Dosha type is determined by practitioner
          ),

          _buildProfileItem(
            title: 'Allergies',
            value: widget.patientData?.allergies ?? 'None',
            icon: Icons.health_and_safety,
            isEditing: _isEditing,
            controller: _allergiesController,
            maxLines: 3,
          ),

          _buildProfileItem(
            title: 'Medical History',
            value: widget.patientData?.medicalHistory ?? 'None',
            icon: Icons.medical_services,
            isEditing: _isEditing,
            controller: _medicalHistoryController,
            maxLines: 5,
          ),

          SizedBox(height: 24),

          // Account Actions
          if (!_isEditing)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 40),
                Text(
                  'Account Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.lock, color: Colors.green.shade700),
                  title: Text('Change Password'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to change password screen
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: Colors.green.shade700,
                  ),
                  title: Text('Notification Settings'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to notification settings
                  },
                ),
                ListTile(
                  leading: Icon(Icons.help, color: Colors.green.shade700),
                  title: Text('Help & Support'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to help & support
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.privacy_tip,
                    color: Colors.green.shade700,
                  ),
                  title: Text('Privacy Policy'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to privacy policy
                  },
                ),
                SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      // Implement logout functionality
                    },
                    icon: Icon(Icons.logout, color: Colors.red.shade400),
                    label: Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required String title,
    required String value,
    required IconData icon,
    required bool isEditing,
    TextEditingController? controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          SizedBox(height: 8),
          isEditing && controller != null
              ? TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon, color: Colors.green.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade700),
                    ),
                  ),
                  maxLines: maxLines,
                )
              : Row(
                  children: [
                    Icon(icon, color: Colors.green.shade700, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(value, style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  void _saveProfile() {
    // Implement save functionality with the auth service
    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }
}
