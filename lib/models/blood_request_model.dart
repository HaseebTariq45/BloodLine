import 'package:intl/intl.dart';

class BloodRequestModel {
  final String id;
  final String requesterId;
  final String requesterName;
  final String contactNumber;
  final String bloodType;
  final String location;
  final String city;
  final String urgency; // Normal, Urgent
  final DateTime requestDate;
  final String status; // New, Accepted, Scheduled, Completed, Cancelled
  final String notes;
  final String? responderId;
  final String? responderName;
  final String? responderPhone;

  BloodRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.contactNumber,
    required this.bloodType,
    required this.location,
    required this.requestDate,
    this.city = '',
    this.urgency = 'Normal',
    this.status = 'New',
    this.notes = '',
    this.responderId,
    this.responderName,
    this.responderPhone,
  });

  String get formattedDate => DateFormat('MMM dd, yyyy').format(requestDate);

  bool get isUrgent => urgency == 'Urgent';

  factory BloodRequestModel.dummy(int index) {
    final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    final urgencyTypes = ['Normal', 'Urgent'];
    final statusTypes = ['New', 'Accepted', 'Completed', 'Cancelled'];

    return BloodRequestModel(
      id: 'request_$index',
      requesterId: 'requester_$index',
      requesterName: 'Requester ${index + 1}',
      contactNumber: '+12345${index}7890',
      bloodType: bloodTypes[index % bloodTypes.length],
      location: 'Hospital ${index + 1}',
      city: 'Karachi',
      requestDate: DateTime.now().subtract(Duration(days: index * 2)),
      urgency: urgencyTypes[index % 2],
      status: statusTypes[index % 4],
      notes: index % 2 == 0 ? 'Needed for surgery' : 'Regular requirement',
    );
  }

  static List<BloodRequestModel> getDummyList() {
    return List.generate(8, (index) => BloodRequestModel.dummy(index));
  }

  // Convert BloodRequestModel to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'contactNumber': contactNumber,
      'bloodType': bloodType,
      'location': location,
      'city': city,
      'urgency': urgency,
      'requestDate': requestDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'responderId': responderId,
      'responderName': responderName,
      'responderPhone': responderPhone,
    };
  }

  // Create a BloodRequestModel from a Firestore document
  factory BloodRequestModel.fromMap(Map<String, dynamic> map) {
    return BloodRequestModel(
      id: map['id'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      bloodType: map['bloodType'] ?? '',
      location: map['location'] ?? '',
      city: map['city'] ?? '',
      urgency: map['urgency'] ?? 'Normal',
      requestDate:
          map['requestDate'] != null
              ? DateTime.parse(map['requestDate'])
              : DateTime.now(),
      status: map['status'] ?? 'Pending',
      notes: map['notes'] ?? '',
      responderId: map['responderId'],
      responderName: map['responderName'],
      responderPhone: map['responderPhone'],
    );
  }
}
