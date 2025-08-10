import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // Collection references
  static final CollectionReference _usersCollection = _firestore.collection('users');
  
  // Save or update user data in Firestore from Firebase Auth User
  static Future<void> saveUserFromAuth(auth.User user) async {
    try {
      // Get FCM token
      String? fcmToken = await _messaging.getToken();
      
      // Create user data map
      final Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'fcmToken': fcmToken,
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Save to Firestore with merge option to update existing document
      await _usersCollection.doc(user.uid).set(userData, SetOptions(merge: true));
      
      print('User data saved to Firestore: ${user.uid}');
    } catch (e) {
      print('Error saving user data to Firestore: $e');
      rethrow;
    }
  }
  
  // Save or update user data in Firestore
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final String uid = userData['uid'] as String;
      
      // Get FCM token
      String? fcmToken = await _messaging.getToken();
      
      // Add FCM token to user data
      final Map<String, dynamic> updatedUserData = {
        ...userData,
        'fcmToken': fcmToken,
        'lastLogin': FieldValue.serverTimestamp(),
      };
      
      // Save to Firestore with merge option to update existing document
      await _usersCollection.doc(uid).set(updatedUserData, SetOptions(merge: true));
      
      print('User data saved to Firestore: $uid');
    } catch (e) {
      print('Error saving user data to Firestore: $e');
      rethrow;
    }
  }
  
  // Update user's FCM token
  static Future<void> updateFcmToken(String uid) async {
    try {
      String? fcmToken = await _messaging.getToken();
      
      if (fcmToken != null) {
        await _usersCollection.doc(uid).update({
          'fcmToken': fcmToken,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        
        print('FCM token updated for user: $uid');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
  
  // Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user data from Firestore: $e');
      return null;
    }
  }
}