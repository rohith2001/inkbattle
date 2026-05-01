import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:inkbattle_frontend/services/ad_service.dart';

/// A widget that displays the persistent banner ad at the bottom of the screen.
/// The banner ad is loaded once at app startup and persists across all screens.
class PersistentBannerAdWidget extends StatefulWidget {
  const PersistentBannerAdWidget({super.key});

  @override
  State<PersistentBannerAdWidget> createState() =>
      _PersistentBannerAdWidgetState();
}

class _PersistentBannerAdWidgetState extends State<PersistentBannerAdWidget> {
  @override
  void initState() {
    super.initState();
    // Ensure banner ad is loading if not already loaded
    if (!AdService.isBannerAdLoaded()) {
      AdService.loadPersistentBannerAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AdService.bannerStateNotifier,
      builder: (context, _, __) {
        final bannerAd = AdService.getPersistentBannerAd();
        final isLoaded = AdService.isBannerAdLoaded();

        if (isLoaded && bannerAd != null) {
          return Container(
            width: double.infinity,
            height: 60.h,
            color: Colors.black.withOpacity(0.3),
            child: AdWidget(ad: bannerAd),
          );
        }

        // Show loading placeholder while ad is loading
        return Container(
          width: double.infinity,
          height: 60.h,
          color: Colors.grey.withOpacity(0.2),
          child: Center(
            child: Text(
              'Loading ads...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.sp,
              ),
            ),
          ),
        );
      },
    );
  }
}
