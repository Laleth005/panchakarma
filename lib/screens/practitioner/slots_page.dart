import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SlotsPage extends StatefulWidget {
  final String practitionerId;
  
  const SlotsPage({Key? key, required this.practitionerId}) : super(key: key);

  @override
  _SlotsPageState createState() => _SlotsPageState();
}

class _SlotsPageState extends State<SlotsPage> with SingleTickerProviderStateMixin {
  final Map<String, List<TimeSlot>> _weeklySlots = {};
  final Map<String, Set<String>> _selectedSlots = {};
  TabController? _tabController;
  bool _isLoading = true;
  DateTime _currentWeekStart = DateTime.now();
  
  final List<String> _daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  // Time slots from 9 AM to 5 PM (excluding lunch break 12-1 PM)
  final List<TimeSlot> _timeSlots = [
    TimeSlot('09:00', '10:00'),
    TimeSlot('10:00', '11:00'),
    TimeSlot('11:00', '12:00'),
    // Lunch break 12:00-13:00
    TimeSlot('13:00', '14:00'),
    TimeSlot('14:00', '15:00'),
    TimeSlot('15:00', '16:00'),
    TimeSlot('16:00', '17:00'),
  ];

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(DateTime.now());
    _initializeWeeklySlots();
    _tabController = TabController(length: _daysOfWeek.length, vsync: this);
    _loadExistingSlots();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    int daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  void _initializeWeeklySlots() {
    for (int i = 0; i < _daysOfWeek.length; i++) {
      String day = _daysOfWeek[i];
      _weeklySlots[day] = List.from(_timeSlots);
      _selectedSlots[day] = <String>{};
    }
  }

  Future<void> _loadExistingSlots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DateTime weekEnd = _currentWeekStart.add(Duration(days: 6));
      
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('slots_practitioner')
          .where('practitionerId', isEqualTo: widget.practitionerId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_currentWeekStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd.add(Duration(days: 1))))
          .get();

      // Clear existing selections
      for (String day in _daysOfWeek) {
        _selectedSlots[day]!.clear();
      }

      // Load existing slots
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime slotDate = (data['date'] as Timestamp).toDate();
        String dayName = _daysOfWeek[slotDate.weekday - 1];
        
        List<String> availableSlots = List<String>.from(data['availableTimeSlots'] ?? []);
        _selectedSlots[dayName]!.addAll(availableSlots);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading existing slots: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Set Available Slots',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _navigateToPreviousWeek,
            icon: Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: _navigateToNextWeek,
            icon: Icon(Icons.chevron_right),
          ),
        ],
        bottom: _tabController != null ? TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _daysOfWeek.map((day) {
            DateTime dayDate = _currentWeekStart.add(Duration(days: _daysOfWeek.indexOf(day)));
            return Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(day.substring(0, 3)),
                  Text(
                    '${dayDate.day}/${dayDate.month}',
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
            );
          }).toList(),
        ) : null,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.green[50],
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select your available time slots for each day. Tap on slots to toggle availability.',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _tabController != null ? TabBarView(
                    controller: _tabController,
                    children: _daysOfWeek.map((day) => _buildDayView(day)).toList(),
                  ) : Container(),
                ),
                _buildBottomActionBar(),
              ],
            ),
    );
  }

  Widget _buildDayView(String day) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Time Slots for $day',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Lunch Break: 12:00 PM - 1:00 PM',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[700],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                TimeSlot slot = _timeSlots[index];
                String slotString = '${slot.startTime}-${slot.endTime}';
                bool isSelected = _selectedSlots[day]!.contains(slotString);
                
                return _buildTimeSlotCard(slot, isSelected, () {
                  setState(() {
                    if (isSelected) {
                      _selectedSlots[day]!.remove(slotString);
                    } else {
                      _selectedSlots[day]!.add(slotString);
                    }
                  });
                });
              },
            ),
          ),
          if (_selectedSlots[day]!.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Slots (${_selectedSlots[day]!.length}):',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _selectedSlots[day]!.map((slot) {
                      return Chip(
                        label: Text(
                          slot,
                          style: TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.green[100],
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedSlots[day]!.remove(slot);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[100] : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green[400]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.access_time,
              color: isSelected ? Colors.green[600] : Colors.grey[600],
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.green[700] : Colors.grey[700],
              ),
            ),
            if (isSelected)
              Text(
                'Available',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    int totalSelectedSlots = _selectedSlots.values.fold(0, (sum, slots) => sum + slots.length);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.green[600], size: 20),
              SizedBox(width: 8),
              Text(
                'Total Selected Slots: $totalSelectedSlots',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearAllSlots,
                  child: Text('Clear All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: totalSelectedSlots > 0 ? _saveAllSlots : null,
                  child: Text('Save Available Slots'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(String time) {
    List<String> parts = time.split(':');
    int hour = int.parse(parts[0]);
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour:${parts[1]} $period';
  }

  void _navigateToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(Duration(days: 7));
      _initializeWeeklySlots();
    });
    _loadExistingSlots();
  }

  void _navigateToNextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: 7));
      _initializeWeeklySlots();
    });
    _loadExistingSlots();
  }

  void _clearAllSlots() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Slots'),
        content: Text('Are you sure you want to clear all selected time slots?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                for (String day in _daysOfWeek) {
                  _selectedSlots[day]!.clear();
                }
              });
              Navigator.pop(context);
            },
            child: Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAllSlots() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
              SizedBox(width: 16),
              Text('Saving slots...'),
            ],
          ),
        ),
      );

      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      for (int i = 0; i < _daysOfWeek.length; i++) {
        String day = _daysOfWeek[i];
        DateTime dayDate = _currentWeekStart.add(Duration(days: i));
        
        if (_selectedSlots[day]!.isNotEmpty) {
          // Check if document exists for this date
          String docId = '${widget.practitionerId}_${dayDate.year}_${dayDate.month}_${dayDate.day}';
          DocumentReference docRef = FirebaseFirestore.instance
              .collection('slots_practitioner')
              .doc(docId);
          
          Map<String, dynamic> slotData = {
            'practitionerId': widget.practitionerId,
            'date': Timestamp.fromDate(dayDate),
            'dayName': day,
            'availableTimeSlots': _selectedSlots[day]!.toList(),
            'totalSlots': _selectedSlots[day]!.length,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          
          // Check if document exists
          DocumentSnapshot docSnapshot = await docRef.get();
          if (docSnapshot.exists) {
            batch.update(docRef, slotData);
          } else {
            slotData['createdAt'] = FieldValue.serverTimestamp();
            batch.set(docRef, slotData);
          }
        }
      }

      await batch.commit();
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Available slots saved successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Error saving slots: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to save slots. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

class TimeSlot {
  final String startTime;
  final String endTime;

  TimeSlot(this.startTime, this.endTime);
}