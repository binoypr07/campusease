import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -----------------------------------------------------------
  // LOGIN
  // -----------------------------------------------------------
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = result.user;

      if (user == null) return null;

      // Check if approved (exists in "users")
      var doc = await _db.collection("users").doc(user.uid).get();

      if (!doc.exists) {
        print("User pending approval.");
        return null;
      }

      return user;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  // -----------------------------------------------------------
  // REGISTER USER (GOES TO pendingUsers)
  // -----------------------------------------------------------
  Future<User?> registerUser(
    String email,
    String password,
    Map<String, dynamic> data,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = result.user;

      if (user == null) return null;

      // Store user details in pendingUsers
      await _db.collection("pendingUsers").doc(user.uid).set(data);

      return user;
    } catch (e) {
      print("Register error: $e");
      return null;
    }
  }

  // -----------------------------------------------------------
  // APPROVE USER
  // -----------------------------------------------------------
  Future<void> approveUser(String uid, Map<String, dynamic> data) async {
    try {
      // Move user to "users"
      await _db.collection("users").doc(uid).set(data);

      // Delete from pending
      await _db.collection("pendingUsers").doc(uid).delete();

      print("User approved successfully");
    } catch (e) {
      print("Approve user error: $e");
    }
  }

  // -----------------------------------------------------------
  // STORE EXTRA TEACHER DATA
  // -----------------------------------------------------------
  Future<void> addExtraTeacherData(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection("pendingUsers").doc(uid).update(data);
    } catch (e) {
      print("Teacher extra data error: $e");
    }
  }

  // -----------------------------------------------------------
  // GET USER ROLE (admin / teacher / student)
  // -----------------------------------------------------------
  Future<Map<String, dynamic>?> getUserRole(String uid) async {
    var snap = await _db.collection("users").doc(uid).get();
    if (!snap.exists) return null;
    return snap.data(); // return MAP
  }
}
