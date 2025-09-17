import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/practitioner_model.dart';
import '../../models/therapy_session_model.dart';
import '../../models/patient_feedback_model.dart';
import '../../models/notification_model.dart';
import '../../models/therapy_progress_model.dart';
import '../../utils/dummy_therapy_progress_data.dart';
import '../../widgets/today_schedule_panel.dart';
import '../../widgets/patient_feedback_panel.dart';
import '../../widgets/analytics_dashboard.dart';
import '../../widgets/task_reminder_panel.dart';
import '../../widgets/knowledge_hub_panel.dart';
import '../../widgets/notifications_alerts_panel.dart';
import '../../widgets/patient_therapy_progress_tracker.dart';
import '../../widgets/therapy_progress_detail_dialog.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/key_metrics_panel.dart';
import '../../services/knowledge_hub_service.dart';
import '../auth/login_screen_new.dart';
import 'appointments_screen.dart';
import 'patients_screen.dart';
import 'practitioner_profile_screen.dart';
import 'practitioner_settings_screen.dart';
import 'practitioner_messages_screen.dart';

class PractitionerHomeDashboard extends StatefulWidget {
  final String? practitionerId;
  
  const PractitionerHomeDashboard({this.practitionerId, super.key});

  @override
  State<PractitionerHomeDashboard> createState() => _PractitionerHomeDashboardState();
}

