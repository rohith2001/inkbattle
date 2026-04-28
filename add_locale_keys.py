# -*- coding: utf-8 -*-
"""Add missing localization keys to lang.dart for locales that only have up to 'movies'."""
import re

path = r'lib\utils\lang.dart'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Blocks to insert: (locale_suffix, next_locale_code, list of "      'key': 'value'," lines)
LOCALES_TO_ADD = [
    ('kn', 'ml', [
        "      'please_select_an_avatar': 'ದಯವಿಟ್ಟು ಅವತಾರವನ್ನು ಆಯ್ಕೆಮಾಡಿ',",
        "      'please_enter_username': 'ದಯವಿಟ್ಟು ಬಳಕೆದಾರ ಹೆಸರನ್ನು ನಮೂದಿಸಿ',",
        "      'please_select_any_language': 'ದಯವಿಟ್ಟು ಯಾವುದೇ ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ',",
        "      'please_select_any_country': 'ದಯವಿಟ್ಟು ಯಾವುದೇ ದೇಶ ಆಯ್ಕೆಮಾಡಿ',",
        "      'please_select_any_category': 'ದಯವಿಟ್ಟು ಯಾವುದೇ ವರ್ಗ ಆಯ್ಕೆಮಾಡಿ',",
        "      'please_select_target_points': 'ದಯವಿಟ್ಟು ಗುರಿ ಅಂಕಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ',",
        "      'please_enter_a_room_code': 'ದಯವಿಟ್ಟು ಕೋಣೆ ಕೋಡ್ ನಮೂದಿಸಿ',",
        "      'choose_from_gallery': 'ಗ್ಯಾಲರಿಯಿಂದ ಆಯ್ಕೆಮಾಡಿ',",
        "      'choose_photos': 'ಫೋಟೋಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ',",
        "      'open_gallery': 'ಗ್ಯಾಲರಿ ತೆರೆಯಿರಿ',",
        "      'search': 'ಹುಡುಕಿ',",
        "      'search_country': 'ದೇಶ ಹುಡುಕಿ...',",
        "      'start_typing_to_search': 'ಹುಡುಕಲು ಟೈಪ್ ಮಾಡಲು ಪ್ರಾರಂಭಿಸಿ...',",
        "      'insufficient_coins_join_with_amount': 'ಸಾಕಷ್ಟು ನಾಣ್ಯಗಳಿಲ್ಲ! ಈ ಕೋಣೆಗೆ ಸೇರಲು %s ನಾಣ್ಯಗಳು ಬೇಕಾಗುತ್ತವೆ.',",
        "      'successfully_joined_room_entry_cost': 'ಕೋಣೆಗೆ ಯಶಸ್ವಿಯಾಗಿ ಸೇರಿದ್ದೀರಿ! ಪ್ರವೇಶ ವೆಚ್ಚ: ',",
        "      'awesome': 'ಅದ್ಭುತ!',",
        "      'claim_now': 'ಈಗ ಪಡೆಯಿರಿ!',",
        "      'purchase_failed': 'ಖರೀದಿ ವಿಫಲ: ',",
        "      'purchase_successful_but_failed_to_add_coins': 'ಖರೀದಿ ಯಶಸ್ವಿ ಆದರೆ ನಾಣ್ಯಗಳನ್ನು ಸೇರಿಸಲು ವಿಫಲ: ',",
        "      'error_processing_purchase': 'ಖರೀದಿ ಸಂಸ್ಕರಣೆ ದೋಷ: ',",
        "      'purchase_already_in_progress': 'ಖರೀದಿ ಈಗಾಗಲೇ ನಡೆಯುತ್ತಿದೆ. ದಯವಿಟ್ಟು ಕಾಯಿರಿ...',",
        "      'in_app_purchases_only_supported': 'ಇನ್-ಆಪ್ ಖರೀದಿಗಳು Android ಮತ್ತು iOS ಸಾಧನಗಳಲ್ಲಿ ಮಾತ್ರ ಬೆಂಬಲಿತ.',",
        "      'in_app_purchases_not_available': 'ಇನ್-ಆಪ್ ಖರೀದಿಗಳು ಲಭ್ಯವಿಲ್ಲ. ನೀವು ಸೈನ್ ಇನ್ ಆಗಿದ್ದೀರಿ ಎಂದು ಖಚಿತಪಡಿಸಿಕೊಳ್ಳಿ ',",
        "      'failed_to_initiate_purchase': 'ಖರೀದಿ ಪ್ರಾರಂಭಿಸಲು ವಿಫಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ ಅಥವಾ ಸಮಸ್ಯೆ ಮುಂದುವರಿದರೆ ಬೆಂಬಲವನ್ನು ಸಂಪರ್ಕಿಸಿ. (',",
        "      'leave_room': 'ಕೋಣೆ ಬಿಡಿ',",
        "      'do_you_really_want_to_leave_room': 'ನೀವು ನಿಜವಾಗಿಯೂ ಕೋಣೆ ಬಿಡಲು ಬಯಸುವಿರಾ?',",
        "      'exit_button': 'ನಿರ್ಗಮಿಸಿ',",
        "      'an_unexpected_error_occurred': 'ಅನಿರೀಕ್ಷಿತ ದೋಷ ಸಂಭವಿಸಿದೆ.',",
        "      'team_winners': 'ತಂಡ ವಿಜೇತರು!',",
        "      'score': 'ಸ್ಕೋರ್: ',",
        "      'report_an_issue': 'ಸಮಸ್ಯೆ ವರದಿ ಮಾಡಿ',",
        "      'report_member': 'ಸದಸ್ಯರನ್ನು ವರದಿ ಮಾಡಿ',",
        "      'report_drawing': 'ಚಿತ್ರವನ್ನು ವರದಿ ಮಾಡಿ',",
        "      'help_keep_game_fun_and_safe': 'ಆಟವನ್ನು ಖುಷಿ ಮತ್ತು ಸುರಕ್ಷಿತವಾಗಿ ಇರಿಸಲು ನಮಗೆ ಸಹಾಯ ಮಾಡಿ',",
        "      'report_inappropriate_chat': 'ಅನುಚಿತ ಚಾಟ್, ಹೆಸರು ಅಥವಾ ನಡವಳಿಕೆಯನ್ನು ವರದಿ ಮಾಡಿ',",
        "      'report_drawing_description': 'ಯಾರಾದರೂ ಉತ್ತರಗಳು ಅಥವಾ ಆಕ್ಷೇಪಾರ್ಹ ವಿಷಯವನ್ನು ಚಿತ್ರಿಸಿದರೆ ವರದಿ ಮಾಡಿ',",
        "      'report_drawer_only_during_phase': 'ಚಿತ್ರಿಸುವ ಅಥವಾ ಬಹಿರಂಗ ಘಟ್ಟದಲ್ಲಿ ಮಾತ್ರ ಚಿತ್ರಕಾರರನ್ನು ವರದಿ ಮಾಡಬಹುದು.',",
        "      'member_name': 'ಸದಸ್ಯ ಹೆಸರು',",
        "      'please_select_a_member': 'ದಯವಿಟ್ಟು ಸದಸ್ಯರನ್ನು ಆಯ್ಕೆಮಾಡಿ',",
        "      'reason': 'ಕಾರಣ',",
        "      'please_select_a_reason': 'ದಯವಿಟ್ಟು ಕಾರಣವನ್ನು ಆಯ್ಕೆಮಾಡಿ',",
        "      'description': 'ವಿವರಣೆ',",
        "      'enter_description': 'ವಿವರಣೆ ನಮೂದಿಸಿ',",
        "      'please_enter_description': 'ದಯವಿಟ್ಟು ವಿವರಣೆ ನಮೂದಿಸಿ',",
        "      'could_not_get_user_id': 'ಬಳಕೆದಾರ ID ಪಡೆಯಲಾಗಲಿಲ್ಲ. ಇನ್ನೊಬ್ಬ ಸದಸ್ಯರನ್ನು ಪ್ರಯತ್ನಿಸಿ.',",
        "      'submit': 'ಸಲ್ಲಿಸಿ',",
        "      'submitted': 'ಸಲ್ಲಿಸಲಾಗಿದೆ',",
        "      'pick_a_color': 'ಬಣ್ಣ ಆಯ್ಕೆಮಾಡಿ!',",
        "      'continue_button': 'ಮುಂದುವರಿಸಿ',",
        "      'server_syncing_try_again': 'ಸರ್ವರ್ ಸಿಂಕ್ ಆಗುತ್ತಿದೆ. ಕ್ಷಣಗಳಲ್ಲಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',",
        "      'both_teams_need_players_exiting': 'ಎರಡೂ ತಂಡಗಳಿಗೆ ಕನಿಷ್ಠ 2 ಆಟಗಾರರು ಬೇಕಾಗುತ್ತಾರೆ. ಕೋಣೆ ಬಿಡುತ್ತಿದ್ದೇವೆ...',",
        "      'you_were_removed_by_host': 'ಹೋಸ್ಟ್ ನಿಮ್ಮನ್ನು ತೆಗೆದುಹಾಕಿದ್ದಾರೆ.',",
        "      'name_was_removed_by_host': ' ಅವರನ್ನು ಹೋಸ್ಟ್ ತೆಗೆದುಹಾಕಿದ್ದಾರೆ.',",
        "      'system': 'ಸಿಸ್ಟಂ: ',",
        "      'name_missed_turn_selecting_next': ' ತಮ್ಮ ಸರದಿ ಕಳೆದುಕೊಂಡರು. ಮುಂದಿನ ಕಲಾವಿದರನ್ನು ಆಯ್ಕೆಮಾಡುತ್ತಿದ್ದೇವೆ...',",
        "      'you_are_right': 'ನೀವು ಸರಿ!',",
        "      'correct_answer_was': 'ಸರಿಯಾದ ಉತ್ತರ',",
        "      'all_players_must_tap_ready': 'ಪ್ರಾರಂಭಿಸುವ ಮೊದಲು ಎಲ್ಲ ಆಟಗಾರರು ರೆಡಿ ಟ್ಯಾಪ್ ಮಾಡಬೇಕು',",
        "      'both_teams_need_players': 'ಎರಡೂ ತಂಡಗಳಿಗೆ ಕನಿಷ್ಠ 2 ಆಟಗಾರರು ಬೇಕಾಗುತ್ತಾರೆ',",
        "      'failed_to_select_team': 'ತಂಡ ಆಯ್ಕೆಮಾಡಲು ವಿಫಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',",
        "      'room_code_copied': 'ಕೋಣೆ ಕೋಡ್ ನಕಲಿಸಲಾಗಿದೆ!',",
        "      'spectating': '(ನೋಡುತ್ತಿರುವವರು)',",
        "      'nice_try': '👌 ಒಳ್ಳೆಯ ಪ್ರಯತ್ನ!',",
        "      'select_country': 'ದೇಶ ಆಯ್ಕೆಮಾಡಿ',",
        "      'skip_button': 'ಬಿಟ್ಟುಬಿಡಿ ',",
        "      'room_code_placeholder': 'XXXXX',",
        "      'report_reason_spam': 'ಸ್ಪ್ಯಾಮ್',",
        "      'report_reason_abuse': 'ದುರುಪಯೋಗ',",
        "      'report_reason_other': 'ಇತರೆ',",
        "      'eliminated_for_inactivity': 'ನಿಷ್ಕ್ರಿಯತೆಯಿಂದ ತೆಗೆದುಹಾಕಲಾಗಿದೆ',",
        "      'room_closed': 'ಕೋಣೆ ಮುಚ್ಚಲಾಗಿದೆ: ',",
        "      'no_active_participants': 'ಸಕ್ರಿಯ ಭಾಗವಹಿಸುವವರು ಇಲ್ಲ',",
        "      'unknown_error': 'ಅಜ್ಞಾತ ದೋಷ',",
        "      'only_host_can_start_game': 'ಹೋಸ್ಟ್ ಮಾತ್ರ ಆಟ ಪ್ರಾರಂಭಿಸಬಹುದು',",
        "      'need_at_least_2_players_to_start': 'ಪ್ರಾರಂಭಿಸಲು ಕನಿಷ್ಠ 2 ಆಟಗಾರರು ಬೇಕಾಗುತ್ತಾರೆ',",
        "      'insufficient_coins_to_start': 'ಪ್ರಾರಂಭಿಸಲು ಸಾಕಷ್ಟು ನಾಣ್ಯಗಳಿಲ್ಲ',",
        "      'all_players_must_tap_ready_before_host': 'ಹೋಸ್ಟ್ ಪ್ರಾರಂಭಿಸುವ ಮೊದಲು ಎಲ್ಲ ಆಟಗಾರರು ರೆಡಿ ಟ್ಯಾಪ್ ಮಾಡಬೇಕು.',",
        "      'only_host_can_remove_players': 'ಹೋಸ್ಟ್ ಮಾತ್ರ ಆಟಗಾರರನ್ನು ತೆಗೆದುಹಾಕಬಹುದು.',",
        "      'cannot_remove_players_during_game': 'ಆಟದ ಸಮಯದಲ್ಲಿ ಆಟಗಾರರನ್ನು ತೆಗೆದುಹಾಕಲು ಸಾಧ್ಯವಿಲ್ಲ.',",
        "      'team_selection_only_in_team_mode': 'ತಂಡ ಆಯ್ಕೆ ತಂಡ ವರ್ಸಸ್ ತಂಡ ಮೋಡ್‌ನಲ್ಲಿ ಮಾತ್ರ ಲಭ್ಯ. ಮೊದಲು ಆಟ ಮೋಡ್ ಬದಲಾಯಿಸಿ.',",
        "      'game_already_started': 'ಆಟ ಈಗಾಗಲೇ ಪ್ರಾರಂಭವಾಗಿದೆ',",
        "      'authentication_error_reconnect': 'ದೃಢೀಕರಣ ದೋಷ. ಮತ್ತೆ ಸಂಪರ್ಕಿಸಿ.',",
        "      'replaced_due_to_inactivity': 'ನಿಷ್ಕ್ರಿಯತೆಯಿಂದ ಯಾರೋ ನಿಮ್ಮನ್ನು ಈ ಕೋಣೆಯಲ್ಲಿ ಬದಲಿಸಿದ್ದಾರೆ.',",
        "      'room_full_max_players': 'ಕೋಣೆ ತುಂಬಿದೆ. ಗರಿಷ್ಠ ಆಟಗಾರರು ತಲುಪಿದ್ದಾರೆ.',",
        "      'you_are_banned_from_room': 'ಈ ಕೋಣೆಯಿಂದ ನಿಮ್ಮ ಮೇಲೆ ನಿಷೇಧವಿದೆ.',",
        "      'room_no_longer_exists_leaving': 'ಕೋಣೆ ಇನ್ನು ಅಸ್ತಿತ್ವದಲ್ಲಿಲ್ಲ. ಬಿಡುತ್ತಿದ್ದೇವೆ.',",
        "      'not_enough_players_exiting_room': 'ಸಾಕಷ್ಟು ಆಟಗಾರರು ಇಲ್ಲ. ಕೋಣೆ ಬಿಡುತ್ತಿದ್ದೇವೆ...',",
        "      'exited_inactive_90_seconds': '೯೦ ಸೆಕೆಂಡುಗಳಿಗಿಂತ ಹೆಚ್ಚು ನಿಷ್ಕ್ರಿಯರಾಗಿದ್ದರಿಂದ ನಿರ್ಗಮಿಸಿದ್ದೀರಿ.',",
    ]),
]

