// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.
// @dart=2.12
// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = MessageLookup();

typedef String? MessageIfAbsent(
    String? messageStr, List<Object>? args);

class MessageLookup extends MessageLookupByLibrary {
  @override
  String get localeName => 'en';

  static m0(count) => "${count} songs ready";

  static m1(count) => "${count} songs sent.";

  static m2(count) => "Skipped: ${count} songs";

  static m3(title) => "Do you want to permanently delete \"${title}\"?\nIt will be removed from all playlists.";

  static m4(error) => "Export error: ${error}";

  static m5(error) => "Import error: ${error}";

  static m6(current, total) => "Frame ${current} / ${total}";

  static m7(count) => "Imported: ${count} songs";

  static m8(count) => "${count} songs";

  static m9(rssi) => "Signal: ${rssi} dBm";

  static m10(title) => "\"${title}\" imported!";

  static m11(title) => "\"${title}\" updated!";

  static m12(count) => "${count} songs imported!";

  @override
  final Map<String, dynamic> messages = _notInlinedMessages(_notInlinedMessages);

  static Map<String, dynamic> _notInlinedMessages(Object? _) => {
      'abuse': MessageLookupByLibrary.simpleMessage('Report abuse'),
    'abuse_desc': MessageLookupByLibrary.simpleMessage('Reason for reporting'),
    'abuse_title': MessageLookupByLibrary.simpleMessage('Do you want to report this song?'),
    'account': MessageLookupByLibrary.simpleMessage('Account'),
    'add': MessageLookupByLibrary.simpleMessage('Add'),
    'add_playlist': MessageLookupByLibrary.simpleMessage('Add a playlist'),
    'add_to_playlist': MessageLookupByLibrary.simpleMessage('Add to playlist'),
    'app_settings': MessageLookupByLibrary.simpleMessage('Application settings'),
    'ask_remove': MessageLookupByLibrary.simpleMessage('Remove?'),
    'ask_remove_desc': MessageLookupByLibrary.simpleMessage('Do you want to remove the playlist: '),
    'auto_scroll': MessageLookupByLibrary.simpleMessage('Autoscroll'),
    'ble_ready_count': m0,
    'ble_sent_count': m1,
    'ble_skipped_count': m2,
    'change': MessageLookupByLibrary.simpleMessage('CHANGE'),
    'choose_font': MessageLookupByLibrary.simpleMessage('Choose a font'),
    'choose_playlist': MessageLookupByLibrary.simpleMessage('Choose a playlist'),
    'choose_scope': MessageLookupByLibrary.simpleMessage('Choose the scope'),
    'chord_color': MessageLookupByLibrary.simpleMessage('Chord\'s color'),
    'chord_color_press': MessageLookupByLibrary.simpleMessage('Press to change'),
    'chose_title': MessageLookupByLibrary.simpleMessage('What is the title of the song?'),
    'church': MessageLookupByLibrary.simpleMessage('Church'),
    'confirm_delete_song': m3,
    'confirmed': MessageLookupByLibrary.simpleMessage('(confirmation)'),
    'create': MessageLookupByLibrary.simpleMessage('CREATE'),
    'create_account': MessageLookupByLibrary.simpleMessage('Create an account'),
    'create_dialog_body': MessageLookupByLibrary.simpleMessage('Remember that the songs will be visible to all users.\nThe songs must be written in the ChordPro format.\nFor example:'),
    'create_dialog_body_more': MessageLookupByLibrary.simpleMessage('Find more on: '),
    'create_dialog_body_sample': MessageLookupByLibrary.simpleMessage('[Do]Camminerò, [La-]camminerò'),
    'create_dialog_title': MessageLookupByLibrary.simpleMessage('You are going to create a new song!'),
    'create_song': MessageLookupByLibrary.simpleMessage('Create song'),
    'description': MessageLookupByLibrary.simpleMessage('Description'),
    'dialog_cancel': MessageLookupByLibrary.simpleMessage('Cancel'),
    'dialog_confirm': MessageLookupByLibrary.simpleMessage('Confirm'),
    'dismiss': MessageLookupByLibrary.simpleMessage('CLOSE'),
    'do_you_want_to_remove': MessageLookupByLibrary.simpleMessage('Do you want to remove \"###\" from the playlist:'),
    'donate': MessageLookupByLibrary.simpleMessage('Donate'),
    'done': MessageLookupByLibrary.simpleMessage('DONE'),
    'edit': MessageLookupByLibrary.simpleMessage('Edit'),
    'edit_song': MessageLookupByLibrary.simpleMessage('Edit the song: '),
    'eg': MessageLookupByLibrary.simpleMessage('E / G'),
    'email': MessageLookupByLibrary.simpleMessage('E-mail'),
    'error_upload_song_graph_parentesis': MessageLookupByLibrary.simpleMessage('Error: Cannot load song, graph brackets not balanced'),
    'error_upload_song_malformed': MessageLookupByLibrary.simpleMessage('Error: Cannot load song, format is wrong'),
    'error_upload_song_missing_chord': MessageLookupByLibrary.simpleMessage('Error: Cannot load the song, no chord'),
    'error_upload_song_parentesis': MessageLookupByLibrary.simpleMessage('Error: Cannot load song, square brackets not balanced'),
    'export_chopack': MessageLookupByLibrary.simpleMessage('Export .chopack'),
    'export_chopro': MessageLookupByLibrary.simpleMessage('Export .chopro'),
    'export_error': m4,
    'export_library': MessageLookupByLibrary.simpleMessage('Export library (.chopack)'),
    'export_pdf': MessageLookupByLibrary.simpleMessage('Export PDF'),
    'font': MessageLookupByLibrary.simpleMessage('Font'),
    'full_library_option': MessageLookupByLibrary.simpleMessage('Full library'),
    'guide': MessageLookupByLibrary.simpleMessage('Guide'),
    'have_an_account_yet': MessageLookupByLibrary.simpleMessage('Do you already have an account? Login'),
    'hello': MessageLookupByLibrary.simpleMessage('Hello'),
    'here_song_text': MessageLookupByLibrary.simpleMessage('Here is the text of the song: '),
    'i_accept_the': MessageLookupByLibrary.simpleMessage('I accept the'),
    'import_collection': MessageLookupByLibrary.simpleMessage('Import collection (.chopack)'),
    'import_error': m5,
    'import_from_file': MessageLookupByLibrary.simpleMessage('Import from file (.cho / .chopro)'),
    'importing_in_progress': MessageLookupByLibrary.simpleMessage('Importing…'),
    'lc': MessageLookupByLibrary.simpleMessage('L / C'),
    'library_section': MessageLookupByLibrary.simpleMessage('LIBRARY'),
    'login': MessageLookupByLibrary.simpleMessage('Log in'),
    'login_desc': MessageLookupByLibrary.simpleMessage('Login to access all features'),
    'login_needed': MessageLookupByLibrary.simpleMessage('Login Required'),
    'logout': MessageLookupByLibrary.simpleMessage('Logout'),
    'look_this_playlist': MessageLookupByLibrary.simpleMessage('Watch this playlist: '),
    'manage_user_password': MessageLookupByLibrary.simpleMessage('CHANGE PASSWORD USER'),
    'multimedia': MessageLookupByLibrary.simpleMessage('Load media'),
    'name_playlist': MessageLookupByLibrary.simpleMessage('Give your playlist a name.'),
    'new_password': MessageLookupByLibrary.simpleMessage('New password'),
    'no_playlist': MessageLookupByLibrary.simpleMessage('There are no playlists yet...'),
    'no_songs_hint': MessageLookupByLibrary.simpleMessage('No songs.\nPress + to add one.'),
    'no_songs_in_file': MessageLookupByLibrary.simpleMessage('No songs found in the file.'),
    'no_songs_to_export': MessageLookupByLibrary.simpleMessage('No songs to export.'),
    'no_songs_to_share': MessageLookupByLibrary.simpleMessage('No songs to share.'),
    'ok': MessageLookupByLibrary.simpleMessage('OK'),
    'old_password': MessageLookupByLibrary.simpleMessage('old password'),
    'open_settings': MessageLookupByLibrary.simpleMessage('Open settings'),
    'other': MessageLookupByLibrary.simpleMessage('Other'),
    'password': MessageLookupByLibrary.simpleMessage('Password'),
    'password_changed': MessageLookupByLibrary.simpleMessage('Password changed'),
    'password_changed_success': MessageLookupByLibrary.simpleMessage('The password has been changed correctly.'),
    'pick_a_color': MessageLookupByLibrary.simpleMessage('Choose a color'),
    'playlist': MessageLookupByLibrary.simpleMessage('Playlist'),
    'playlist_desc': MessageLookupByLibrary.simpleMessage('See all your playlists'),
    'playlist_list': MessageLookupByLibrary.simpleMessage('Playlist list'),
    'playlist_name': MessageLookupByLibrary.simpleMessage('Playlist name'),
    'playlist_option': MessageLookupByLibrary.simpleMessage('Playlist'),
    'please_accept': MessageLookupByLibrary.simpleMessage('Please accept the Terms of service'),
    'qr_footer_text': MessageLookupByLibrary.simpleMessage('The sequence repeats continuously.\nReceivers can join at any time.'),
    'qr_frame_display': m6,
    'qr_imported_count': m7,
    'qr_importing': MessageLookupByLibrary.simpleMessage('Importing…'),
    'qr_point_camera': MessageLookupByLibrary.simpleMessage('Point the camera at this screen'),
    'qr_preparing': MessageLookupByLibrary.simpleMessage('Preparing…'),
    'qr_song_count': m8,
    'reading_file': MessageLookupByLibrary.simpleMessage('Reading file…'),
    'receive_bluetooth': MessageLookupByLibrary.simpleMessage('Receive via Bluetooth'),
    'receive_songs_title': MessageLookupByLibrary.simpleMessage('Receive songs'),
    'receive_via_qr': MessageLookupByLibrary.simpleMessage('Receive via QR'),
    'rs': MessageLookupByLibrary.simpleMessage('R / S'),
    'save': MessageLookupByLibrary.simpleMessage('Save'),
    'search_again': MessageLookupByLibrary.simpleMessage('Search again'),
    'search_devices': MessageLookupByLibrary.simpleMessage('Search for devices'),
    'searching_devices': MessageLookupByLibrary.simpleMessage('Searching for devices…'),
    'select_chopack_file': MessageLookupByLibrary.simpleMessage('Select a .chopack file'),
    'select_chordpro_file': MessageLookupByLibrary.simpleMessage('Select a .chopro, .cho or .txt file'),
    'send': MessageLookupByLibrary.simpleMessage('SEND'),
    'send_bluetooth': MessageLookupByLibrary.simpleMessage('Send via Bluetooth'),
    'send_songs_title': MessageLookupByLibrary.simpleMessage('Send songs'),
    'settings': MessageLookupByLibrary.simpleMessage('Settings'),
    'share': MessageLookupByLibrary.simpleMessage('Share'),
    'share_text': MessageLookupByLibrary.simpleMessage('Share text'),
    'share_via_qr_default_title': MessageLookupByLibrary.simpleMessage('Share via QR'),
    'share_via_qr_menu': MessageLookupByLibrary.simpleMessage('Share via QR'),
    'shut_down': MessageLookupByLibrary.simpleMessage('Close'),
    'signal_strength': m9,
    'song': MessageLookupByLibrary.simpleMessage('track'),
    'song_imported': m10,
    'song_updated': m11,
    'songs': MessageLookupByLibrary.simpleMessage('tracks'),
    'songs_book': MessageLookupByLibrary.simpleMessage('Songsbook'),
    'songs_book_desc': MessageLookupByLibrary.simpleMessage('Read the lyrics of all the songs!'),
    'songs_imported': m12,
    'songs_list': MessageLookupByLibrary.simpleMessage('List of Songs'),
    'start_sending': MessageLookupByLibrary.simpleMessage('Start sending'),
    'sync': MessageLookupByLibrary.simpleMessage('Synchronize'),
    'tags': MessageLookupByLibrary.simpleMessage('Tags'),
    'text_settings': MessageLookupByLibrary.simpleMessage('Text settings'),
    'text_size': MessageLookupByLibrary.simpleMessage('Text size'),
    'text_title': MessageLookupByLibrary.simpleMessage('Title'),
    'title': MessageLookupByLibrary.simpleMessage('Scout Songs'),
    'try_again': MessageLookupByLibrary.simpleMessage('Try again'),
    'unable_to_save': MessageLookupByLibrary.simpleMessage('Unable to Save'),
    'unable_to_update_song': MessageLookupByLibrary.simpleMessage('Error: Cannot load the song'),
    'undo': MessageLookupByLibrary.simpleMessage('CANCEL'),
    'upload_dialog_body': MessageLookupByLibrary.simpleMessage('You are editing this song for all Canti Scout users, are you sure you have edited the text and chords correctly?\nHave you followed the ChordPro standard?\nNot to have made spelling mistakes?'),
    'upload_dialog_title': MessageLookupByLibrary.simpleMessage('Confirm the edit?'),
    'username': MessageLookupByLibrary.simpleMessage('Username'),
    'value_must_not_be_empty': MessageLookupByLibrary.simpleMessage('Value Can\'t Be Empty'),
    'verify_account': MessageLookupByLibrary.simpleMessage('Verify the creation of your account'),
    'verify_account_desc': MessageLookupByLibrary.simpleMessage('A confirmation email has been sent to your address'),
    'what_to_send': MessageLookupByLibrary.simpleMessage('What do you want to send?')
  };
}
