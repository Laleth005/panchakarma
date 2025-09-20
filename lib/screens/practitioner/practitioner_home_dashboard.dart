import 'package:flutter/material.dart';
import 'consultations_screen.dart';
import 'appointments_screen.dart';
import 'slots_page.dart';
import 'practitioner_profile_screen.dart';
import 'practitioner_home_screen.dart';

class PractitionerMainDashboard extends StatefulWidget {
  final String practitionerId;
  
  const PractitionerMainDashboard({
    Key? key,
    required this.practitionerId,
  }) : super(key: key);

  @override
  _PractitionerMainDashboardState createState() => _PractitionerMainDashboardState();
}

class _PractitionerMainDashboardState extends State<PractitionerMainDashboard> {
  int _selectedIndex = 0;
  
  // Ayurvedic Green theme
  static const Color primaryGreen = Color(0xFF2E7D32);

  // Page controllers for each tab
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  void _initializePages() {
    _pages = [
      PractitionerHomeScreen(practitionerId: widget.practitionerId),
      ConsultationsScreen(practitionerId: widget.practitionerId),
      AppointmentsScreen(),
      SlotsPage(practitionerId: widget.practitionerId),
      PractitionerProfileScreen(practitionerId: widget.practitionerId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: primaryGreen,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.spa_outlined),
              activeIcon: Icon(Icons.spa),
              label: "Consultations",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: "Appointments",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule_outlined),
              activeIcon: Icon(Icons.schedule),
              label: "Slots",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
