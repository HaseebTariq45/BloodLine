import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final String address;
  final String contactType; // 'personal', 'hospital', 'blood_bank', 'ambulance'
  final String imageUrl;
  final bool isPinned; // To pin important contacts to the top
  final DateTime createdAt;
  final String userId; // ID of the user who added this contact

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.relationship = '',
    this.address = '',
    required this.contactType,
    this.imageUrl = '',
    this.isPinned = false,
    required this.createdAt,
    required this.userId,
  });

  // Factory constructor to create a EmergencyContactModel from a Firebase document
  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      relationship: json['relationship'] ?? '',
      address: json['address'] ?? '',
      contactType: json['contactType'] ?? 'personal',
      imageUrl: json['imageUrl'] ?? '',
      isPinned: json['isPinned'] ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: json['userId'] ?? '',
    );
  }

  // Convert EmergencyContactModel to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'address': address,
      'contactType': contactType,
      'imageUrl': imageUrl,
      'isPinned': isPinned,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }

  // Create a copy of this EmergencyContactModel with modified fields
  EmergencyContactModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    String? address,
    String? contactType,
    String? imageUrl,
    bool? isPinned,
    DateTime? createdAt,
    String? userId,
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      address: address ?? this.address,
      contactType: contactType ?? this.contactType,
      imageUrl: imageUrl ?? this.imageUrl,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  // Generate some built-in emergency contacts
  static List<EmergencyContactModel> getBuiltInContacts(String userId) {
    return [
      EmergencyContactModel(
        id: 'emergency-ambulance',
        name: 'Ambulance Emergency',
        phoneNumber: '108',
        contactType: 'ambulance',
        createdAt: DateTime.now(),
        userId: 'system',
        isPinned: true,
      ),
      EmergencyContactModel(
        id: 'emergency-national',
        name: 'National Emergency',
        phoneNumber: '112',
        contactType: 'ambulance',
        createdAt: DateTime.now(),
        userId: 'system',
        isPinned: true,
      ),
      EmergencyContactModel(
        id: 'emergency-redcross',
        name: 'Red Cross Blood Services',
        phoneNumber: '1-800-RED-CROSS',
        relationship: 'Blood Donation Organization',
        contactType: 'blood_bank',
        createdAt: DateTime.now(),
        userId: 'system',
        isPinned: true,
      ),
    ];
  }
} 