# Pattern: after this locale's block we have "    },\n    'next_locale':"
# We need to find "    },\n    'ml': {" when adding for kn
for locale_suffix, next_locale, lines in LOCALES_TO_ADD:
    pattern = r"(\n    \},\n    '" + next_locale + r"': \{\n)"
    insert_text = ",\n" + "\n".join(lines) + "\n" + "    },\n    '" + next_locale + "': {\n"
    replacement = "\n" + "\n".join(lines) + "\n    },\n    '" + next_locale + "': {\n"
    # We need to insert BEFORE "    }," so we search for the closing of this locale.
    # The locale block ends with "    }," followed by "    'next': {"
    # So we want to replace "    },\n    'ml': {" with "      'key': 'val',\n ... \n    },\n    'ml': {"
    old_block = "    },\n    '" + next_locale + "': {"
    new_block = ",\n" + "\n".join(lines) + "\n    },\n    '" + next_locale + "': {"
    # But the previous line might already end with comma (movies line). So we look for
    # "'movies': '...',\n    },\n    'next':"
    # and replace with "'movies': '...',\n" + lines + "\n    },\n    'next':"
    count = 0
    def replacer(m):
        nonlocal count
        count += 1
        return new_block
    content_new, n = re.subn(r"'movies': '[^']*',\n    \},\n    '" + next_locale + r"': \{", 
                             lambda m: m.group(0).replace("    },\n    '" + next_locale + "': {", new_block),
                             content, count=1)
    if n:
        content = content_new
        print("Inserted keys before '%s' (locale ending before %s)" % (next_locale, locale_suffix))
    else:
        print("Pattern not found for locale ending before '%s'" % next_locale)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done.")
