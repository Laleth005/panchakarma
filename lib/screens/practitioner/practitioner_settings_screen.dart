import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/practitioner_model.dart';

class PractitionerSettingsScreen extends StatefulWidget {
  final String? practitionerId;

  const PractitionerSettingsScreen({Key? key, this.practitionerId})
    : super(key: key);

  @override
  _PractitionerSettingsScreenState createState() =>
      _PractitionerSettingsScreenState();
}

class _PractitionerSettingsScreenState
    extends State<PractitionerSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  PractitionerModel? _practitionerData;

  // Settings flags
  bool _enableNotifications = true;
  bool _enableEmailAlerts = true;
  bool _enableDarkMode = false;
  bool _enableAutoLogout = false;

  // Display preferences
  String _preferredDateFormat = 'DD/MM/YYYY';
  String _preferredTimeFormat = '12-hour';
  String _preferredLanguage = 'English';

  // Session settings
  int _defaultSessionDuration = 60; // minutes

  @override
  void initState() {
    super.initState();
    // Delay to avoid context issues
    Future.microtask(() => _loadPractitionerSettings());
  }

  Future<void> _loadPractitionerSettings() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      String? practitionerId = widget.practitionerId;

      if (practitionerId == null) {
        // Try to get from Firebase Auth if not provided
        final User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          practitionerId = currentUser.uid;
        }
      }

      if (practitionerId == null) {
        throw Exception('Could not determine practitioner ID');
      }

      // Load practitioner data
      final DocumentSnapshot practitionerDoc = await _firestore
          .collection('practitioners')
          .doc(practitionerId)
          .get();

      if (!practitionerDoc.exists) {
        throw Exception('Practitioner not found');
      }

      // Convert Firestore doc to Map and add the id field
      final data = practitionerDoc.data() as Map<String, dynamic>;
      data['uid'] = practitionerDoc.id; // Ensure uid is set
      _practitionerData = PractitionerModel.fromJson(data);

      // Load settings from Firestore if available
      final DocumentSnapshot? settingsDoc = await _firestore
          .collection('practitioners')
          .doc(practitionerId)
          .collection('settings')
          .doc('preferences')
          .get();

      if (settingsDoc != null && settingsDoc.exists) {
        final settingsData = settingsDoc.data() as Map<String, dynamic>;

        setState(() {
          _enableNotifications = settingsData['enableNotifications'] ?? true;
          _enableEmailAlerts = settingsData['enableEmailAlerts'] ?? true;
          _enableDarkMode = settingsData['enableDarkMode'] ?? false;
          _enableAutoLogout = settingsData['enableAutoLogout'] ?? false;
          _preferredDateFormat =
              settingsData['preferredDateFormat'] ?? 'DD/MM/YYYY';
          _preferredTimeFormat =
              settingsData['preferredTimeFormat'] ?? '12-hour';
          _preferredLanguage = settingsData['preferredLanguage'] ?? 'English';
          _defaultSessionDuration =
              settingsData['defaultSessionDuration'] ?? 60;
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
        print('Error loading settings: $e');
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? practitionerId = widget.practitionerId;

      if (practitionerId == null) {
        // Try to get from Firebase Auth if not provided
        final User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          practitionerId = currentUser.uid;
        }
      }

      if (practitionerId == null) {
        throw Exception('Could not determine practitioner ID');
      }

      // Save settings to Firestore
      await _firestore
          .collection('practitioners')
          .doc(practitionerId)
          .collection('settings')
          .doc('preferences')
          .set({
            'enableNotifications': _enableNotifications,
            'enableEmailAlerts': _enableEmailAlerts,
            'enableDarkMode': _enableDarkMode,
            'enableAutoLogout': _enableAutoLogout,
            'preferredDateFormat': _preferredDateFormat,
            'preferredTimeFormat': _preferredTimeFormat,
            'preferredLanguage': _preferredLanguage,
            'defaultSessionDuration': _defaultSessionDuration,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Settings',
            onPressed: _isLoading ? null : _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading settings: $_errorMessage',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadPractitionerSettings,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _buildSettingsForm(),
    );
  }

  Widget _buildSettingsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Notifications'),
          _buildSettingSwitch(
            'Enable Notifications',
            'Receive in-app notifications about appointments and patient updates',
            _enableNotifications,
            (value) {
              setState(() {
                _enableNotifications = value;
              });
            },
          ),
          _buildSettingSwitch(
            'Email Alerts',
            'Receive email alerts for important updates',
            _enableEmailAlerts,
            (value) {
              setState(() {
                _enableEmailAlerts = value;
              });
            },
          ),
          const Divider(),

          _buildSectionHeader('Display Preferences'),
          _buildSettingSwitch(
            'Dark Mode',
            'Use dark theme for the application',
            _enableDarkMode,
            (value) {
              setState(() {
                _enableDarkMode = value;
              });
            },
          ),
          _buildDropdownSetting(
            'Date Format',
            'Select your preferred date format',
            _preferredDateFormat,
            ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
            (value) {
              setState(() {
                _preferredDateFormat = value!;
              });
            },
          ),
          _buildDropdownSetting(
            'Time Format',
            'Select your preferred time format',
            _preferredTimeFormat,
            ['12-hour', '24-hour'],
            (value) {
              setState(() {
                _preferredTimeFormat = value!;
              });
            },
          ),
          _buildDropdownSetting(
            'Language',
            'Select your preferred language',
            _preferredLanguage,
            ['English', 'Hindi', 'Tamil', 'Telugu', 'Malayalam', 'Kannada'],
            (value) {
              setState(() {
                _preferredLanguage = value!;
              });
            },
          ),
          const Divider(),

          _buildSectionHeader('Session Settings'),
          _buildSliderSetting(
            'Default Session Duration',
            'Set the default duration for therapy sessions',
            _defaultSessionDuration.toDouble(),
            30,
            120,
            15,
            (value) {
              setState(() {
                _defaultSessionDuration = value.round();
              });
            },
            '${_defaultSessionDuration.toString()} minutes',
          ),
          const Divider(),

          _buildSectionHeader('Security'),
          _buildSettingSwitch(
            'Auto Logout',
            'Automatically log out after 30 minutes of inactivity',
            _enableAutoLogout,
            (value) {
              setState(() {
                _enableAutoLogout = value;
              });
            },
          ),
          const Divider(),

          _buildSectionHeader('Account'),
          ListTile(
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            leading: const Icon(Icons.lock_outline),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to change password screen or show dialog
              _showChangePasswordDialog();
            },
          ),
          const Divider(),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Save Settings'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingSwitch(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String description,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    String description,
    double value,
    double min,
    double max,
    double divisions,
    Function(double) onChanged,
    String valueLabel,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(title),
            subtitle: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions.toInt(),
                    label: valueLabel,
                    onChanged: onChanged,
                  ),
                ),
                Container(
                  width: 60,
                  alignment: Alignment.center,
                  child: Text(
                    valueLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              try {
                User? user = _auth.currentUser;

                if (user != null) {
                  // Re-authenticate user
                  AuthCredential credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPasswordController.text,
                  );

                  await user.reauthenticateWithCredential(credential);

                  // Change password
                  await user.updatePassword(newPasswordController.text);

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  throw Exception('User not found');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
