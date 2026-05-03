import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:go_router/go_router.dart';
import 'package:inkbattle_frontend/constants/app_images.dart';
import 'package:inkbattle_frontend/widgets/blue_background_scaffold.dart';
import 'package:inkbattle_frontend/repositories/room_repository.dart';
import 'package:inkbattle_frontend/repositories/theme_repository.dart';
import 'package:inkbattle_frontend/repositories/user_repository.dart';
import 'package:inkbattle_frontend/models/room_model.dart';
import 'package:inkbattle_frontend/utils/lang.dart';
import 'package:inkbattle_frontend/widgets/persistent_banner_ad_widget.dart';
import 'package:inkbattle_frontend/widgets/country_picker_widget.dart';
import 'package:inkbattle_frontend/presentations/room_preferences/widgets/selection_bottom_sheet.dart';
import 'package:inkbattle_frontend/presentations/room_preferences/widgets/multi_selection_bottom_sheet.dart';
import 'dart:developer' as developer;

class MultiplayerScreen extends StatefulWidget {
  const MultiplayerScreen({super.key});

  @override
  State<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> {
  static const String _logTag = 'MultiplayerScreen';
  final RoomRepository _roomRepository = RoomRepository();
  final UserRepository _userRepository = UserRepository();
  final ThemeRepository _themeRepository = ThemeRepository();

  String? selectedLanguage;
  String? selectedScript;
  String? selectedCountry;
  String? selectedPoints;
  // String? selectedCategory;
  List<String> selectedCategories = [];
  bool voiceEnabled = false;
  String? selectedGameMode;
  bool _isLoading = false;
  
  // REMOVED: Ad variables
  // BannerAd? _bannerAd;
  // bool _isBannerAdLoaded = false;

  List<RoomModel> _rooms = [];

  List<String> languages = [];
  final List<String> scripts = ["default", "english"];
  // Countries are now handled via CountryPickerWidget with ISO-2 codes
  final List<String> points = ["50", "100", "150", "200"];
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    // Load languages/categories first, then load rooms (so allFilled is true when we fetch)
    _loadLanguagesAndCategories();
    // REMOVED: _loadBannerAd();
  }

  @override
  void dispose() {
    // REMOVED: _bannerAd?.dispose();
    super.dispose();
  }

  // REMOVED: _loadBannerAd() function

