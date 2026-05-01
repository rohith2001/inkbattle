import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:inkbattle_frontend/services/native_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  // Android App ID: ca-app-pub-2111477197639109~2310576980
  // iOS App ID: ca-app-pub-2111477197639109~9891158883

  // Android Ad Unit IDs
  static const String androidBannerAdUnitId =
      'ca-app-pub-2111477197639109/9642912729';
  static const String androidInterstitialAdUnitId =
      'ca-app-pub-2111477197639109/8228337825';
  static const String androidRewardedAdUnitId =
      'ca-app-pub-2111477197639109/1443132698';

  // iOS Ad Unit IDs
  static const String iosBannerAdUnitId =
      'ca-app-pub-2111477197639109/6915256150';
  static const String iosInterstitialAdUnitId =
      'ca-app-pub-2111477197639109/8649028008';
  static const String iosRewardedAdUnitId =
      'ca-app-pub-2111477197639109/8649028008';
  static const String _androidBannerFloorBAdUnitId =
      'ca-app-pub-2111477197639109/6939001957';
  static const String _androidInterstitialFloorBAdUnitId =
      'ca-app-pub-2111477197639109/6793774138';
  static const String _androidRewardedFloorBAdUnitId =
      'ca-app-pub-2111477197639109/1074543594';
  static const String _iosBannerFloorBAdUnitId =
      String.fromEnvironment('ADMOB_IOS_BANNER_FLOOR_B', defaultValue: '');
  static const String _iosInterstitialFloorBAdUnitId =
      String.fromEnvironment('ADMOB_IOS_INTERSTITIAL_FLOOR_B', defaultValue: '');
  static const String _iosRewardedFloorBAdUnitId =
      String.fromEnvironment('ADMOB_IOS_REWARDED_FLOOR_B', defaultValue: '');
  static const String _adCohortPrefsKey = 'ad_ab_cohort_bucket';
  static const int _adCohortSplitPercent = 50;

  // Track initialization status
  static bool _initialized = false;

  // Persistent banner ad (app-wide, loaded once)
  static BannerAd? _persistentBannerAd;
  static bool _isBannerAdLoaded = false;
  static bool _isBannerAdLoading = false;
  static int _bannerRetryAttempt = 0;
  static const int _maxBannerRetryAttempts = 6;
  static final ValueNotifier<int> _bannerStateVersion = ValueNotifier<int>(0);
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static String? _adCohort;

  static ValueListenable<int> get bannerStateNotifier => _bannerStateVersion;
  static String get currentAdCohort => _adCohort ?? 'A';

  // Get platform-specific banner ad unit ID
  static String getBannerAdUnitId() {
    final bool isB = _adCohort == 'B';
    if (Platform.isAndroid) {
      return isB
          ? _pickCohortAdUnit(
              mainAdUnitId: androidBannerAdUnitId,
              bAdUnitId: _androidBannerFloorBAdUnitId,
              adFormat: 'banner',
              platform: 'android',
            )
          : androidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return isB
          ? _pickCohortAdUnit(
              mainAdUnitId: iosBannerAdUnitId,
              bAdUnitId: _iosBannerFloorBAdUnitId,
              adFormat: 'banner',
              platform: 'ios',
            )
          : iosBannerAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Get platform-specific interstitial ad unit ID
  static String getInterstitialAdUnitId() {
    final bool isB = _adCohort == 'B';
    if (Platform.isAndroid) {
      return isB
          ? _pickCohortAdUnit(
              mainAdUnitId: androidInterstitialAdUnitId,
              bAdUnitId: _androidInterstitialFloorBAdUnitId,
              adFormat: 'interstitial',
              platform: 'android',
            )
          : androidInterstitialAdUnitId;
    } else if (Platform.isIOS) {
      return isB
          ? _pickCohortAdUnit(
              mainAdUnitId: iosInterstitialAdUnitId,
              bAdUnitId: _iosInterstitialFloorBAdUnitId,
              adFormat: 'interstitial',
              platform: 'ios',
            )
          : iosInterstitialAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Get platform-specific rewarded ad unit ID
  static String getRewardedAdUnitId() {
    final bool isB = _adCohort == 'B';
    if (Platform.isAndroid) {
      return isB
          ? _pickCohortAdUnit(
              mainAdUnitId: androidRewardedAdUnitId,
              bAdUnitId: _androidRewardedFloorBAdUnitId,
              adFormat: 'rewarded',
              platform: 'android',
            )
          : androidRewardedAdUnitId;
    } else if (Platform.isIOS) {
      return isB
          ? _pickCohortAdUnit(
              mainAdUnitId: iosRewardedAdUnitId,
              bAdUnitId: _iosRewardedFloorBAdUnitId,
              adFormat: 'rewarded',
              platform: 'ios',
            )
          : iosRewardedAdUnitId;
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
      await _resolveAdExperimentCohort();

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
      NativeLogService.log(
        'MobileAds initialized successfully. Cohort=$currentAdCohort',
        tag: 'AdService',
        level: 'debug',
      );
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

  static Future<void> _resolveAdExperimentCohort() async {
    if (_adCohort != null) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      int bucket = prefs.getInt(_adCohortPrefsKey) ?? -1;
      if (bucket < 0 || bucket > 99) {
        bucket = Random().nextInt(100);
        await prefs.setInt(_adCohortPrefsKey, bucket);
      }
      _adCohort = bucket < _adCohortSplitPercent ? 'A' : 'B';
      await _analytics.setUserProperty(name: 'ad_ab_cohort', value: _adCohort);
      await _analytics.logEvent(
        name: 'ad_ab_initialized',
        parameters: <String, Object>{
          'cohort': _adCohort ?? 'A',
          'split_percent_a': _adCohortSplitPercent,
        },
      );
    } catch (e) {
      _adCohort = 'A';
      NativeLogService.log(
        'Failed to resolve ad cohort, defaulting to A: $e',
        tag: 'AdService',
        level: 'error',
      );
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

      final adUnitId = getRewardedAdUnitId();
      print('🔄 Loading rewarded ad with unit ID: $adUnitId');

      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            print('✅ Rewarded ad loaded successfully');
            _logAdLoadSuccess(
              adFormat: 'rewarded',
              adUnitId: adUnitId,
            );
            onAdLoaded(ad);
          },
          onAdFailedToLoad: (error) {
            print(
                '❌ Rewarded ad failed to load: ${error.code} - ${error.message}');
            print(
                '   Domain: ${error.domain}, ResponseInfo: ${error.responseInfo}');
            _logAdLoadFailure(
              adFormat: 'rewarded',
              adUnitId: adUnitId,
              error: error,
            );
            onAdFailedToLoad(error);
          },
        ),
      );
      return null; // Ad is loaded via callback
    } catch (e, stackTrace) {
      print('❌ Exception loading rewarded ad: $e');
      print('   Stack trace: $stackTrace');
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Rewarded ad load exception',
      );
      return null;
    }
  }

  // Load Interstitial Ad
  static Future<void> loadInterstitialAd({
    required void Function(InterstitialAd) onAdLoaded,
    required void Function(LoadAdError) onAdFailedToLoad,
  }) async {
    try {
      await initializeMobileAds();
      await Future.delayed(const Duration(milliseconds: 300));
      final adUnitId = getInterstitialAdUnitId();
      print('🔄 Loading interstitial ad with unit ID: $adUnitId');
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            print('✅ Interstitial ad loaded successfully');
            _logAdLoadSuccess(
              adFormat: 'interstitial',
              adUnitId: adUnitId,
            );
            onAdLoaded(ad);
          },
          onAdFailedToLoad: (error) {
            print(
                '❌ Interstitial ad failed to load: ${error.code} - ${error.message}');
            _logAdLoadFailure(
              adFormat: 'interstitial',
              adUnitId: adUnitId,
              error: error,
            );
            onAdFailedToLoad(error);
          },
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Exception loading interstitial ad: $e');
      print('   Stack trace: $stackTrace');
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Interstitial ad load exception',
      );
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
            _logAdLoadSuccess(
              adFormat: 'banner',
              adUnitId: getBannerAdUnitId(),
            );
            onAdLoaded(ad);
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print(
                '❌ Banner ad failed to load: ${error.code} - ${error.message}');
            _logAdLoadFailure(
              adFormat: 'banner',
              adUnitId: getBannerAdUnitId(),
              error: error,
            );
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
            _bannerRetryAttempt = 0;
            _notifyBannerStateChanged();
            _logAdLoadSuccess(
              adFormat: 'banner_persistent',
              adUnitId: getBannerAdUnitId(),
            );
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print(
                '❌ Persistent banner ad failed to load: ${error.code} - ${error.message}');
            _isBannerAdLoaded = false;
            _isBannerAdLoading = false;
            _notifyBannerStateChanged();
            _logAdLoadFailure(
              adFormat: 'banner',
              adUnitId: getBannerAdUnitId(),
              error: error,
            );
            _schedulePersistentBannerRetry();
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
            _notifyBannerStateChanged();
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
      _notifyBannerStateChanged();
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Persistent banner load exception',
      );
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
    _bannerRetryAttempt = 0;
    _notifyBannerStateChanged();
  }

  static void _schedulePersistentBannerRetry() {
    if (_bannerRetryAttempt >= _maxBannerRetryAttempts) {
      NativeLogService.log(
        'Banner retry cap reached, skipping further retries this session',
        tag: 'AdService',
        level: 'warning',
      );
      return;
    }
    _bannerRetryAttempt++;
    final int delaySeconds = [5, 15, 30, 60, 120, 300][_bannerRetryAttempt - 1];
    NativeLogService.log(
      'Retrying banner load in ${delaySeconds}s (attempt $_bannerRetryAttempt/$_maxBannerRetryAttempts)',
      tag: 'AdService',
      level: 'warning',
    );
    Future.delayed(Duration(seconds: delaySeconds), () {
      if (_persistentBannerAd == null && !_isBannerAdLoading) {
        loadPersistentBannerAd();
      }
    });
  }

  static void _notifyBannerStateChanged() {
    _bannerStateVersion.value = _bannerStateVersion.value + 1;
  }

  static Future<void> _logAdLoadFailure({
    required String adFormat,
    required String adUnitId,
    required LoadAdError error,
  }) async {
    final bool isNoFill = error.code == 3;
    final Map<String, Object> params = <String, Object>{
      'ad_format': adFormat,
      'ad_cohort': currentAdCohort,
      'ad_unit': _maskAdUnitId(adUnitId),
      'error_code': error.code,
      'error_domain': error.domain,
      'is_no_fill': isNoFill ? 1 : 0,
      'error_message': error.message,
    };
    try {
      await _analytics.logEvent(name: 'ad_load_failed', parameters: params);
    } catch (analyticsError) {
      NativeLogService.log(
        'Failed to write ad failure analytics event: $analyticsError',
        tag: 'AdService',
        level: 'error',
      );
    }

    if (!isNoFill) {
      FirebaseCrashlytics.instance.setCustomKey('ad_format', adFormat);
      FirebaseCrashlytics.instance
          .setCustomKey('ad_unit', _maskAdUnitId(adUnitId));
      FirebaseCrashlytics.instance.setCustomKey('ad_error_code', error.code);
      FirebaseCrashlytics.instance
          .setCustomKey('ad_error_domain', error.domain);
      FirebaseCrashlytics.instance.log(
        'Ad load failed (${error.code}): ${error.message}',
      );
    }
  }

  static Future<void> _logAdLoadSuccess({
    required String adFormat,
    required String adUnitId,
  }) async {
    final maskedUnit = _maskAdUnitId(adUnitId);
    NativeLogService.log(
      'Ad loaded successfully | format=$adFormat cohort=$currentAdCohort unit=$maskedUnit',
      tag: 'AdService',
      level: 'debug',
    );
    try {
      await _analytics.logEvent(
        name: 'ad_load_success',
        parameters: <String, Object>{
          'ad_format': adFormat,
          'ad_cohort': currentAdCohort,
          'ad_unit': maskedUnit,
        },
      );
    } catch (analyticsError) {
      NativeLogService.log(
        'Failed to write ad success analytics event: $analyticsError',
        tag: 'AdService',
        level: 'error',
      );
    }
  }

  static String _maskAdUnitId(String adUnitId) {
    if (adUnitId.length <= 6) return adUnitId;
    return '${adUnitId.substring(0, 6)}...${adUnitId.substring(adUnitId.length - 4)}';
  }

  static String _pickCohortAdUnit({
    required String mainAdUnitId,
    required String bAdUnitId,
    required String adFormat,
    required String platform,
  }) {
    if (_isValidAdUnitId(bAdUnitId)) {
      return bAdUnitId;
    }
    NativeLogService.log(
      'Invalid/empty B ad unit for $platform-$adFormat. Falling back to main unit.',
      tag: 'AdService',
      level: 'warning',
    );
    return mainAdUnitId;
  }

  static bool _isValidAdUnitId(String adUnitId) {
    final trimmed = adUnitId.trim();
    if (trimmed.isEmpty) return false;
    final RegExp adUnitPattern = RegExp(r'^ca-app-pub-\d{16}/\d{10}$');
    return adUnitPattern.hasMatch(trimmed);
  }
}
