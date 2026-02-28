import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkbattle_frontend/constants/app_images.dart';

class Team {
  final String name;
  final int score;
  final String avatar;

  Team({
    required this.name,
    required this.score,
    required this.avatar,
  });
}

class TeamWinnerPopup extends StatelessWidget {
  final List<Team> teams;
  final bool isTeamvTeam;
  final VoidCallback? onNext;
  const TeamWinnerPopup({
    super.key,
    required this.teams,
    this.isTeamvTeam = false,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(360, 800));

    final sortedTeams = List<Team>.from(teams)
      ..sort((a, b) => b.score.compareTo(a.score));

    final first = sortedTeams.isNotEmpty ? sortedTeams[0] : null;
    final second = sortedTeams.length > 1 ? sortedTeams[1] : null;
    final third = sortedTeams.length > 2 ? sortedTeams[2] : null;

    final isTwoWinners = sortedTeams.length == 2;
    // Assuming AppImages.podium2 for 2 winners, and AppImages.podium for 3+ winners
    final podiumAsset = isTwoWinners ? AppImages.podium_2 : AppImages.podium_3;

    return Center(
      child: Container(
        width: 0.9.sw,
        height: 0.80.sh,
        decoration: BoxDecoration(
          color: const Color(0xFF101020),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.blueAccent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              blurRadius: 8.r,
              spreadRadius: 1,
            )
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 12.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // ... (Container with RibbonTextPainter remains unchanged)
              Container(
                height: 100.h,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(AppImages.redflg),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                // child: ClipRect(
                //   child: CustomPaint(
                //     painter: RibbonTextPainter(
                //       text: "CONGRATULATIONS",
                //       textStyle: GoogleFonts.inter(
                //         color: Colors.white,
                //         fontSize: 18.sp,
                //         fontWeight: FontWeight.w900,
                //       ),
                //     ),
                //     child: SizedBox(
                //       width: 200.w,
                //       height: 100.h,
                //     ),
                //   ),
                // ),
              ),
              SizedBox(height: 70.h),

              // --- START MODIFIED PODIUM STACK ---
              Container(
                width: 300.w,
                height: 300.h,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    alignment: AlignmentGeometry.center,
                    // Use the correct asset based on winner count
                    image: AssetImage(podiumAsset),
                    fit: BoxFit.fitHeight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // --- POSITION 1: Highest Podium (Center) ---
                    if (first != null)
                      _buildTeamWinnerAvatar(
                        team: first,
                        rank: 1,
                        // Position for Rank 1 (Top Center for both 2 and 3 winners)
                        top: 20
                            .h, // Slightly lower than 0.1h for better alignment
                        left: 100.w, // Center of the 300w container (300/3)
                        isTeamvTeam: isTeamvTeam,
                      ),

                    // FIXED: Proper logic for 2 vs 3+ winners
                    ...(isTwoWinners
                        ? [
                            // 2 winners: Show first and second
                            if (second != null)
                              _buildTeamWinnerAvatar(
                                team: second,
                                rank: 2,
                                top: 80.h,
                                left: 170.w,
                                isTeamvTeam: isTeamvTeam,
                              ),
                          ]
                        : [
                            // 3+ winners: Show second and third
                            if (second != null)
                              _buildTeamWinnerAvatar(
                                team: second,
                                rank: 2,
                                // Position for Rank 2 (Left, lower) in 3-winner mode
                                top: 80.h,
                                left: 30.w,
                                isTeamvTeam: isTeamvTeam,
                              ),
                            if (third != null)
                              _buildTeamWinnerAvatar(
                                team: third,
                                rank: 3,
                                // Position for Rank 3 (Right, lowest) in 3-winner mode
                                top: 100.h,
                                left: 170.w,
                                isTeamvTeam: isTeamvTeam,
                              ),
                          ]),
                  ],
                ),
              ),
              // --- END MODIFIED PODIUM STACK ---

              SizedBox(height: 50.h),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onNext?.call(); // Call onNext callback if provided
                },
                child: Container(
                  width: 150.w,
                  height: 50.h,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(AppImages.winnernextbutton),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build the winner's avatar and text column
  Widget _buildTeamWinnerAvatar({
    required Team team,
    required int rank,
    required double top,
    required double left,
    required bool isTeamvTeam,
  }) {
    // Determine size and color based on rank
    final double avatarRadius = rank == 1 ? 28.r : 26.r;
    final double innerRadius = rank == 1 ? 25.r : 23.r;
    final Color outerColor = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey[400]!
            : Colors.brown;

    return Positioned(
      top: top,
      left: left,
      child: Column(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: outerColor,
            child: CircleAvatar(
              radius: innerRadius,
              backgroundImage: AssetImage(team.avatar),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            team.name,
            style: GoogleFonts.lato(
              // Color logic: Team mode uses team colors, 1v1 mode uses rank-based colors
              color: isTeamvTeam
                  ? (team.name == 'Team A' ? Colors.blue : Colors.orange)
                  : (rank == 1
                      ? Colors.amber
                      : rank == 2
                          ? Colors.grey[300]!
                          : Colors.brown[300]!),
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            "${team.score}",
            style: GoogleFonts.inter(
              color: Colors.amber,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class RibbonTextPainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;

  RibbonTextPainter({required this.text, required this.textStyle});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const curveHeight = 20.0;

    final charCount = text.length;
    final charWidth = textPainter.width / charCount;

    for (int i = 0; i < charCount; i++) {
      final x =
          centerX - (textPainter.width / 2) + (i * charWidth) + (charWidth / 2);
      final y = centerY -
          curveHeight +
          (curveHeight * math.pow((i - charCount / 2) / (charCount / 2), 2));

      final charPainter = TextPainter(
        text: TextSpan(text: text[i], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      charPainter.layout();

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(0);
      charPainter.paint(
          canvas, Offset(-charPainter.width / 2, -charPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
