import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/messages_all.dart';


//https://proandroiddev.com/flutter-localization-step-by-step-30f95d06018d
class AppLocalizations {
  static Future<AppLocalizations> load(Locale locale) {
    final String name =
        locale.countryCode == null ? locale.languageCode : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((bool _) {
      Intl.defaultLocale = localeName;
      return new AppLocalizations();
    });
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String get title {
    return Intl.message('Canti Scout',
        name: 'title', desc: 'The application title');
  }

  String get password_changed {
    return Intl.message('Password Cambiata',
        name: 'password_changed', desc: 'Account: Password Cambiata');
  }

  String get password_changed_success {
    return Intl.message('La password è stata cambiata correttamente.',
        name: 'password_changed_success', desc: 'Account: Password Cambiata');
  }

  String get dismiss {
    return Intl.message('CHIUDI', name: 'dismiss', desc: 'Account: DISMISS');
  }

  String get manage_user_password {
    return Intl.message('CAMBIA PASSWORD UTENZA',
        name: 'manage_user_password', desc: 'Account: MANAGE USER PASSWORD');
  }

  String get old_password {
    return Intl.message('Vecchia password',
        name: 'old_password', desc: 'Account: Old password');
  }

  String get new_password {
    return Intl.message('Nuova password',
        name: 'new_password', desc: 'Account: New password');
  }

  String get confirmed {
    return Intl.message('(conferma)',
        name: 'confirmed', desc: 'Account: confiermed');
  }

  String get undo {
    return Intl.message('ANNULLA', name: 'undo', desc: 'Account: annulla');
  }

  String get change {
    return Intl.message('CAMBIA', name: 'change', desc: 'Account: change');
  }

  String get logout {
    return Intl.message('Logout', name: 'logout', desc: 'Account: logout');
  }

  String get login {
    return Intl.message('Login', name: 'login', desc: 'Homepage: login');
  }

  String get login_desc {
    return Intl.message(
        'Effettua il login per accedere a tutte le funzionalità',
        name: 'login_desc',
        desc: 'Homepage: login');
  }

  String get choose_playlist {
    return Intl.message('Scegli una playlist',
        name: 'choose_playlist', desc: 'ChoosePlaylist: Choose platlist');
  }

  String get song {
    return Intl.message('brano', name: 'song', desc: 'ChoosePlaylist: song');
  }

  String get songs {
    return Intl.message('brani', name: 'songs', desc: 'ChoosePlaylist: song');
  }

  String get no_playlist {
    return Intl.message('Non ci sono ancora playlist...',
        name: 'no_playlist', desc: 'ChoosePlaylist: No playlist yet...');
  }

  String get name_playlist {
    return Intl.message('Dai un nome alla tua playlist.',
        name: 'name_playlist',
        desc: 'CreatePlaylist: Give a name to your playlist.');
  }

  String get playlist_name {
    return Intl.message('Plylist name',
        name: 'playlist_name', desc: 'CreatePlaylist: Playlist name');
  }

  String get create {
    return Intl.message('CREA', name: 'create', desc: 'CreatePlaylist: CREATE');
  }

  String get value_must_not_be_empty {
    return Intl.message('Value Can\'t Be Empty',
        name: 'value_must_not_be_empty',
        desc: 'CreatePlaylist: Value must not be empty');
  }

  String get chose_title {
    return Intl.message('Quale è il titolo della canzone?',
        name: 'chose_title', desc: 'CreateSong: Chose song title?');
  }

  String get church {
    return Intl.message('Chiesa', name: 'church', desc: 'CreateSong: Chiesa');
  }

  String get lc {
    return Intl.message('L/C', name: 'lc', desc: 'CreateSong: l/c');
  }

  String get eg {
    return Intl.message('E/G', name: 'eg', desc: 'CreateSong: E/G');
  }

  String get rs {
    return Intl.message('R/S', name: 'rs', desc: 'CreateSong: R/S');
  }

  String get other {
    return Intl.message('Altro', name: 'other', desc: 'CreateSong: Altro');
  }

  String get choose_scope {
    return Intl.message('Scegli l\'ambito',
        name: 'choose_scope', desc: 'CreateSong: Chose scope');
  }

  String get text_title {
    return Intl.message('Titolo',
        name: 'text_title', desc: 'CreateSong: Title');
  }

  String get unable_to_update_song {
    return Intl.message('Errore: Impossibile caricare la canzone',
        name: 'unable_to_update_song',
        desc: 'EditSongText: Unable to load song');
  }

  String get unable_to_save {
    return Intl.message('Impossibile Salvare',
        name: 'unable_to_save', desc: 'EditSongText: Unable to save');
  }

  String get save {
    return Intl.message('Salva', name: 'save', desc: 'EditSongText: save');
  }

  String get edit_song {
    return Intl.message('Modifica la canzone: ',
        name: 'edit_song', desc: 'EditSongText: edit song: SONG_NAME');
  }

  String get sync {
    return Intl.message('Sincronizza',
        name: 'sync', desc: 'Homepage: Syncronize');
  }

  String get account {
    return Intl.message('Account', name: 'account', desc: 'Homepage: Account');
  }

  String get settings {
    return Intl.message('Impostazioni',
        name: 'settings', desc: 'Homepage: Settings');
  }

  String get guide {
    return Intl.message('Guida', name: 'guide', desc: 'Homepage: Guida');
  }

  String get donate {
    return Intl.message('Dona', name: 'donate', desc: 'Homepage: Donate');
  }

  String get songs_list {
    return Intl.message('Elenco Canzoni',
        name: 'songs_list', desc: 'Homepage: Settings');
  }

  String get songs_book {
    return Intl.message('Canzoniere',
        name: 'songs_book', desc: 'Homepage: Soongs book');
  }

  String get songs_book_desc {
    return Intl.message('Leggi i testi di tutte le canzoni!',
        name: 'songs_book_desc', desc: 'Homepage: Soongs book desc');
  }

  String get playlist {
    return Intl.message('Playlist',
        name: 'playlist', desc: 'Homepage: Playlist');
  }

  String get playlist_desc {
    return Intl.message('Guarda tutte le tue playlist',
        name: 'playlist_desc', desc: 'Homepage: Playlist desc');
  }

  String get verify_account {
    return Intl.message('Verifica la creazione del tuo account',
        name: 'verify_account', desc: 'LoginSignUpPage: Verify your account');
  }

  String get verify_account_desc {
    return Intl.message('Una mail di conferma è stata sperida al tuo indirizzo',
        name: 'verify_account_desc',
        desc:
            'LoginSignUpPage: Confirmation of login has been sent to your email');
  }

  String get username {
    return Intl.message('Nome utente',
        name: 'username', desc: 'LoginSignUpPage: username');
  }

  String get email {
    return Intl.message('Email', name: 'email', desc: 'LoginSignUpPage: email');
  }

  String get password {
    return Intl.message('Password',
        name: 'password', desc: 'LoginSignUpPage: password');
  }

  String get create_account {
    return Intl.message('Crea un account',
        name: 'create_account', desc: 'LoginSignUpPage: crea');
  }

  String get have_an_account_yet {
    return Intl.message('Hai già un account? Fai Login',
        name: 'have_an_account_yet',
        desc: 'LoginSignUpPage: have an account? Sign in');
  }

  String get playlist_list {
    return Intl.message('Elenco Playlist',
        name: 'playlist_list', desc: 'PlaylistUl: Playlist list');
  }

  String get add_playlist {
    return Intl.message('Aggiungi una playlist',
        name: 'add_playlist', desc: 'PlaylistUl: Playlist list');
  }

  String get add_to_playlist {
    return Intl.message('Aggiungi alla playlist',
        name: 'add_to_playlist', desc: 'PlaylistUl: Playlist list');
  }

  String get ask_remove {
    return Intl.message('Rimuovere?',
        name: 'ask_remove', desc: 'PlaylistUl: Remove?');
  }

  String get ask_remove_desc {
    return Intl.message('Vuoi rimuovere la playlist: ',
        name: 'ask_remove_desc', desc: 'PlaylistUl: Remove?');
  }

  String get ok {
    return Intl.message('OK', name: 'ok', desc: 'PlaylistUl: ok');
  }

  String get pick_a_color {
    return Intl.message('Scegli un colore',
        name: 'pick_a_color', desc: 'Settings: pick color');
  }

  String get done {
    return Intl.message('FATTO', name: 'done', desc: 'Settings: Done');
  }

  String get text_settings {
    return Intl.message('Impostazioni del testo',
        name: 'text_settings', desc: 'Settings: Text formatting');
  }

  String get text_size {
    return Intl.message('Dimensione del testo',
        name: 'text_size', desc: 'Settings: Text size');
  }

  String get font {
    return Intl.message('Font', name: 'font', desc: 'Settings: font');
  }

  String get choose_font {
    return Intl.message('Scegli un font',
        name: 'choose_font', desc: 'Settings: Choose font');
  }

  String get chord_color {
    return Intl.message('Colore accordi',
        name: 'chord_color', desc: 'Settings: Choose color');
  }

  String get chord_color_press {
    return Intl.message('Premere per modificare',
        name: 'chord_color_press', desc: 'Settings: Press to edit');
  }

  String get app_settings {
    return Intl.message('Impostazioni dell\'applicazione',
        name: 'app_settings', desc: 'Settings: Application settings');
  }

  String get auto_scroll {
    return Intl.message('Autoscorrimento',
        name: 'auto_scroll', desc: 'Settings: Autoscorrimento');
  }

  String get login_needed {
    return Intl.message('Richiesto Login',
        name: 'login_needed', desc: 'SongText: login');
  }

  String get edit {
    return Intl.message('Modifica', name: 'edit', desc: 'SongText: edit');
  }

  String get here_song_text {
    return Intl.message('Ecco il testo della canzone: ',
        name: 'here_song_text', desc: 'SongText: edit');
  }

  String get tags {
    return Intl.message('Tags', name: 'tags', desc: 'SongText: edit');
  }

  String get multimedia {
    return Intl.message('Carica media',
        name: 'multimedia', desc: 'SongText: load multimedia');
  }

  String get abuse {
    return Intl.message('Segnala un abuso',
        name: 'abuse', desc: 'SongText: load multimedia');
  }

  String get abuse_title {
    return Intl.message('Vuoi segnalare questa canzone?',
        name: 'abuse_title', desc: 'SongText: abuse');
  }

  String get abuse_desc {
    return Intl.message('Ragione della segnalazione',
        name: 'abuse_desc', desc: 'SongText: reasons');
  }

  String get description {
    return Intl.message('Descrizione',
        name: 'description', desc: 'SongText: description');
  }

  String get send {
    return Intl.message('INVIA', name: 'send', desc: 'SongText: SEND');
  }

  String get look_this_playlist {
    return Intl.message('Guarda questa playlist: ',
        name: 'look_this_playlist',
        desc: 'SongUlPlylist: look this playlist: ');
  }

  String get do_you_want_to_remove {
    return Intl.message('Vuoi rimuovere "###" dalla playlist:',
        name: 'do_you_want_to_remove',
        desc:
            'SongUlPlylist: Do you want to remove "###" from playlist: do not remove ### ');
  }

  String get create_song {
    return Intl.message('Crea canzone',
        name: 'create_song', desc: 'SongUlStateless: Create song');
  }

  String get add {
    return Intl.message('Aggiungi', name: 'add', desc: 'SongUlStateless: add');
  }

  String get hello {
    return Intl.message('Hello', name: 'hello');
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'it'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
