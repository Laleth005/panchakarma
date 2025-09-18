import 'dart:async';

/// A service for verifying various identification credentials.
/// Currently supports mock verification for testing purposes.
class VerificationService {
  /// Verifies if the given Aadhar number is valid.
  /// This is a mock implementation for demonstration purposes.
  /// In a real application, this would connect to an official verification API.
  Future<bool> verifyAadhar(String aadharNumber) async {
    // Add a delay to simulate network request
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock verification logic
    // In a real application, this would make an API call to verify
    if (aadharNumber.length != 12) {
      return false;
    }
    
    // Simple validation for demo purposes
    // Check if all characters are digits
    if (aadharNumber.contains(RegExp(r'[^0-9]'))) {
      return false;
    }
    
    // For testing: certain numbers always return true/false
    if (aadharNumber == '000000000000') {
      return false;
    }
    
    // Mock success for most inputs
    return true;
  }

  /// Verifies if the given ABHA ID is valid.
  /// This is a mock implementation for demonstration purposes.
  Future<bool> verifyAbha(String abhaId) async {
    // Add a delay to simulate network request
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock verification logic
    // In a real implementation, this would verify against the ABHA system
    
    // Basic validation
    if (abhaId.isEmpty) {
      return false;
    }
    
    // For testing: certain IDs always return false
    if (abhaId == '0000000000') {
      return false;
    }
    
    // Mock success for most inputs
    return true;
  }

  /// Verifies if the given medical registration number is valid.
  /// This is a mock implementation for demonstration purposes.
  Future<bool> verifyMedicalRegistration(String registrationNumber) async {
    // Add a delay to simulate network request
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock verification logic
    // In a real implementation, this would verify against medical council records
    
    // Basic validation
    if (registrationNumber.isEmpty) {
      return false;
    }
    
    // For testing: certain numbers always return false
    if (registrationNumber == '000000') {
      return false;
    }
    
    // Mock success for most inputs
    return true;
  }
}