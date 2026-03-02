import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:inkbattle_frontend/utils/preferences/local_preferences.dart';

// ---------------- EVENTS ----------------
abstract class SettingsEvent {}

class SettingsInitialEvent extends SettingsEvent {}

class UpdateSoundValue extends SettingsEvent {
  final double value;
  UpdateSoundValue(this.value);
}

// ---------------- STATE ----------------
class SettingsState extends Equatable {
  final double soundValue;

  const SettingsState({required this.soundValue});

  SettingsState copyWith({double? soundValue}) {
    return SettingsState(
      soundValue: soundValue ?? this.soundValue,
    );
  }

  @override
  List<Object?> get props => [soundValue];
}

// ---------------- BLOC ----------------
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _saveDebounce;

  SettingsBloc() : super(const SettingsState(soundValue: 1.0)) {

    /// Pre-warm player (removes first-touch lag)
    _audioPlayer.setVolume(1.0);

    on<SettingsInitialEvent>(_onSettingsInitial);

    /// ⭐ Restartable transformer (Lag Killer)
    on<UpdateSoundValue>(
      _onUpdateSoundValue,
      transformer: restartable(),
    );
  }

  // ---------------- INITIAL LOAD ----------------
  Future<void> _onSettingsInitial(
    SettingsInitialEvent event,
    Emitter<SettingsState> emit,
  ) async {

    final vol = await LocalStorageUtils.getVolume();

    if (vol == state.soundValue) return;

    _audioPlayer.setVolume(vol);

    emit(state.copyWith(soundValue: vol));
  }

  // ---------------- VOLUME UPDATE ----------------
  void _onUpdateSoundValue(
    UpdateSoundValue event,
    Emitter<SettingsState> emit,
  ) {

    final newVolume = event.value.clamp(0.0, 1.0);

    if (newVolume == state.soundValue) return;

    /// 1️⃣ Instant UI update
    emit(state.copyWith(soundValue: newVolume));

    /// 2️⃣ Non-blocking side effects
    _handleSideEffects(newVolume);
  }

  // ---------------- SIDE EFFECTS ----------------
  void _handleSideEffects(double volume) {

    /// Immediate audio feedback
    unawaited(_audioPlayer.setVolume(volume));

    /// Debounced storage write
    _saveDebounce?.cancel();
    _saveDebounce = Timer(
      const Duration(milliseconds: 500),
      () => LocalStorageUtils.setVolume(volume),
    );
  }

  // ---------------- CLEANUP ----------------
  @override
  Future<void> close() {
    if (_saveDebounce?.isActive ?? false) {
      LocalStorageUtils.setVolume(state.soundValue);
    }
    _saveDebounce?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}