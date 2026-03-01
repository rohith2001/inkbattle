import 'dart:async';

import 'package:flutter/material.dart';

class RoundAnnouncementManager {
  final BuildContext context;
  final Function() onAllComplete;

  /// Builders create a fresh OverlayEntry per sequence so we never re-insert a removed entry
  /// (avoids lifecycle/mounted inconsistencies and stuck overlays after resume).
  final OverlayEntry? Function()? overlay1Builder;
  final OverlayEntry? Function()? overlay2Builder;
  final OverlayEntry? Function()? overlay3Builder;

  Timer? _sequenceTimer;
  Timer? _safetyTimer;

  // Track the visibility state using a list of entries for easy removal
  final List<OverlayEntry> _activeOverlays = [];

  RoundAnnouncementManager({
    required this.context,
    required this.onAllComplete,
    this.overlay1Builder,
    this.overlay2Builder,
    this.overlay3Builder,
  });

  /// When [showOverlay2Soon] is true (e.g. drawer earned points), show overlay2 (guess compliments) soon
  /// so it appears while points are still animating (~2s), instead of after 2.5s.
  void startAnnouncementSequence({bool? isTimeUp, bool showOverlay2Soon = false}) {
    clearSequence();
    final isTimeUpVal = isTimeUp == true;
    final firstDelayMs = showOverlay2Soon ? 400 : 2500;

    final overlay = Overlay.of(context);

    // Capture the exact entry we insert so we remove by reference, not by list position (handles skipped overlay1, early clear, async races).
    OverlayEntry? step1Entry;
    if (isTimeUpVal && overlay1Builder != null) {
      step1Entry = overlay1Builder!();
      if (step1Entry != null) {
        overlay.insert(step1Entry!);
        _activeOverlays.add(step1Entry!);
      }
    }

    // Safety: clear any stuck overlays after 8s so compliment never blocks (phase_change to interval will still come from server)
    _safetyTimer = Timer(Duration(milliseconds: 8000), () {
      if (_activeOverlays.isNotEmpty && context.mounted) {
        clearSequence();
      }
    });

    _sequenceTimer = Timer(Duration(milliseconds: firstDelayMs), () {
      if (!context.mounted) {
        clearSequence();
        return;
      }
      _removeOverlaySafe(step1Entry);

      OverlayEntry? step2Entry;
      if (overlay2Builder != null) {
        step2Entry = overlay2Builder!();
        if (step2Entry != null) {
          overlay.insert(step2Entry!);
          _activeOverlays.add(step2Entry!);
        }
      }

      _sequenceTimer = Timer(const Duration(milliseconds: 2500), () {
        if (!context.mounted) {
          clearSequence();
          return;
        }
        _removeOverlaySafe(step2Entry);

        OverlayEntry? step3Entry;
        if (overlay3Builder != null) {
          step3Entry = overlay3Builder!();
          if (step3Entry != null) {
            overlay.insert(step3Entry!);
            _activeOverlays.add(step3Entry!);
          }
        }

        _sequenceTimer = Timer(const Duration(milliseconds: 2000), () {
          _removeOverlaySafe(step3Entry);
          onAllComplete();
          clearSequence();
        });
      });
    });
  }

  // --- CLEANUP ---

  /// Remove a single entry (try/catch so already-removed or bad state does not throw).
  void _removeOverlaySafe(OverlayEntry? entry) {
    if (entry == null) return;
    try {
      entry.remove();
    } catch (_) {}
    _activeOverlays.remove(entry);
  }

  void clearSequence() {
    _sequenceTimer?.cancel();
    _sequenceTimer = null;
    _safetyTimer?.cancel();
    _safetyTimer = null;

    // Remove all active overlays immediately; always try remove() to avoid stuck overlays (e.g. after resume when mounted can be stale)
    for (var entry in List<OverlayEntry>.from(_activeOverlays)) {
      try {
        entry.remove();
      } catch (_) {}
    }
    _activeOverlays.clear();
  }
}
