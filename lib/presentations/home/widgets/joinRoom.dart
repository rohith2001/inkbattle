import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkbattle_frontend/constants/app_images.dart';
import 'package:inkbattle_frontend/repositories/room_repository.dart';
import 'package:inkbattle_frontend/repositories/user_repository.dart';
import 'package:inkbattle_frontend/utils/lang.dart';

class JoinRoomPopup extends StatefulWidget {
  const JoinRoomPopup({super.key});

  @override
  State<JoinRoomPopup> createState() => _JoinRoomPopupState();
}

class _JoinRoomPopupState extends State<JoinRoomPopup> {
  final List<String> _digits = List.filled(5, '');
  late List<TextEditingController> _digitControllers;
  late List<FocusNode> _focusNodes;

  final RoomRepository _roomRepository = RoomRepository();
  final UserRepository _userRepository = UserRepository();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;
  String? selectedTeam; // For team rooms
  bool showTeamSelection = false;
  bool _isHandlingPaste = false; // Flag to prevent recursive calls during paste

  @override
  void initState() {
    super.initState();
    _digitControllers = List.generate(5, (_) => TextEditingController());
    _focusNodes = List.generate(5, (_) => FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _onDigitChanged(String value, int index) {
    // Skip if we're already handling a paste to prevent recursive calls
    if (_isHandlingPaste) {
      return;
    }

    // Handle paste: if value length > 1, it means user pasted multiple characters
    if (value.length > 1 && index == 0) {
      _isHandlingPaste = true;

      // Extract only alphanumeric characters and take first 5
      String pastedCode =
          value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      if (pastedCode.length > 5) {
        pastedCode = pastedCode.substring(0, 5);
      }

      // Fill all boxes with pasted code
      for (int i = 0;
          i < pastedCode.length && i < _digitControllers.length;
          i++) {
        _digitControllers[i].text = pastedCode[i];
        _digits[i] = pastedCode[i];
      }

      // Clear remaining boxes if pasted code is shorter than 5
      for (int i = pastedCode.length; i < _digitControllers.length; i++) {
        _digitControllers[i].text = '';
        _digits[i] = '';
      }

      _isHandlingPaste = false;

      // Check if all filled and auto-join
      if (pastedCode.length == 5 && _digits.every((d) => d.isNotEmpty)) {
        String code = pastedCode;
        _handleJoinRoom(code);
        return;
      }

      // Focus on the next empty box or last box
      int nextIndex = pastedCode.length < _digitControllers.length
          ? pastedCode.length
          : _digitControllers.length - 1;
      _focusNodes[nextIndex].requestFocus();
      return;
    }

    _digits[index] = value;

    // 1. Check for completion (Original logic)
    if (_digits.every((d) => d.isNotEmpty)) {
      String code = _digits.join();
      _handleJoinRoom(code);
    }

    // 2. Auto-advance (Forward logic)
    // If a digit is entered AND it's not the last box
    if (value.length == 1 && index < _digitControllers.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    // 3. Auto-move backwards (Backspace logic)
    // If the box is now empty (digit deleted) AND it's not the first box
    else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  double _getOffsetForIndex(int index, bool isTablet) {
    if (index == 0 || index == 4) {
      return isTablet ? 100.h : 70.h;
    } else if (index == 1 || index == 3) {
      return isTablet ? 50.h : 40.h;
    } else {
      return 0;
    }
  }

  Future<void> _handleJoinRoom(String code) async {
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.pleaseEnterARoomCode),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First, fetch room details to get actual entry cost
      final roomDetailsResult =
          await _roomRepository.getRoomByCode(roomCode: code);

      int entryCost = 250; // Default
      roomDetailsResult.fold(
        (failure) {
          // If we can't fetch room, use default
          entryCost = 250;
        },
        (room) {
          entryCost = room.entryPoints ?? 250;
        },
      );

      // Check if user has enough coins
      final userResult = await _userRepository.getMe();
      final hasEnoughCoins = userResult.fold(
        (failure) => false,
        (user) => (user.coins ?? 0) >= entryCost,
      );

      if (!hasEnoughCoins) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.translate('insufficient_coins_join_with_amount').replaceFirst('%s', entryCost.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Join room
      final result = await _roomRepository.joinRoomByCode(
        roomCode: code,
        team: selectedTeam,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${AppLocalizations.failedToJoinRoom}: '
                    '${failure.message.isNotEmpty ? failure.message : AppLocalizations.pleaseCheckCode}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (roomResponse) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${AppLocalizations.successfullyJoinedRoomEntryCost}$entryCost ${AppLocalizations.coins}'),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate to game room
            context.push('/game-room/${roomResponse.room?.id}');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.error}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _digitControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final viewInsets = mediaQuery.viewInsets;
    final safePadding = mediaQuery.padding;

    final bool isTablet = size.width > 600;
    final double dialogWidth = isTablet ? size.width * 0.70 : size.width * 0.85;

    // Keep the popup visible when the keyboard opens by:
    // - animating it upward using viewInsets.bottom
    // - shrinking its height to fit in the remaining space
    final double availableHeight =
        size.height - viewInsets.bottom - safePadding.top - safePadding.bottom;
    final double maxDialogHeight = (availableHeight > 0 ? availableHeight : 0) * 0.90;
    final double preferredDialogHeight =
        isTablet ? size.height * 0.60 : size.height * 0.45;
    final double dialogHeight = preferredDialogHeight.clamp(0.0, maxDialogHeight);
    final double closeSize = 35.w;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 6, 9, 14),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(color: Colors.white, width: 3.0),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 40.h, 20.w, 20.h),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: isTablet ? 0.5.sw : 0.6.sw,
                          height: isTablet ? 60.h : 50.h,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                AppImages.roombackbutton,
                                fit: BoxFit.contain,
                              ),
                              Center(
                                  child: Padding(
                                padding: EdgeInsets.only(top: 10.h),
                                child: Stack(
                                  children: [
                                    Text(
                                      'ROOM CARD NO.',
                                      style: GoogleFonts.luckiestGuy(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w400,
                                        foreground: Paint()
                                          ..style = PaintingStyle.stroke
                                          ..strokeWidth = 2
                                          ..color = Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'ROOM CARD NO.',
                                      style: GoogleFonts.luckiestGuy(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                        SizedBox(height: isTablet ? 30.h : 20.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _digitControllers.length,
                            (index) => _buildDigitBox(
                              _digitControllers[index],
                              _focusNodes[index],
                              // Use a function to determine offset based on index
                              _getOffsetForIndex(index, isTablet),
                              isTablet ? 30.w : 35.w,
                              45.h,
                              index, // Pass the index now
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -closeSize * 0.5,
                  left: -closeSize * 0.25,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SizedBox(
                      width: closeSize,
                      height: closeSize,
                      child: Image.asset(
                        AppImages.roomback,
                        width: closeSize,
                        height: closeSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDigitBox(
    TextEditingController controller,
    FocusNode focusNode,
    double topOffset,
    double boxWidth,
    double boxHeight,
    int index, // Added index parameter
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        children: [
          SizedBox(height: topOffset),
          SizedBox(
            width: boxWidth,
            height: boxHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  AppImages.inputbox,
                  fit: BoxFit.fill,
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Center(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLength:
                          index == 0 ? 5 : 1, // Allow paste in first field
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      style: GoogleFonts.play(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        filled: false,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]')),
                        if (index > 0) LengthLimitingTextInputFormatter(1),
                      ],
                      onChanged: (value) => _onDigitChanged(value, index),
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