class _PractitionerHomeDashboardState extends State<PractitionerHomeDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Dashboard metrics
  int _totalPatients = 0;
  int _upcomingAppointments = 0;
  int _clearedAppointments = 0;
  double _satisfactionScore = 0.0;
  int _completedTherapiesToday = 0;
  int _patientsSeen = 0;
  int _patientsSeenToday = 0;
  
  // Current practitioner data
  PractitionerModel? _practitionerData;
  bool _isLoading = true;
  int _selectedIndex = 0;
  
  // Therapy progress data
  List<TherapyProgressModel> _therapyProgressList = [];
  
  // We're not using this field yet, but will be useful for advanced responsive layouts
  
  // Page controller for smooth transitions
  late PageController _pageController;
  
  // Navigation items
  final List<NavigationDestination> _navigationDestinations = [
    const NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const NavigationDestination(
      icon: Icon(Icons.people_outlined),
      selectedIcon: Icon(Icons.people),
      label: 'Patients',
    ),
    const NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: 'Schedule',
    ),
    const NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: 'Reports',
    ),
    const NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    // Slight delay to allow widgets to initialize
    Future.delayed(Duration.zero, () {
      _loadDashboardData();
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      debugPrint('Loading dashboard data...');
      
      // Get user ID either from Firebase Auth or from widget parameters
      String? userId;
      
      // First try to get from Firebase Auth (for Firebase Auth login)
      final User? user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
        debugPrint('Using Firebase Auth user ID: $userId');
      } else if (widget.practitionerId != null) {
        // If Firebase Auth user is null, use the practitionerId passed from navigation
        userId = widget.practitionerId;
        debugPrint('Using practitioner ID from navigation: $userId');
      } else {
        // No user ID available, show error and return
        debugPrint('No user ID available. Cannot load practitioner data.');
        setState(() {
          _isLoading = false;
          // We'll handle this in the build method
        });
        return;
      }
      
      // Load therapy progress data (using dummy data for now)
      // In a real app, you would fetch this from Firestore
      _therapyProgressList = DummyTherapyProgressData.getTherapyProgressData();

      // Get practitioner data
      debugPrint('Fetching practitioner document for ID: $userId');
      final practitionerDoc = await _firestore.collection('practitioners').doc(userId).get();
      
      if (practitionerDoc.exists) {
        debugPrint('Practitioner document found');
        Map<String, dynamic> data = practitionerDoc.data() as Map<String, dynamic>;
        
        setState(() {
          // Include uid in the data map before passing to fromJson
          data['uid'] = userId;
          _practitionerData = PractitionerModel.fromJson(data);
          debugPrint('Practitioner model created: ${_practitionerData?.fullName}');
        });
      } else {
        debugPrint('Practitioner document does not exist for ID: $userId');
      }

      // Get patients count
      final patientSnapshot = await _firestore.collection('patients').where('practitionerId', isEqualTo: userId).get();
      setState(() {
        _totalPatients = patientSnapshot.size;
      });

      // Get current date for appointments filtering
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Query for all appointments for this practitioner without complex queries requiring indexes
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('practitionerId', isEqualTo: userId)
          .get();
          
      // Filter appointments in memory
      int upcomingAppointmentsCount = 0;
      int clearedAppointmentsCount = 0;
      
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        
        // Check if appointment has a date field (which can be either Timestamp or String)
        var appointmentDate;
        if (data.containsKey('appointmentDate') && data['appointmentDate'] != null) {
          appointmentDate = data['appointmentDate'] is Timestamp 
              ? (data['appointmentDate'] as Timestamp).toDate()
              : DateTime.parse(data['appointmentDate'].toString());
        } else if (data.containsKey('dateTime') && data['dateTime'] != null) {
          appointmentDate = data['dateTime'] is Timestamp
              ? (data['dateTime'] as Timestamp).toDate()
              : DateTime.parse(data['dateTime'].toString());
        } else if (data.containsKey('date') && data['date'] != null) {
          try {
            appointmentDate = data['date'] is Timestamp
                ? (data['date'] as Timestamp).toDate()
                : DateTime.parse(data['date'].toString());
          } catch (e) {
            // If parse fails, use today as fallback
            appointmentDate = now;
          }
        }
        
        if (status == 'scheduled' && appointmentDate != null && 
            (appointmentDate.isAfter(now) || appointmentDate.day == now.day)) {
          upcomingAppointmentsCount++;
        } else if (status == 'completed') {
          clearedAppointmentsCount++;
        }
      }
      
      // Get average satisfaction score
      final feedbackSnapshot = await _firestore
          .collection('patient_feedback')
          .where('practitionerId', isEqualTo: userId)
          .get();
      
      double totalScore = 0;
      int validFeedbacks = 0;
      
      for (var doc in feedbackSnapshot.docs) {
        final data = doc.data();
        if (data['rating'] != null) {
          totalScore += (data['rating'] as num).toDouble();
          validFeedbacks++;
        }
      }
      
      // Calculate metrics based on appointments
      int completedTherapies = 0;
      int patientsSeenToday = 0;
      Set<String> uniquePatientIds = {};
      Set<String> uniquePatientsSeenToday = {};
      
      // Process appointments to count metrics
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        String patientId = data['patientId'] ?? '';
        
        // Skip if no patient ID
        if (patientId.isEmpty) continue;
        
        // Add to total unique patients
        uniquePatientIds.add(patientId);
        
        // If it's a completed appointment, add to completed therapies
        if (data['status'] == 'completed') {
          completedTherapies++;
        }
        
        // Check if appointment is today
        DateTime? appointmentDate;
        try {
          if (data['appointmentDate'] is Timestamp) {
            appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
          } else if (data['dateTime'] is Timestamp) {
            appointmentDate = (data['dateTime'] as Timestamp).toDate();
          } else if (data['date'] is Timestamp) {
            appointmentDate = (data['date'] as Timestamp).toDate();
          } else if (data['dateStr'] != null) {
            appointmentDate = DateFormat('yyyy-MM-dd').parse(data['dateStr']);
          }
          
          // If appointment is today, add to patients seen today
          if (appointmentDate != null && 
              appointmentDate.year == today.year && 
              appointmentDate.month == today.month && 
              appointmentDate.day == today.day &&
              (data['status'] == 'completed' || data['status'] == 'scheduled')) {
            uniquePatientsSeenToday.add(patientId);
          }
        } catch (e) {
          debugPrint('Error parsing appointment date: $e');
        }
      }
      
      // Set the patients seen today count
      patientsSeenToday = uniquePatientsSeenToday.length;
      
      setState(() {
        _upcomingAppointments = upcomingAppointmentsCount;
        _clearedAppointments = clearedAppointmentsCount;
        _satisfactionScore = validFeedbacks > 0 ? totalScore / validFeedbacks : 0.0;
        _completedTherapiesToday = completedTherapies;
        _patientsSeen = uniquePatientIds.length;
        // Make sure we update this metric too
        _patientsSeenToday = patientsSeenToday;
        _isLoading = false;
      });
      
    } catch (e, stackTrace) {
      debugPrint('Error loading dashboard data: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sign out method
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sign out. Please try again.')),
        );
      }
    }
  }
  
  // Show logout confirmation dialog
  Future<void> _showLogoutConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm logout
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
    
    if (result == true) {
      await _signOut();
    }
  }
  
  // Handle session status change
  void _handleSessionStatusChange(TherapySessionModel session, SessionStatus newStatus) {
    // Here you would update the session status in Firestore
    // For now, just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session ${session.id} updated to ${_getStatusText(newStatus)}'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
    
    // Refresh data
    _loadDashboardData();
  }
  
  // Handle session tapped
  void _handleSessionTap(TherapySessionModel session) {
    // Navigate to session details or patient details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing session details for ${session.patientName}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  // Get status text helper
  String _getStatusText(SessionStatus status) {
    switch (status) {
      case SessionStatus.pending:
        return 'Pending';
      case SessionStatus.inProgress:
        return 'In Progress';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.cancelled:
        return 'Cancelled';
    }
  }
  
  // Handle loading state changes from widgets
  void _handleLoadingState(bool isLoading) {
    // Optional: implement global loading state if needed
  }
  
  // Handle feedback response
  void _handleFeedbackResponse(PatientFeedbackModel feedback) {
    // Navigate to feedback response screen or show dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Responding to feedback from ${feedback.patientName}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  // Handle adding a task
  void _handleAddTask() {
    // Show dialog to add new task
    TextEditingController taskController = TextEditingController();
    TextEditingController descController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'Enter task title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter task description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Due Date'),
                  subtitle: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                // Add task to Firestore
                // For now, just close dialog
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task added successfully')),
                );
              },
            ),
          ],
        );
      },
    );
  }
  
  // Handle knowledge item selected
  dynamic _handleKnowledgeItemSelected(KnowledgeItem item) {
    // Show knowledge item details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing knowledge item: ${item.title}')),
    );
  }
  
  // Handle notification tap
  void _handleNotificationTap(NotificationModel notification) {
    // Here you would handle different actions based on the notification type
    String message;
    
    switch (notification.type) {
      case NotificationType.sessionReminder:
        message = 'Viewing session details for ${notification.patientName ?? "patient"}';
        break;
      case NotificationType.patientAlert:
        message = 'Checking alert for ${notification.patientName ?? "patient"}';
        break;
      case NotificationType.procedurePrecaution:
        message = 'Viewing procedure notes for ${notification.patientName ?? "patient"}';
        break;
      case NotificationType.general:
        message = 'Viewing notification details';
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  // Handle therapy progress item tap
  void _handleTherapyProgressTap(TherapyProgressModel therapy) {
    showDialog(
      context: context,
      builder: (context) => TherapyProgressDetailDialog(therapy: therapy),
    );
  }
  
  // Handle view therapies details
  void _handleViewTherapiesDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing completed therapies details'),
        duration: Duration(seconds: 1),
      ),
    );
    // In a real app, navigate to a detailed view or show a dialog
  }
  
  // Handle view patients details
  void _handleViewPatientsDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing patients seen today'),
        duration: Duration(seconds: 1),
      ),
    );
    // In a real app, navigate to a detailed view or show a dialog
  }
  
  // Handle profile tap
  void _handleProfileTap() {
    if (_practitionerData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PractitionerProfileScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot access profile. Practitioner data not loaded.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on a tablet/desktop or mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 900;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aayur Sutra - Practitioner Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // Show notifications
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: _handleProfileTap,
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutConfirmation,
            tooltip: 'Logout',
          ),
        ],
      ),
      // Use drawer for mobile and NavigationRail for tablets/desktops
      drawer: isLargeScreen ? null : _buildDrawer(),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading dashboard...'),
                ],
              ),
            )
          : Row(
              children: [
                // Show NavigationRail only on larger screens
                if (isLargeScreen) _buildNavigationRail(),
                
                // Main content area
                Expanded(
                  child: _buildDashboardContent(),
                ),
              ],
            ),
      // Show bottom navigation bar only on smaller screens
      bottomNavigationBar: isLargeScreen ? null : _buildBottomNavigationBar(),
    );
  }
  
  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      groupAlignment: -1.0,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
        // Handle navigation based on selected index
        _handleNavigation(index);
      },
      labelType: NavigationRailLabelType.all,
      destinations: _navigationDestinations.map((destination) {
        return NavigationRailDestination(
          icon: destination.icon,
          selectedIcon: destination.selectedIcon,
          label: Text(destination.label),
        );
      }).toList(),
    );
  }
  
  Widget _buildBottomNavigationBar() {
    // Define bottom navigation items based on the design in the attached image
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        // Handle navigation based on selected index
        _handleNavigation(index);
      },
      type: BottomNavigationBarType.fixed, // Use fixed to display all 5 items
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Appointments',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outlined),
          activeIcon: Icon(Icons.people),
          label: 'Patients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_outlined),
          activeIcon: Icon(Icons.chat),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              _practitionerData?.fullName ?? 'Practitioner',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(_practitionerData?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (_practitionerData?.fullName != null && _practitionerData!.fullName.isNotEmpty)
                ? _practitionerData!.fullName.substring(0, 1).toUpperCase() 
                : 'P',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _navigationDestinations.length,
              itemBuilder: (context, index) {
                final destination = _navigationDestinations[index];
                return ListTile(
                  leading: _selectedIndex == index
                    ? destination.selectedIcon
                    : destination.icon,
                  title: Text(destination.label),
                  selected: _selectedIndex == index,
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    Navigator.pop(context); // Close drawer
                    _handleNavigation(index);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _showLogoutConfirmation();
            },
          ),
        ],
      ),
    );
  }
  
  void _handleNavigation(int index) {
    // Get the current screen width to determine if we're using sidebar or bottom navigation
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 900;
    
    if (isLargeScreen) {
      // Navigation rail/sidebar navigation
      switch (index) {
        case 0: // Dashboard - already on dashboard
          break;
        case 1: // Patients
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PatientsScreen()),
          );
          break;
        case 2: // Schedule
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppointmentsScreen()),
          );
          break;
        case 3: // Reports/Messages
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PractitionerMessagesScreen(
              practitionerId: _practitionerData?.uid,
            )),
          );
          break;
        case 4: // Settings
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PractitionerSettingsScreen(
              practitionerId: _practitionerData?.uid,
            )),
          );
          break;
      }
    } else {
      // Bottom navigation
      switch (index) {
        case 0: // Home/Dashboard - reload dashboard
          _loadDashboardData();
          break;
        case 1: // Appointments
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppointmentsScreen()),
          );
          break;
        case 2: // Patients
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PatientsScreen()),
          );
          break;
        case 3: // Messages
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PractitionerMessagesScreen(
              practitionerId: _practitionerData?.uid,
            )),
          );
          break;
        case 4: // Settings
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PractitionerSettingsScreen(
              practitionerId: _practitionerData?.uid,
            )),
          );
          break;
      }
    }
  }
  
  Widget _buildDashboardContent() {
    if (_practitionerData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Error loading practitioner data.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Header
            DashboardHeader(
              practitionerName: _practitionerData!.fullName,
              profileImageUrl: _practitionerData!.profileImageUrl,
              onProfileTap: _handleProfileTap,
            ),
            
            const SizedBox(height: 24),
            
            // Key Metrics Panel
            KeyMetricsPanel(
              completedTherapies: _completedTherapiesToday,
              patientsToday: _patientsSeenToday, // Use patients seen today instead of all patients
              onViewTherapiesDetails: _handleViewTherapiesDetails,
              onViewPatientsDetails: _handleViewPatientsDetails,
            ),
            
            const SizedBox(height: 24),
            
            // Summary cards (keeping this for now)
            _buildSummaryCards(),
            
            const SizedBox(height: 24),
            
            // Notifications & Alerts
            _practitionerData != null ? NotificationsAlertsPanel(
              practitionerId: _practitionerData!.uid,
              onNotificationTap: _handleNotificationTap,
            ) : const SizedBox(),
            
            const SizedBox(height: 24),
            
            // Today's Schedule
            TodaySchedulePanel(
              practitionerId: _practitionerData!.uid,
              onSessionTap: _handleSessionTap,
              onStatusChange: _handleSessionStatusChange,
              onLoadingStateChanged: _handleLoadingState,
            ),
            
            const SizedBox(height: 24),
            
            // Patient Therapy Progress Tracker and Patient Feedback in a row for larger screens
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _practitionerData != null ? PatientTherapyProgressTracker(
                          therapyProgressList: _therapyProgressList,
                          onProgressTap: _handleTherapyProgressTap,
                        ) : const SizedBox(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _practitionerData != null ? PatientFeedbackPanel(
                          practitionerId: _practitionerData!.uid,
                          onRespondToFeedback: _handleFeedbackResponse,
                        ) : const SizedBox(),
                      ),
                    ],
                  );
                } else {
                  // Stack them vertically on smaller screens
                  return Column(
                    children: [
                      _practitionerData != null ? PatientTherapyProgressTracker(
                          therapyProgressList: _therapyProgressList,
                          onProgressTap: _handleTherapyProgressTap,
                        ) : const SizedBox(),
                      
                      const SizedBox(height: 24),
                      
                      _practitionerData != null ? PatientFeedbackPanel(
                        practitionerId: _practitionerData!.uid,
                        onRespondToFeedback: _handleFeedbackResponse,
                      ) : const SizedBox(),
                    ],
                  );
                }
              },
            ),
            
            const SizedBox(height: 24),
            
            // Analytics Dashboard and Task Reminder in a row for larger screens
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _practitionerData != null ? AnalyticsDashboard(
                          practitionerId: _practitionerData!.uid,
                        ) : const SizedBox(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _practitionerData != null ? TaskReminderPanel(
                          practitionerId: _practitionerData!.uid,
                          onAddTask: _handleAddTask,
                        ) : const SizedBox(),
                      ),
                    ],
                  );
                } else {
                  // Stack them vertically on smaller screens
                  return Column(
                    children: [
                      _practitionerData != null ? AnalyticsDashboard(
                        practitionerId: _practitionerData!.uid,
                      ) : const SizedBox(),
                      
                      const SizedBox(height: 24),
                      
                      _practitionerData != null ? TaskReminderPanel(
                        practitionerId: _practitionerData!.uid,
                        onAddTask: _handleAddTask,
                      ) : const SizedBox(),
                    ],
                  );
                }
              },
            ),
            
            const SizedBox(height: 24),
            
            // Knowledge Hub
            KnowledgeHubPanel(
              onItemSelected: _handleKnowledgeItemSelected,
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }



  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 
                    MediaQuery.of(context).size.width > 600 ? 2 : 1,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSummaryCard(
          'Total Patients',
          _totalPatients.toString(),
          Icons.people,
          Colors.blue,
          'View all patients',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PatientsScreen()),
            );
          },
        ),
        _buildSummaryCard(
          'Upcoming Appointments',
          _upcomingAppointments.toString(),
          Icons.calendar_today,
          Colors.orange,
          'View schedule',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AppointmentsScreen()),
            );
          },
        ),
        _buildSummaryCard(
          'Completed Sessions',
          _clearedAppointments.toString(),
          Icons.check_circle,
          Colors.green,
          'View history',
          () {
            // Navigate to history/reports
          },
        ),
        _buildSummaryCard(
          'Satisfaction Score',
          '${(_satisfactionScore * 20).toStringAsFixed(1)}%',
          Icons.star,
          Colors.amber,
          'View feedback',
          () {
            // Navigate to feedback section
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title, 
    String value, 
    IconData icon, 
    Color color, 
    String actionText, 
    VoidCallback onAction,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'action') {
                      onAction();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'action',
                      child: Text(actionText),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  Text(
                    actionText,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom class for navigation destinations
class NavigationDestination {
  final Widget icon;
  final Widget selectedIcon;
  final String label;

  const NavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

// Using KnowledgeItem from the knowledge_hub_service.dart file