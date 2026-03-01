import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inkbattle_frontend/constants/app_colors.dart';
import 'package:inkbattle_frontend/constants/app_images.dart';
import 'package:inkbattle_frontend/widgets/backgroun_scafold.dart';
import 'package:inkbattle_frontend/widgets/custom_svg.dart';
import 'package:inkbattle_frontend/widgets/text_widget.dart';
import 'package:inkbattle_frontend/widgets/textformfield_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:inkbattle_frontend/utils/routes/routes.dart';
import 'package:inkbattle_frontend/widgets/topCoins.dart';
import 'package:inkbattle_frontend/repositories/user_repository.dart';
import 'package:inkbattle_frontend/utils/lang.dart';
import 'package:inkbattle_frontend/utils/preferences/local_preferences.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final UserRepository _userRepository = UserRepository();
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  String? selectedLanguage;
  String? selectedCountry;
  XFile? selctedProfilePhoto;

  // ADDED: Avatar selection variables (from GuestSignUpScreen)
  int selectedAvatarIndex = 0;
  String? selectedProfilePhoto = AppImages.profileSelect;
  bool showAvatarSelection = false;
  List<String> avatarsURLs = [
    AppImages.pencilAngry,
    AppImages.profileSelect,
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  late AnimationController _controller;
  late List<Animation<Offset>> _coinDrops;
  late Animation<double> _textOpacity;

  final List<String> languages = ["Hindi", "Marathi", "English"];
  final List<String> countries = ["India", "USA", "UK", "Japan"];

  // ADDED: Avatar selection methods (from GuestSignUpScreen)
  void _selectAvatar(int index) {
    setState(() {
      selectedAvatarIndex = index;
      if (index <= avatarsURLs.length - 1) {
        selectedProfilePhoto = avatarsURLs[index];
        selctedProfilePhoto =
            null; // Clear custom photo when avatar is selected
      } else {
        selectedProfilePhoto = null;
      }
    });
  }

  void _toggleAvatarSelection() {
    setState(() {
      showAvatarSelection = !showAvatarSelection;
    });
  }

  @override
  void initState() {
    super.initState();
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

    _coinDrops = [];
    _textOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.80, 1.0, curve: Curves.easeIn),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final random = Random();
    final stackWidth = 0.6.sw;
    final stackHeight = 0.4.sh;
    final childSize = 0.1.sw;
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
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.usernameRequired)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Lazy creation: save pending guest locally; no DB row until first server action.
      final pending = LocalStorageUtils.getPendingGuest();
      final random = Random();
      final localGuestId = pending?['localGuestId'] ??
          'g_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(999999)}';
      await LocalStorageUtils.savePendingGuest(
        localGuestId: localGuestId,
        name: username,
        avatar: selectedProfilePhoto,
        language: selectedLanguage,
        country: selectedCountry,
      );

      if (!mounted) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
          if (index == 1) _controller.forward(from: 0);
        },
        itemBuilder: (context, index) {
          if (index == 0) return _buildFirstPage();
          return _buildSecondPage();
        },
      ),
    );
  }

  Widget _buildFirstPage() {
    double size = 0.15.sw;
    // ADDED: Avatar widgets (from GuestSignUpScreen)
    List<Widget> avatars = List.generate(4, (index) {
      return CircleAvatar(
        radius: size / 3,
        backgroundColor: Colors.transparent,
        child: index > avatarsURLs.length - 1
            ? const Icon(Icons.person)
            : Image.asset(avatarsURLs[index]),
      );
    });

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const CoinContainer(coins: 0),
            SizedBox(height: 0.15.sh),
            // MODIFIED: Profile photo section with avatar selection
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: _toggleAvatarSelection,
                  child: Container(
                    height: 150.h,
                    width: 150.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color.fromRGBO(9, 189, 255, 1),
                        width: 2.w,
                      ),
                    ),
                    child: ClipOval(
                      child: selctedProfilePhoto != null
                          ? Image.file(
                              File(selctedProfilePhoto!.path),
                              fit: BoxFit.cover,
                            )
                          : selectedProfilePhoto != null
                              ? Image.asset(selectedProfilePhoto!)
                              : Icon(
                                  Icons.add_a_photo,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 50.sp,
                                ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10.h,
                  right: 10.w,
                  child: GestureDetector(
                    onTap: _toggleAvatarSelection,
                    child: Container(
                      height: 40.h,
                      width: 40.w,
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(217, 217, 217, 1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5.r,
                            offset: Offset(2.w, 2.h),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        AppImages.pencil,
                        height: 30.h,
                        width: 30.w,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ADDED: Avatar selection widget (from GuestSignUpScreen)
            if (showAvatarSelection) ...[
              SizedBox(height: 5.h),
              SizedBox(
                height: 0.1.sh,
                width: double.infinity,
                child: Stack(
                  children: List.generate(4, (index) {
                    selectedAvatarIndex == index;

                    if (size < 0.08.sw) size = 0.08.sw;

                    double centerX = 0.5.sw;
                    double startY = 0;

                    double x, y;
                    if (index == 0) {
                      x = centerX - (0.30.sw);
                      y = startY;
                    } else if (index == 1) {
                      x = centerX - (0.48.sw);
                      y = startY + 15.h;
                    } else if (index == 2) {
                      x = centerX - (size / 2.0);
                      y = startY + 1.h;
                    } else {
                      x = centerX + (0.10.sw);
                      y = startY + 15.h;
                    }

                    return Positioned(
                      left: x + 30.w,
                      top: y,
                      child: GestureDetector(
                        onTap: () => _selectAvatar(index),
                        child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.5),
                                width: 3.w,
                              ),
                            ),
                            child: avatars[index]),
                      ),
                    );
                  }),
                ),
              ),
            ],
            SizedBox(height: 0.05.sh),
            SizedBox(
              width: 0.6.sw,
              child: TextformFieldWidget(
                controller: _usernameController,
                focusNode: _usernameFocusNode,
                height: 48.h,
                rouneded: 15.r,
                fontSize: 18.sp,
                hintTextColor: const Color.fromRGBO(255, 255, 255, 0.52),
                hintText: AppLocalizations.enterUsername,
                prefixIcon: Padding(
                  padding: EdgeInsets.all(10.w),
                  child: CustomSvgImage(
                    imageUrl: AppImages.userSvg,
                    height: 21.h,
                    width: 21.w,
                  ),
                ),
              ),
            ),
            SizedBox(height: 0.03.sh),
            SizedBox(
              width: 0.6.sw,
              child: _buildGradientDropdown(
                hint: AppLocalizations.language,
                value: selectedLanguage,
                items: languages,
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: CustomSvgImage(
                    imageUrl: AppImages.languageSvg,
                    height: 21.h,
                    width: 21.w,
                  ),
                ),
                onChanged: (val) => setState(() => selectedLanguage = val),
              ),
            ),
            SizedBox(height: 0.03.sh),
            SizedBox(
              width: 0.6.sw,
              child: _buildGradientDropdown(
                hint: AppLocalizations.country,
                value: selectedCountry,
                items: countries,
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: CustomSvgImage(
                    imageUrl: AppImages.coutrySvg,
                    height: 21.h,
                    width: 21.w,
                  ),
                ),
                onChanged: (val) => setState(() => selectedCountry = val),
              ),
            ),
            SizedBox(height: 0.07.sh),
            InkWell(
              onTap: _isSubmitting ? null : _handleSignup,
              child: Row(
                children: [
                  const Spacer(),
                  _isSubmitting
                      ? SizedBox(
                          width: 18.sp,
                          height: 18.sp,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : TextWidget(
                          text: AppLocalizations.next,
                          fontSize: 18.sp,
                          color: AppColors.whiteColor,
                        ),
                  Icon(Icons.navigate_next_outlined,
                      color: AppColors.whiteColor, size: 22.sp),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Widget prefixIcon,
    required ValueChanged<String?> onChanged,
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
                final box =
                    tapKey.currentContext!.findRenderObject() as RenderBox;
                final Offset pos = box.localToGlobal(Offset.zero);
                final Size size = box.size;
                const double gap = -2.0;
                final selected = await showMenu<String>(
                  context: context,
                  position: RelativeRect.fromLTRB(
                      pos.dx,
                      pos.dy + size.height + gap,
                      pos.dx + size.width,
                      pos.dy + size.height + gap),
                  color: Colors.transparent,
                  constraints: BoxConstraints(
                    minWidth: size.width,
                    maxWidth: size.width,
                  ),
                  items: [
                    PopupMenuItem<String>(
                      enabled: false,
                      padding: EdgeInsets.zero,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.r),
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromRGBO(255, 255, 255, 1),
                              Color.fromRGBO(9, 189, 255, 1)
                            ],
                          ),
                        ),
                        padding: EdgeInsets.all(2.w),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.r),
                            color: Colors.black,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final e = entry.value;
                              return Container(
                                decoration: BoxDecoration(
                                  border: index < items.length - 1
                                      ? const Border(
                                          bottom: BorderSide(
                                              color: Color.fromRGBO(
                                                  255, 255, 255, 0.2),
                                              width: 3))
                                      : null,
                                ),
                                child: InkWell(
                                  onTap: () => Navigator.pop(context, e),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 12.h,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        e,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
                if (selected != null) onChanged(selected);
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
                      child: Text(
                        value ?? hint,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: value == null
                              ? const Color.fromRGBO(255, 255, 255, 0.52)
                              : Colors.white,
                          fontSize: 18.sp,
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

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        child: Column(
          children: [
            const CoinContainer(coins: coinReward),
            const Spacer(),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxWidth * 0.7;

                  return SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Circular container
                        Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                            Border.all(color: Colors.blueAccent, width: 2.w),
                          ),
                        ),
                        // Center coin image
                        Positioned(
                          bottom: size * 0.12,
                          child: Image.asset(
                            AppImages.coin2,
                            height: size * 0.45,
                            width: size * 0.45,
                          ),
                        ),
                        // Coin drops
                        ..._coinDrops.map((anim) {
                          return SlideTransition(
                            position: anim,
                            child: Image.asset(
                              AppImages.coin,
                              height: size * 0.08,
                              width: size * 0.08,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final count =
                (coinReward * _controller.value).round().clamp(0, coinReward);
                return TextWidget(
                  text: "+ $count Coins",
                  fontSize: 25.sp,
                  color: AppColors.whiteColor,
                  fontWeight: FontWeight.bold,
                );
              },
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomCenter,
              child: TextButton(
                onPressed: () => context.go(Routes.homeScreen),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${AppLocalizations.skip} ",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.sp,
                        )),
                    Icon(Icons.arrow_forward_ios,
                        size: 16.sp, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
