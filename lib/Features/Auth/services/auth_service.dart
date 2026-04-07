import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // We return a String so we can easily pass back error messages,
  // or return null if the login was completely successful.
  Future<String?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Null means no errors, success!
    } on FirebaseAuthException catch (e) {
      // Return the specific Firebase error message to show in the UI
      return e.message ?? 'An unknown authentication error occurred.';
    } catch (e) {
      return 'Check your internet connection and try again.';
    }
  }

  // A handy method to check if someone is already logged in
  User? get currentUser => _auth.currentUser;

  // A method for when the cashier closes the register
  Future<void> logout() async {
    await _auth.signOut();
  }
}
