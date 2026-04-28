# -*- coding: utf-8 -*-
"""Insert missing locale keys into lang.dart. Inserts before the line that is "    },"
which is followed by "    'NEXT': {" for each locale."""
path = r'lib\utils\lang.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# All keys to add (same key names for all locales). Values per locale.
KEYS_ORDER = [
    'please_select_an_avatar', 'please_enter_username', 'please_select_any_language',
    'please_select_any_country', 'please_select_any_category', 'please_select_target_points',
    'please_enter_a_room_code', 'choose_from_gallery', 'choose_photos', 'open_gallery',
    'search', 'search_country', 'start_typing_to_search', 'insufficient_coins_join_with_amount',
    'successfully_joined_room_entry_cost', 'awesome', 'claim_now', 'purchase_failed',
    'purchase_successful_but_failed_to_add_coins', 'error_processing_purchase',
    'purchase_already_in_progress', 'in_app_purchases_only_supported', 'in_app_purchases_not_available',
    'failed_to_initiate_purchase', 'leave_room', 'do_you_really_want_to_leave_room',
    'exit_button', 'an_unexpected_error_occurred', 'team_winners', 'score', 'report_an_issue',
    'report_member', 'report_drawing', 'help_keep_game_fun_and_safe', 'report_inappropriate_chat',
    'report_drawing_description', 'report_drawer_only_during_phase', 'member_name',
    'please_select_a_member', 'reason', 'please_select_a_reason', 'description',
    'enter_description', 'please_enter_description', 'could_not_get_user_id', 'submit',
    'submitted', 'pick_a_color', 'continue_button', 'server_syncing_try_again',
    'both_teams_need_players_exiting', 'you_were_removed_by_host', 'name_was_removed_by_host',
    'system', 'name_missed_turn_selecting_next', 'you_are_right', 'correct_answer_was',
    'all_players_must_tap_ready', 'both_teams_need_players', 'failed_to_select_team',
    'room_code_copied', 'spectating', 'nice_try', 'select_country', 'skip_button',
    'room_code_placeholder', 'report_reason_spam', 'report_reason_abuse', 'report_reason_other',
    'eliminated_for_inactivity', 'room_closed', 'no_active_participants', 'unknown_error',
    'only_host_can_start_game', 'need_at_least_2_players_to_start', 'insufficient_coins_to_start',
    'all_players_must_tap_ready_before_host', 'only_host_can_remove_players',
    'cannot_remove_players_during_game', 'team_selection_only_in_team_mode', 'game_already_started',
    'authentication_error_reconnect', 'replaced_due_to_inactivity', 'room_full_max_players',
    'you_are_banned_from_room', 'room_no_longer_exists_leaving', 'not_enough_players_exiting_room',
    'exited_inactive_90_seconds'
]

