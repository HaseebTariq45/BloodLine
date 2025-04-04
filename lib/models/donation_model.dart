import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationModel {
  final String id;
  final String donorId;
  final String donorName;
  final String bloodType;
  final DateTime date;
  final String centerName;
  final String address;
  final String recipientId;
  final String recipientName;
  final String? recipientPhone;
  final String status; // Accepted, Scheduled, Completed, Cancelled

  DonationModel({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.bloodType,
    required this.date,
    required this.centerName,
    required this.address,
    this.recipientId = '',
    this.recipientName = '',
    this.recipientPhone,
    this.status = 'Accepted',
  });

  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);

  // Create a copy of this donation with updated fields
  DonationModel copyWith({
    String? id,
    String? donorId,
    String? donorName,
    String? bloodType,
    DateTime? date,
    String? centerName,
    String? address,
    String? recipientId,
    String? recipientName,
    String? recipientPhone,
    String? status,
  }) {
    return DonationModel(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      bloodType: bloodType ?? this.bloodType,
      date: date ?? this.date,
      centerName: centerName ?? this.centerName,
      address: address ?? this.address,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      status: status ?? this.status,
    );
  }

  // Convert DonationModel to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donorId': donorId,
      'donorName': donorName,
      'bloodType': bloodType,
      'date': date.millisecondsSinceEpoch,
      'centerName': centerName,
      'address': address,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Create DonationModel from Firestore document
  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      id: json['id'] ?? '',
      donorId: json['donorId'] ?? '',
      donorName: json['donorName'] ?? '',
      recipientId: json['recipientId'] ?? '',
      recipientName: json['recipientName'] ?? '',
      recipientPhone: json['recipientPhone'],
      bloodType: json['bloodType'] ?? '',
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      centerName: json['centerName'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? 'Accepted',
    );
  }

  // Factory method to create a new donation for a specific donor and blood center
  factory DonationModel.create({
    required String donorId,
    required String donorName,
    required String bloodType,
    required String centerName,
    required String address,
  }) {
    return DonationModel(
      id: '', // Will be assigned by Firestore
      donorId: donorId,
      donorName: donorName,
      bloodType: bloodType,
      date: DateTime.now(),
      centerName: centerName,
      address: address,
      status: 'Pending',
    );
  }

  factory DonationModel.dummy(int index) {
    final statuses = ['Completed', 'Pending', 'Cancelled'];
    final bloodTypes = ['A+', 'B+', 'AB+', 'O+', 'A-', 'B-', 'AB-', 'O-'];
    final centers = [
      'City Blood Bank',
      'Central Hospital',
      'Red Cross Center',
      'Community Donation Center',
      'Medical College Hospital',
    ];

    final randomDays = (index + 1) * 30;
    final randomStatus = statuses[index % statuses.length];
    final randomBloodType = bloodTypes[index % bloodTypes.length];
    final randomCenter = centers[index % centers.length];

    return DonationModel(
      id: 'donation_$index',
      donorId: 'donor_$index',
      donorName: 'Donor ${index + 1}',
      recipientId: 'recipient_$index',
      recipientName: 'Recipient ${index + 1}',
      recipientPhone: '+92 300 ${1000000 + index}',
      bloodType: randomBloodType,
      date: DateTime.now().subtract(Duration(days: index * 3)),
      centerName: randomCenter,
      address: 'Address ${index + 1}, City',
      status: randomStatus,
    );
  }

  static List<DonationModel> getDummyList(int count) {
    return List.generate(count, (index) => DonationModel.dummy(index));
  }
}
