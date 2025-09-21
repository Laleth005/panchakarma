import 'package:flutter/material.dart';
import '../screens/practitioner/practitioner_dashboard.dart';

class AppRouter {
  // Navigation methods for Aayur Sutra application

  // Navigate to Practitioner Dashboard
  static void navigateToPractitionerDashboard(
    BuildContext context,
    String practitionerId,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            PractitionerMainDashboard(practitionerId: practitionerId),
      ),
    );
  }

  // Method to navigate and replace current screen
  static void navigateReplacingCurrent(
    BuildContext context,
    Widget destination,
  ) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => destination));
  }

  // Method to navigate to a new screen
  static void navigateTo(BuildContext context, Widget destination) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => destination));
  }

  // Method to pop to root and show a specific screen
  static void popToRootAndShow(BuildContext context, Widget destination) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    navigateReplacingCurrent(context, destination);
  }
}
