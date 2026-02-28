import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkbattle_frontend/constants/app_images.dart';
import 'package:inkbattle_frontend/models/room_model.dart';
import 'package:inkbattle_frontend/repositories/room_repository.dart';
import 'package:inkbattle_frontend/repositories/user_repository.dart';
import 'package:inkbattle_frontend/utils/lang.dart';
import 'package:inkbattle_frontend/widgets/blue_background_scaffold.dart';
import 'package:inkbattle_frontend/widgets/custom_svg.dart';
import 'package:inkbattle_frontend/widgets/persistent_banner_ad_widget.dart';

class OneVsOneScreen extends StatefulWidget {
  final List<String> categories;
  final int points;
  final String roomId;
  final RoomModel? roomModel;

  const OneVsOneScreen({
    super.key,
    required this.categories,
    required this.points,
    required this.roomId,
    this.roomModel,
  });

  @override
  State<OneVsOneScreen> createState() => _OneVsOneScreenState();
}

class _OneVsOneScreenState extends State<OneVsOneScreen> {
  bool isButtonPressed = false;
  Color gradientStartColor =
      const Color.fromRGBO(110, 136, 206, 1); // rgba(110, 136, 206, 1)
  Color gradientEndColor =
      const Color.fromRGBO(44, 61, 106, 1); // rgba(44, 61, 106, 1)

  double borderWidth = 1.2;

  final RoomRepository _roomRepository = RoomRepository();
  final UserRepository _userRepository = UserRepository();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;
  String? selectedTeam;
  bool showTeamSelection = false;

  /// Current room data (refreshed on init so participantCount and targetPoints are up to date).
  RoomModel? _roomModel;

  Future<void> _handleJoinRoom(String code) async {
    try {
      // Join room
      final result = await _roomRepository.joinRoomById(
        roomId: int.parse(code),
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${AppLocalizations.failedToJoinRoom}'
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
                content:
                    Text('${AppLocalizations.successfullyJoinedRoomEntryCost}250 ${AppLocalizations.coins}'),
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
  void initState() {
    super.initState();
    _roomModel = widget.roomModel;
    _refreshRoom();
  }

  Future<void> _refreshRoom() async {
    if (widget.roomId.isEmpty || widget.roomId == 'Unknown') return;
    final result = await _roomRepository.getRoomDetails(roomId: widget.roomId);
    result.fold(
      (_) {},
      (room) {
        if (mounted) setState(() => _roomModel = room);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) {
        final isTablet = MediaQuery.of(context).size.shortestSide > 600;

        return BlueBackgroundScaffold(
          child: SafeArea(
            bottom: true, // Protect bottom for ad visibility
            child: Padding(
              padding: EdgeInsets.only(
                left: 25.w,
                right: 25.w,
                top: isTablet ? 20.h : 15.h,
                bottom: 0,
              ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const CustomSvgImage(
                        imageUrl: AppImages.arrow_back,
                        height: 25,
                        width: 25,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 10.h),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(50.r + borderWidth),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [gradientStartColor, gradientEndColor],
                          ),
                        ),
                        padding: EdgeInsets.all(borderWidth),
                        child: CircleAvatar(
                          backgroundColor: const Color.fromRGBO(26, 42, 81, 1),
                          radius: 50.r,
                          child: Image.asset(
                            _getCategoryIcon(
                                widget.categories.isNotEmpty
                                    ? widget.categories.first
                                    : 'Animals'),
                            width: 70.w,
                            height: 70.h,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        widget.categories.isEmpty
                            ? 'Animals'
                            : widget.categories.length == 1
                                ? widget.categories.first
                                : widget.categories.join(', '),
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Are you ready to join Individual Game?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94AFE7),
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person, color: Colors.white, size: 25.sp),
                          SizedBox(width: 6.w),
                          Text(
                            "${(_roomModel ?? widget.roomModel)?.participantCount ?? 0}/${(_roomModel ?? widget.roomModel)?.maxPlayers ?? 0}",
                            style: GoogleFonts.lato(
                              color: const Color(0xFFB9C7E5),
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 55.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Row(children: [
                                Icon(Icons.language,
                                    color: Colors.white, size: 28.sp),
                                SizedBox(width: isTablet ? 6.w : 4.w),
                                Text(
                                  (_roomModel ?? widget.roomModel)?.language?.isNotEmpty == true
                                      ? (_roomModel ?? widget.roomModel)!.language!
                                      : 'EN',
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontSize: isTablet ? 18.sp : 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ]),
                            ],
                          ),
                          Container(
                            height: 50.h,
                            width: 1.w,
                            color: Colors.white.withOpacity(0.5),
                            margin: EdgeInsets.symmetric(horizontal: 16.w),
                          ),
                          Column(
                            children: [
                              Row(children: [
                                Icon(Icons.people,
                                    color: Colors.white, size: 21.sp),
                                SizedBox(width: isTablet ? 6.w : 4.w),
                                Text(
                                  "${(_roomModel ?? widget.roomModel)?.participantCount ?? 0}/${(_roomModel ?? widget.roomModel)?.maxPlayers ?? 0}",
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ]),
                            ],
                          ),
                          Container(
                            height: 50.h,
                            width: 1.w,
                            color: Colors.white.withOpacity(0.5),
                            margin: EdgeInsets.symmetric(horizontal: 16.w),
                          ),
                          Column(
                            children: [
                              Row(children: [
                                Icon(Icons.flag,
                                    color: Colors.amber, size: 21.sp),
                                SizedBox(width: isTablet ? 6.w : 4.w),
                                Text(
                                  "${(_roomModel ?? widget.roomModel)?.pointsTarget ?? 100}",
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ]),
                            ],
                          )
                        ],
                      ),
                      SizedBox(height: 99.h),
                      GestureDetector(
                        onTap: () {
                          if (!isButtonPressed) _handleJoinRoom(widget.roomId);
                          if (mounted) {
                            setState(() {
                              isButtonPressed = !isButtonPressed;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 50.h,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: isButtonPressed
                                ? Colors.green
                                : const Color.fromARGB(255, 189, 16, 4),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              isButtonPressed
                                  ? Text(
                                      "🚀  Let's go!",
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(children: [
                                      Image.asset(
                                        AppImages.coin,
                                        height: 30.h,
                                        width: 30.w,
                                      ),
                                      Text(
                                        "250",
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ])
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Persistent Banner Ad (app-wide, loaded once)
                const PersistentBannerAdWidget(),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case "Fruits":
        return AppImages.fruit;
      case "Animals":
        return AppImages.animal;
      case "Food":
        return AppImages.food;
      case "Movies":
        return AppImages.movies;
      default:
        return AppImages.food;
    }
  }
}
