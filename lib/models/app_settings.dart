class AppSettings {
  final bool notificationsEnabled;
  final bool bloodRequestNotificationsEnabled;
  final bool donationRequestNotificationsEnabled;
  final bool responseNotificationsEnabled;
  final bool bloodAvailabilityNotificationsEnabled;
  final bool healthTipsNotificationsEnabled;
  final bool eventNotificationsEnabled;
  final bool backgroundNotificationsEnabled;

  const AppSettings({
    this.notificationsEnabled = true,
    this.bloodRequestNotificationsEnabled = true,
    this.donationRequestNotificationsEnabled = true,
    this.responseNotificationsEnabled = true,
    this.bloodAvailabilityNotificationsEnabled = true,
    this.healthTipsNotificationsEnabled = true,
    this.eventNotificationsEnabled = true,
    this.backgroundNotificationsEnabled = true,
  });

  // Copy with method to create a new instance with some changes
  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? bloodRequestNotificationsEnabled,
    bool? donationRequestNotificationsEnabled,
    bool? responseNotificationsEnabled,
    bool? bloodAvailabilityNotificationsEnabled,
    bool? healthTipsNotificationsEnabled,
    bool? eventNotificationsEnabled,
    bool? backgroundNotificationsEnabled,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      bloodRequestNotificationsEnabled: bloodRequestNotificationsEnabled ??
          this.bloodRequestNotificationsEnabled,
      donationRequestNotificationsEnabled: donationRequestNotificationsEnabled ??
          this.donationRequestNotificationsEnabled,
      responseNotificationsEnabled:
          responseNotificationsEnabled ?? this.responseNotificationsEnabled,
      bloodAvailabilityNotificationsEnabled:
          bloodAvailabilityNotificationsEnabled ??
              this.bloodAvailabilityNotificationsEnabled,
      healthTipsNotificationsEnabled:
          healthTipsNotificationsEnabled ?? this.healthTipsNotificationsEnabled,
      eventNotificationsEnabled:
          eventNotificationsEnabled ?? this.eventNotificationsEnabled,
      backgroundNotificationsEnabled:
          backgroundNotificationsEnabled ?? this.backgroundNotificationsEnabled,
    );
  }

  // Convert to map for storing in preferences
  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'bloodRequestNotificationsEnabled': bloodRequestNotificationsEnabled,
      'donationRequestNotificationsEnabled': donationRequestNotificationsEnabled,
      'responseNotificationsEnabled': responseNotificationsEnabled,
      'bloodAvailabilityNotificationsEnabled':
          bloodAvailabilityNotificationsEnabled,
      'healthTipsNotificationsEnabled': healthTipsNotificationsEnabled,
      'eventNotificationsEnabled': eventNotificationsEnabled,
      'backgroundNotificationsEnabled': backgroundNotificationsEnabled,
    };
  }

  // Create from map (loaded from preferences)
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      bloodRequestNotificationsEnabled:
          map['bloodRequestNotificationsEnabled'] ?? true,
      donationRequestNotificationsEnabled:
          map['donationRequestNotificationsEnabled'] ?? true,
      responseNotificationsEnabled: map['responseNotificationsEnabled'] ?? true,
      bloodAvailabilityNotificationsEnabled:
          map['bloodAvailabilityNotificationsEnabled'] ?? true,
      healthTipsNotificationsEnabled:
          map['healthTipsNotificationsEnabled'] ?? true,
      eventNotificationsEnabled: map['eventNotificationsEnabled'] ?? true,
      backgroundNotificationsEnabled: map['backgroundNotificationsEnabled'] ?? true,
    );
  }
} 