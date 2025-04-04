/// Utility class for determining blood type compatibility between donors and recipients
class BloodCompatibility {
  /// Returns a list of blood types that can donate to the specified recipient blood type
  static List<String> getCompatibleDonorTypes(String recipientBloodType) {
    switch (recipientBloodType) {
      case 'A+':
        return ['A+', 'A-', 'O+', 'O-'];
      case 'A-':
        return ['A-', 'O-'];
      case 'B+':
        return ['B+', 'B-', 'O+', 'O-'];
      case 'B-':
        return ['B-', 'O-'];
      case 'AB+':
        return [
          'A+',
          'A-',
          'B+',
          'B-',
          'AB+',
          'AB-',
          'O+',
          'O-',
        ]; // Can receive from all types
      case 'AB-':
        return ['A-', 'B-', 'AB-', 'O-']; // Can receive from all negative types
      case 'O+':
        return ['O+', 'O-'];
      case 'O-':
        return ['O-']; // Universal donor
      default:
        return [];
    }
  }

  /// Returns a list of blood types that can receive from the specified donor blood type
  static List<String> getCompatibleRecipientTypes(String donorBloodType) {
    switch (donorBloodType) {
      case 'A+':
        return ['A+', 'AB+'];
      case 'A-':
        return ['A+', 'A-', 'AB+', 'AB-'];
      case 'B+':
        return ['B+', 'AB+'];
      case 'B-':
        return ['B+', 'B-', 'AB+', 'AB-'];
      case 'AB+':
        return ['AB+'];
      case 'AB-':
        return ['AB+', 'AB-'];
      case 'O+':
        return ['A+', 'B+', 'AB+', 'O+'];
      case 'O-':
        return [
          'A+',
          'A-',
          'B+',
          'B-',
          'AB+',
          'AB-',
          'O+',
          'O-',
        ]; // Universal donor
      default:
        return [];
    }
  }

  /// Checks if a donor with donorBloodType can donate to a recipient with recipientBloodType
  static bool canDonate(String donorBloodType, String recipientBloodType) {
    final recipientCompatibleTypes = getCompatibleDonorTypes(
      recipientBloodType,
    );
    return recipientCompatibleTypes.contains(donorBloodType);
  }

  /// Gets a color code for urgency level (for UI purposes)
  static int getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'urgent':
        return 0xFFE53935; // Red
      case 'high':
        return 0xFFF57C00; // Orange
      case 'normal':
        return 0xFF43A047; // Green
      default:
        return 0xFF43A047; // Default green
    }
  }
}
