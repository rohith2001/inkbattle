import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:inkbattle_frontend/constants/app_images.dart';
import 'package:inkbattle_frontend/presentations/home/bloc/settings_bloc.dart';
import 'package:inkbattle_frontend/widgets/custom_svg.dart';
import 'package:inkbattle_frontend/utils/preferences/local_preferences.dart';
import 'package:inkbattle_frontend/utils/routes/routes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:inkbattle_frontend/repositories/user_repository.dart';
import 'package:inkbattle_frontend/utils/lang.dart';
import 'package:inkbattle_frontend/logic/auth/google_auth_service.dart';
import 'package:inkbattle_frontend/logic/auth/facebook_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkbattle_frontend/widgets/persistent_banner_ad_widget.dart';
import 'package:inkbattle_frontend/services/ad_service.dart';
import 'package:inkbattle_frontend/services/native_log_service.dart';
import 'dart:developer' as developer;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final String _logTag = 'SettingsScreen';
  double soundValue = 0.5;
  final UserRepository _userRepo = UserRepository();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final FacebookAuthService _facebookAuthService = FacebookAuthService();
  final instagramUrl = Uri.parse(
      'https://www.instagram.com/inkbattleofficial?igsh=MThvcDY5ZjhsbHRoaA==');

  final youtubeUrl = Uri.parse('https://www.youtube.com/@RLCommunity-sx6mt');

  final twitterUrl = Uri.parse('https://x.com/RLCommunity0');
  final deleteAccountUrl = Uri.parse('https://forms.gle/wpY1drhr76rHwBGU7');

  @override
  void initState() {
    super.initState();
    // Ensure banner ad is loaded when settings screen opens
    _loadBannerAd();
  }

  // Load banner ad if not already loaded
  Future<void> _loadBannerAd() async {
    try {
      // Check if banner ad is already loaded
      if (!AdService.isBannerAdLoaded()) {
        // Load the persistent banner ad
        await AdService.loadPersistentBannerAd();
      }
    } catch (e) {
      NativeLogService.log('Error loading banner ad in settings screen: $e', tag: _logTag, level: 'error');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
        key: ValueKey(AppLocalizations
            .getCurrentLanguage()), // Force rebuild on language change
        backgroundColor: const Color(0xFF1A2A44),
        body: SafeArea(
          bottom: true, // Protect bottom for ad visibility
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 15.h, horizontal: 8.w),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: CustomSvgImage(
                                  imageUrl: AppImages.arrow_back,
                                  height: isTablet ? 32 : 25,
                                  width: isTablet ? 32 : 25,
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    AppLocalizations.settings,
                                    style: GoogleFonts.lato(
                                      color: Colors.white,
                                      fontSize: isTablet ? 32 : 30.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )),
                      SizedBox(height: 15.h),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Added spacers in scroll view might be tricky,
                              // better to use SizedBox for consistent spacing
                              SizedBox(height: 20.h),
                              
                              _buildButton(context, AppLocalizations.sound,
                                  Icons.volume_up, () {}, true),
                              SizedBox(height: 15.h),
                              _buildButton(
                                  context,
                                  AppLocalizations.profileAndAccounts,
                                  Icons.person, () async {
                                final result =
                                    await context.push(Routes.profileEditScreen);
                                // If language was changed, trigger rebuild
                                if (result == true && mounted) {
                                  setState(() {});
                                }
                              }, false),
                              SizedBox(height: 15.h),
                              _buildButton(
                                  context,
                                  AppLocalizations.privacyAndSafety,
                                  Icons.privacy_tip, () {
                                context.push(Routes.privacySafetyScreen);
                              }, false),
                              SizedBox(height: 15.h),
                              _buildButton(context, AppLocalizations.contact,
                                  Icons.email, () {}, false),
                              SizedBox(height: 15.h),
                              _buildButton(context, AppLocalizations.deleteAccount,
                                  Icons.delete_forever, () async {
                                    if (await canLaunchUrl(deleteAccountUrl)) {
                                      await launchUrl(deleteAccountUrl,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  }, false),
                              SizedBox(height: 15.h),
                              _buildButton(context, AppLocalizations.logout,
                                  Icons.logout, () {
                                    _handleLogout(context);
                                  }, false),

                              SizedBox(height: 30.h),
                              
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                child: Column(
                                  children: [
                                    Text(
                                      AppLocalizations.connectUsAt,
                                      style: GoogleFonts.lato(
                                        color: const Color(0xFF90C1D6),
                                        fontSize: isTablet ? 24 : 20.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CustomSvgImage(
                                          onTap: () async {
                                            if (await canLaunchUrl(twitterUrl)) {
                                              await launchUrl(twitterUrl,
                                                  mode: LaunchMode.externalApplication);
                                            }
                                          },
                                          imageUrl: AppImages.twitterSvg,
                                          width: isTablet ? 30 : 22.w,
                                          height: isTablet ? 30 : 22.h,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 15.w),
                                        CustomSvgImage(
                                          onTap: () async {
                                            if (await canLaunchUrl(youtubeUrl)) {
                                              await launchUrl(youtubeUrl,
                                                  mode: LaunchMode.externalApplication);
                                            }
                                          },
                                          imageUrl: AppImages.youtubeSvg,
                                          width: isTablet ? 30 : 22.w,
                                          height: isTablet ? 30 : 21.h,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 15.w),
                                        CustomSvgImage(
                                          onTap: () async {
                                            if (await canLaunchUrl(instagramUrl)) {
                                              await launchUrl(instagramUrl,
                                                  mode: LaunchMode.externalApplication);
                                            }
                                          },
                                          imageUrl: AppImages.instaSvg,
                                          width: isTablet ? 30 : 22.w,
                                          height: isTablet ? 30 : 22.h,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10.h),
                                    Text(
                                      '${AppLocalizations.version} 1.0.0',
                                      style: GoogleFonts.lato(
                                        color: const Color(0xFF869998),
                                        fontSize: isTablet ? 18 : 16.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Extra space for potential bottom navigation or ad overlap
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Persistent Banner Ad (app-wide, loaded once)
              const PersistentBannerAdWidget(),
            ],
          ),
        ),
    );
  }

Widget _buildButton(
  BuildContext context,
  String text,
  IconData iconData,
  VoidCallback onPressed,
  bool soundControl,
) {
  final width = MediaQuery.of(context).size.width;
  final bool isTablet = width >= 600;

  final double maxWidth = isTablet ? 500 : 340;
  final double height = isTablet ? 100 : 56;
  final double iconSize = isTablet ? 35 : 24;
  final double fontSize = isTablet ? 30 : 16;

  return Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        height: height,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: soundControl ? null : onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage(AppImages.bluebutton),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [

                /// ICON
                if (soundControl)
                  BlocSelector<SettingsBloc, SettingsState, double>(
                    selector: (state) => state.soundValue,
                    builder: (_, soundValue) {

                      final icon = soundValue == 0
                          ? Icons.volume_off
                          : soundValue < 0.5
                              ? Icons.volume_down
                              : Icons.volume_up;

                      return Icon(
                        icon,
                        color: Colors.white,
                        size: iconSize,
                      );
                    },
                  )
                else
                  Icon(iconData,
                      color: Colors.white,
                      size: iconSize),

                const SizedBox(width: 24),

                /// TEXT
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                /// SLIDER
                if (soundControl)
                  SizedBox(
                    width: isTablet ? 140 : 100,
                    child: BlocSelector<SettingsBloc, SettingsState, double>(
                      selector: (state) => state.soundValue,
                      builder: (context, soundValue) {
                        return Slider(
                          value: soundValue,
                          min: 0.0,
                          max: 1.0,

                          /// ⭐ reduces event spam dramatically
                          divisions: 20,

                          activeColor: Colors.white,
                          inactiveColor: Colors.white30,
                          onChanged: (v) {
                            context
                                .read<SettingsBloc>()
                                .add(UpdateSoundValue(v));
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2A44),
          title: Text(
            AppLocalizations.logout,
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            AppLocalizations.areYouSureLogout,
            style: GoogleFonts.lato(
              color: Colors.white70,
              fontSize: 16.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                AppLocalizations.cancel,
                style: GoogleFonts.lato(
                  color: Colors.white70,
                  fontSize: 14.sp,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await _userRepo.logout();
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(
                AppLocalizations.logout,
                style: GoogleFonts.lato(
                  color: Colors.red,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      // Sign out from Google and Facebook
      try {
        await _googleAuthService.signOut();
      } catch (e) {
        NativeLogService.log('Error signing out from Google: $e', tag: _logTag, level: 'error');
      }
      try {
        await _facebookAuthService.signOut();
      } catch (e) {
        NativeLogService.log('Error signing out from Facebook: $e', tag: _logTag, level: 'error');
      }

      // Clear all stored data - ensure everything is cleared
      await LocalStorageUtils.clear();

      // Force clear again to ensure all preferences are removed
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Reset language to default after clearing
      AppLocalizations.setLanguage('en');

      // Navigate to sign in screen
      if (context.mounted) {
        context.go(Routes.signInScreen);
      }
    }
  }
}
