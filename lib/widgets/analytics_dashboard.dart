import 'package:flutter/material.dart';
import '../services/practitioner_repository.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboard extends StatefulWidget {
  final String practitionerId;

  const AnalyticsDashboard({Key? key, required this.practitionerId})
    : super(key: key);

  @override
  _AnalyticsDashboardState createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final PractitionerRepository _repository = PractitionerRepository();
  bool _isLoading = true;
  bool _hasError = false;

  // Analytics data
  int _patientsToday = 0;
  int _patientsWeek = 0;
  double _satisfactionScore = 0.0;
  double _completionRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await _repository.getPractitionerAnalytics(
        widget.practitionerId,
      );

      setState(() {
        _patientsToday = data['patientsToday'] ?? 0;
        _patientsWeek = data['patientsWeek'] ?? 0;
        _satisfactionScore = data['satisfactionScore'] ?? 0.0;
        _completionRate = data['completionRate'] ?? 0.0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
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
                  'Analytics & Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.green),
                  onPressed: _loadAnalytics,
                  tooltip: 'Refresh',
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
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Error loading analytics',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    TextButton(onPressed: _loadAnalytics, child: Text('Retry')),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Patients Today',
                          _patientsToday.toString(),
                          Icons.people,
                          Colors.blue.shade700,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsCard(
                          'This Week',
                          _patientsWeek.toString(),
                          Icons.calendar_today,
                          Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRatingCard(
                          'Satisfaction Score',
                          _satisfactionScore,
                          5.0,
                          Icons.star,
                          Colors.amber.shade700,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildProgressCard(
                          'Completion Rate',
                          _completionRate,
                          Icons.check_circle_outline,
                          Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  // Add weekly summary chart here if needed
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(
    String title,
    double value,
    double maxValue,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '/ ${maxValue.toInt()}',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: List.generate(
              maxValue.toInt(),
              (index) => Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: Icon(
                  index < value.floor()
                      ? Icons.star
                      : (index < value ? Icons.star_half : Icons.star_border),
                  color: color,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    String title,
    double percentage,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                percentage.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
