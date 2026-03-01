import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inkbattle_frontend/constants/app_colors.dart';
import 'package:inkbattle_frontend/constants/app_images.dart';
import 'package:inkbattle_frontend/widgets/backgroun_scafold.dart';
import 'package:inkbattle_frontend/widgets/text_widget.dart';
import 'package:inkbattle_frontend/widgets/textformfield_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:inkbattle_frontend/utils/routes/routes.dart';
import 'package:inkbattle_frontend/widgets/topCoins.dart';
import 'package:inkbattle_frontend/repositories/user_repository.dart';
import 'package:video_player/video_player.dart';
import 'package:inkbattle_frontend/utils/lang.dart';
import 'package:inkbattle_frontend/utils/preferences/local_preferences.dart';
import 'package:inkbattle_frontend/widgets/country_picker_widget.dart';
import 'package:inkbattle_frontend/services/native_log_service.dart';
import 'package:inkbattle_frontend/presentations/room_preferences/widgets/selection_bottom_sheet.dart';
import 'package:country_picker/country_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class GuestSignUpScreen extends StatefulWidget {
  const GuestSignUpScreen({super.key});

  @override
  State<GuestSignUpScreen> createState() => _GuestSignUpScreenState();
}

class _GuestSignUpScreenState extends State<GuestSignUpScreen>
    with TickerProviderStateMixin {
  final String _logTag = 'GuestSignUpScreen';
  final UserRepository _userRepository = UserRepository();
  late final TextEditingController _usernameController;
  final FocusNode _usernameFocusNode = FocusNode();
  String? selectedLanguage;
  String? selectedCountry;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int selectedAvatarIndex = 2;
  String? selectedProfilePhoto = AppImages.av3;
  bool showAvatarSelection = false;
  bool _isSubmitting = false;
  bool _showFieldErrors = false;
  List<String> avatarsURLs = [
    AppImages.av1,
    AppImages.av2,
    AppImages.av3,
    AppImages.av4,
    AppImages.av5,
  ];

  late AnimationController _controller;
  late AnimationController _avatarMoveController;
  late List<Animation<Offset>> _coinDrops;
  late Animation<double> _textOpacity;
  VideoPlayerController? _videoController;
  final random = Random();

  // Avatar animation variables
  int? _movingAvatarIndex;
  final GlobalKey _centerAvatarKey = GlobalKey();

// Countries are now handled via CountryPickerWidget with ISO-2 codes

  void _selectAvatar(int index) {
    if (_movingAvatarIndex != null) return; // Prevent multiple animations

    setState(() {
      _movingAvatarIndex = index;
      selectedAvatarIndex = index;
    });

    // Reset the controller before starting animation
    _avatarMoveController.reset();

    // Start the move animation
    _avatarMoveController.forward().then((_) {
      // Update the profile photo after animation completes
      setState(() {
        if (index <= avatarsURLs.length - 1) {
          selectedProfilePhoto = avatarsURLs[index];
        } else {
          selectedProfilePhoto = null;
        }
        _movingAvatarIndex = null;
        // showAvatarSelection = false;  // COMMENT THIS LINE TO KEEP SELECTION OPEN
      });
      // Trigger rebuild to update button state
      if (mounted) setState(() {});
    });
  }

  void _toggleAvatarSelection() {
    setState(() {
      showAvatarSelection = !showAvatarSelection;
    });
  }

  void _loadLanguage() {
    final savedLanguage = LocalStorageUtils.getLanguage();
    selectedLanguage = AppLocalizations.languageDisplayName(savedLanguage);
  }

  Future<void> _changeLanguage(String? language) async {
    if (language == null) return;

    setState(() {
      selectedLanguage = language;
    });
    if (mounted) setState(() {});

    final languageCode = AppLocalizations.languageCodeFromDisplayName(language);
    await LocalStorageUtils.saveLanguage(languageCode);
    AppLocalizations.setLanguage(languageCode);

    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();

    // Load saved language
    _loadLanguage();

    _usernameController = TextEditingController(
      text: 'Guest_${random.nextInt(99999).toString().padLeft(5, '0')}',
    );
    // Add listener to update button state when username changes
    _usernameController.addListener(() {
      if (mounted) setState(() {});
    });

    // Main animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) context.go(Routes.homeScreen);
        });
      }
    });

    // Avatar move animation controller
    _avatarMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _coinDrops = [];
    _textOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.80, 1.0, curve: Curves.easeIn),
    );
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(
      'asset/animationVideos/coin_reward_animation.mp4',
    );
    await _videoController!.initialize();
    _videoController!.setLooping(false);
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final random = Random();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final stackWidth = screenWidth * 0.6;
    final stackHeight = screenHeight * 0.4;
    final childSize = screenWidth * 0.1;
    final radius = min(stackWidth, stackHeight) * 0.15;

    _coinDrops = List.generate(20, (i) {
      final angle =
          (i * 2 * pi / 20) + (random.nextDouble() * pi / 10 - pi / 20);
      final endDx = (radius * cos(angle)) / childSize;
      final endDy = (radius * sin(angle)) / childSize;
      final beginDx = random.nextDouble() * 4 - 2;
      final beginDy = -(stackHeight / childSize) - (random.nextDouble() * 2);

      return Tween<Offset>(
        begin: Offset(beginDx, beginDy),
        end: Offset(endDx, endDy),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(i * 0.05, 1.0, curve: Curves.easeOut),
      ));
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    _pageController.dispose();
    _controller.dispose();
    _avatarMoveController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      child: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 2,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
          if (index == 1) {
            _controller.forward(from: 0);
            if (_videoController != null &&
                _videoController!.value.isInitialized) {
              _videoController!.seekTo(Duration.zero);
              _videoController!.play();
            }
          }
        },
        itemBuilder: (context, index) {
          if (index == 0) return _buildFirstPage();
          return _buildSecondPage();
        },
      ),
    );
  }


  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedProfilePhoto = image.path; // Use path for local file
        selectedAvatarIndex = -1; // Deselect preset avatars
      });
    }
  }

  static const double _kTabletMaxWidth = 600;

  Widget _buildFirstPage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    double contentWidth = isTablet ? _kTabletMaxWidth : screenWidth;
    List<Widget> avatars = List.generate(5, (index) {
      return Container();
    });
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 10.h),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: isTablet ? 52.w : 40.w,
                      height: isTablet ? 52.w : 40.w,
                      color: Colors.transparent,
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: isTablet ? 28.sp : 22.sp,
                      ),
                    ),
                  ),
                  const CoinContainer(coins: 0),
                ],
              ),
            ),
            const Spacer(flex: 1),
            Flexible(
              flex: 8,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 700 : double.infinity,
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    child: SizedBox(
                      width: contentWidth,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 0.0 : 20.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  // Main Profile Avatar
                                  Container(
                                    key: _centerAvatarKey,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: isTablet ? _showTabletAvatarSelectionSheet : _showTabletAvatarSelectionSheet,
                                      child: Container(
                                        clipBehavior: Clip.hardEdge,
                                        height: isTablet ? 160.h : 120.h,
                                        width: isTablet ? 160.w : 120.w,
                                        padding: EdgeInsets.all(2.w),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF09BDFF),
                                              Color(0xFF6FE4FF),
                                              Color(0xFFFFFFFF),
                                            ],
                                          ),
                                        ),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black,
                                          ),
                                          child: ClipOval(
                                            clipBehavior: Clip.hardEdge,
                                            child: SizedBox(
                                              width: isTablet ? 150.r : 110.r,
                                              height: isTablet ? 150.r : 110.r,
                                              child: _buildAvatarImage(isTablet),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                    if (!showAvatarSelection || isTablet)
                                    Positioned(
                                      bottom: isTablet ? 10.h : 0.h,
                                      right: isTablet ? 0 : 0.w,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: isTablet ? _showTabletAvatarSelectionSheet : _showTabletAvatarSelectionSheet,
                                        child: Container(
                                          height: isTablet ? 45.h : 40.h,
                                          width: isTablet ? 45.w : 40.w,
                                          decoration: const BoxDecoration(
                                            color: Color.fromRGBO(217, 217, 217, 1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Image.asset(
                                              AppImages.pencil,
                                              height: isTablet ? 30.h : 24.h,
                                              width: isTablet ? 30.w : 24.w,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Avatar Selection Options (mobile only; tablet uses bottom sheet)
                                  if (showAvatarSelection && !isTablet)
                                    _buildAvatarSelectionStack(
                                        avatars, isTablet ? contentWidth * 0.12 : contentWidth * 0.15, contentWidth, isTablet),

                                  // Moving Avatar Animation
                                  if (_movingAvatarIndex != null)
                                    _buildMovingAvatar(
                                        _movingAvatarIndex!, contentWidth, isTablet),
                                ],
                              ),
                            ),

                          
                          SizedBox(height: isTablet ? 40.h : 20.h),
                          if (_showFieldErrors && selectedProfilePhoto == null) ...[
                            Padding(
                              padding: EdgeInsets.only(left: 4.w),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red, size: 16.sp),
                                  SizedBox(width: 6.w),
                                  Text(AppLocalizations.pleaseSelectAnAvatar, style: TextStyle(color: Colors.red, fontSize: 12.sp)),
                                ],
                              ),
                            ),
                            SizedBox(height: 8.h),
                          ],
                          // Form Fields Section (full width of container on tablet)
                          SizedBox(
                            width: contentWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextformFieldWidget(
                                  readOnly: false,
                                  controller: _usernameController,
                                  focusNode: _usernameFocusNode,
                                  height: isTablet ? 60.h : 50.h,
                                  rouneded: 15.r,
                                  fontSize: isTablet ? 20.sp : 18.sp,
                                  hintTextColor:
                                      const Color.fromRGBO(255, 255, 255, 0.52),
                                  hintText: AppLocalizations.enterUsername,
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.all(10.w),
                                    child: Icon(
                                      Icons.person_outline,
                                      color: const Color.fromRGBO(255, 255, 255, 0.52),
                                      size: isTablet ? 24.sp : 21.sp,
                                    ),
                                  ),
                                ),
                                if (_showFieldErrors && _usernameController.text.trim().isEmpty) ...[
                                  SizedBox(height: 4.h),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red, size: 16.sp),
                                      SizedBox(width: 6.w),
                                      Text(AppLocalizations.pleaseEnterUsername, style: TextStyle(color: Colors.red, fontSize: 12.sp)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: isTablet ? 25.h : 15.h),
                          SizedBox(
                            width: contentWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildGradientDropdown(
                                  hint: AppLocalizations.language,
                                  value: selectedLanguage,
                                  items: AppLocalizations.supportedLanguageDisplayNames,
                                  isTablet: isTablet,
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.all(12.w),
                                    child: Icon(
                                      Icons.language,
                                      color: const Color.fromRGBO(255, 255, 255, 0.52),
                                      size: isTablet ? 24.sp : 21.sp,
                                    ),
                                  ),
                                  onChanged: (val) => _changeLanguage(val),
                                ),
                                if (_showFieldErrors && selectedLanguage == null) ...[
                                  SizedBox(height: 4.h),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red, size: 16.sp),
                                      SizedBox(width: 6.w),
                                      Text(AppLocalizations.pleaseSelectAnyLanguage, style: TextStyle(color: Colors.red, fontSize: 12.sp)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: isTablet ? 25.h : 15.h),
                          isTablet
                              ? SizedBox(
                                  width: contentWidth,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildTabletCountryDropdown(),
                          if (_showFieldErrors && selectedCountry == null) ...[
                                  SizedBox(height: 4.h),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red, size: 16.sp),
                                      SizedBox(width: 6.w),
                                      Text(AppLocalizations.pleaseSelectAnyCountry, style: TextStyle(color: Colors.red, fontSize: 12.sp)),
                                    ],
                                  ),
                                ],
                                    ],
                                  ),
                                )
                              : SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CountryPickerWidget(
                                  selectedCountryCode: selectedCountry,
                                  onCountrySelected: (countryCode) {
                                    setState(() => selectedCountry = countryCode);
                                    if (mounted) setState(() {});
                                  },
                                  hintText: AppLocalizations.country,
                                  icon: Icons.public,
                                  iconColor: const Color.fromRGBO(255, 255, 255, 0.52),
                                  isTablet: isTablet,
                                  useGradientDesign: true,
                                ),
                                if (_showFieldErrors && selectedCountry == null) ...[
                                  SizedBox(height: 4.h),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red, size: 16.sp),
                                      SizedBox(width: 6.w),
                                      Text(AppLocalizations.pleaseSelectAnyCountry, style: TextStyle(color: Colors.red, fontSize: 12.sp)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: isTablet ? 40.h : 25.h),
                          InkWell(
                            onTap: (_isSubmitting || !_areAllFieldsFilled())
                                ? null
                                : _handleGuestSignup,
                            child: Opacity(
                              opacity: (_isSubmitting || !_areAllFieldsFilled())
                                  ? 0.5
                                  : 1.0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Spacer(),
                                  _isSubmitting
                                      ? SizedBox(
                                          width: isTablet ? 20.sp : 18.sp,
                                          height: isTablet ? 20.sp : 18.sp,
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: TextWidget(
                                              text: AppLocalizations.next,
                                              fontSize: isTablet ? 22.sp : 18.sp,
                                              color: AppColors.whiteColor,
                                            ),
                                          ),
                                        ),
                                  SizedBox(width: 5.w),
                                  Icon(Icons.navigate_next_outlined,
                                      color: AppColors.whiteColor,
                                      size: isTablet ? 28.sp : 22.sp),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Dynamic spacer at bottom
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(bool isTablet) {
    if (selectedProfilePhoto == null) {
      return Center(
        child: Icon(Icons.person,
            size: isTablet ? 60.sp : 50.sp, color: Colors.grey),
      );
    }
    
    // Check if it's a local file or asset
    bool isLocalFile = !avatarsURLs.contains(selectedProfilePhoto);
    
    if (isLocalFile) {
       return Padding(
         padding: EdgeInsets.all(isTablet ? 0.0 : 0.0), // Fill circle
         child: Image.file(
           File(selectedProfilePhoto!),
           fit: BoxFit.cover,
         ),
       );
    } else {
      return Padding(
        padding: EdgeInsets.all(isTablet ? 30.0 : 20.0),
        child: Image.asset(
          selectedProfilePhoto!,
          fit: BoxFit.contain,
        ),
      );
    }
  }

  Widget _buildAvatarSelectionStack(
      List<Widget> avatars, double size, double contentWidth, bool isTablet) {
    double centerX = contentWidth * 0.5;
    double centerY = isTablet ? 0.12.sh : 0.17.sh;

    // 4 bubble positions - adjusted for tablet view
    final bubblePositions = isTablet
        ? [
            {'x': centerX - contentWidth * 0.28, 'y': centerY}, // Top left
            {
              'x': centerX - contentWidth * 0.35,
              'y': centerY + 40.h
            }, // Bottom left
            {
              'x': centerX + contentWidth * 0.18,
              'y': centerY + 5.h
            }, // Top right
            {
              'x': centerX + contentWidth * 0.30,
              'y': centerY + 45.h
            }, // Bottom right
          ]
        : [
            {'x': centerX - contentWidth * 0.35, 'y': centerY}, // Top left
            {
              'x': centerX - contentWidth * 0.44,
              'y': centerY + 31.h
            }, // Bottom left
            {
              'x': centerX + contentWidth * 0.22,
              'y': centerY + 2.h
            }, // Top right
            {
              'x': centerX + contentWidth * 0.38,
              'y': centerY + 32.h
            }, // Bottom right
          ];

    return SizedBox(
      height: 0.3.sh,
      width: double.infinity,
      child: Stack(
        children: List.generate(5, (index) {
          // Don't show the moving avatar in the selection stack
          if (index == _movingAvatarIndex) return const SizedBox.shrink();
          // Don't show the selected avatar in the surrounding positions
          if (index == selectedAvatarIndex && _movingAvatarIndex == null) {
            return const SizedBox.shrink();
          }

          // Map avatar index to bubble position (skip center avatar index 2)
          int bubbleIndex = index;
          if (index > selectedAvatarIndex) {
            bubbleIndex = index - 1;
          }
          // Safety clamp to prevent out of range
          bubbleIndex = bubbleIndex.clamp(0, bubblePositions.length - 1);

          double x = bubblePositions[bubbleIndex]['x']!;
          double y = bubblePositions[bubbleIndex]['y']!;

          double bubbleSize = (bubbleIndex % 2 == 0) ? size : size / 2;

          return Positioned(
            left: x,
            top: y,
            child: GestureDetector(
              onTap: () => _selectAvatar(index),
              child: Container(
                width: bubbleSize,
                height: bubbleSize,
                padding: EdgeInsets.all(1.w),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    Color(0xFF09BDFF),
                    Color(0xFF09BDFF),
                    Color(0xFF4A4A4A)
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: bubbleSize - 4.w,
                      height: bubbleSize - 4.w,
                      child: Image.asset(
                        avatarsURLs[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMovingAvatar(int index, double contentWidth, bool isTablet) {
    double centerX = contentWidth * 0.5;
    double centerY = isTablet ? 0.12.sh : 0.17.sh;
    double size = isTablet ? contentWidth * 0.12 : contentWidth * 0.15;

    // 4 bubble positions - adjusted for tablet view
    final bubblePositions = isTablet
        ? [
            {'x': centerX - contentWidth * 0.30, 'y': centerY}, // Top left
            {
              'x': centerX - contentWidth * 0.37,
              'y': centerY + 40.h
            }, // Bottom left
            {
              'x': centerX + contentWidth * 0.20,
              'y': centerY + 5.h
            }, // Top right
            {
              'x': centerX + contentWidth * 0.32,
              'y': centerY + 45.h
            }, // Bottom right
          ]
        : [
            {'x': centerX - contentWidth * 0.37, 'y': centerY}, // Top left
            {
              'x': centerX - contentWidth * 0.44,
              'y': centerY + 31.h
            }, // Bottom left
            {
              'x': centerX + contentWidth * 0.22,
              'y': centerY + 2.h
            }, // Top right
            {
              'x': centerX + contentWidth * 0.36,
              'y': centerY + 32.h
            }, // Bottom right
          ];

    // Map avatar index to bubble position (skip center avatar index 2)
    int bubbleIndex = index;
    if (index > selectedAvatarIndex) {
      bubbleIndex = index - 1;
    }
    // Safety clamp to prevent out of range
    bubbleIndex = bubbleIndex.clamp(0, bubblePositions.length - 1);

    double startX = bubblePositions[bubbleIndex]['x']!;
    double startY = bubblePositions[bubbleIndex]['y']!;

    // Calculate center position (where the main avatar is)
    double endX = contentWidth * 0.5 -
        (isTablet ? 50.w : 40.w); // Center minus half width
    double endY = (isTablet ? 0.12.sh : 0.17.sh) -
        (isTablet ? 50.h : 40.h); // Center minus half height

    return AnimatedBuilder(
      animation: _avatarMoveController,
      builder: (context, child) {
        double animatedX =
            startX + (endX - startX) * _avatarMoveController.value;
        double animatedY =
            startY + (endY - startY) * _avatarMoveController.value;

        // Scale down as it moves to center
        double scale = 1.0 - (0.7 * _avatarMoveController.value);

        double bubbleSize = (bubbleIndex % 2 == 0) ? size : size / 2;

        return Positioned(
          left: animatedX,
          top: animatedY,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: bubbleSize,
              height: bubbleSize,
              padding: EdgeInsets.all(1.w),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  Color(0xFF09BDFF),
                  Color(0xFF09BDFF),
                  Color(0xFF4A4A4A)
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: bubbleSize - 4.w,
                    height: bubbleSize - 4.w,
                    child: Image.asset(
                      avatarsURLs[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTabletAvatarSelectionSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TabletAvatarSelectionSheet(
        avatarsURLs: avatarsURLs,
        selectedAvatarIndex: selectedAvatarIndex,
        selectedProfilePhoto: selectedProfilePhoto,
        onAvatarSelected: (index) {
          _selectAvatar(index);
          Navigator.pop(context);
        },
        onChoosePhoto: () {
          Navigator.pop(context);
          _pickImage();
        },
        onBack: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _showLanguageBottomSheet() async {
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectionBottomSheet(
        title: AppLocalizations.language,
        items: AppLocalizations.supportedLanguageDisplayNames,
        selectedItem: selectedLanguage,
      ),
    );
    if (result != null && mounted) _changeLanguage(result);
  }

  Future<void> _showCountryBottomSheet() async {
    FocusScope.of(context).unfocus();
    final countries = CountryService().getAll();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountrySelectionBottomSheet(
        title: AppLocalizations.country,
        countries: countries,
        selectedCountryCode: selectedCountry,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        selectedCountry = result;
      });
    }
  }

  Widget _buildTabletCountryDropdown() {
    final countryCode = selectedCountry;
    final countryName = countryCode != null
        ? CountryPickerWidget.getCountryName(countryCode)
        : null;
    final displayText = countryName ?? AppLocalizations.country;
    final isFilled = countryCode != null && countryCode.isNotEmpty;
    // Exactly matching the language dropdown style
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(255, 255, 255, 1),
            Color.fromRGBO(9, 189, 255, 1),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13.r),
          onTap: _showCountryBottomSheet,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13.r),
              color: Colors.black,
            ),
             child: Padding(  // Add padding for consistent height/alignment
              padding: EdgeInsets.symmetric(vertical: 2.h), // Adjust as needed
              child: Row(
              children: [
                if (!isFilled)
                  Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Icon(
                      Icons.public,
                      color: const Color.fromRGBO(255, 255, 255, 0.52),
                      size: 24.sp,
                    ),
                  ),
                if (!isFilled) SizedBox(width: 8.w),
                Expanded(
                  child: Padding( // Add padding for text
                    padding: EdgeInsets.only(left: isFilled ? 12.w : 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        if (isFilled) ...[
                          Text(CountryPickerWidget.getCountryFlag(countryCode), style: TextStyle(fontSize: 24.sp)), // Larger flag on tablet
                          SizedBox(width: 8.w),
                        ],
                        Expanded(child: Text(
                          displayText,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isFilled ? Colors.white : const Color.fromRGBO(255, 255, 255, 0.52),
                            fontSize: 18.sp,
                          ),
                        )),
                      ],
                    ),
                  ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Icon(Icons.arrow_drop_down, size: 35.sp, color: const Color.fromRGBO(9, 189, 255, 1)),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  // Check if all required fields are filled
  bool _areAllFieldsFilled() {
    final nameInput = _usernameController.text.trim();
    return nameInput.isNotEmpty &&
        selectedLanguage != null &&
        selectedCountry != null &&
        selectedProfilePhoto != null;
  }

  Future<void> _handleGuestSignup() async {
    // Validate all fields are filled
    if (!_areAllFieldsFilled()) {
      if (mounted) setState(() => _showFieldErrors = true);
      return;
    }
    setState(() => _showFieldErrors = false);

    // Dismiss Keyboard immediately to prevent layout resize glitch
    FocusManager.instance.primaryFocus?.unfocus();

    final nameInput = _usernameController.text.trim();
    final username = nameInput;

    setState(() => _isSubmitting = true);

    try {
      final languageCode = selectedLanguage != null
          ? AppLocalizations.languageCodeFromDisplayName(selectedLanguage!)
          : 'en';

      if (selectedLanguage != null) {
        await LocalStorageUtils.saveLanguage(languageCode);
        AppLocalizations.setLanguage(languageCode);
      }

      // Lazy creation: save pending guest locally; no DB row until first server action (e.g. getMe, join room).
      final pending = LocalStorageUtils.getPendingGuest();
      final localGuestId = pending?['localGuestId'] ??
          'g_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(999999)}';
      await LocalStorageUtils.savePendingGuest(
        localGuestId: localGuestId,
        name: username,
        avatar: selectedProfilePhoto,
        language: languageCode,
        country: selectedCountry,
      );

      if (!mounted) return;
      NativeLogService.log('Guest pending saved (lazy creation)', tag: _logTag, level: 'debug');
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.error}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildGradientDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Widget prefixIcon,
    required ValueChanged<String?> onChanged,
    bool isTablet = false,
  }) {
    final GlobalKey tapKey = GlobalKey();
    return Builder(
      builder: (context) {
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            gradient: const LinearGradient(
              colors: [
                Color.fromRGBO(255, 255, 255, 1),
                Color.fromRGBO(9, 189, 255, 1)
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: tapKey,
              borderRadius: BorderRadius.circular(13.r),
              onTap: () async {
                await _showLanguageBottomSheet();
                // Removed popup menu logic as we are now using bottom sheet for both mobile and tablet
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13.r),
                  color: Colors.black,
                ),
                child: Row(
                  children: [
                    prefixIcon,
                    SizedBox(width: 8.w),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value ?? hint,
                          style: TextStyle(
                            color: value == null
                                ? const Color.fromRGBO(255, 255, 255, 0.52)
                                : Colors.white,
                            fontSize: 18.sp,
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 35.sp,
                      color: const Color.fromRGBO(9, 189, 255, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecondPage() {
    const int coinReward = 1000;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen video without cutting
          Center(
            child: _videoController != null &&
                    _videoController!.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.contain, // Ensures entire video is visible
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.white),
          ),

          // Overlay content
          SafeArea(
            child: Column(
              children: [
                // Top coin container
                const CoinContainer(coins: coinReward),

                const Spacer(),

                // Animated coins count
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final count = (coinReward * _controller.value)
                        .round()
                        .clamp(0, coinReward);
                    return TextWidget(
                      text: "+ $count Coins",
                      fontSize: 28.sp,
                      color: AppColors.whiteColor,
                      fontWeight: FontWeight.bold,
                    );
                  },
                ),

                const Spacer(),

                // Skip button at bottom
                Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: TextButton(
                    onPressed: () => context.go(Routes.homeScreen),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Skip ",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 16.sp),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 18.sp, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma-style country selection bottom sheet (tablet); returns country code.
class _CountrySelectionBottomSheet extends StatefulWidget {
  final String title;
  final List<Country> countries;
  final String? selectedCountryCode;

  const _CountrySelectionBottomSheet({
    required this.title,
    required this.countries,
    this.selectedCountryCode,
  });

  @override
  State<_CountrySelectionBottomSheet> createState() => _CountrySelectionBottomSheetState();
}

class _CountrySelectionBottomSheetState extends State<_CountrySelectionBottomSheet> {
  late List<Country> _filteredCountries;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCountries = List.from(widget.countries);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCountries = widget.countries
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20.h,
        left: 15.w,
        right: 15.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 15.h),
          TextWidget(text: widget.title, fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
          SizedBox(height: 15.h),
          TextField(
            controller: _searchController,
            style: GoogleFonts.lato(color: Colors.white, fontSize: 16.sp),
            decoration: InputDecoration(
              labelText: AppLocalizations.search,
              labelStyle: GoogleFonts.lato(color: Colors.white70, fontSize: 14.sp),
              hintText: AppLocalizations.searchCountry,
              hintStyle: GoogleFonts.lato(color: const Color.fromRGBO(255, 255, 255, 0.52), fontSize: 14.sp),
              prefixIcon: const Icon(Icons.search, color: Color.fromRGBO(9, 189, 255, 1)),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              filled: true,
              fillColor: Colors.black,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.2), width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.2), width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: const BorderSide(color: Color.fromRGBO(9, 189, 255, 1), width: 1.5)),
            ),
          ),
          SizedBox(height: 15.h),
          Expanded(
            child: _filteredCountries.isEmpty
                ? Center(child: TextWidget(text: AppLocalizations.noMatchesFound, color: Colors.grey, fontSize: 14.sp))
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredCountries.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                    itemBuilder: (context, index) {
                      final country = _filteredCountries[index];
                      final isSelected = country.countryCode == widget.selectedCountryCode;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context, country.countryCode),
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 4.h),
                            padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color.fromRGBO(9, 189, 255, 0.1) : null,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              children: [
                                Text(country.flagEmoji, style: TextStyle(fontSize: 18.sp)),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    country.name,
                                    style: GoogleFonts.lato(
                                      color: isSelected ? const Color.fromRGBO(9, 189, 255, 1) : Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: const Color.fromRGBO(9, 189, 255, 1),
                                    size: 26.sp,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Figma-style avatar selection bottom sheet (tablet): Avatars tab + Choose photos tab, grid layout.
class _TabletAvatarSelectionSheet extends StatefulWidget {
  final List<String> avatarsURLs;
  final int selectedAvatarIndex;
  final String? selectedProfilePhoto;
  final ValueChanged<int> onAvatarSelected;
  final VoidCallback onChoosePhoto;
  final VoidCallback onBack;

  const _TabletAvatarSelectionSheet({
    required this.avatarsURLs,
    required this.selectedAvatarIndex,
    required this.selectedProfilePhoto,
    required this.onAvatarSelected,
    required this.onChoosePhoto,
    required this.onBack,
  });

  @override
  State<_TabletAvatarSelectionSheet> createState() => _TabletAvatarSelectionSheetState();
}

class _TabletAvatarSelectionSheetState extends State<_TabletAvatarSelectionSheet> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.r), topRight: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: Row(
              children: [
                const Spacer(),
                GestureDetector(
                  onTap: widget.onBack,
                  child: Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 0),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: _tabIndex == 0 ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          'Avatars',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _tabIndex == 0 ? Colors.white : Colors.black87,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 1),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: _tabIndex == 1 ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.choosePhotos,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _tabIndex == 1 ? Colors.white : Colors.black87,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            height: 1.h,
            color: Colors.black26,
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: _tabIndex == 0
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12.h,
                        crossAxisSpacing: 12.w,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: widget.avatarsURLs.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == widget.selectedAvatarIndex;
                        return GestureDetector(
                          onTap: () => widget.onAvatarSelected(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: isSelected ? Border.all(color: const Color(0xFF09BDFF), width: 3) : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: Padding(
                                padding: EdgeInsets.all(8.w),
                                child: Image.asset(widget.avatarsURLs[index], fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 48.sp, color: Colors.grey),
                        SizedBox(height: 12.h),
                        Text(AppLocalizations.chooseFromGallery, style: TextStyle(fontSize: 16.sp, color: Colors.black87)),
                        SizedBox(height: 16.h),
                        TextButton(
                          onPressed: widget.onChoosePhoto,
                          child: Text(AppLocalizations.openGallery, style: TextStyle(fontSize: 16.sp)),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}



