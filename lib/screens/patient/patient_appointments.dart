import 'package:flutter/material.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  @override
  _PatientAppointmentsScreenState createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.green.shade800,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.green.shade800,
          tabs: [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentList('upcoming'),
              _buildAppointmentList('completed'),
              _buildAppointmentList('cancelled'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAppointmentList(String type) {
    // In a real app, you would fetch appointments based on the type
    bool hasAppointments = false;
    
    if (!hasAppointments) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForType(type),
              size: 80,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              _getMessageForType(type),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your ${type} appointments will appear here',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (type == 'upcoming')
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text('Book an Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 0, // Replace with actual appointment count
      itemBuilder: (context, index) {
        return Container(); // Replace with actual appointment card
      },
    );
  }
  
  IconData _getIconForType(String type) {
    switch (type) {
      case 'upcoming':
        return Icons.event;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.calendar_today;
    }
  }
  
  String _getMessageForType(String type) {
    switch (type) {
      case 'upcoming':
        return 'No upcoming appointments';
      case 'completed':
        return 'No completed appointments';
      case 'cancelled':
        return 'No cancelled appointments';
      default:
        return 'No appointments found';
    }
  }
}