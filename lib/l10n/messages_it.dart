// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a it locale. All the
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
  String get localeName => 'it';

  static m0(count) => "${count} canzoni pronte";

  static m1(count) => "${count} canzoni inviate.";

  static m2(count) => "Saltate: ${count} canzoni";

  static m3(title) => "Vuoi eliminare definitivamente \"${title}\"?\nVerrà rimossa da tutte le playlist.";

  static m4(error) => "Errore esportazione: ${error}";

  static m5(error) => "Errore importazione: ${error}";

  static m6(current, total) => "Frame ${current} / ${total}";

  static m7(count) => "Importate: ${count} canzoni";

  static m8(count) => "${count} canzoni";

  static m9(rssi) => "Segnale: ${rssi} dBm";

  static m10(title) => "\"${title}\" importata!";

  static m11(title) => "\"${title}\" aggiornata!";

  static m12(count) => "${count} canzoni importate!";

  @override
  final Map<String, dynamic> messages = _notInlinedMessages(_notInlinedMessages);

  static Map<String, dynamic> _notInlinedMessages(Object? _) => {
      'abuse': MessageLookupByLibrary.simpleMessage('Segnala un abuso'),
    'abuse_desc': MessageLookupByLibrary.simpleMessage('Ragione della segnalazione'),
    'abuse_title': MessageLookupByLibrary.simpleMessage('Vuoi segnalare questa canzone?'),
    'account': MessageLookupByLibrary.simpleMessage('Account'),
    'add': MessageLookupByLibrary.simpleMessage('Aggiungi'),
    'add_playlist': MessageLookupByLibrary.simpleMessage('Aggiungi una playlist'),
    'add_to_playlist': MessageLookupByLibrary.simpleMessage('Aggiungi alla playlist'),
    'app_settings': MessageLookupByLibrary.simpleMessage('Impostazioni dell\'applicazione'),
    'ask_remove': MessageLookupByLibrary.simpleMessage('Rimuovere?'),
    'ask_remove_desc': MessageLookupByLibrary.simpleMessage('Vuoi rimuovere la playlist: '),
    'auto_scroll': MessageLookupByLibrary.simpleMessage('Autoscorrimento'),
    'ble_ready_count': m0,
    'ble_sent_count': m1,
    'ble_skipped_count': m2,
    'change': MessageLookupByLibrary.simpleMessage('CAMBIA'),
    'choose_font': MessageLookupByLibrary.simpleMessage('Scegli un font'),
    'choose_playlist': MessageLookupByLibrary.simpleMessage('Scegli una playlist'),
    'choose_scope': MessageLookupByLibrary.simpleMessage('Scegli l\'ambito'),
    'chord_color': MessageLookupByLibrary.simpleMessage('Colore accordi'),
    'chord_color_press': MessageLookupByLibrary.simpleMessage('Premere per modificare'),
    'chose_title': MessageLookupByLibrary.simpleMessage('Quale è il titolo della canzone?'),
    'church': MessageLookupByLibrary.simpleMessage('Chiesa'),
    'confirm_delete_song': m3,
    'confirmed': MessageLookupByLibrary.simpleMessage('(conferma)'),
    'create': MessageLookupByLibrary.simpleMessage('CREA'),
    'create_account': MessageLookupByLibrary.simpleMessage('Crea un account'),
    'create_dialog_body': MessageLookupByLibrary.simpleMessage('Ricordati che le canzoni saranno visibili a tutti gli utenti.\nLe canzoni vanno scritte nel formato ChordPro.\nAd esempio:'),
    'create_dialog_body_more': MessageLookupByLibrary.simpleMessage('Scopri di più su: '),
    'create_dialog_body_sample': MessageLookupByLibrary.simpleMessage('[Do]Camminerò, [La-]camminerò'),
    'create_dialog_title': MessageLookupByLibrary.simpleMessage('Stai per aggiungere una canzone!'),
    'create_song': MessageLookupByLibrary.simpleMessage('Crea canzone'),
    'description': MessageLookupByLibrary.simpleMessage('Descrizione'),
    'dialog_cancel': MessageLookupByLibrary.simpleMessage('Annulla'),
    'dialog_confirm': MessageLookupByLibrary.simpleMessage('Conferma'),
    'dismiss': MessageLookupByLibrary.simpleMessage('CHIUDI'),
    'do_you_want_to_remove': MessageLookupByLibrary.simpleMessage('Vuoi rimuovere \"###\" dalla playlist:'),
    'donate': MessageLookupByLibrary.simpleMessage('Dona'),
    'done': MessageLookupByLibrary.simpleMessage('FATTO'),
    'edit': MessageLookupByLibrary.simpleMessage('Modifica'),
    'edit_song': MessageLookupByLibrary.simpleMessage('Modifica la canzone: '),
    'eg': MessageLookupByLibrary.simpleMessage('E/G'),
    'email': MessageLookupByLibrary.simpleMessage('Email'),
    'error_upload_song_graph_parentesis': MessageLookupByLibrary.simpleMessage('Errore: Impossibile caricare la canzone, parentesi graffe non bilanciate'),
    'error_upload_song_malformed': MessageLookupByLibrary.simpleMessage('Errore: Impossibile caricare la canzone, formattazione errata'),
    'error_upload_song_missing_chord': MessageLookupByLibrary.simpleMessage('Errore: Impossibile caricare la canzone, nessun accordo'),
    'error_upload_song_parentesis': MessageLookupByLibrary.simpleMessage('Errore: Impossibile caricare la canzone, parentesi quadre non bilanciate'),
    'export_chopack': MessageLookupByLibrary.simpleMessage('Esporta .chopack'),
    'export_chopro': MessageLookupByLibrary.simpleMessage('Esporta .chopro'),
    'export_error': m4,
    'export_library': MessageLookupByLibrary.simpleMessage('Esporta libreria (.chopack)'),
    'export_pdf': MessageLookupByLibrary.simpleMessage('Esporta PDF'),
    'font': MessageLookupByLibrary.simpleMessage('Font'),
    'full_library_option': MessageLookupByLibrary.simpleMessage('Libreria completa'),
    'guide': MessageLookupByLibrary.simpleMessage('Guida'),
    'have_an_account_yet': MessageLookupByLibrary.simpleMessage('Hai già un account? Fai Login'),
    'hello': MessageLookupByLibrary.simpleMessage('Hello'),
    'here_song_text': MessageLookupByLibrary.simpleMessage('Ecco il testo della canzone: '),
    'i_accept_the': MessageLookupByLibrary.simpleMessage('Io accetto i'),
    'import_collection': MessageLookupByLibrary.simpleMessage('Importa raccolta (.chopack)'),
    'import_error': m5,
    'import_from_file': MessageLookupByLibrary.simpleMessage('Importa da file (.cho / .chopro)'),
    'importing_in_progress': MessageLookupByLibrary.simpleMessage('Importazione in corso…'),
    'lc': MessageLookupByLibrary.simpleMessage('L/C'),
    'library_section': MessageLookupByLibrary.simpleMessage('LIBRERIA'),
    'login': MessageLookupByLibrary.simpleMessage('Login'),
    'login_desc': MessageLookupByLibrary.simpleMessage('Effettua il login per accedere a tutte le funzionalità'),
    'login_needed': MessageLookupByLibrary.simpleMessage('Richiesto Login'),
    'logout': MessageLookupByLibrary.simpleMessage('Logout'),
    'look_this_playlist': MessageLookupByLibrary.simpleMessage('Guarda questa playlist: '),
    'manage_user_password': MessageLookupByLibrary.simpleMessage('CAMBIA PASSWORD UTENZA'),
    'multimedia': MessageLookupByLibrary.simpleMessage('Carica media'),
    'name_playlist': MessageLookupByLibrary.simpleMessage('Dai un nome alla tua playlist.'),
    'new_password': MessageLookupByLibrary.simpleMessage('Nuova password'),
    'no_playlist': MessageLookupByLibrary.simpleMessage('Non ci sono ancora playlist...'),
    'no_songs_hint': MessageLookupByLibrary.simpleMessage('Nessuna canzone.\nPremi + per aggiungerne una.'),
    'no_songs_in_file': MessageLookupByLibrary.simpleMessage('Nessuna canzone trovata nel file.'),
    'no_songs_to_export': MessageLookupByLibrary.simpleMessage('Nessuna canzone da esportare.'),
    'no_songs_to_share': MessageLookupByLibrary.simpleMessage('Nessuna canzone da condividere.'),
    'ok': MessageLookupByLibrary.simpleMessage('OK'),
    'old_password': MessageLookupByLibrary.simpleMessage('Vecchia password'),
    'open_settings': MessageLookupByLibrary.simpleMessage('Apri impostazioni'),
    'other': MessageLookupByLibrary.simpleMessage('Altro'),
    'password': MessageLookupByLibrary.simpleMessage('Password'),
    'password_changed': MessageLookupByLibrary.simpleMessage('Password Cambiata'),
    'password_changed_success': MessageLookupByLibrary.simpleMessage('La password è stata cambiata correttamente.'),
    'pick_a_color': MessageLookupByLibrary.simpleMessage('Scegli un colore'),
    'playlist': MessageLookupByLibrary.simpleMessage('Playlist'),
    'playlist_desc': MessageLookupByLibrary.simpleMessage('Guarda tutte le tue playlist'),
    'playlist_list': MessageLookupByLibrary.simpleMessage('Elenco Playlist'),
    'playlist_name': MessageLookupByLibrary.simpleMessage('Nome playlist'),
    'playlist_option': MessageLookupByLibrary.simpleMessage('Playlist'),
    'please_accept': MessageLookupByLibrary.simpleMessage('Ti prego di accettare i termini di servizio'),
    'qr_footer_text': MessageLookupByLibrary.simpleMessage('La sequenza si ripete continuamente.\nI riceventi possono unirsi in qualsiasi momento.'),
    'qr_frame_display': m6,
    'qr_imported_count': m7,
    'qr_importing': MessageLookupByLibrary.simpleMessage('Importazione in corso…'),
    'qr_point_camera': MessageLookupByLibrary.simpleMessage('Punta la fotocamera su questo schermo'),
    'qr_preparing': MessageLookupByLibrary.simpleMessage('Preparazione…'),
    'qr_song_count': m8,
    'reading_file': MessageLookupByLibrary.simpleMessage('Lettura del file in corso…'),
    'receive_bluetooth': MessageLookupByLibrary.simpleMessage('Ricevi via Bluetooth'),
    'receive_songs_title': MessageLookupByLibrary.simpleMessage('Ricevi canzoni'),
    'receive_via_qr': MessageLookupByLibrary.simpleMessage('Ricevi via QR'),
    'rs': MessageLookupByLibrary.simpleMessage('R/S'),
    'save': MessageLookupByLibrary.simpleMessage('Salva'),
    'search_again': MessageLookupByLibrary.simpleMessage('Cerca di nuovo'),
    'search_devices': MessageLookupByLibrary.simpleMessage('Cerca dispositivi'),
    'searching_devices': MessageLookupByLibrary.simpleMessage('Ricerca dispositivi in corso…'),
    'select_chopack_file': MessageLookupByLibrary.simpleMessage('Seleziona un file .chopack'),
    'select_chordpro_file': MessageLookupByLibrary.simpleMessage('Seleziona un file .chopro, .cho o .txt'),
    'send': MessageLookupByLibrary.simpleMessage('INVIA'),
    'send_bluetooth': MessageLookupByLibrary.simpleMessage('Invia via Bluetooth'),
    'send_songs_title': MessageLookupByLibrary.simpleMessage('Invia canzoni'),
    'settings': MessageLookupByLibrary.simpleMessage('Impostazioni'),
    'share': MessageLookupByLibrary.simpleMessage('Condividi'),
    'share_text': MessageLookupByLibrary.simpleMessage('Condividi testo'),
    'share_via_qr_default_title': MessageLookupByLibrary.simpleMessage('Condividi via QR'),
    'share_via_qr_menu': MessageLookupByLibrary.simpleMessage('Condividi via QR'),
    'shut_down': MessageLookupByLibrary.simpleMessage('Chiudi'),
    'signal_strength': m9,
    'song': MessageLookupByLibrary.simpleMessage('brano'),
    'song_imported': m10,
    'song_updated': m11,
    'songs': MessageLookupByLibrary.simpleMessage('brani'),
    'songs_book': MessageLookupByLibrary.simpleMessage('Canzoniere'),
    'songs_book_desc': MessageLookupByLibrary.simpleMessage('Leggi i testi di tutte le canzoni!'),
    'songs_imported': m12,
    'songs_list': MessageLookupByLibrary.simpleMessage('Elenco Canzoni'),
    'start_sending': MessageLookupByLibrary.simpleMessage('Avvia invio'),
    'sync': MessageLookupByLibrary.simpleMessage('Sincronizza'),
    'tags': MessageLookupByLibrary.simpleMessage('Tags'),
    'text_settings': MessageLookupByLibrary.simpleMessage('Impostazioni del testo'),
    'text_size': MessageLookupByLibrary.simpleMessage('Dimensione del testo'),
    'text_title': MessageLookupByLibrary.simpleMessage('Titolo'),
    'title': MessageLookupByLibrary.simpleMessage('Canti Scout'),
    'try_again': MessageLookupByLibrary.simpleMessage('Riprova'),
    'unable_to_save': MessageLookupByLibrary.simpleMessage('Impossibile Salvare'),
    'unable_to_update_song': MessageLookupByLibrary.simpleMessage('Errore: Impossibile caricare la canzone'),
    'undo': MessageLookupByLibrary.simpleMessage('ANNULLA'),
    'upload_dialog_body': MessageLookupByLibrary.simpleMessage('Stai modificando questa canzone per tutti gli utenti di Canti Scout, sei sicuro di aver modificato correttamente il testo e gli accordi?\nDi aver seguito lo standard ChordPro?\nDi non aver fatto errori ortografici?'),
    'upload_dialog_title': MessageLookupByLibrary.simpleMessage('Confermi le modifiche?'),
    'username': MessageLookupByLibrary.simpleMessage('Nome utente'),
    'value_must_not_be_empty': MessageLookupByLibrary.simpleMessage('Il campo non può essere vuoto.'),
    'verify_account': MessageLookupByLibrary.simpleMessage('Verifica la creazione del tuo account'),
    'verify_account_desc': MessageLookupByLibrary.simpleMessage('Una mail di conferma è stata spedita al tuo indirizzo'),
    'what_to_send': MessageLookupByLibrary.simpleMessage('Cosa vuoi inviare?')
  };
}
