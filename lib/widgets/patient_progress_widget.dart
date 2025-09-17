import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../models/treatment_record_model.dart';
import '../services/practitioner_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PatientProgressWidget extends StatefulWidget {
  final String patientId;
  final String patientName;
  final Function() onViewFullProgress;
  
  const PatientProgressWidget({
    Key? key,
    required this.patientId,
    required this.patientName,
    required this.onViewFullProgress,
  }) : super(key: key);

  @override
  _PatientProgressWidgetState createState() => _PatientProgressWidgetState();
}

class _PatientProgressWidgetState extends State<PatientProgressWidget> {
  bool _isLoading = true;
  bool _hasError = false;
  List<TreatmentRecordModel> _treatmentRecords = [];
  
  // Recovery stages
  final List<String> _stages = ['Initial Assessment', 'Detoxification', 'Rejuvenation', 'Post-care'];
  int _currentStage = 1; // Default to detox stage
  double _progressPercentage = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadTreatmentRecords();
  }
  
  Future<void> _loadTreatmentRecords() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      // Load treatment records from Firestore
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('treatment_records')
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('date', descending: true)
          .limit(10)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final records = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return TreatmentRecordModel.fromJson(data);
        }).toList();
        
        // Determine current stage and progress
        _calculateProgress(records);
        
        setState(() {
          _treatmentRecords = records;
          _isLoading = false;
        });
      } else {
        setState(() {
          _treatmentRecords = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading treatment records: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }
  
  void _calculateProgress(List<TreatmentRecordModel> records) {
    if (records.isEmpty) return;
    
    // Simplified logic - in a real app, this would be more sophisticated
    // based on treatment type, duration, effectiveness scores, etc.
    
    // Check latest record for stage information
    final latestRecord = records.first;
    if (latestRecord.treatmentStage != null) {
      switch (latestRecord.treatmentStage!.toLowerCase()) {
        case 'initial':
        case 'assessment':
          _currentStage = 0;
          break;
        case 'detox':
        case 'purvakarma':
          _currentStage = 1;
          break;
        case 'rejuvenation':
        case 'pradhankarma':
          _currentStage = 2;
          break;
        case 'post-care':
        case 'paschatkarma':
          _currentStage = 3;
          break;
      }
    }
    
    // Calculate progress percentage within the current stage
    // This is simplified logic and would be more complex in a real app
    if (latestRecord.progressPercentage != null) {
      _progressPercentage = latestRecord.progressPercentage!;
    } else {
      // Default calculation based on number of sessions
      final double baseProgress = (_currentStage / (_stages.length - 1)) * 100;
      final double stageProgress = 25 * (records.length % 4) / 4; // Simple calculation
      _progressPercentage = baseProgress + stageProgress;
      if (_progressPercentage > 100) _progressPercentage = 100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Patient Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: widget.onViewFullProgress,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasError)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    SizedBox(height: 16),
                    Text(
                      'Error loading progress data',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    TextButton(
                      onPressed: _loadTreatmentRecords,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        radius: 20,
                        child: Text(
                          widget.patientName.isNotEmpty
                              ? widget.patientName.substring(0, 1).toUpperCase()
                              : 'P',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.patientName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Current Stage: ${_stages[_currentStage]}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Overall Progress',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${_progressPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progressPercentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade500),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                  
                  // Treatment Milestones
                  SizedBox(height: 24),
                  Text(
                    'Treatment Milestones',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_stages.length, (index) {
                      final isActive = index <= _currentStage;
                      final isCurrent = index == _currentStage;
                      
                      return Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? Colors.green.shade500 : Colors.grey.shade300,
                              border: isCurrent
                                  ? Border.all(color: Colors.green.shade700, width: 2)
                                  : null,
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              _getStageIcon(index),
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            _stages[index],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? Colors.green.shade700 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  
                  // Recent Treatment Notes
                  if (_treatmentRecords.isNotEmpty) ...[
                    SizedBox(height: 24),
                    Text(
                      'Recent Treatment Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _treatmentRecords.first.treatmentType ?? 'Unknown Treatment',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _treatmentRecords.first.date != null
                                    ? DateFormat('MMM d, yyyy').format(_treatmentRecords.first.date!)
                                    : 'Date not available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            _treatmentRecords.first.notes ?? 'No notes provided',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  IconData _getStageIcon(int index) {
    switch (index) {
      case 0:
        return Icons.assignment;
      case 1:
        return Icons.cleaning_services;
      case 2:
        return Icons.spa;
      case 3:
        return Icons.health_and_safety;
      default:
        return Icons.circle;
    }
  }
}