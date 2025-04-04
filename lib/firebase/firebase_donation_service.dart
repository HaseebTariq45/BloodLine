import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/donation_model.dart';

class FirebaseDonationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'donations';
  
  // Get all donations
  Future<List<DonationModel>> getAllDonations() async {
    try {
      debugPrint('Fetching all donations from Firestore');
      final snapshot = await _firestore.collection(_collection).get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure ID is set correctly
        data['id'] = doc.id;
        return DonationModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching donations: $e');
      rethrow;
    }
  }
  
  // Get donations for a specific user
  Future<List<DonationModel>> getUserDonations(String userId) async {
    try {
      debugPrint('Fetching donations for user: $userId');
      
      // Because of the index issue, we'll just filter on donorId and sort manually
      final snapshot = await _firestore
          .collection(_collection)
          .where('donorId', isEqualTo: userId)
          .get();
      
      final donations = snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure ID is set correctly
        data['id'] = doc.id;
        return DonationModel.fromJson(data);
      }).toList();
      
      // Sort manually by date (descending)
      donations.sort((a, b) => b.date.compareTo(a.date));
      
      return donations;
    } catch (e) {
      debugPrint('Error fetching user donations: $e');
      rethrow;
    }
  }
  
  // Stream of donations for a specific user for real-time updates
  Stream<List<DonationModel>> getUserDonationsStream(String userId) {
    try {
      debugPrint('Creating stream for user donations: $userId');
      
      // Because of the index issue, we'll use a simpler query without sorting
      return _firestore
          .collection(_collection)
          .where('donorId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final donations = snapshot.docs.map((doc) {
              final data = doc.data();
              // Ensure ID is set correctly
              data['id'] = doc.id;
              return DonationModel.fromJson(data);
            }).toList();
            
            // Sort manually by date (descending)
            donations.sort((a, b) => b.date.compareTo(a.date));
            
            return donations;
          });
    } catch (e) {
      debugPrint('Error creating donation stream: $e');
      // Return an empty stream in case of error
      return Stream.value([]);
    }
  }
  
  // Add a new donation
  Future<DonationModel> addDonation(DonationModel donation) async {
    try {
      debugPrint('Adding new donation to Firestore');
      // Create a document reference with auto-generated ID if not provided
      final docRef = donation.id.isEmpty || donation.id.startsWith('donation_') 
          ? _firestore.collection(_collection).doc() 
          : _firestore.collection(_collection).doc(donation.id);
      
      // Create donation with generated ID
      final newDonation = donation.id.isEmpty || donation.id.startsWith('donation_')
          ? donation.copyWith(id: docRef.id)
          : donation;
      
      // Save to Firestore
      await docRef.set(newDonation.toJson());
      
      debugPrint('Donation added successfully with ID: ${newDonation.id}');
      return newDonation;
    } catch (e) {
      debugPrint('Error adding donation: $e');
      rethrow;
    }
  }
  
  // Update donation status
  Future<void> updateDonationStatus(String donationId, String newStatus) async {
    try {
      debugPrint('Updating donation status: $donationId to $newStatus');
      await _firestore.collection(_collection).doc(donationId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Donation status updated successfully');
    } catch (e) {
      debugPrint('Error updating donation status: $e');
      rethrow;
    }
  }
  
  // Delete a donation
  Future<void> deleteDonation(String donationId) async {
    try {
      debugPrint('Deleting donation: $donationId');
      await _firestore.collection(_collection).doc(donationId).delete();
      
      debugPrint('Donation deleted successfully');
    } catch (e) {
      debugPrint('Error deleting donation: $e');
      rethrow;
    }
  }
  
  // Get donation by ID
  Future<DonationModel?> getDonationById(String donationId) async {
    try {
      debugPrint('Fetching donation by ID: $donationId');
      final doc = await _firestore.collection(_collection).doc(donationId).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Ensure ID is set correctly
        data['id'] = doc.id;
        return DonationModel.fromJson(data);
      }
      
      debugPrint('No donation found with ID: $donationId');
      return null;
    } catch (e) {
      debugPrint('Error fetching donation by ID: $e');
      rethrow;
    }
  }
} 