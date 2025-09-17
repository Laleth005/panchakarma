import 'package:flutter/material.dart';
import '../models/therapy_progress_model.dart';

class PatientTherapyProgressTracker extends StatelessWidget {
  final List<TherapyProgressModel> therapyProgressList;
  final Function(TherapyProgressModel) onProgressTap;

  const PatientTherapyProgressTracker({
    required this.therapyProgressList,
    required this.onProgressTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildProgressList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Patient Therapy Progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {
            // Navigate to all therapy progress view
          },
          child: const Row(
            children: [
              Text('View All'),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressList(BuildContext context) {
    if (therapyProgressList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text('No therapy progress data available'),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: therapyProgressList.length > 5 ? 5 : therapyProgressList.length,
      separatorBuilder: (context, index) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final therapy = therapyProgressList[index];
        return _buildProgressItem(context, therapy);
      },
    );
  }

  Widget _buildProgressItem(BuildContext context, TherapyProgressModel therapy) {
    return InkWell(
      onTap: () => onProgressTap(therapy),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient profile image
            CircleAvatar(
              radius: 24,
              backgroundImage: therapy.profileImageUrl != null
                  ? NetworkImage(therapy.profileImageUrl!)
                  : null,
              child: therapy.profileImageUrl == null
                  ? Text(
                      therapy.patientName.isNotEmpty
                          ? therapy.patientName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 20),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Patient and therapy details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        therapy.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(therapy.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    therapy.therapyName,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: therapy.progressPercentage / 100,
                            backgroundColor: Colors.grey.shade200,
                            minHeight: 8,
                            color: _getProgressColor(therapy.status),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${therapy.completedSessions}/${therapy.totalSessions}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (therapy.notes != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      therapy.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
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