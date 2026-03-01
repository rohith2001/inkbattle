import 'package:dartz/dartz.dart';
import 'package:inkbattle_frontend/constants/api_end_points.dart';
import 'package:inkbattle_frontend/models/user_model.dart';
import 'package:inkbattle_frontend/utils/api/api_exceptions.dart';
import 'package:inkbattle_frontend/utils/api/api_manager.dart';
import 'package:inkbattle_frontend/utils/api/failure.dart';
import 'package:inkbattle_frontend/utils/preferences/local_preferences.dart';
import 'dart:convert';

class UserRepository {
  final ApiManager _apiManager = ApiManager();

  // Google/Facebook Signup
  Future<Either<Failure, AuthResponse>> signup({
    required String provider,
    required String providerId,
    required String name,
    String? avatar,
    String? language,
    String? country,
  }) async {
    try {
      var payload = {
        "provider": provider,
        "providerId": providerId,
        "name": name,
        "avatar": avatar,
        "language": language,
        "country": country,
      };

      var jsonResponse = await _apiManager.post(
        ApiEndPoints.signup,
        payload,
        isTokenMandatory: false,
      );

      var authResponse = AuthResponse.fromJson(jsonResponse);

      // Save token locally
      if (authResponse.token != null) {
        await LocalStorageUtils.saveUserDetails(authResponse.token!);
      }

      return right(authResponse);
    } on AppException catch (e) {
      return left(ApiFailure(message: e.message));
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  // Guest Signup (find-or-create by providerId; used for lazy creation)
  Future<Either<Failure, AuthResponse>> guestSignup({
    required String name,
    String? providerId,
    String? avatar,
    String? language,
    String? country,
  }) async {
    try {
      final effectiveProviderId =
          providerId ?? "guest_${DateTime.now().millisecondsSinceEpoch}";
      var payload = {
        "provider": "guest",
        "providerId": effectiveProviderId,
        "name": name,
        "avatar": avatar,
        "language": language,
        "country": country,
      };

      var jsonResponse = await _apiManager.post(
        ApiEndPoints.signup,
        payload,
        isTokenMandatory: false,
      );

      var authResponse = AuthResponse.fromJson(jsonResponse);

      // Save token locally
      if (authResponse.token != null) {
        await LocalStorageUtils.saveUserDetails(authResponse.token!);
      }

      return right(authResponse);
    } on AppException catch (e) {
      return left(ApiFailure(message: e.message));
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  // Get current user profile
  Future<Either<Failure, UserModel>> getMe() async {
    try {
      var jsonResponse = await _apiManager.get(
        ApiEndPoints.getMe,
        isTokenMandatory: true,
      );

      var userResponse = UserResponse.fromJson(jsonResponse);

      // Save user data locally
      if (userResponse.user != null) {
        await _saveUserLocally(userResponse.user!);
      }

      return right(userResponse.user!);
    } on AppException catch (e) {
      return left(ApiFailure(message: e.message));
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  // Update profile
  Future<Either<Failure, UserModel>> updateProfile({
    String? name,
    String? avatar,
    String? language,
    String? country,
  }) async {
    try {
      var payload = {
        "name": name,
        "avatar": avatar,
        "language": language,
        "country": country,
      };

      var jsonResponse = await _apiManager.post(
        ApiEndPoints.updateProfile,
        payload,
        isTokenMandatory: true,
      );

      var userModel = UserModel.fromJson(jsonResponse['user']);

      // Update local storage
      await _saveUserLocally(userModel);

      return right(userModel);
    } on AppException catch (e) {
      return left(ApiFailure(message: e.message));
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  // Logout
  Future<Either<Failure, bool>> logout() async {
    try {
      await _apiManager.post(
        ApiEndPoints.logout,
        {},
        isTokenMandatory: true,
      );

      // Clear local storage
      await LocalStorageUtils.clear();
      token = "";

      return right(true);
    } on AppException catch (e) {
      return left(ApiFailure(message: e.message));
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  // Add coins
  Future<Either<Failure, UserModel>> addCoins({
    required int amount,
    String? reason,
  }) async {
    try {
      var payload = {
        "amount": amount,
        "reason": reason ?? "manual",
      };

      var jsonResponse = await _apiManager.post(
        ApiEndPoints.addCoins,
        payload,
        isTokenMandatory: true,
      );

      var userModel = UserModel.fromJson(jsonResponse['user']);

      // Update local storage
      await _saveUserLocally(userModel);

      return right(userModel);
    } on AppException catch (e) {
      return left(ApiFailure(message: e.message));
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  // Save user data locally
  Future<void> _saveUserLocally(UserModel user) async {
    final userData = json.encode(user.toJson());
    await LocalStorageUtils.instance.setString('user_data', userData);
  }

  // Get user data from local storage
  Future<UserModel?> getUserLocally() async {
    try {
      final userData = LocalStorageUtils.instance.getString('user_data');
      if (userData != null && userData.isNotEmpty) {
        return UserModel.fromJson(json.decode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await LocalStorageUtils.fetchToken();
    return token != null && token.isNotEmpty;
  }

  /// Ensures a guest user exists on the server (lazy creation).
  /// If no token but pending guest prefs exist, creates/finds guest and saves token.
  Future<bool> ensureGuest() async {
    if (await isLoggedIn()) return true;
    final pending = LocalStorageUtils.getPendingGuest();
    if (pending == null) return false;
    final result = await guestSignup(
      name: pending['name'] ?? 'Guest',
      providerId: pending['localGuestId'],
      avatar: pending['avatar'],
      language: pending['language'],
      country: pending['country'],
    );
    return result.fold((_) => false, (_) => true);
  }

  // Claim daily login bonus
  Future<Either<Failure, Map<String, dynamic>>> claimDailyBonus() async {
    try {
      var jsonResponse = await _apiManager.post(
        ApiEndPoints.claimDailyBonus,
        {},
        isTokenMandatory: true,
      );

      // Update local user data with new coins
      if (jsonResponse['user'] != null) {
        var userModel = UserModel.fromJson(jsonResponse['user']);
        await _saveUserLocally(userModel);
      }

      return right(jsonResponse);
    } on AppException catch (e) {
      return left(ApiFailure(message: e.message));
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  // Check daily bonus status
  Future<Either<Failure, Map<String, dynamic>>> getDailyBonusStatus() async {
    try {
      var jsonResponse = await _apiManager.get(
        ApiEndPoints.dailyBonusStatus,
        isTokenMandatory: true,
      );

      return right(jsonResponse);
    } on AppException catch (e) {
      return left(ApiFailure(message: e.message));
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  // Claim ad reward
  Future<Either<Failure, Map<String, dynamic>>> claimAdReward({
    String? adType,
  }) async {
    try {
      var payload = {
        "adType": adType ?? "interstitial",
      };

      var jsonResponse = await _apiManager.post(
        ApiEndPoints.claimAdReward,
        payload,
        isTokenMandatory: true,
      );

      // Update local user data with new coins
      if (jsonResponse['user'] != null) {
        var userModel = UserModel.fromJson(jsonResponse['user']);
        await _saveUserLocally(userModel);
      }

      return right(jsonResponse);
    } on AppException catch (e) {
      return left(ApiFailure(message: e.message));
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  // Get all supported languages
  Future<Either<Failure, List<Map<String, dynamic>>>> getLanguages() async {
    try {
      var jsonResponse = await _apiManager.get(
        ApiEndPoints.getLanguages,
        isTokenMandatory: true,
      );

      List<dynamic> languagesList = jsonResponse['languages'] ?? [];
      List<Map<String, dynamic>> languages =
          languagesList.map((lang) => lang as Map<String, dynamic>).toList();

      return right(languages);
    } on AppException catch (e) {
      return left(ApiFailure(message: e.message));
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  /// [reportType] 'user' = report member (behavior): first time criteria = exit. 'drawing' = report drawer: 1st strike = abort drawing, 2nd = exit.
  Future<Either<Failure, bool>> reportUser({
    required String roomId,
    required int userToBlockId,
    String reportType = 'user',
  }) async {
    try {
      await _apiManager.post(
        ApiEndPoints.report,
        {
          'roomId': roomId,
          'userToBlockId': userToBlockId,
          'reportType': reportType,
        },
        isTokenMandatory: true,
      );

      return right(true);
    } on AppException catch (e) {
      return left(ApiFailure(message: e.message));
    } catch (e) {
      // Catch any other unexpected errors
      return left(
          ApiFailure(message: 'Unknown error occurred: ${e.toString()}'));
    }
  }
}