  Future<void> _loadLanguagesAndCategories() async {
    // Load languages and categories in parallel so rooms can be fetched once both are ready
    final languagesResult = await _userRepository.getLanguages();
    final categoriesResult = await _themeRepository.getCategories();

    String? lang;
    List<String> langList = ["English", "Hindi", "Marathi", "Telugu"];
    languagesResult.fold(
      (failure) {
        lang = langList.isNotEmpty ? langList.first : null;
      },
      (languagesList) {
        if (languagesList.isEmpty) {
          lang = langList.isNotEmpty ? langList.first : null;
        } else {
          langList = languagesList
              .map((l) => l['languageName'] as String? ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
          lang = langList.isNotEmpty ? langList.first : null;
        }
      },
    );

    List<String> catList = ["Fruits", "Animals", "Food", "Movies"];
    categoriesResult.fold(
      (failure) {
        catList = ["Fruits", "Animals", "Food", "Movies"];
      },
      (categoriesList) {
        if (categoriesList.isEmpty) {
          catList = ["Fruits", "Animals", "Food", "Movies"];
        } else {
          catList = categoriesList
              .map((cat) => cat['title'] as String? ?? '')
              .where((title) => title.isNotEmpty)
              .toList();
        }
      },
    );

    if (mounted) {
      setState(() {
        languages = langList;
        selectedLanguage = null;
        categories = catList;
        selectedCategories = [];
      });
      // Now allFilled is false; user must select fields to fetch rooms
      // _loadRooms();
    }
  }

  Future<void> _loadRooms() async {
    // Only load if essential filters are set
    if (!allFilled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final categoriesToSend =
        selectedCategories.isEmpty ? null : selectedCategories;
      // // If user has selected all categories, don't send category filter at all.
      // // This avoids over-filtering when rooms may have slightly different / mixed categories,
      // // and lets the backend return any category that matches the other filters.
      // final bool allCategoriesSelected =
      //     selectedCategories.isNotEmpty &&
      //     categories.isNotEmpty &&
      //     selectedCategories.length == categories.length;

      // final categoriesToSend = (selectedCategories.isEmpty || allCategoriesSelected)
      //     ? null
      //     : selectedCategories;
      final result = await _roomRepository.listRooms(
          language: selectedLanguage,
          gameMode: selectedGameMode,
          country: selectedCountry == "All" ? null : selectedCountry,
          categories: categoriesToSend,
          script: selectedScript,
          targetPoints: int.tryParse(selectedPoints.toString()) ?? 250,
          voiceEnabled: voiceEnabled);

      result.fold(
        (failure) {
          developer.log(
            'Failed to load rooms: ${failure.message}',
            name: _logTag,
          );
          if (mounted) {
            setState(() {
              _rooms = [];
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load rooms')),
            );
          }
        },
        (roomListResponse) {
          if (mounted) {
            setState(() {
              final rooms = roomListResponse.rooms ?? [];
              developer.log(
                'Loaded ${rooms.length} rooms from server', 
                name: _logTag,
              );
              // Sort rooms by fill percentage (most filled first)
              // Fill percentage = participantCount / maxPlayers
              _rooms = rooms
                ..sort((a, b) {
                  final fillA = (a.participantCount ?? 0) / (a.maxPlayers ?? 1);
                  final fillB = (b.participantCount ?? 0) / (b.maxPlayers ?? 1);
                  // Sort in descending order (highest fill percentage first)
                  return fillB.compareTo(fillA);
                });
            });
          }
        },
      );
    } catch (e) {
      developer.log(
        'Error loading rooms: $e',
        name: _logTag,
        error: e,
      );
      if (mounted) {
        setState(() {
          _rooms = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong')),
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

  Future<void> _joinRoom(RoomModel room) async {
    final result = await _roomRepository.getRoomDetails(roomId: room.id.toString());
    final updatedRoom = result.fold(
      (failure) => room,
      (roomModel) => roomModel,
    );
    final categoriesPath = _encodeCategoriesForPath(_roomCategoriesList(room));
    room.gameMode == 'team' || room.gameMode == 'team_vs_team'
        ? context.push(
            "/teamvsteam/${room.id}/$categoriesPath/${room.entryPoints}",
            extra: {
                "roomModel": updatedRoom,
                // Removed passing bannerAd as it is now persistent
              })
        : context.push(
            "/onevsone/${room.id}/$categoriesPath/${room.entryPoints}",
            extra: {
                "roomModel": updatedRoom,
                // Removed passing bannerAd as it is now persistent
              });
  }

  Future<String?> _showTeamSelectionDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Select Your Team',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTeamOption('orange', Colors.orange),
            SizedBox(height: 16.h),
            _buildTeamOption('blue', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamOption(String team, Color color) {
    return InkWell(
      onTap: () => Navigator.pop(context, team),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Team ${team[0].toUpperCase()}${team.substring(1)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // void _showInsufficientCoinsDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       backgroundColor: const Color(0xFF1A1A2E),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(20.r),
  //       ),
  //       title: Text(
  //         AppLocalizations.insufficientCoinsTitle,
  //         style: TextStyle(
  //           fontSize: 18.sp,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.white,
  //         ),
  //       ),
  //       content: Text(
  //         AppLocalizations.insufficientCoinsMessage,
  //         style: TextStyle(
  //           fontSize: 14.sp,
  //           color: Colors.grey,
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: TextWidget(
  //             text: AppLocalizations.cancel,
  //             fontSize: 14.sp,
  //             color: Colors.grey,
  //           ),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               SnackBar(content: Text(AppLocalizations.watchAdsComingSoon)),  
  //             );
  //           },
  //           child: TextWidget(
  //             text: AppLocalizations.watchAds,
  //             fontSize: 14.sp,
  //             color: Colors.orange,
  //           ),
  //         ),
  //         // TextButton(
  //         //   onPressed: () {
  //         //     // Navigator.pop(context);
  //         //     // ScaffoldMessenger.of(context).showSnackBar(
  //         //     //   const SnackBar(content: Text('Buy coins feature coming soon!')),
  //         //     // );
  //         //   },
  //         //   child: Text(
  //         //     AppLocalizations.buyCoins,
  //         //     style: TextStyle(
  //         //       fontSize: 14.sp,
  //         //       color: Colors.green,
  //         //     ),
  //         //   ),
  //         // ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return BlueBackgroundScaffold(
      child: SafeArea(
        bottom: true, // Protect bottom for ad visibility
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                // Back button
                Padding(
                  padding: EdgeInsets.only(
                      left: isTablet ? 16.0 : 8.w,
                      top: isTablet ? 16.0 : 8.h,
                      bottom: isTablet ? 24.0 : 16.h,
                      right: isTablet ? 16.0 : 8.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: isTablet ? 32.0 : 24.sp,
                      ),
                    ),
                  ),
                ),

                // Filter Pills - Row 1
                Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFilterPill(
                          image: null, // User requested Flutter icons
                          icon: Icons.language,
                          value: selectedLanguage,
                          items: languages,
                          onChanged: (val) {
                            setState(() {
                              selectedLanguage = val;
                              selectedScript = 'default';
                              _rooms = [];
                            });
                            developer.log(
                              'Selected language: $selectedLanguage',
                              name: _logTag,
                            );
                            // _loadRooms();
                          },
                          hintText: AppLocalizations.language,
                          iconColor: Colors.lightBlueAccent,
                          isTablet: isTablet,
                        ),
                      ),
                      SizedBox(width: isTablet ? 16.0 : 8.w),
                      Expanded(
                        child: _isEnglishLanguage(selectedLanguage)
                            ? _buildFilterPill(
                                image: null,
                                icon: Icons.text_fields,
                                value: 'Default',
                                items: const <String>['Word Script: English (auto)'],
                                onChanged: null,
                                hintText: AppLocalizations.script,
                                iconColor: Colors.deepPurpleAccent,
                                isTablet: isTablet,
                              )
                            : _buildFilterPill(
                                image: null, // User requested Flutter icons
                                icon: Icons.text_fields, // Better icon for "Script"
                                value: selectedScript,
                                items: scripts,
                                onChanged: (val) {
                                  setState(() {
                                    selectedScript = val;
                                    _rooms = [];
                                  });
                                  developer.log(
                                    'Selected script: $selectedScript',
                                    name: _logTag,
                                  );
                                  // _loadRooms();
                                },
                                hintText: AppLocalizations.script,
                                iconColor: Colors.deepPurpleAccent,
                                isTablet: isTablet,
                              ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 16.0 : 10.h),

                // Filter Pills - Row 2
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: CountryPickerWidget(
                          selectedCountryCode: selectedCountry,
                          onCountrySelected: (countryCode) {
                            setState(() {
                              selectedCountry = countryCode;
                              _rooms = [];
                            });
                            developer.log(
                              'Selected country code: $selectedCountry',
                              name: _logTag,
                            );
                            // _loadRooms();
                          },
                          hintText: AppLocalizations.country,
                          height: isTablet ? 65.0 : 45.h, // Explicit height to match other fields
                          iconColor: Colors.lightGreenAccent,
                          isTablet: isTablet,
                        ),
                      ),
                      SizedBox(width: isTablet ? 16.0 : 8.w),
                      Expanded(
                        child: _buildFilterPill(
                          image: null, // User requested Flutter icons
                          icon: Icons.star,
                          value: selectedPoints,
                          items: points,
                          onChanged: (val) {
                            setState(() {
                              selectedPoints = val;
                              _rooms = [];
                            });
                            developer.log(
                              'Selected points: $selectedPoints',
                              name: _logTag,
                            );
                            // _loadRooms();
                          },
                          hintText: AppLocalizations.points,
                          iconColor: Colors.amber,
                          isTablet: isTablet,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 16.0 : 10.h),

                // Filter Pills - Row 3
                Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMultiSelectCategoryPill(
                          image: null, // User requested Flutter icons
                          icon: Icons.category,
                          selectedValues: selectedCategories,
                          items: categories,
                          onChanged: (val) {
                            setState(() {
                              selectedCategories = val;
                              _rooms = [];
                            });
                            developer.log(
                              'Selected categories: $selectedCategories',
                              name: _logTag,
                            );
                            // _loadRooms();
                          },
                          hintText: AppLocalizations.category,
                          iconColor: Colors.orange,
                          isTablet: isTablet,
                        ),
                      ),
                      SizedBox(width: isTablet ? 16.0 : 8.w),
                      Expanded(
                        child: _buildFilterPill(
                          image: null, // User requested Flutter icons
                          icon: Icons.people,
                          value: selectedGameMode == "team_vs_team"
                              ? AppLocalizations.team
                              : selectedGameMode == "1v1"
                                  ? AppLocalizations.individual
                                  : null,
                          onChanged: (val) {
                            if (val == AppLocalizations.team) {
                              setState(() {
                                selectedGameMode = "team_vs_team";
                                _rooms = [];
                              });
                            } else if (val == AppLocalizations.individual) {
                              setState(() {
                                selectedGameMode = "1v1";
                                _rooms = [];
                              });
                            }
                            developer.log(
                              'Selected game mode: $selectedGameMode',
                              name: _logTag,
                            );
                            // _loadRooms();
                          },
                          hintText: AppLocalizations.mode,
                          items: [
                            // AppLocalizations.team,
                            AppLocalizations.individual
                          ],
                          iconColor: Colors.blueAccent,
                          isStatic: false, // Make it static/unchangeable
                          isTablet: isTablet,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 16.0 : 12.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 16.w),
                  child: SizedBox(
                    width: double.infinity,
                    height: isTablet ? 60 : 48.h,
                    child: ElevatedButton(
                      onPressed: allFilled && !_isLoading
                          ? () async {
                              setState(() {
                                _rooms = []; // clear old results
                              });
                              await _loadRooms();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                      child: Text(
                        "Search Rooms",
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: isTablet ? 24.0 : 16.h),

                // Rooms Container
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24.0 : 12.w),
                    padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 24.0 : 16.h,
                        horizontal: isTablet ? 20.0 : 12.w),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            begin: AlignmentGeometry.topCenter,
                            end: AlignmentGeometry.bottomCenter,
                            colors: [
                              Color.fromARGB(255, 34, 52, 96),
                              Color.fromARGB(
                                255,
                                17,
                                29,
                                63,
                              ),
                              Color.fromARGB(
                                255,
                                17,
                                29,
                                63,
                              ),
                              Color.fromARGB(
                                255,
                                17,
                                29,
                                63,
                              ),
                              Color.fromARGB(
                                255,
                                22,
                                43,
                                81,
                              ),
                            ]),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                            color: const Color.fromARGB(255, 52, 91, 168), width: 1)),
                    child: allFilled
                        ? _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white),
                              )
                            : _rooms.isEmpty
                                ? Center(
                                    child: Text(
                                      _isLoading
                                        ? ""
                                        : "No rooms found. Try different filters",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: isTablet ? 24.0 : 16.sp,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _rooms.length,
                                    separatorBuilder: (_, __) =>
                          SizedBox(height: isTablet ? 20.0 : 16.h),
                                    itemBuilder: (context, index) {
                                      final room = _rooms[index];
                        return _buildRoomCard(room, isTablet: isTablet);
                                    },
                                  )
                        : Center(
                      child: Text(
                        AppLocalizations.selectAllFiltersToViewRooms,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: isTablet ? 20.0 : 16.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Persistent Banner Ad (app-wide, loaded once)
                const PersistentBannerAdWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to check if language is English
  bool _isEnglishLanguage(String? language) {
    if (language == null) return false;
    final normalized = language.toLowerCase();
    return normalized == 'english' || normalized == 'en';
  }

  // Helper widget for handling both Dropdowns and Static Toggles
  Widget _buildFilterPill({
    required IconData icon,
    String? value,
    List<String>? items,
    ValueChanged<String?>? onChanged, // Used for dropdowns
    VoidCallback? onTap, // Used for static/toggle buttons
    required String hintText,
    Color iconColor = Colors.white,
    bool isStatic =
        false, // If true, ignore dropdown logic and just execute onTap
    bool isToggle = false,
    String? image, // If true, ignore dropdown logic and just execute onTap
    bool isTablet = false,
  }) {
    final GlobalKey tapKey = GlobalKey();
    final String displayValue = value ?? hintText;
    final bool isInteractive = onChanged != null || onTap != null;
    final bool isDropdown =
        !isStatic && !isToggle; // True if it should open a menu

    final bool isFilled = value != null;

    // Increased height and padding for tablet
    return Container(
      height: isTablet ? 65.0 : 45.h, // Increased height for larger font
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
        // Use a subtle gradient/border for styling
        border: Border.all(color: Colors.white, width: isTablet ? 2.0 : 1.w),
        color: isFilled ? Colors.black.withOpacity(0.35) : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: tapKey,
          borderRadius: BorderRadius.circular(25.r),
          onTap: (_isEnglishLanguage(selectedLanguage) && hintText == AppLocalizations.script) || (isDropdown && onChanged == null)
              ? null
              : isDropdown
                  ? () async {
                      // If it's a dropdown, show the bottom sheet
                      FocusScope.of(context).unfocus();
                      final result = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => SelectionBottomSheet(
                          title: hintText,
                          items: items ?? [],
                          selectedItem: value,
                        ),
                      );
                      if (result != null && onChanged != null) {
                        onChanged(result);
                      }
                    }
                  : onTap, // If it's a static/toggle button, execute the direct onTap

          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20.0 : 10.w,
                vertical: isTablet ? 12.0 : 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (image != null) ...[
                  Image.asset(
                    image,
                    height: isTablet ? 32.0 : 18.h, // Use 32 if image is present
                    width: isTablet ? 32.0 : 18.w,
                  ),
                  SizedBox(width: isTablet ? 12.0 : 8.w),
                ] else ...[
                  Icon(icon,
                      color: iconColor,
                      size: isTablet ? 32.0 : 18.sp), // Increased icon size
                  SizedBox(width: isTablet ? 12.0 : 8.w),
                ],
                Expanded(
                  child: Text(
                    displayValue,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.lato(
                      color: isFilled ? Colors.white : Colors.white54,
                      fontSize: isTablet ? 22.0 : 13.sp, // Increased font size
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
                if (isDropdown) ...[
                  SizedBox(width: isTablet ? 10.0 : 6.w),
                  Icon(Icons.keyboard_arrow_down_rounded, // Improved icon
                      color: Colors.white70, size: isTablet ? 32.0 : 16.sp), // Increased arrow size
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectCategoryPill({
    required IconData icon,
    required List<String> selectedValues,
    required List<String> items,
    required ValueChanged<List<String>> onChanged,
    required String hintText,
    Color iconColor = Colors.white,
    String? image,
    bool isTablet = false,
  }) {
    final GlobalKey tapKey = GlobalKey();
    final displayText = selectedValues.isEmpty
        ? hintText
        : selectedValues.length == 1
            ? AppLocalizations.oneCategorySelected
            : '${selectedValues.length} ${AppLocalizations.categoriesSelected}';

    return Container(
      height: isTablet ? 65.0 : 45.h, // Increased height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: Colors.white, width: isTablet ? 2.0 : 1.w),
        color: selectedValues.isNotEmpty ? Colors.black.withOpacity(0.35) : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: tapKey,
          borderRadius: BorderRadius.circular(25.r),
          onTap: () async {
            FocusScope.of(context).unfocus();
            final result = await showModalBottomSheet<List<String>>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => MultiSelectionBottomSheet(
                title: hintText,
                items: items,
                selectedItems: selectedValues,
              ),
            );
            if (result != null) {
              onChanged(result);
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20.0 : 10.w,
                vertical: isTablet ? 12.0 : 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (image != null) ...[
                  Image.asset(
                    image,
                    height: isTablet ? 32.0 : 18.h,
                    width: isTablet ? 32.0 : 18.w,
                  ),
                  SizedBox(width: isTablet ? 12.0 : 8.w),
                ] else ...[
                  Icon(icon, 
                      color: iconColor, 
                      size: isTablet ? 32.0 : 18.sp), // Increased size
                  SizedBox(width: isTablet ? 12.0 : 8.w),
                ],
                Expanded(
                  child: Text(
                    displayText,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.lato(
                      color: selectedValues.isEmpty ? Colors.white54 : Colors.white,
                      fontSize: isTablet ? 22.0 : 13.sp, // Increased font
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 10.0 : 6.w),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70, size: isTablet ? 32.0 : 16.sp), // Increased arrow size
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientDropdown({
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hintText,
    Color iconColor = Colors.white,
  }) {
    return _buildFilterPill(
      icon: icon,
      value: value,
      items: items,
      onChanged: onChanged,
      hintText: hintText,
      iconColor: iconColor,
    );
  }

  // --- Existing logic (kept for completeness) ---

  Widget _buildRoomCard(RoomModel room, {bool isTablet = false}) {
    const Color gradientStartColor =
        Color.fromRGBO(110, 136, 206, 1); // rgba(110, 136, 206, 1)
    const Color gradientEndColor =
        Color.fromRGBO(44, 61, 106, 1); // rgba(44, 61, 106, 1)

    // The thickness of the gradient border
    const double borderWidth = 1.2;
    return GestureDetector(
      onTap: room.isFull == true ? null : () => _joinRoom(room),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20.0 : 14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isTablet ? 20.0 : 16.r),
          border: BoxBorder.fromLTRB(
            bottom: const BorderSide(
              color: Color.fromRGBO(31, 48, 96, 1),
              width: borderWidth,
            ),
          ),
        ),
        child: Row(
          children: [
            // Icon Circle
            Container(
              // 1. Outer Container: Applies the Gradient
              height: isTablet ? 70.0 : 50.h,
              width: isTablet ? 70.0 : 50.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular((isTablet ? 20.0 : 16.r) + borderWidth),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gradientStartColor, gradientEndColor],
                ),
              ),
              padding: const EdgeInsets.all(borderWidth), // Creates the border gap

              // 2. Inner Container: Holds the original content
              child: Container(
                decoration: BoxDecoration(
                  // Use the original solid background color
                  color: const Color.fromARGB(255, 26, 42, 81),
                  borderRadius: BorderRadius.circular(isTablet ? 20.0 : 16.r),
                ),
                child: Center(
                  child: Image.asset(
                    _getCategoryIcon(_roomCategoryString(room)),
                    width: isTablet ? 74.0 : 53.w,
                    height: isTablet ? 78.0 : 57.h,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.category,
                      color: Colors.white,
                      size: isTablet ? 40.0 : 32.sp,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: isTablet ? 16.0 : 12.w),

            // Room Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  SizedBox(
                    height: isTablet ? 32.0 : 24.h,
                    child: Row(
                      children: [
                        Text(
                          room.name ?? 'Room',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 20.0 : 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        VerticalDivider(
                          width: isTablet ? 32.0 : 24.h,
                          color: const Color.fromRGBO(76, 99, 162, 1),
                        ),
                        (room.gameMode != null &&
                                room.gameMode == 'team_vs_team')
                            ? Text(
                                '👥vs👥',
                                style: TextStyle(
                            fontSize: isTablet ? 16.0 : 13.sp,
                                  color: const Color.fromRGBO(132, 156, 206, 1),
                                ),
                              )
                            : Text(
                                '👤vs👤',
                                style: TextStyle(
                            fontSize: isTablet ? 16.0 : 13.sp,
                                  color: const Color.fromRGBO(132, 156, 206, 1),
                                ),
                              ),
                        SizedBox(
                          width: isTablet ? 20.0 : 15.w,
                        ),
                        Text(
                          _getCountryFlag(room.country ?? 'India'),
                          style: TextStyle(fontSize: isTablet ? 20.0 : 16.sp),
                        ),
                        const Spacer(),
                        if (room.voiceEnabled == true) ...[
                          SizedBox(height: isTablet ? 10.0 : 8.h),
                          Icon(
                            Icons.mic,
                            color: const Color.fromRGBO(132, 156, 206, 1),
                            size: isTablet ? 24.0 : 20.sp,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: isTablet ? 10.0 : 8.h),
                  // Info Row
                  SizedBox(
                    height: isTablet ? 32.0 : 24.h,
                    child: Row(
                      children: [
                        Icon(Icons.people,
                            color: const Color.fromRGBO(132, 156, 206, 1),
                            size: isTablet ? 18.0 : 14.sp),
                        SizedBox(width: 4.w),
                        Text(
                          '${room.participantCount}/${room.maxPlayers}',
                          style: TextStyle(
                            color: const Color.fromRGBO(132, 156, 206, 1),
                            fontSize: isTablet ? 16.0 : 13.sp,
                          ),
                        ),
                        SizedBox(width: isTablet ? 16.0 : 12.w),
                        Icon(Icons.star,
                            color: const Color.fromRGBO(132, 156, 206, 1),
                            size: isTablet ? 18.0 : 14.sp),
                        SizedBox(width: 4.w),
                        Text(
                          '${room.pointsTarget}',
                          style: TextStyle(
                            color: const Color.fromRGBO(132, 156, 206, 1),
                            fontSize: isTablet ? 16.0 : 13.sp,
                          ),
                        ),
                        SizedBox(width: isTablet ? 40.0 : 30.w),
                        _buildBadge(
                            room.language?.substring(0, 2).toUpperCase() ??
                                'EN', isTablet: isTablet),
                        const VerticalDivider(
                            color: Color.fromRGBO(132, 156, 206, 1),
                            thickness: 1),
                        _buildBadge(
                            room.script?.substring(0, 2).toUpperCase() ?? 'EN', isTablet: isTablet),
                      ], 
                    ),
                  ),
                ],
              ),
            ),

            // Right Column
          ],
        ),
      ),
    );
  }



  Widget _buildBadge(String text, {bool isTablet = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 10.0 : 8.w, vertical: isTablet ? 4.0 : 2.h),
      child: Text(
        text,
        style: TextStyle(
          color: const Color.fromRGBO(148, 175, 231, 1),
          fontSize: isTablet ? 14.0 : 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getCountryFlag(String? country) {
    // Handle both ISO-2 codes and old country names for backward compatibility
    if (country == null || country.isEmpty) return '🏳️';
    
    // If it's already an ISO-2 code (2 characters), use CountryPickerWidget helper
    if (country.length == 2) {
      return CountryPickerWidget.getCountryFlag(country);
    }
    
    // Backward compatibility: Map old country names to ISO-2 codes
    final Map<String, String> countryNameToCode = {
      'India': 'IN',
      'USA': 'US',
      'UK': 'GB',
      'United Kingdom': 'GB',
      'Russia': 'RU',
      'Ukraine': 'UA',
      'Canada': 'CA',
      'Japan': 'JP',
      'Spain': 'ES',
      'Portugal': 'PT',
      'France': 'FR',
      'Germany': 'DE',
    };
    
    final code = countryNameToCode[country] ?? country;
    return CountryPickerWidget.getCountryFlag(code);
  }

  bool get allFilled =>
      selectedLanguage != null &&
      selectedScript != null &&
      // selectedCountry != null && // Country is optional
      selectedPoints != null &&
      selectedCategories.isNotEmpty &&
      selectedGameMode != null;

  /// Delimiter for encoding multiple categories in route path (must match routes.dart parsing).
  static const String _categoriesPathDelimiter = ',';

  /// Normalizes RoomModel's dynamic category (String or List from API) to a list of category strings.
  List<String> _roomCategoriesList(RoomModel room) {
    final c = room.category;
    if (c == null) return ['Animals'];
    if (c is String) return c.isNotEmpty ? [c] : ['Animals'];
    if (c is List && c.isNotEmpty) {
      return c
          .map((e) => e is String ? e : e?.toString())
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();
    }
    return ['Animals'];
  }

  /// Single category string for display (e.g. icon); uses first category.
  String _roomCategoryString(RoomModel room) {
    final list = _roomCategoriesList(room);
    return list.isNotEmpty ? list.first : 'Animals';
  }

  /// Encodes categories for route path (comma-separated).
  String _encodeCategoriesForPath(List<String> categories) {
    if (categories.isEmpty) return 'Animals';
    return categories.join(_categoriesPathDelimiter);
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
        return AppImages.animal;
    }
  }

  Future<String?> _showDropdownMenu(List<String> items) async {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return null;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero, ancestor: overlay),
        renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    return showMenu<String>(
      context: context,
      position: position,
      color: const Color(0xFF1E3A5F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      items: items.map((item) {
        return PopupMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
        );
      }).toList(),
    );
  }
}