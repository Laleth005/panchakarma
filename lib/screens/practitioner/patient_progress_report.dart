import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/patient_model.dart';
import '../../models/treatment_record_model.dart';

class PatientProgressReportScreen extends StatefulWidget {
  final String patientId;

  const PatientProgressReportScreen({Key? key, required this.patientId})
    : super(key: key);

  @override
  _PatientProgressReportScreenState createState() =>
      _PatientProgressReportScreenState();
}

class _PatientProgressReportScreenState
    extends State<PatientProgressReportScreen> {
  PatientModel? _patient;
  bool _isLoading = true;
  List<TreatmentRecordModel> _treatmentRecords = [];
  String _selectedTimeRange = 'Last Month';
  List<String> _timeRanges = [
    'Last Week',
    'Last Month',
    'Last 3 Months',
    'Last Year',
    'All Time',
  ];

  // For storing analytics data
  Map<String, dynamic> _analytics = {
    'totalSessions': 0,
    'completedSessions': 0,
    'canceledSessions': 0,
    'avgFeedbackScore': 0.0,
    'healthImprovementScore': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadPatientData();
    _loadTreatmentRecords();
  }

  Future<void> _loadPatientData() async {
    try {
      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();

      if (patientDoc.exists) {
        final data = patientDoc.data()!;
        data['uid'] = widget.patientId;

        // Handle timestamps
        DateTime createdAt = DateTime.now();
        DateTime updatedAt = DateTime.now();

        if (data.containsKey('createdAt') && data['createdAt'] != null) {
          if (data['createdAt'] is Timestamp) {
            createdAt = (data['createdAt'] as Timestamp).toDate();
          }
        }

        if (data.containsKey('updatedAt') && data['updatedAt'] != null) {
          if (data['updatedAt'] is Timestamp) {
            updatedAt = (data['updatedAt'] as Timestamp).toDate();
          }
        }

        final patient = PatientModel(
          uid: widget.patientId,
          email: data['email'] as String? ?? '',
          fullName: data['fullName'] as String? ?? 'Patient',
          createdAt: createdAt,
          updatedAt: updatedAt,
          // Optional fields
          dateOfBirth: data['dateOfBirth'] as String?,
          gender: data['gender'] as String?,
          address: data['address'] as String?,
          phoneNumber: data['phoneNumber'] as String?,
          medicalHistory: data['medicalHistory'] as String?,
          allergies: data['allergies'] as String?,
          doshaType: data['doshaType'] as String?,
          profileImageUrl: data['profileImageUrl'] as String?,
          primaryPractitionerId: data['primaryPractitionerId'] as String?,
        );

        setState(() {
          _patient = patient;
        });
      }
    } catch (e) {
      print('Error loading patient data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTreatmentRecords() async {
    try {
      final records = await FirebaseFirestore.instance
          .collection('treatmentRecords')
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('treatmentDate', descending: true)
          .get();

      List<TreatmentRecordModel> treatmentRecords = [];
      double totalFeedbackScore = 0;
      int recordsWithFeedback = 0;

      for (var doc in records.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        final record = TreatmentRecordModel.fromJson(data);
        treatmentRecords.add(record);

        if (record.patientFeedbackScore != null) {
          totalFeedbackScore += record.patientFeedbackScore!;
          recordsWithFeedback++;
        }
      }

      // Calculate analytics
      final analytics = {
        'totalSessions': treatmentRecords.length,
        'completedSessions': treatmentRecords
            .where((r) => r.status == 'completed')
            .length,
        'canceledSessions': treatmentRecords
            .where((r) => r.status == 'canceled')
            .length,
        'avgFeedbackScore': recordsWithFeedback > 0
            ? totalFeedbackScore / recordsWithFeedback
            : 0.0,
        'healthImprovementScore': _calculateHealthImprovement(treatmentRecords),
      };

      setState(() {
        _treatmentRecords = treatmentRecords;
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading treatment records: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateHealthImprovement(List<TreatmentRecordModel> records) {
    if (records.isEmpty) return 0.0;

    // This is a simplified calculation - in a real app this would be more sophisticated
    // based on practitioners' assessments, patient feedback, and objective metrics
    final recentRecords = records
        .take(5)
        .toList(); // Take the 5 most recent records

    double improvementScore = 0.0;
    int count = 0;

    for (var record in recentRecords) {
      if (record.healthImprovementScore != null) {
        improvementScore += record.healthImprovementScore!;
        count++;
      }
    }

    return count > 0 ? improvementScore / count : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Patient Progress')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_patient?.fullName ?? "Patient"} Progress'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientInfoCard(),
            SizedBox(height: 20),

            _buildTimeRangeSelector(),
            SizedBox(height: 20),

            _buildProgressSummary(),
            SizedBox(height: 20),

            _buildProgressCharts(),
            SizedBox(height: 20),

            _buildTreatmentRecordsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    _patient?.fullName.substring(0, 1).toUpperCase() ?? 'P',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _patient?.fullName ?? 'Patient',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_patient?.gender ?? 'Not specified'} • ${_patient?.dateOfBirth ?? 'DOB not specified'}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _patient?.email ?? '',
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
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    'Dosha: ${_patient?.doshaType ?? 'Not determined'}',
                  ),
                  backgroundColor: Colors.green.shade100,
                ),
                if (_patient?.medicalHistory != null)
                  Chip(
                    label: Text('Medical History'),
                    backgroundColor: Colors.orange.shade100,
                  ),
                if (_patient?.allergies != null)
                  Chip(
                    label: Text('Allergies'),
                    backgroundColor: Colors.red.shade100,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Text('Time Range:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedTimeRange,
                isExpanded: true,
                underline: Container(height: 1, color: Colors.grey.shade300),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTimeRange = newValue;
                      // In a real app, reload data based on the selected time range
                    });
                  }
                },
                items: _timeRanges.map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            _buildSummaryCard(
              'Total Sessions',
              _analytics['totalSessions'].toString(),
              Icons.event_note,
              Colors.blue,
            ),
            SizedBox(width: 12),
            _buildSummaryCard(
              'Completed',
              _analytics['completedSessions'].toString(),
              Icons.check_circle,
              Colors.green,
            ),
            SizedBox(width: 12),
            _buildSummaryCard(
              'Feedback Score',
              _analytics['avgFeedbackScore'].toStringAsFixed(1),
              Icons.star,
              Colors.amber,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Progress',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Improvement Score',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Container(
                  height: 200,
                  child: _treatmentRecords.isEmpty
                      ? Center(
                          child: Text(
                            'No treatment records available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : LineChart(_healthProgressData()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartData _healthProgressData() {
    // Generate dummy data for demonstration
    // In a real app, this would come from actual treatment records
    final spots = List.generate(
      min(10, _treatmentRecords.length),
      (i) => FlSpot(
        i.toDouble(),
        _treatmentRecords[i].healthImprovementScore ?? (3 + i * 0.2),
      ),
    );

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
        },
        getDrawingVerticalLine: (value) {
          return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              // Show session number or date
              if (value.toInt() < _treatmentRecords.length &&
                  value.toInt() % 2 == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'S${value.toInt() + 1}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value % 2 == 0) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  textAlign: TextAlign.center,
                );
              }
              return const Text('');
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      minY: 0,
      maxY: 10,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.green,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentRecordsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Treatment History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        _treatmentRecords.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No treatment records available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : Column(
                children: _treatmentRecords
                    .take(5) // Limit to 5 most recent
                    .map((record) => _buildTreatmentRecordCard(record))
                    .toList(),
              ),
        if (_treatmentRecords.length > 5)
          Center(
            child: TextButton(
              onPressed: () {
                // Show all treatment records
              },
              child: Text('View All ${_treatmentRecords.length} Records'),
            ),
          ),
      ],
    );
  }

  Widget _buildTreatmentRecordCard(TreatmentRecordModel record) {
    final statusColor = record.status == 'completed'
        ? Colors.green
        : record.status == 'canceled'
        ? Colors.red
        : Colors.orange;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.treatmentName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Date: ${_formatDate(record.treatmentDate)}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (record.practitionerNotes != null &&
                record.practitionerNotes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Notes: ${record.practitionerNotes}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            if (record.patientFeedbackScore != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Text(
                      'Feedback: ',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < (record.patientFeedbackScore ?? 0).round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }
}
