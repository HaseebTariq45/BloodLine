class BloodBankModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final String openingHours;
  final bool isOpen;
  final double rating;
  final int distance; // in meters
  final Map<String, int> availableBloodTypes; // Blood type -> Units available

  BloodBankModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.openingHours,
    this.isOpen = true,
    this.rating = 4.5,
    this.distance = 0,
    required this.availableBloodTypes,
  });

  String get formattedDistance {
    if (distance < 1000) {
      return '$distance m';
    } else {
      final kilometers = distance / 1000;
      return '${kilometers.toStringAsFixed(1)} km';
    }
  }

  factory BloodBankModel.dummy(int index) {
    final bloodTypes = {
      'A+': 10 + index,
      'A-': 5 + index,
      'B+': 8 + index,
      'B-': 3 + index,
      'AB+': 4 + index,
      'AB-': 2 + index,
      'O+': 15 + index,
      'O-': 7 + index,
    };

    return BloodBankModel(
      id: 'bank_$index',
      name: 'Blood Bank ${index + 1}',
      address: '${100 + index} Main Street, City',
      phone: '+1234${index}56789',
      latitude: 37.7749 + (index * 0.01),
      longitude: -122.4194 + (index * 0.01),
      openingHours: '9:00 AM - 5:00 PM',
      isOpen: index % 3 != 0,
      rating: 3.5 + (index % 2),
      distance: 500 * (index + 1),
      availableBloodTypes: bloodTypes,
    );
  }

  static List<BloodBankModel> getDummyList() {
    return List.generate(5, (index) => BloodBankModel.dummy(index));
  }
} 