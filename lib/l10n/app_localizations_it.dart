// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Pression Tracker';

  @override
  String get history => 'Storico';

  @override
  String get trends => 'Andamento';

  @override
  String get newReading => 'Nuova misurazione';

  @override
  String get takePhoto => 'Scatta una foto del misuratore';

  @override
  String get choosePhoto => 'Scegli una foto';

  @override
  String get enterManually => 'Inserisci manualmente';

  @override
  String get readingDisplay => 'Lettura del display…';

  @override
  String get editReading => 'Modifica misurazione';

  @override
  String get delete => 'Elimina';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get deleteReadingTitle => 'Eliminare questa misurazione?';

  @override
  String get deleteReadingBody =>
      'La misurazione e la sua foto verranno eliminate.';

  @override
  String get required => 'Obbligatorio';

  @override
  String rangeError(String min, String max) {
    return '$min–$max';
  }

  @override
  String get photoUnavailable => 'Foto non disponibile';

  @override
  String get ocrIncomplete =>
      'Non è stato possibile leggere tutti i valori dalla foto. Inserisci i numeri mancanti.';

  @override
  String get ocrComplete =>
      'Valori letti dalla foto. Confrontali con il display prima di salvare.';

  @override
  String get systolic => 'Sistolica';

  @override
  String get diastolic => 'Diastolica';

  @override
  String get pulse => 'Battito';

  @override
  String get pulseOptional => 'Battito (facoltativo)';

  @override
  String get noteOptional => 'Nota (facoltativa)';

  @override
  String get noteHint =>
      'es. dopo il caffè, braccio sinistro, prima del farmaco';

  @override
  String get noReadingsTitle => 'Nessuna misurazione';

  @override
  String get noReadingsBody =>
      'Tocca \"Nuova misurazione\" e scatta una foto del misuratore di pressione. I valori vengono letti automaticamente e puoi correggerli prima di salvare.';

  @override
  String get addReadingsForTrends =>
      'Aggiungi delle misurazioni per vedere l\'andamento.';

  @override
  String get noReadingsInPeriod => 'Nessuna misurazione in questo periodo.';

  @override
  String averageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Media · $count misurazioni',
      one: 'Media · 1 misurazione',
    );
    return '$_temp0';
  }

  @override
  String comparePrevious(String period) {
    return 'Le frecce confrontano con i $period precedenti.';
  }

  @override
  String get range7 => '7 giorni';

  @override
  String get range30 => '30 giorni';

  @override
  String get range90 => '90 giorni';

  @override
  String get rangeAll => 'Tutto';

  @override
  String get readingsByCategory => 'Misurazioni per categoria';

  @override
  String get categoryDisclaimer =>
      'Le categorie seguono le linee guida ACC/AHA e hanno solo scopo informativo. Parla delle tue misurazioni con il tuo medico.';

  @override
  String get catNormal => 'Normale';

  @override
  String get catElevated => 'Elevata';

  @override
  String get catStage1 => 'Alta – Stadio 1';

  @override
  String get catStage2 => 'Alta – Stadio 2';

  @override
  String get catCrisis => 'Crisi ipertensiva';

  @override
  String get catNormalRange => '< 120 e < 80';

  @override
  String get catElevatedRange => '120–129 e < 80';

  @override
  String get catStage1Range => '130–139 o 80–89';

  @override
  String get catStage2Range => '≥ 140 o ≥ 90';

  @override
  String get catCrisisRange => '> 180 o > 120';

  @override
  String get welcomeTitle => 'Benvenuto';

  @override
  String get welcomeBody =>
      'Crea un profilo per iniziare a monitorare la pressione. Ogni persona che usa questo telefono può avere il proprio profilo.';

  @override
  String get createProfile => 'Crea profilo';

  @override
  String get editProfile => 'Modifica profilo';

  @override
  String get addProfile => 'Aggiungi persona';

  @override
  String get peopleOnDevice => 'Persone su questo dispositivo';

  @override
  String get viewingNow => 'In visualizzazione';

  @override
  String get tapToSwitch => 'Tocca per passare a questa persona';

  @override
  String get whoIsMeasuring => 'Chi sta misurando?';

  @override
  String get name => 'Nome';

  @override
  String get birthYearOptional => 'Anno di nascita (facoltativo)';

  @override
  String get invalidYear => 'Inserisci un anno valido';

  @override
  String get pinLock => 'Proteggi con un PIN';

  @override
  String get pinLockHint =>
      'Il PIN viene richiesto all\'apertura di questo profilo.';

  @override
  String get pin => 'PIN';

  @override
  String get confirmPin => 'Conferma PIN';

  @override
  String get newPinOptional =>
      'Nuovo PIN (lascia vuoto per mantenere quello attuale)';

  @override
  String get pinTooShort => 'Usa da 4 a 8 cifre';

  @override
  String get pinMismatch => 'I PIN non corrispondono';

  @override
  String enterPin(String name) {
    return 'Inserisci il PIN di $name';
  }

  @override
  String get wrongPin => 'PIN errato';

  @override
  String get unlock => 'Sblocca';

  @override
  String get switchProfile => 'Cambia profilo';

  @override
  String get deleteProfile => 'Elimina profilo';

  @override
  String deleteProfileTitle(String name) {
    return 'Eliminare $name?';
  }

  @override
  String get deleteProfileBody =>
      'Il profilo e tutte le sue misurazioni e foto verranno eliminati definitivamente.';

  @override
  String bornIn(String year) {
    return 'Anno di nascita: $year';
  }

  @override
  String readingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count misurazioni',
      one: '1 misurazione',
      zero: 'Nessuna misurazione',
    );
    return '$_temp0';
  }

  @override
  String get account => 'Account';

  @override
  String get language => 'Lingua';

  @override
  String get systemLanguage => 'Lingua di sistema';

  @override
  String get help => 'Come funziona';

  @override
  String get helpIntro =>
      'Pression Tracker legge il tuo misuratore di pressione da una foto e conserva lo storico delle tue misurazioni.';

  @override
  String get helpStep1Title => '1. Scatta una foto';

  @override
  String get helpStep1Body =>
      'Tocca \"Nuova misurazione\" e fotografa il display del misuratore. Per risultati migliori usa una buona luce, tieni il telefono dritto davanti allo schermo, inquadra bene il display ed evita i riflessi.';

  @override
  String get helpStep2Title => '2. Controlla i valori';

  @override
  String get helpStep2Body =>
      'Sistolica, diastolica e battito vengono letti automaticamente. Le cifre LCD possono essere lette male, quindi confronta i numeri con il display e correggili se necessario. Puoi anche cambiare data e ora o aggiungere una nota.';

  @override
  String get helpStep3Title => '3. Storico';

  @override
  String get helpStep3Body =>
      'Ogni misurazione è elencata con il colore della sua categoria. Le frecce mostrano la variazione rispetto alla misurazione precedente: ▲ rossa significa più alta, ▼ verde significa più bassa. Tocca una misurazione per modificarla o eliminarla.';

  @override
  String get helpStep4Title => '4. Andamento';

  @override
  String get helpStep4Body =>
      'Scegli un periodo per vedere i valori medi, un grafico nel tempo e quante misurazioni rientrano in ogni categoria. Le frecce confrontano le medie con il periodo precedente.';

  @override
  String get helpCategoriesTitle => 'Categorie di pressione (mmHg)';

  @override
  String get helpProfilesTitle => 'Profili';

  @override
  String get helpProfilesBody =>
      'Ogni membro della famiglia può avere il proprio profilo con misurazioni, storico e andamento separati. Tocca il nome in alto a destra per passare a un\'altra persona, aggiungerne una nuova, modificare o eliminare un profilo o cambiare lingua. Aggiungi un PIN per mantenere privato un profilo.';

  @override
  String get helpPrivacyTitle => 'Privacy';

  @override
  String get helpPrivacyBody =>
      'Tutto resta su questo telefono: le foto vengono lette sul dispositivo e nessun dato viene inviato altrove.';

  @override
  String get madeBy => 'Realizzato da Alex Rogatski';

  @override
  String get helpDisclaimer =>
      'Questa app non è un dispositivo medico e non sostituisce il parere del tuo medico.';
}
