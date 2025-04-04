import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_contact_model.dart';

class FirebaseEmergencyContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'emergency_contacts';

  // Get all system emergency contacts and user's personal contacts
  Future<List<EmergencyContactModel>> getAllEmergencyContacts(
    String userId,
  ) async {
    try {
      // Get built-in contacts
      final List<EmergencyContactModel> builtInContacts =
          EmergencyContactModel.getBuiltInContacts(userId);

      // Get user's personal contacts
      final QuerySnapshot userContactsSnapshot =
          await _firestore
              .collection(_collectionPath)
              .where('userId', isEqualTo: userId)
              .orderBy('isPinned', descending: true)
              .orderBy('name')
              .get();

      final List<EmergencyContactModel> userContacts =
          userContactsSnapshot.docs
              .map(
                (doc) => EmergencyContactModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();

      // Combine built-in and user contacts
      final allContacts = [...builtInContacts, ...userContacts];

      // Sort: pinned contacts first, then alphabetically by name
      allContacts.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return a.name.compareTo(b.name);
      });

      return allContacts;
    } catch (e) {
      print('Error getting emergency contacts: $e');
      return [];
    }
  }

  // Stream of emergency contacts for real-time updates
  Stream<List<EmergencyContactModel>> getEmergencyContactsStream(
    String userId,
  ) {
    try {
      // Get built-in contacts
      final List<EmergencyContactModel> builtInContacts =
          EmergencyContactModel.getBuiltInContacts(userId);

      // Stream user's personal contacts
      return _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId)
          .orderBy('isPinned', descending: true)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
            final List<EmergencyContactModel> userContacts =
                snapshot.docs
                    .map((doc) => EmergencyContactModel.fromJson(doc.data()))
                    .toList();

            // Combine built-in and user contacts
            final allContacts = [...builtInContacts, ...userContacts];

            // Sort: pinned contacts first, then alphabetically by name
            allContacts.sort((a, b) {
              if (a.isPinned && !b.isPinned) return -1;
              if (!a.isPinned && b.isPinned) return 1;
              return a.name.compareTo(b.name);
            });

            return allContacts;
          });
    } catch (e) {
      print('Error streaming emergency contacts: $e');
      // Return an empty stream
      return Stream.value([]);
    }
  }

  // Add a new emergency contact
  Future<bool> addEmergencyContact(EmergencyContactModel contact) async {
    try {
      String contactId =
          contact.id.isEmpty
              ? _firestore.collection(_collectionPath).doc().id
              : contact.id;

      final updatedContact = contact.copyWith(
        id: contactId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_collectionPath)
          .doc(contactId)
          .set(updatedContact.toJson());

      print('Emergency contact added successfully: ${updatedContact.name}');
      return true;
    } catch (e) {
      print('Error adding emergency contact: $e');
      return false;
    }
  }

  // Update an existing emergency contact
  Future<bool> updateEmergencyContact(EmergencyContactModel contact) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(contact.id)
          .update(contact.toJson());

      print('Emergency contact updated successfully: ${contact.name}');
      return true;
    } catch (e) {
      print('Error updating emergency contact: $e');
      return false;
    }
  }

  // Delete an emergency contact
  Future<bool> deleteEmergencyContact(String contactId) async {
    try {
      await _firestore.collection(_collectionPath).doc(contactId).delete();

      print('Emergency contact deleted successfully: $contactId');
      return true;
    } catch (e) {
      print('Error deleting emergency contact: $e');
      return false;
    }
  }

  // Get only user-added emergency contacts (not built-in ones)
  Future<List<EmergencyContactModel>> getEmergencyContactsForUser(
    String userId,
  ) async {
    try {
      // Validate userId
      if (userId.isEmpty) {
        print('Error: Empty userId provided to getEmergencyContactsForUser');
        return [];
      }

      print('Getting user-added emergency contacts for user: $userId');

      // Get only user's personal contacts (not built-in ones)
      final QuerySnapshot userContactsSnapshot =
          await _firestore
              .collection(_collectionPath)
              .where('userId', isEqualTo: userId)
              .orderBy('isPinned', descending: true)
              .orderBy('name')
              .get();

      final List<EmergencyContactModel> userContacts =
          userContactsSnapshot.docs
              .map(
                (doc) => EmergencyContactModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();

      print(
        'Successfully retrieved ${userContacts.length} user-added emergency contacts',
      );
      return userContacts;
    } catch (e) {
      print('Error getting emergency contacts: $e');

      // Check if it's a Firestore index error
      if (e.toString().contains('failed-precondition') &&
          e.toString().contains('requires an index')) {
        print('Firestore index missing for emergency contacts query');
        // Return empty list
        return [];
      }

      // For other errors, return an empty list
      return [];
    }
  }

  // Toggle pin status for a contact
  Future<bool> togglePinStatus(String contactId, bool isPinned) async {
    try {
      await _firestore.collection(_collectionPath).doc(contactId).update({
        'isPinned': isPinned,
      });

      print('Updated pin status for contact $contactId to $isPinned');
      return true;
    } catch (e) {
      print('Error updating pin status: $e');
      return false;
    }
  }
}
