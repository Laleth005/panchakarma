import 'package:flutter/material.dart';
import '../models/patient_feedback_model.dart';
import '../services/practitioner_repository.dart';
import 'package:intl/intl.dart';

class PatientFeedbackPanel extends StatefulWidget {
  final String practitionerId;
  final Function(PatientFeedbackModel) onRespondToFeedback;

  const PatientFeedbackPanel({
    Key? key,
    required this.practitionerId,
    required this.onRespondToFeedback,
  }) : super(key: key);

  @override
  _PatientFeedbackPanelState createState() => _PatientFeedbackPanelState();
}

class _PatientFeedbackPanelState extends State<PatientFeedbackPanel> {
  final PractitionerRepository _repository = PractitionerRepository();
  List<PatientFeedbackModel> _feedbacks = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final feedbacks = await _repository.getPendingFeedback(
        widget.practitionerId,
      );
      setState(() {
        _feedbacks = feedbacks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _acknowledgeFeedback(
    PatientFeedbackModel feedback, [
    String? response,
  ]) async {
    final success = await _repository.acknowledgeFeedback(
      feedback.id,
      response,
    );

    if (success) {
      setState(() {
        _feedbacks.removeWhere((f) => f.id == feedback.id);
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
                  'Patient Feedback',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.green),
                  onPressed: _loadFeedback,
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
                      'Error loading feedback',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    TextButton(onPressed: _loadFeedback, child: Text('Retry')),
                  ],
                ),
              ),
            )
          else if (_feedbacks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.green.shade300,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No pending feedback',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _feedbacks.length,
                padding: EdgeInsets.symmetric(vertical: 8),
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final feedback = _feedbacks[index];
                  return _buildFeedbackItem(feedback);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(PatientFeedbackModel feedback) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.patientName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d, yyyy').format(feedback.dateTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < feedback.rating ? Icons.star : Icons.star_border,
                    color: i < feedback.rating
                        ? Colors.amber
                        : Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (feedback.therapyType != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                feedback.therapyType!,
                style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
              ),
            ),
          SizedBox(height: 8),
          Text(
            feedback.feedback,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _acknowledgeFeedback(feedback),
                child: Text('Acknowledge'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size(0, 0),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => widget.onRespondToFeedback(feedback),
                child: Text('Respond'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size(0, 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
