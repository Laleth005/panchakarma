import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardHeader extends StatelessWidget {
  final String practitionerName;
  final String? profileImageUrl;
  final VoidCallback onProfileTap;

  const DashboardHeader({
    required this.practitionerName,
    required this.onProfileTap,
    this.profileImageUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Get greeting based on time of day
    final hour = DateTime.now().hour;
    String greeting = '';

    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    // Get current date
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Practitioner info and greeting
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dr. $practitionerName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Profile image
            InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(30),
              child: CircleAvatar(
                radius: 30,
                backgroundImage:
                    profileImageUrl != null && profileImageUrl!.isNotEmpty
                    ? NetworkImage(profileImageUrl!)
                    : null,
                child: profileImageUrl == null || profileImageUrl!.isEmpty
                    ? Text(
                        practitionerName.isNotEmpty
                            ? practitionerName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
