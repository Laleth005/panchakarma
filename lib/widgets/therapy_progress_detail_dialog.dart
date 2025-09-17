import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/therapy_progress_model.dart';

class TherapyProgressDetailDialog extends StatelessWidget {
  final TherapyProgressModel therapy;

  const TherapyProgressDetailDialog({
    required this.therapy,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildPatientInfo(),
            const SizedBox(height: 24),
            _buildProgressDetails(),
            const SizedBox(height: 24),
            _buildSessionsInfo(),
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Therapy Progress Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildPatientInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: therapy.profileImageUrl != null
              ? NetworkImage(therapy.profileImageUrl!)
              : null,
          child: therapy.profileImageUrl == null
              ? Text(
                  therapy.patientName.isNotEmpty
                      ? therapy.patientName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 24),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                therapy.patientName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Patient ID: ${therapy.patientId}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        _buildStatusChip(therapy.status),
      ],
    );
  }

  Widget _buildProgressDetails() {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Therapy Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Therapy Type', therapy.therapyName),
        _buildDetailRow(
          'Start Date',
          dateFormat.format(therapy.startDate),
        ),
        if (therapy.endDate != null)
          _buildDetailRow(
            'End Date',
            dateFormat.format(therapy.endDate!),
          ),
        _buildDetailRow(
          'Progress',
          '${therapy.progressPercentage.toStringAsFixed(1)}%',
        ),
        if (therapy.notes != null && therapy.notes!.isNotEmpty)
          _buildDetailRow('Notes', therapy.notes!),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sessions Progress',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: therapy.progressPercentage / 100,
            backgroundColor: Colors.grey.shade200,
            minHeight: 12,
            color: _getProgressColor(therapy.status),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sessions Completed: ${therapy.completedSessions}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Total Sessions: ${therapy.totalSessions}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Only show update button if not completed
        if (therapy.status != TherapyStatus.completed)
          OutlinedButton.icon(
            onPressed: () {
              // Update session logic
              Navigator.pop(context);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Update Progress'),
          ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            // View detailed history logic
            Navigator.pop(context);
          },
          icon: const Icon(Icons.history),
          label: const Text('View Session History'),
        ),
      ],
    );
  }

  Widget _buildStatusChip(TherapyStatus status) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String text;

    switch (status) {
      case TherapyStatus.notStarted:
        backgroundColor = Colors.grey;
        text = 'Not Started';
        break;
      case TherapyStatus.inProgress:
        backgroundColor = Colors.blue;
        text = 'In Progress';
        break;
      case TherapyStatus.completed:
        backgroundColor = Colors.green;
        text = 'Completed';
        break;
      case TherapyStatus.cancelled:
        backgroundColor = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getProgressColor(TherapyStatus status) {
    switch (status) {
      case TherapyStatus.notStarted:
        return Colors.grey;
      case TherapyStatus.inProgress:
        return Colors.blue;
      case TherapyStatus.completed:
        return Colors.green;
      case TherapyStatus.cancelled:
        return Colors.red;
    }
  }
}