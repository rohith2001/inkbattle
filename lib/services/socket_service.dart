import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:developer';
import 'dart:async'; // Import for Completer
import 'package:inkbattle_frontend/config/environment.dart';



class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _lastToken;

  /// Called when the same socket instance reconnects (e.g. after app resume or server restart).
  /// Use for re-joining room; do NOT create a new socket here.
  void Function()? _onReconnect;

  /// Called when socket disconnects. Use to set connection state to syncing so game actions are blocked until room_joined.
  void Function()? _onDisconnect;

  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;

  /// Register callback to run when socket reconnects (same instance, new connection).
  /// Call once from game screen so we re-join room and sync phase.
  void setOnReconnect(void Function() callback) {
    _onReconnect = callback;
  }

  /// Register callback to run when socket disconnects. Use to set syncing state so user actions are blocked until room_joined.
  void setOnDisconnect(void Function() callback) {
    _onDisconnect = callback;
  }

  /// Connect with token. Uses ONE socket instance; only creates new socket when none exists or token changed (e.g. logout/login).
  /// App resume: do NOT call connect() again — same socket auto-reconnects and listeners stay attached.
  /// Returns true if a new socket was created (caller should register listeners once); false if reusing existing socket.
  bool connect(String token) {
    // Same token and socket exists: do nothing (socket may be disconnected; auto-reconnect will handle).
  if (_socket != null && _lastToken == token) {
    // Ensure auth payload is always refreshed before reconnect attempts.
    _socket!.auth = {'token': token};
    if (!_socket!.connected) {
      log('Socket exists but disconnected → reconnecting');
      _socket!.connect();   // actively re-open connection
    } else {
      log('Socket already connected');
    }
    return false;           // reusing existing instance
  }

    // Token changed or explicit new session: dispose old socket.
    if (_socket != null) {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
      _lastToken = null;
      log('Socket disposed (token change or reset)');
    }

    print("Sending token: $token");
    _lastToken = token;
    _socket = IO.io(
      Environment.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .enableForceNew()
          .setAuth({'token': token})
          .setExtraHeaders({'X-App-Secret': Environment.appSecret})
          .build(),
    );

    _socket?.onConnect((_) {
      _isConnected = true;
      log('Socket connected: ${_socket?.id}');
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
      log('Socket disconnected');
      _onDisconnect?.call();
    });

    _socket?.on('reconnect_attempt', (_) {
      log('Socket reconnect attempt');
    });

    _socket?.on('reconnect', (_) {
      _isConnected = true;
      log('Socket reconnected (same instance): ${_socket?.id}');
      _onReconnect?.call();
    });

    _socket?.on('reconnect_failed', (_) {
      log('Socket reconnect failed (all attempts exhausted)');
    });

    _socket?.onError((error) {
      log('Socket error: $error');
    });

    _socket?.onConnectError((error) {
      log('Socket connection error: $error');
    });
    return true;
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _lastToken = null;
    _onReconnect = null;
    _onDisconnect = null;
    log('Socket disconnected and disposed');
  }

  // New request method for emitting events with acknowledgment
  Future<dynamic> request(String event, [dynamic data]) {
    final completer = Completer<dynamic>();
    if (_socket == null || !_isConnected) {
      completer.completeError('Socket not connected for event: $event');
      return completer.future;
    }

    _socket?.emitWithAck(
      event,
      data,
      ack: (response) {
        if (response is Map && response.containsKey('error')) {
          completer.completeError(response['error']);
        } else {
          completer.complete(response);
        }
      },
    );
    return completer.future;
  }

  // Room events
  /// Join a room using an acknowledged handshake. Returns the raw ack payload:
  /// { ok: true, roomCode, roomId } on success, or { ok: false, error: '...' } on failure.
  Future<Map<String, dynamic>> joinRoomWithAck(String roomId, {String? team}) {
    final completer = Completer<Map<String, dynamic>>();
    if (_socket == null || !_isConnected) {
      completer.complete(<String, dynamic>{
        'ok': false,
        'error': 'not_connected',
      });
      return completer.future;
    }

    final data = <String, dynamic>{'roomId': roomId};
    if (team != null) {
      data['team'] = team;
    }

    _socket?.emitWithAck(
      'join_room',
      data,
      ack: (response) {
        if (completer.isCompleted) return;
        try {
          if (response is Map) {
            completer.complete(Map<String, dynamic>.from(response));
          } else {
            completer.complete(<String, dynamic>{
              'ok': false,
              'error': 'invalid_ack',
            });
          }
        } catch (e) {
          completer.complete(<String, dynamic>{
            'ok': false,
            'error': 'ack_exception',
          });
        }
      },
    );
    log('Joining room (with ack): $roomId${team != null ? ' with team: $team' : ''}');
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        return <String, dynamic>{
          'ok': false,
          'error': 'ack_timeout',
        };
      },
    );
  }

  /// Notify server then fully tear down the client so the old JWT cannot auto-reconnect
  /// (avoids a stale socket identity after leaving the game UI or switching accounts).
  void leaveRoom(String roomId) {
    final s = _socket;
    if (s != null) {
      try {
        s.emit('leave_room', {'roomId': roomId});
      } catch (_) {}
      log('Leaving room: $roomId');
    }
    disconnect();
  }

  // Drawing events
  void sendDrawing(String roomId, Map<String, dynamic> drawData) {
    _socket?.emit('drawing_data', {'roomId': roomId, 'strokes': drawData});
  }

  void clearCanvas(String roomId, [int? canvasVersion]) {
    _socket?.emit('clear_canvas', {
      'roomId': roomId,
      'canvasVersion': canvasVersion,
    });
  }

  // Chat events
  void sendMessage(String roomId, String message, String avatar) {
    _socket?.emit('chat_message',
        {'roomId': roomId, 'content': message, 'avatar': avatar});
  }

  void sendGuess(String roomId, String guess) {
    _socket?.emit('submit_guess', {'roomId': roomId, 'guess': guess});
  }

  void sendHint(String roomId, String revealedWord, int hintsRemaining) {
    _socket?.emit('word_hint', {
      'roomId': roomId,
      'revealedWord': revealedWord,
      'hintsRemaining': hintsRemaining,
    });
  }

  // Game events
  void startGame(String roomId) {
    _socket?.emit('start_game', {'roomId': roomId});
  }

  void setReady(String roomId) {
    _socket?.emit('set_ready', {'roomId': roomId});
  }

  void setNotReady(String roomId) {
    _socket?.emit('set_not_ready', {'roomId': roomId});
  }

  void removeParticipant(String roomId, dynamic userId) {
    _socket?.emit('remove_participant', {'roomId': roomId, 'userId': userId});
  }

  void nextRound(String roomId) {
    _socket?.emit('next_round', {'roomId': roomId});
  }

  void continueWaiting(String roomId) {
    _socket?.emit('continue_waiting', {'roomId': roomId});
  }

  // Listeners
  void onServerSyncing(void Function() callback) {
    _socket?.on('server_syncing', (_) => callback());
  }

  void onRoomJoined(Function(dynamic) callback) {
    _socket?.on('room_joined', callback);
  }

  void onRoomParticipants(Function(dynamic) callback) {
    _socket?.on('room_participants', callback);
  }

  void onUserBannedFromGame(Function(dynamic) callback) {
    _socket?.on('user_banned_from_room', callback);
  }

  void onUserKickedFromGame(Function(dynamic) callback) {
    _socket?.on('user_banned', callback);
  }

  void onRequestCanvasData(Function(dynamic) callback) {
    ///  {roomCode: room.code,
    ///  targetSocketId: resumingSocketId }
    ///
    _socket?.on('request_canvas_data', callback);
  }

  void onCanvasDataReceived(Function(dynamic) callback) {
    /// {
    /// roomCode: roomCode,
    ///history: history,
    ///}
    _socket?.on('canvas_resume', callback);
  }

  void onPlayerJoined(Function(dynamic) callback) {
    _socket?.on('player_joined', callback);
  }

  void onPlayerLeft(Function(dynamic) callback) {
    _socket?.on('player_left', callback);
  }

  void onPlayerRemoved(Function(dynamic) callback) {
    _socket?.on('player_removed', callback);
  }
  void onEliminatePlayer(Function(dynamic) callback){
    _socket?.on('eliminate_player',callback);
  }

  void onDraw(Function(dynamic) callback) {
    _socket?.on('drawing_data', callback);
  }

  void onDrawingData(Function(dynamic) callback) {
    _socket?.on('drawing_data', callback);
  }

  //  Acknowledgment listener for drawing data
  void onDrawingAck(Function(dynamic) callback) {
    _socket?.on('drawing_ack', callback);
  }

  void onClearCanvas(Function(dynamic) callback) {
    _socket?.on('clear_canvas', callback);
  }

  void onCanvasClear(Function(dynamic) callback) {
    _socket?.on('canvas_cleared', callback);
  }

  void onChatMessage(Function(dynamic) callback) {
    _socket?.on('chat_message', callback);
  }

  void onCorrectGuess(Function(dynamic) callback) {
    _socket?.on('correct_guess', callback);
  }

  void onGuessResult(Function(dynamic) callback) {
    _socket?.on('guess_result', callback);
  }

  void onIncorrectGuess(Function(dynamic) callback) {
    _socket?.on('incorrect_guess', callback);
  }

  void onWordHint(Function(dynamic) callback) {
    _socket?.on('word_hint', callback);
  }

  void onGameStart(Function(dynamic) callback) {
    _socket?.on('game_started', callback);
  }

  void onRoundStart(Function(dynamic) callback) {
    _socket?.on('round_started', callback);
  }

  void onRoundEnd(Function(dynamic) callback) {
    _socket?.on('round_end', callback);
  }

  void onGameEnd(Function(dynamic) callback) {
    _socket?.on('game_end', callback);
  }

  void onScoreUpdate(Function(dynamic) callback) {
    _socket?.on('score_update', callback);
  }

  void onSkipTurn(Function(dynamic) callback) {
    _socket?.on('skip_turn', callback);
  }

  void onLobbyTimeExceeded(Function(dynamic) callback) {
    /*{
      "roomCode": "ABC12",
      "message": "It looks like everyone left! Do you want to continue waiting or exit?",
      "duration": 120
    } */
    _socket?.on('lobby_time_exceeded', callback);
  }

  void onRoomClosed(Function(dynamic) callback) {
    _socket?.on('room_closed', callback);
  }

  // New events for refactored game
  void onSettingsUpdated(Function(dynamic) callback) {
    _socket?.on('settings_updated', callback);
  }

  void onPhaseChange(Function(dynamic) callback) {
    _socket?.on('phase_change', callback);
  }

  void onDrawerSelected(Function(dynamic) callback) {
    _socket?.on('drawer_selected', callback);
  }

  void onWordOptions(Function(dynamic) callback) {
    _socket?.on('word_options', callback);
  }

  void onDrawerSkipped(Function(dynamic) callback) {
    _socket?.on('drawer_skipped', callback);
  }

  void onTimeUpdate(Function(dynamic) callback) {
    _socket?.on('time_update', callback);
  }

  void onClearChat(Function(dynamic) callback) {
    _socket?.on('clear_chat', callback);
  }

  // void onPrepareToLeavePermanently(Function(dynamic) callback) {
  //   _socket?.on('prepare_to_leave_permanently', callback);
  // }

  void onGameStarted(Function(dynamic) callback) {
    _socket?.on('game_started', callback);
  }

  void onGameEnded(Function(dynamic) callback) {
    _socket?.on('game_ended', callback);
  }

  void onGameEndedInsufficientPlayers(Function(dynamic) callback) {
    _socket?.on('game_ended_insufficient_players', callback);
  }

  void onExitedDueToInactivity(Function(dynamic) callback) {
    _socket?.on('exited_due_to_inactivity', callback);
  }

  void onRoomBackToLobby(Function(dynamic) callback) {
    _socket?.on('room_back_to_lobby', callback);
  }

  void onServerRestarting(Function(dynamic) callback) {
    _socket?.on('server:restarting', callback);
  }

  // Emit new events
  void updateSettings(String roomId, Map<String, dynamic> settings) {
    _socket?.emit('update_settings', {'roomId': roomId, 'settings': settings});
  }

  // Emits to server: "I'm leaving for real" (e.g. app detached / remove from recents). Server uses short grace (1s) instead of 90s.
  void emitPrepareToLeavePermanently() {
    _socket?.emit('prepare_to_leave_permanently');
  }

  void sendCanvasData(String roomCode, String targetSocketId,
      List<Map<String, dynamic>> history, double remainingTime,
      {int lastSequence = 0, Object? targetUserId}) {
    final payload = <String, dynamic>{
      'roomCode': roomCode,
      'targetSocketId': targetSocketId,
      'history': history,
      'remainingTime': remainingTime,
      'lastSequence': lastSequence,
    };
    if (targetUserId != null) payload['targetUserId'] = targetUserId;
    _socket?.emit('send_canvas_data', payload);
  }

  /// Call after applying canvas_resume snapshot so server stops skipping drawing_data for this socket.
  void emitResyncDone() {
    _socket?.emit('resync_done');
  }

  void skipTurn(String roomid) {
    _socket!.emit('skip_turn', {"roomId": roomid});
  }

  void selectTeam(String roomId, String team) {
    print("selecting Team");
    _socket?.emit('select_team', {'roomId': roomId, 'team': team});
  }

  void chooseWord(String roomId, String word) {
    _socket?.emit('choose_word', {'roomId': roomId, 'word': word});
  }

  /// Removes all game listeners then runs [register]. Ensures remove and register
  /// run sequentially and never in parallel with another replaceGameListeners call.
  void replaceGameListeners(void Function() register) {
    removeAllListeners();
    register();
  }

  // Remove listeners (e.g. when leaving game screen). Also clear reconnect callback so we don't hold widget reference.
  void removeAllListeners() {
    _onReconnect = null;
    _socket?.off('room_joined');
    _socket?.off('room_participants');
    _socket?.off('player_joined');
    _socket?.off('player_left');
    _socket?.off('player_removed');
    _socket?.off('drawing_data');
    _socket?.off('clear_canvas');
    _socket?.off('canvas_cleared');
    _socket?.off('chat_message');
    _socket?.off('correct_guess');
    _socket?.off('guess_result');
    _socket?.off('game_started');
    _socket?.off('round_started');
    _socket?.off('round_end');
    _socket?.off('game_end');
    _socket?.off('score_update');
    _socket?.off('room_closed');
    _socket?.off('settings_updated');
    _socket?.off('phase_change');
    _socket?.off('drawer_selected');
    _socket?.off('word_options');
    _socket?.off('drawer_skipped');
    _socket?.off('time_update');
    _socket?.off('clear_chat');
    _socket?.off('game_ended');
    _socket?.off('game_ended_insufficient_players');
    _socket?.off('exited_due_to_inactivity');
    _socket?.off('server:restarting');
    _socket?.off('server_syncing');
  }
}
