import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inkbattle_frontend/constants/app_images.dart';
import 'package:inkbattle_frontend/utils/routes/routes.dart';
import 'package:inkbattle_frontend/widgets/backgroun_scafold.dart';
import 'package:inkbattle_frontend/utils/preferences/local_preferences.dart';
import 'package:inkbattle_frontend/repositories/user_repository.dart';
import 'package:inkbattle_frontend/services/native_log_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _logTag = 'SplashScreen';
  final UserRepository _userRepository = UserRepository();
  String _version = "";

  // Adding the Version Number to Splash Screen
  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _checkAuthAndNavigate();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Check if token exists
      final token = await LocalStorageUtils.fetchToken();

      NativeLogService.log(
        'SplashScreen -> token: $token',
        tag: _logTag,
        level: 'debug',
      );
      if (token != null && token.isNotEmpty && token.trim().isNotEmpty) {
        // Token exists, verify it's valid by fetching user
        final result = await _userRepository.getMe();
        
        result.fold(
          (failure) {
            // Token invalid or expired, clear it and go to sign in
            NativeLogService.log(
              'Token validation failed: ${failure.message}',
              tag: _logTag,
              level: 'error',
            );
            if (mounted) {
              LocalStorageUtils.clear();
              context.go(Routes.signInScreen);
            }
          },
          (user) {
            // Token valid, go to home
            NativeLogService.log(
              'User authenticated, navigating to home',
              tag: _logTag,
              level: 'debug',
            );
            if (mounted) context.go(Routes.homeScreen);
          },
        );
      } else {
        // No token: if pending guest, go to Home (only Home calls ensureGuest to avoid duplicate requests)
        if (LocalStorageUtils.hasPendingGuest()) {
          if (mounted) context.go(Routes.homeScreen);
          return;
        }
        if (mounted) context.go(Routes.signInScreen);
      }
    } catch (e) {
      NativeLogService.log(
        'Error checking auth: $e',
        tag: _logTag,
        level: 'error',
      );
      // On error, go to sign in
      if (mounted) context.go(Routes.signInScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      child: Stack( // Use a Stack to place version at the bottom
        children: [
          Center(
            // child: Image.asset(AppImages.logo, 
            child: Image.asset(AppImages.splashLogo,
            width: 200.w, // Added width scaling for tablets
            fit: BoxFit.contain),
          ),
          // Responsive Version Label
          Positioned(
            bottom: 30.h, // Scales the distance from the bottom
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Version $_version",
                style: TextStyle(
                  color: Colors.white70, 
                  fontSize: 12.sp // Scales font for readability on tablets
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
