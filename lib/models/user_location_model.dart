class UserLocationModel {
  final double latitude;
  final double longitude;
  final String? address;
  
  UserLocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
  });
  
  factory UserLocationModel.fromMap(Map<String, dynamic> map) {
    return UserLocationModel(
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      address: map['address'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}
