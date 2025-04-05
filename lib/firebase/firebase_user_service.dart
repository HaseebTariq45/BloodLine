import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

class FirebaseUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Constructor - enable Firestore settings
  FirebaseUserService() {
    // Enable cache persistence and set cache size
    _configureFirestore();
  }

  // Configure Firestore settings
  void _configureFirestore() {
    try {
      // Set Firestore settings for better performance
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('Firestore persistence configured successfully');
    } catch (e) {
      debugPrint('Error configuring Firestore settings: $e');
    }
  }

  // Save user data to Firestore
  Future<void> saveUserData(UserModel user) async {
    try {
      debugPrint('Saving user data to Firestore for user ID: ${user.id}');
      debugPrint('User data being saved: ${user.toString()}');
      
      // Create a map of all user data
      final Map<String, dynamic> userData = {
        'name': user.name,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'bloodType': user.bloodType,
        'address': user.address,
        'city': user.city,
        'imageUrl': user.imageUrl,
        'isAvailableToDonate': user.isAvailableToDonate,
        'neverDonatedBefore': user.neverDonatedBefore,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Only set lastDonationDate if it's not null and user has donated before
      if (user.lastDonationDate != null && !user.neverDonatedBefore) {
        userData['lastDonationDate'] = user.lastDonationDate!.millisecondsSinceEpoch;
      } else {
        // Explicitly set to null when the user has never donated
        userData['lastDonationDate'] = null;
      }

      await _firestore.collection(_collection).doc(user.id).set(userData);

      debugPrint('User data successfully saved to Firestore');
    } catch (e) {
      debugPrint('Error saving user data to Firestore: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      debugPrint(
        'Attempting to retrieve user data from Firestore for user ID: $userId',
      );

      final doc = await _firestore.collection(_collection).doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        debugPrint('Retrieved user data from Firestore: ${data.toString()}');

        return UserModel(
          id: userId,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phoneNumber: data['phoneNumber'] ?? '',
          bloodType: data['bloodType'] ?? 'A+',
          address: data['address'] ?? '',
          city: data['city'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          isAvailableToDonate: data['isAvailableToDonate'] ?? true,
          lastDonationDate:
              data['lastDonationDate'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                    data['lastDonationDate'],
                  )
                  : null,
          neverDonatedBefore: data['neverDonatedBefore'] ?? true,
        );
      }

      debugPrint('No user data found in Firestore for user ID: $userId');
      return null;
    } catch (e) {
      debugPrint('Error retrieving user data from Firestore: $e');
      rethrow;
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData(UserModel user) async {
    try {
      // Create a map of all user data to update
      final Map<String, dynamic> userData = {
        'name': user.name,
        'phoneNumber': user.phoneNumber,
        'bloodType': user.bloodType,
        'address': user.address,
        'city': user.city,
        'imageUrl': user.imageUrl,
        'isAvailableToDonate': user.isAvailableToDonate,
        'neverDonatedBefore': user.neverDonatedBefore,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Only set lastDonationDate if it's not null and user has donated before
      if (user.lastDonationDate != null && !user.neverDonatedBefore) {
        userData['lastDonationDate'] = user.lastDonationDate!.millisecondsSinceEpoch;
      } else {
        // Explicitly set to null when the user has never donated
        userData['lastDonationDate'] = null;
      }
      
      await _firestore.collection(_collection).doc(user.id).update(userData);
      
      debugPrint('User data successfully updated in Firestore');
    } catch (e) {
      debugPrint('Error updating user data in Firestore: $e');
      rethrow;
    }
  }

  // Get all donors (users who are available to donate)
  Future<List<UserModel>> getAvailableDonors() async {
    try {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('isAvailableToDonate', isEqualTo: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phoneNumber: data['phoneNumber'] ?? '',
          bloodType: data['bloodType'] ?? 'A+',
          address: data['address'] ?? '',
          city: data['city'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          isAvailableToDonate: data['isAvailableToDonate'] ?? true,
          lastDonationDate:
              data['lastDonationDate'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                    data['lastDonationDate'],
                  )
                  : null,
          neverDonatedBefore: data['neverDonatedBefore'] ?? true,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get donors by blood type
  Future<List<UserModel>> getDonorsByBloodType(String bloodType) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('isAvailableToDonate', isEqualTo: true)
              .where('bloodType', isEqualTo: bloodType)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phoneNumber: data['phoneNumber'] ?? '',
          bloodType: data['bloodType'] ?? 'A+',
          address: data['address'] ?? '',
          city: data['city'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          isAvailableToDonate: data['isAvailableToDonate'] ?? true,
          lastDonationDate:
              data['lastDonationDate'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                    data['lastDonationDate'],
                  )
                  : null,
          neverDonatedBefore: data['neverDonatedBefore'] ?? true,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Delete user data from Firestore
  Future<void> deleteUserData(String userId) async {
    try {
      debugPrint(
        'Attempting to delete user data from Firestore for user ID: $userId',
      );

      // Delete the user document
      await _firestore.collection(_collection).doc(userId).delete();

      // Note: In a production app, you might want to also delete related user data
      // such as blood requests, donations, etc.

      debugPrint('User data successfully deleted from Firestore');
    } catch (e) {
      debugPrint('Error deleting user data from Firestore: $e');
      rethrow;
    }
  }
}
