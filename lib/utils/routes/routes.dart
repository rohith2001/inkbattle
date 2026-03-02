import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inkbattle_frontend/presentations/home/bloc/settings_bloc.dart';
import 'package:inkbattle_frontend/presentations/home/screens/instructions.dart';
import 'package:inkbattle_frontend/presentations/multiplayer/multiplayer_screen.dart';
import 'package:inkbattle_frontend/presentations/multiplayer/one_vs_one.dart';
import 'package:inkbattle_frontend/presentations/multiplayer/team_vs_team.dart';
import 'package:inkbattle_frontend/presentations/privacy_safety/privacy_safety_screen.dart';
import 'package:inkbattle_frontend/presentations/profile_edit/profile_edit_screen.dart';
import 'package:inkbattle_frontend/presentations/sign_in/sign_in_screen.dart';
import 'package:inkbattle_frontend/presentations/sign_up/sign_up_screen.dart';
import 'package:inkbattle_frontend/presentations/home/screens/home_screen.dart';
import 'package:inkbattle_frontend/presentations/home/screens/settings_screen.dart';
import 'package:inkbattle_frontend/presentations/guest/guest_signup.dart';
import 'package:inkbattle_frontend/presentations/create_room/create_room.dart';
import 'package:inkbattle_frontend/presentations/game/screens/game_screen.dart';
import 'package:inkbattle_frontend/presentations/room_preferences/room_preferences_screen.dart';
import 'package:inkbattle_frontend/presentations/create_room/create_room_screen.dart';
import 'package:inkbattle_frontend/presentations/join_room/join_room_screen.dart';
import 'package:inkbattle_frontend/presentations/game_room/game_room_screen.dart';
import 'package:inkbattle_frontend/presentations/splash_screen/splash_screen.dart';

class Routes {
  static String initial = "/";
  static String splashScreen = "/splash";
  static String signupScreen = "/signup";
  static String signInScreen = "/signIn";
  static String homeScreen = "/home";
  static String settingsScreen = "/settings";
  static String profileEditScreen = "/profileEditScreen";
  static String privacySafetyScreen = "/privacySafetyScreen";

  static String guestSignupScreen = "/guestsignup";
  static String createRoom = "/createRoom";
  static String gameScreen = "/gameScreen";
  static String multiplayer = "/multiplayer";
  static String onevsone = "/onevsone/:roomId/:category/:points";
  static String teamvsteam = "/teamvsteam/:roomId/:category/:points";
  static String instructions = "/instructions";

  GoRouter get router => _goRouter;
  late final GoRouter _goRouter = GoRouter(
    initialLocation: splashScreen,
    routes: [
      GoRoute(
        path: splashScreen,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: signInScreen,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: signupScreen,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: profileEditScreen,
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: homeScreen,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: privacySafetyScreen,
        builder: (context, state) => const PrivacySafetyScreen(),
      ),
      GoRoute(
        path: settingsScreen,
        builder: (context, state) => BlocProvider(
          create: (_) => SettingsBloc()..add(SettingsInitialEvent()),
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: guestSignupScreen,
        builder: (context, state) => const GuestSignUpScreen(),
      ),
      GoRoute(
        path: createRoom,
        builder: (context, state) => const CreateRoom(),
      ),
      GoRoute(
        path: gameScreen,
        builder: (context, state) => const GameScreen(),
      ),
      GoRoute(
        path: multiplayer,
        builder: (context, state) =>  MultiplayerScreen(),
      ),
      GoRoute(
        path: onevsone,
        builder: (context, state) {
          final categoryParam = state.pathParameters['category'] ?? 'Animals';
          final categories = categoryParam
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          final categoriesList = categories.isEmpty ? ['Animals'] : categories;
          final pointsStr = state.pathParameters['points'] ?? '0';
          final roomId = state.pathParameters['roomId'] ?? 'Unknown';
          final points = int.tryParse(pointsStr) ?? 0;
          return OneVsOneScreen(
              roomModel: state.extra != null
                  ? (state.extra as Map<String, dynamic>?)!["roomModel"]
                  : null,
              categories: categoriesList,
              points: points,
              roomId: roomId);
        },
      ),
      GoRoute(
        path: teamvsteam,
        builder: (context, state) {
          final categoryParam = state.pathParameters['category'] ?? 'Animals';
          final categories = categoryParam
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          final categoriesList = categories.isEmpty ? ['Animals'] : categories;
          final pointsStr = state.pathParameters['points'] ?? '0';
          final roomId = state.pathParameters['roomId'] ?? 'Unknown';
          final points = int.tryParse(pointsStr) ?? 0;
          return TeamVsTeamScreen(
              roomModel: state.extra != null
                  ? (state.extra as Map<String, dynamic>?)!["roomModel"]
                  : null,
              categories: categoriesList,
              points: points,
              roomId: roomId);
        },
      ),
      GoRoute(
        path: instructions,
        builder: (context, state) => const InstructionsScreen(),
      ),
      GoRoute(
        path: '/room-preferences',
        builder: (context, state) => const RoomPreferencesScreen(),
      ),
      GoRoute(
        path: '/create-room',
        builder: (context, state) => const CreateRoomScreen(isTeamMode: false),
      ),
      GoRoute(
        path: '/create-team-room',
        builder: (context, state) => const CreateRoomScreen(isTeamMode: true),
      ),
      GoRoute(
        path: '/join-room',
        builder: (context, state) => const JoinRoomScreen(),
      ),
      GoRoute(
        path: '/game-room/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';

          return GameRoomScreen(
              roomId: roomId,
              selectedTeam: state.extra != null
                  ? (state.extra as Map<String, dynamic>?)!["selectedTeam"]
                  : null);
        },
      ),
    ],
  );
}