TRANSLATIONS = {
    'kn': [
        'ದಯವಿಟ್ಟು ಅವತಾರವನ್ನು ಆಯ್ಕೆಮಾಡಿ', 'ದಯವಿಟ್ಟು ಬಳಕೆದಾರ ಹೆಸರನ್ನು ನಮೂದಿಸಿ', 'ದಯವಿಟ್ಟು ಯಾವುದೇ ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ',
        'ದಯವಿಟ್ಟು ಯಾವುದೇ ದೇಶ ಆಯ್ಕೆಮಾಡಿ', 'ದಯವಿಟ್ಟು ಯಾವುದೇ ವರ್ಗ ಆಯ್ಕೆಮಾಡಿ', 'ದಯವಿಟ್ಟು ಗುರಿ ಅಂಕಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ',
        'ದಯವಿಟ್ಟು ಕೋಣೆ ಕೋಡ್ ನಮೂದಿಸಿ', 'ಗ್ಯಾಲರಿಯಿಂದ ಆಯ್ಕೆಮಾಡಿ', 'ಫೋಟೋಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ', 'ಗ್ಯಾಲರಿ ತೆರೆಯಿರಿ',
        'ಹುಡುಕಿ', 'ದೇಶ ಹುಡುಕಿ...', 'ಹುಡುಕಲು ಟೈಪ್ ಮಾಡಲು ಪ್ರಾರಂಭಿಸಿ...', 'ಸಾಕಷ್ಟು ನಾಣ್ಯಗಳಿಲ್ಲ! ಈ ಕೋಣೆಗೆ ಸೇರಲು %s ನಾಣ್ಯಗಳು ಬೇಕಾಗುತ್ತವೆ.',
        'ಕೋಣೆಗೆ ಯಶಸ್ವಿಯಾಗಿ ಸೇರಿದ್ದೀರಿ! ಪ್ರವೇಶ ವೆಚ್ಚ: ', 'ಅದ್ಭುತ!', 'ಈಗ ಪಡೆಯಿರಿ!', 'ಖರೀದಿ ವಿಫಲ: ',
        'ಖರೀದಿ ಯಶಸ್ವಿ ಆದರೆ ನಾಣ್ಯಗಳನ್ನು ಸೇರಿಸಲು ವಿಫಲ: ', 'ಖರೀದಿ ಸಂಸ್ಕರಣೆ ದೋಷ: ', 'ಖರೀದಿ ಈಗಾಗಲೇ ನಡೆಯುತ್ತಿದೆ. ದಯವಿಟ್ಟು ಕಾಯಿರಿ...',
        'ಇನ್-ಆಪ್ ಖರೀದಿಗಳು Android ಮತ್ತು iOS ಸಾಧನಗಳಲ್ಲಿ ಮಾತ್ರ ಬೆಂಬಲಿತ.', 'ಇನ್-ಆಪ್ ಖರೀದಿಗಳು ಲಭ್ಯವಿಲ್ಲ. ನೀವು ಸೈನ್ ಇನ್ ಆಗಿದ್ದೀರಿ ಎಂದು ಖಚಿತಪಡಿಸಿಕೊಳ್ಳಿ ',
        'ಖರೀದಿ ಪ್ರಾರಂಭಿಸಲು ವಿಫಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ ಅಥವಾ ಸಮಸ್ಯೆ ಮುಂದುವರಿದರೆ ಬೆಂಬಲವನ್ನು ಸಂಪರ್ಕಿಸಿ. (\'', 'ಕೋಣೆ ಬಿಡಿ', 'ನೀವು ನಿಜವಾಗಿಯೂ ಕೋಣೆ ಬಿಡಲು ಬಯಸುವಿರಾ?', 'ನಿರ್ಗಮಿಸಿ',
        'ಅನಿರೀಕ್ಷಿತ ದೋಷ ಸಂಭವಿಸಿದೆ.', 'ತಂಡ ವಿಜೇತರು!', 'ಸ್ಕೋರ್: ', 'ಸಮಸ್ಯೆ ವರದಿ ಮಾಡಿ', 'ಸದಸ್ಯರನ್ನು ವರದಿ ಮಾಡಿ', 'ಚಿತ್ರವನ್ನು ವರದಿ ಮಾಡಿ',
        'ಆಟವನ್ನು ಖುಷಿ ಮತ್ತು ಸುರಕ್ಷಿತವಾಗಿ ಇರಿಸಲು ನಮಗೆ ಸಹಾಯ ಮಾಡಿ', 'ಅನುಚಿತ ಚಾಟ್, ಹೆಸರು ಅಥವಾ ನಡವಳಿಕೆಯನ್ನು ವರದಿ ಮಾಡಿ', 'ಯಾರಾದರೂ ಉತ್ತರಗಳು ಅಥವಾ ಆಕ್ಷೇಪಾರ್ಹ ವಿಷಯವನ್ನು ಚಿತ್ರಿಸಿದರೆ ವರದಿ ಮಾಡಿ',
        'ಚಿತ್ರಿಸುವ ಅಥವಾ ಬಹಿರಂಗ ಘಟ್ಟದಲ್ಲಿ ಮಾತ್ರ ಚಿತ್ರಕಾರರನ್ನು ವರದಿ ಮಾಡಬಹುದು.', 'ಸದಸ್ಯ ಹೆಸರು', 'ದಯವಿಟ್ಟು ಸದಸ್ಯರನ್ನು ಆಯ್ಕೆಮಾಡಿ', 'ಕಾರಣ', 'ದಯವಿಟ್ಟು ಕಾರಣವನ್ನು ಆಯ್ಕೆಮಾಡಿ',
        'ವಿವರಣೆ', 'ವಿವರಣೆ ನಮೂದಿಸಿ', 'ದಯವಿಟ್ಟು ವಿವರಣೆ ನಮೂದಿಸಿ', 'ಬಳಕೆದಾರ ID ಪಡೆಯಲಾಗಲಿಲ್ಲ. ಇನ್ನೊಬ್ಬ ಸದಸ್ಯರನ್ನು ಪ್ರಯತ್ನಿಸಿ.', 'ಸಲ್ಲಿಸಿ', 'ಸಲ್ಲಿಸಲಾಗಿದೆ',
        'ಬಣ್ಣ ಆಯ್ಕೆಮಾಡಿ!', 'ಮುಂದುವರಿಸಿ', 'ಸರ್ವರ್ ಸಿಂಕ್ ಆಗುತ್ತಿದೆ. ಕ್ಷಣಗಳಲ್ಲಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.', 'ಎರಡೂ ತಂಡಗಳಿಗೆ ಕನಿಷ್ಠ 2 ಆಟಗಾರರು ಬೇಕಾಗುತ್ತಾರೆ. ಕೋಣೆ ಬಿಡುತ್ತಿದ್ದೇವೆ...',
        'ಹೋಸ್ಟ್ ನಿಮ್ಮನ್ನು ತೆಗೆದುಹಾಕಿದ್ದಾರೆ.', ' ಅವರನ್ನು ಹೋಸ್ಟ್ ತೆಗೆದುಹಾಕಿದ್ದಾರೆ.', 'ಸಿಸ್ಟಂ: ', ' ತಮ್ಮ ಸರದಿ ಕಳೆದುಕೊಂಡರು. ಮುಂದಿನ ಕಲಾವಿದರನ್ನು ಆಯ್ಕೆಮಾಡುತ್ತಿದ್ದೇವೆ...',
        'ನೀವು ಸರಿ!', 'ಸರಿಯಾದ ಉತ್ತರ', 'ಪ್ರಾರಂಭಿಸುವ ಮೊದಲು ಎಲ್ಲ ಆಟಗಾರರು ರೆಡಿ ಟ್ಯಾಪ್ ಮಾಡಬೇಕು', 'ಎರಡೂ ತಂಡಗಳಿಗೆ ಕನಿಷ್ಠ 2 ಆಟಗಾರರು ಬೇಕಾಗುತ್ತಾರೆ', 'ತಂಡ ಆಯ್ಕೆಮಾಡಲು ವಿಫಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
        'ಕೋಣೆ ಕೋಡ್ ನಕಲಿಸಲಾಗಿದೆ!', '(ನೋಡುತ್ತಿರುವವರು)', '👌 ಒಳ್ಳೆಯ ಪ್ರಯತ್ನ!', 'ದೇಶ ಆಯ್ಕೆಮಾಡಿ', 'ಬಿಟ್ಟುಬಿಡಿ ', 'XXXXX', 'ಸ್ಪ್ಯಾಮ್', 'ದುರುಪಯೋಗ', 'ಇತರೆ', 'ನಿಷ್ಕ್ರಿಯತೆಯಿಂದ ತೆಗೆದುಹಾಕಲಾಗಿದೆ',
        'ಕೋಣೆ ಮುಚ್ಚಲಾಗಿದೆ: ', 'ಸಕ್ರಿಯ ಭಾಗವಹಿಸುವವರು ಇಲ್ಲ', 'ಅಜ್ಞಾತ ದೋಷ', 'ಹೋಸ್ಟ್ ಮಾತ್ರ ಆಟ ಪ್ರಾರಂಭಿಸಬಹುದು', 'ಪ್ರಾರಂಭಿಸಲು ಕನಿಷ್ಠ 2 ಆಟಗಾರರು ಬೇಕಾಗುತ್ತಾರೆ', 'ಪ್ರಾರಂಭಿಸಲು ಸಾಕಷ್ಟು ನಾಣ್ಯಗಳಿಲ್ಲ',
        'ಹೋಸ್ಟ್ ಪ್ರಾರಂಭಿಸುವ ಮೊದಲು ಎಲ್ಲ ಆಟಗಾರರು ರೆಡಿ ಟ್ಯಾಪ್ ಮಾಡಬೇಕು.', 'ಹೋಸ್ಟ್ ಮಾತ್ರ ಆಟಗಾರರನ್ನು ತೆಗೆದುಹಾಕಬಹುದು.', 'ಆಟದ ಸಮಯದಲ್ಲಿ ಆಟಗಾರರನ್ನು ತೆಗೆದುಹಾಕಲು ಸಾಧ್ಯವಿಲ್ಲ.',
        'ತಂಡ ಆಯ್ಕೆ ತಂಡ ವರ್ಸಸ್ ತಂಡ ಮೋಡ್‌ನಲ್ಲಿ ಮಾತ್ರ ಲಭ್ಯ. ಮೊದಲು ಆಟ ಮೋಡ್ ಬದಲಾಯಿಸಿ.', 'ಆಟ ಈಗಾಗಲೇ ಪ್ರಾರಂಭವಾಗಿದೆ', 'ದೃಢೀಕರಣ ದೋಷ. ಮತ್ತೆ ಸಂಪರ್ಕಿಸಿ.',
        'ನಿಷ್ಕ್ರಿಯತೆಯಿಂದ ಯಾರೋ ನಿಮ್ಮನ್ನು ಈ ಕೋಣೆಯಲ್ಲಿ ಬದಲಿಸಿದ್ದಾರೆ.', 'ಕೋಣೆ ತುಂಬಿದೆ. ಗರಿಷ್ಠ ಆಟಗಾರರು ತಲುಪಿದ್ದಾರೆ.', 'ಈ ಕೋಣೆಯಿಂದ ನಿಮ್ಮ ಮೇಲೆ ನಿಷೇಧವಿದೆ.', 'ಕೋಣೆ ಇನ್ನು ಅಸ್ತಿತ್ವದಲ್ಲಿಲ್ಲ. ಬಿಡುತ್ತಿದ್ದೇವೆ.',
        'ಸಾಕಷ್ಟು ಆಟಗಾರರು ಇಲ್ಲ. ಕೋಣೆ ಬಿಡುತ್ತಿದ್ದೇವೆ...', '೯೦ ಸೆಕೆಂಡುಗಳಿಗಿಂತ ಹೆಚ್ಚು ನಿಷ್ಕ್ರಿಯರಾಗಿದ್ದರಿಂದ ನಿರ್ಗಮಿಸಿದ್ದೀರಿ.',
    ],
}

def make_block(locale):
    vals = TRANSLATIONS[locale]
    out = []
    for i, key in enumerate(KEYS_ORDER):
        v = vals[i].replace("\\", "\\\\").replace("'", "\\'") if "'" in vals[i] else vals[i]
        out.append("      '%s': '%s'," % (key, v))
    return "\n".join(out)

# Find line index (0-based) where we have "    }," followed by "    'ml': {"
# That is the closing of kn. We insert our new lines BEFORE that "    },"
i = 0
while i < len(lines):
    if lines[i].strip() == '},' and i + 1 < len(lines) and "    'ml': {" in lines[i+1]:
        # This is kn's closing. Insert before line i
        indent = '    '
        new_lines = [line + '\n' for line in make_block('kn').split('\n')]
        lines[i:i] = new_lines
        print("Inserted kn keys at line", i+1)
        break
    i += 1
else:
    print("kn block not found")

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print("Done.")
