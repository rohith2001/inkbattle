import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dartz/dartz.dart';
import 'package:inkbattle_frontend/config/environment.dart';
import 'package:inkbattle_frontend/repositories/user_repository.dart';
import 'package:inkbattle_frontend/models/user_model.dart';
import 'package:inkbattle_frontend/utils/api/failure.dart';
import 'package:inkbattle_frontend/constants/app_images.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: Environment.googleWebClientId,
  );
  final UserRepository _userRepository = UserRepository();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google and register with backend
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Disconnect any previously connected account to force account picker
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        // Ignore errors if no account is connected
      }
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Register/Login with backend with retry logic
      // Use default avatar av3.png (same as guest signup)
      final result = await _retryBackendSignup(
        provider: 'google',
        providerId: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? 'Google User',
        avatar: AppImages.av3,
      );

      return result.fold(
        (failure) {
          print('Backend signup failed: ${failure.toString()}');
          return null;
        },
        (authResponse) => authResponse,
      );
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Retry logic with exponential backoff
  Future<Either<Failure, AuthResponse>> _retryBackendSignup({
    required String provider,
    required String providerId,
    required String name,
    String? avatar,
  }) async {
    int maxRetries = 3;
    int delayMs = 1000;

    for (int i = 0; i < maxRetries; i++) {
      try {
        final result = await _userRepository.signup(
          provider: provider,
          providerId: providerId,
          name: name,
          avatar: avatar,
        );

        // If successful, return immediately
        if (result.isRight()) {
          return result;
        }

        // If it's the last retry, return the failure
        if (i == maxRetries - 1) {
          return result;
        }

        // Wait before retrying with exponential backoff
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2; // Double the delay for next retry
      } catch (e) {
        print('Retry $i failed: $e');
        if (i == maxRetries - 1) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2;
      }
    }

    return left(ApiFailure(message: 'Max retries exceeded'));
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Get user display name
  String? getUserDisplayName() {
    return _auth.currentUser?.displayName;
  }

  // Get user email
  String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  // Get user photo URL
  String? getUserPhotoUrl() {
    return _auth.currentUser?.photoURL;
  }

  // Check if user is signed in
  bool isUserSignedIn() {
    return _auth.currentUser != null;
  }
}
