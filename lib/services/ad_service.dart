import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class AdService {
  // Android App ID: ca-app-pub-2111477197639109~2310576980
  // iOS App ID: ca-app-pub-2111477197639109~9891158883

  // Android Ad Unit IDs
  static const String androidBannerAdUnitId =
      'ca-app-pub-2111477197639109/9642912729';
  static const String androidRewardedAdUnitId =
      'ca-app-pub-2111477197639109/8228337825';

  // iOS Ad Unit IDs
  static const String iosBannerAdUnitId =
      'ca-app-pub-2111477197639109/6915256150';
  static const String iosRewardedAdUnitId =
      'ca-app-pub-2111477197639109/8649028008';

  // Track initialization status
  static bool _initialized = false;
  
  // Persistent banner ad (app-wide, loaded once)
  static BannerAd? _persistentBannerAd;
  static bool _isBannerAdLoaded = false;
  static bool _isBannerAdLoading = false;

  // Get platform-specific banner ad unit ID
  static String getBannerAdUnitId() {
    if (Platform.isAndroid) {
      return androidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return iosBannerAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Get platform-specific interstitial ad unit ID
  static String getRewardedAdUnitId() {
    if (Platform.isAndroid) {
      return androidRewardedAdUnitId;
    } else if (Platform.isIOS) {
      return iosRewardedAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Initialize Google Mobile Ads SDK
  static Future<void> initializeMobileAds() async {
    if (_initialized) {
      print('✅ MobileAds already initialized');
      return;
    }

    try {
      print('🔄 Initializing Google Mobile Ads SDK...');
      
      // On iOS we must request tracking authorization before initializing ads.
      await _requestTrackingAuthorizationIfNeeded();

      final initializationStatus = await MobileAds.instance.initialize();
      
      print('✅ MobileAds initialization completed');
      
      // Log adapter statuses for debugging
      try {
        initializationStatus.adapterStatuses.forEach((key, status) {
          print('   Adapter $key: ${status.state} - ${status.description}');
        });
      } catch (e) {
        // Adapter statuses might not be available in all versions
        print('   (Adapter status details not available)');
      }
      
      // Mark as initialized - even if some adapters aren't ready,
      // we can still attempt to load ads
      _initialized = true;
      print('✅ MobileAds SDK initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Error initializing mobile ads: $e');
      print('   Stack trace: $stackTrace');
      // Don't mark as initialized if there was an error
      // This allows retry on next call
      _initialized = false;
      // Don't rethrow - allow app to continue without ads
    }
  }

  // Request App Tracking Transparency on iOS before accessing IDFA.
  static Future<void> _requestTrackingAuthorizationIfNeeded() async {
    if (!Platform.isIOS) return;

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // Small delay recommended before showing the system prompt.
        await Future.delayed(const Duration(milliseconds: 250));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      // Log and continue; ads will fall back to non-personalized if needed.
      print('ATT request failed: $e');
    }
  }

  // Load Rewarded Ad
  static Future<RewardedAd?> loadRewardedAd({
    required void Function(LoadAdError) onAdFailedToLoad,
    required void Function(RewardedAd) onAdLoaded,
  }) async {
    try {
      // CRITICAL: Ensure MobileAds is initialized before loading ads
      await initializeMobileAds();
      
      // Add a small delay to ensure initialization is complete
      await Future.delayed(const Duration(milliseconds: 300));
      
      print('🔄 Loading rewarded ad with unit ID: ${getRewardedAdUnitId()}');
      
      await RewardedAd.load(
        adUnitId: getRewardedAdUnitId(),
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            print('✅ Rewarded ad loaded successfully');
            onAdLoaded(ad);
          },
          onAdFailedToLoad: (error) {
            print('❌ Rewarded ad failed to load: ${error.code} - ${error.message}');
            print('   Domain: ${error.domain}, ResponseInfo: ${error.responseInfo}');
            onAdFailedToLoad(error);
          },
        ),
      );
      return null; // Ad is loaded via callback
    } catch (e, stackTrace) {
      print('❌ Exception loading rewarded ad: $e');
      print('   Stack trace: $stackTrace');
      // Call the error callback with a generic error
      onAdFailedToLoad(error) {
        print('❌ Rewarded ad failed to load: ${error.code} - ${error.message}');
      }
      return null;
    }
  }

  // Load Banner Ad
  static Future<BannerAd?> loadBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) async {
    try {
      // CRITICAL: Ensure MobileAds is initialized before loading ads
      await initializeMobileAds();
      
      // Add a small delay to ensure initialization is complete
      await Future.delayed(const Duration(milliseconds: 300));
      
      final bannerAd = BannerAd(
        adUnitId: getBannerAdUnitId(),
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            print('✅ Banner ad loaded successfully');
            onAdLoaded(ad);
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print('❌ Banner ad failed to load: ${error.code} - ${error.message}');
            onAdFailedToLoad(ad, error);
          },
        ),
      );

      await bannerAd.load();
      return bannerAd;
    } catch (e, stackTrace) {
      print('❌ Exception loading banner ad: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  // Load persistent banner ad (app-wide, loaded once at startup)
  static Future<void> loadPersistentBannerAd() async {
    // Don't reload if already loaded or currently loading
    if (_persistentBannerAd != null || _isBannerAdLoading) {
      print('ℹ️ Banner ad already loaded or loading in progress');
      return;
    }

    _isBannerAdLoading = true;
    
    try {
      // CRITICAL: Ensure MobileAds is initialized before loading ads
      await initializeMobileAds();
      
      // Add a small delay to ensure initialization is complete
      await Future.delayed(const Duration(milliseconds: 300));
      
      // print('🔄 Loading p ersistent banner ad with unit ID: ${getBannerAdUnitId()}');
      
      final bannerAd = BannerAd(
        adUnitId: getBannerAdUnitId(),
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            print('✅ Persistent banner ad loaded successfully');
            _persistentBannerAd = ad as BannerAd;
            _isBannerAdLoaded = true;
            _isBannerAdLoading = false;
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print('❌ Persistent banner ad failed to load: ${error.code} - ${error.message}');
            _isBannerAdLoaded = false;
            _isBannerAdLoading = false;
            // Try to reload after a delay (exponential backoff)
            Future.delayed(const Duration(seconds: 5), () {
              if (_persistentBannerAd == null && !_isBannerAdLoading) {
                print('🔄 Retrying persistent banner ad load...');
                loadPersistentBannerAd();
              }
            });
          },
          onAdOpened: (Ad ad) {
            print('📱 Persistent banner ad opened');
          },
          onAdClosed: (Ad ad) {
            print('📱 Persistent banner ad closed');
            // Reload the ad when it's closed
            _persistentBannerAd?.dispose();
            _persistentBannerAd = null;
            _isBannerAdLoaded = false;
            loadPersistentBannerAd();
          },
        ),
      );

      await bannerAd.load();
    } catch (e, stackTrace) {
      print('❌ Exception loading persistent banner ad: $e');
      print('   Stack trace: $stackTrace');
      _isBannerAdLoading = false;
      _isBannerAdLoaded = false;
    }
  }

  // Get the persistent banner ad (for use in screens)
  static BannerAd? getPersistentBannerAd() {
    return _persistentBannerAd;
  }

  // Check if banner ad is loaded
  static bool isBannerAdLoaded() {
    return _isBannerAdLoaded && _persistentBannerAd != null;
  }

  // Dispose persistent banner ad (call on app shutdown)
  static void disposePersistentBannerAd() {
    print('🗑️ Disposing persistent banner ad');
    _persistentBannerAd?.dispose();
    _persistentBannerAd = null;
    _isBannerAdLoaded = false;
    _isBannerAdLoading = false;
  }
}
