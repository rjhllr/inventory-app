// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Inventar-App';

  @override
  String get homeTitle => 'Inventar-App';

  @override
  String get startStockTaking => 'Inventur starten';

  @override
  String get resetStocksData => 'Bestände / Daten zurücksetzen';

  @override
  String get stockTakingSettings => 'Inventur-Einstellungen';

  @override
  String get productDatabase => 'Produktdatenbank';

  @override
  String get transactionHistory => 'Transaktionsverlauf';

  @override
  String get exportCSV => 'CSV exportieren';

  @override
  String get exportInventoryData => 'Inventardaten als ZIP-Datei exportieren';

  @override
  String get scanning => 'Scannen';

  @override
  String get turnOffFlash => 'Blitz ausschalten';

  @override
  String get turnOnFlash => 'Blitz einschalten';

  @override
  String get error => 'Fehler';

  @override
  String errorMessage(String message) {
    return 'Fehler: $message';
  }

  @override
  String get promptForQuantity => 'Nach Anzahl fragen';

  @override
  String get additionalPrompts => 'Zusätzliche Abfragen';

  @override
  String get add => 'Hinzufügen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get type => 'Typ';

  @override
  String get mode => 'Modus';

  @override
  String get loading => 'Lädt...';

  @override
  String get transactionDetails => 'Transaktionsdetails';

  @override
  String get product => 'Produkt';

  @override
  String get timestamp => 'Zeitstempel';

  @override
  String get thisTransaction => 'Diese Transaktion';

  @override
  String get currentTotal => 'Aktueller Gesamtwert';

  @override
  String get setNewTotalCount => 'Neue Gesamtanzahl festlegen:';

  @override
  String get totalCount => 'Gesamtanzahl';

  @override
  String get enterDesiredTotal => 'Gewünschte Gesamtanzahl eingeben';

  @override
  String get set => 'Setzen';

  @override
  String get attributes => 'Attribute';

  @override
  String get close => 'Schließen';

  @override
  String totalCountSetTo(int total, String difference) {
    return 'Gesamtanzahl auf $total gesetzt ($difference)';
  }

  @override
  String get editPrompt => 'Abfrage bearbeiten';

  @override
  String get addPrompt => 'Abfrage hinzufügen';

  @override
  String get save => 'Speichern';

  @override
  String get label => 'Bezeichnung';

  @override
  String get labelHelperText =>
      'Dies wird den Benutzern bei der Eingabeaufforderung angezeigt';

  @override
  String get pleaseEnterLabel => 'Bitte geben Sie eine Bezeichnung ein';

  @override
  String get inputType => 'Eingabetyp';

  @override
  String get selectInputTypeDescription =>
      'Wählen Sie aus, welche Art von Eingabe Benutzer bereitstellen:';

  @override
  String get askMode => 'Abfragemodus';

  @override
  String get chooseAskModeDescription =>
      'Wählen Sie, wann diese Frage gestellt werden soll:';

  @override
  String get prefillLastInput => 'Letzte Eingabe vorausfüllen';

  @override
  String get prefillLastInputDescription =>
      'Automatisch mit dem zuletzt eingegebenen Wert befüllen';

  @override
  String get updatePrompt => 'Abfrage aktualisieren';

  @override
  String get inputTypeText => 'Text';

  @override
  String get inputTypeNumber => 'Zahl';

  @override
  String get inputTypePhoto => 'Foto';

  @override
  String get inputTypeDate => 'Datum';

  @override
  String get inputTypeTextDescription => 'Freie Texteingabe';

  @override
  String get inputTypeNumberDescription => 'Nur numerische Eingabe';

  @override
  String get inputTypePhotoDescription => 'Kamera-Aufnahme';

  @override
  String get inputTypeDateDescription => 'Datumsauswahl';

  @override
  String get askModeOnce => 'Einmal pro Produkt';

  @override
  String get askModeEveryS => 'Bei jedem Scan';

  @override
  String get askModeOnceDescription =>
      'Nur beim ersten Mal fragen, wenn ein Produkt gescannt wird';

  @override
  String get askModeEveryScanDescription =>
      'Jedes Mal fragen, wenn ein Produkt gescannt wird';

  @override
  String errorSavingPrompt(String error) {
    return 'Fehler beim Speichern der Abfrage: $error';
  }

  @override
  String productPrefix(String productCode) {
    return 'Produkt: $productCode';
  }

  @override
  String get enterQuantity => 'Menge eingeben';

  @override
  String get next => 'Weiter';

  @override
  String get finish => 'Fertig';

  @override
  String get required => 'Erforderlich';

  @override
  String get optional => 'Optional';

  @override
  String get previous => 'Zurück';

  @override
  String get photo => 'Foto';

  @override
  String get photoPreview => 'Foto-Vorschau';

  @override
  String get usePhoto => 'Foto verwenden';

  @override
  String get retake => 'Erneut aufnehmen';

  @override
  String get failedToLoadImage => 'Bild konnte nicht geladen werden';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get addAnotherPhoto => 'Weiteres Foto hinzufügen';

  @override
  String get enterText => 'Text eingeben';

  @override
  String get enterNumber => 'Zahl eingeben';

  @override
  String get selectDate => 'Datum auswählen';

  @override
  String get pleaseEnterValue => 'Bitte geben Sie einen Wert ein';

  @override
  String get exportInformation => 'Export-Informationen';

  @override
  String get generateExport => 'Export erstellen';

  @override
  String get generatingExport => 'Export wird erstellt...';

  @override
  String get exportCompletedSuccessfully => 'Export erfolgreich abgeschlossen!';

  @override
  String exportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get exportFormat => 'Export-Format';

  @override
  String get exportDescription =>
      'Der Export erstellt eine ZIP-Datei mit folgendem Inhalt:';

  @override
  String get productsCsv => 'products.csv';

  @override
  String get productsCsvDescription =>
      'Enthält alle Produktinformationen einschließlich:';

  @override
  String get productId => 'Produkt-ID';

  @override
  String get createdAtTimestamp => 'Erstellt-am Zeitstempel';

  @override
  String get updatedAtTimestamp => 'Aktualisiert-am Zeitstempel';

  @override
  String get oncePerProductAnswers =>
      'Alle \"einmal pro Produkt\" Abfrageantworten';

  @override
  String get transactionsCsv => 'transactions.csv';

  @override
  String get transactionsCsvDescription =>
      'Enthält alle Transaktions-/Scan-Datensätze einschließlich:';

  @override
  String get transactionId => 'Transaktions-ID';

  @override
  String get quantityScanned => 'Gescannte Menge';

  @override
  String get allPromptAnswers => 'Alle Abfrageantworten';

  @override
  String get imagesFolder => 'images/ Ordner';

  @override
  String get imagesFolderDescription =>
      'Enthält alle beim Scannen aufgenommenen Fotos:';

  @override
  String get photosFromPrompts => 'Fotos von Foto-Typ Abfragen';

  @override
  String get filesReferencedInCsv =>
      'Dateien in CSV referenziert als \"images/dateiname.jpg\"';

  @override
  String get originalFilenames => 'Ursprüngliche Dateinamen erhalten';

  @override
  String get fileNaming => 'Datei-Benennung';

  @override
  String get exportFilenamePattern =>
      'Export-Dateien werden benannt: inventory_export_JJJJMMTT_HHMMSS.zip';

  @override
  String get deleteAllData => 'Alle Daten löschen';

  @override
  String get actionCannotBeUndone =>
      'DIESE AKTION KANN NICHT RÜCKGÄNGIG GEMACHT WERDEN!';

  @override
  String get willPermanentlyDelete => 'Dies wird dauerhaft löschen:';

  @override
  String get allScannedProducts => 'Alle gescannten Produkte';

  @override
  String get allTransactionHistory => 'Alle Transaktionsverläufe';

  @override
  String get allCustomPromptQuestions => 'Alle benutzerdefinierten Abfragen';

  @override
  String get absolutelySureToContinue =>
      'Sind Sie absolut sicher, dass Sie fortfahren möchten?';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get deleteAllCaps => 'ALLE LÖSCHEN';

  @override
  String get allDataPermanentlyDeleted =>
      'Alle Daten wurden dauerhaft gelöscht';

  @override
  String failedToDeleteData(String error) {
    return 'Fehler beim Löschen der Daten: $error';
  }

  @override
  String get resetAllStocks => 'Alle Bestände zurücksetzen';

  @override
  String get resetAllStocksDescription =>
      'Dies erstellt negative Transaktionen, um alle Produktbestände auf null zu bringen. Der Transaktionsverlauf wird zu Prüfzwecken aufbewahrt.\n\nSind Sie sicher, dass Sie fortfahren möchten?';

  @override
  String get resetAll => 'Alle zurücksetzen';

  @override
  String get allStocksResetToZero =>
      'Alle Bestände wurden auf null zurückgesetzt';

  @override
  String get resetProductStock => 'Produktbestand zurücksetzen';

  @override
  String resetProductStockDescription(String productId) {
    return 'Dies erstellt eine negative Transaktion, um den Bestand von \"$productId\" auf null zu bringen. Der Transaktionsverlauf wird zu Prüfzwecken aufbewahrt.\n\nSind Sie sicher, dass Sie fortfahren möchten?';
  }

  @override
  String get reset => 'Zurücksetzen';

  @override
  String stockResetToZero(String productId) {
    return 'Bestand für \"$productId\" wurde auf null zurückgesetzt';
  }

  @override
  String get noTransactionHistoryYet => 'Noch kein Transaktionsverlauf';

  @override
  String get scanProductToSeeHistory =>
      'Scannen Sie dieses Produkt, um seinen Transaktionsverlauf hier zu sehen';

  @override
  String get stockSummary => 'Bestandsübersicht';

  @override
  String get currentStock => 'Aktueller Bestand';

  @override
  String get totalTransactions => 'Anzahl der Transaktionen';

  @override
  String get positive => 'Positiv';

  @override
  String get negative => 'Negativ';

  @override
  String get neutral => 'Neutral';

  @override
  String get fileNotFound => 'Datei nicht gefunden';

  @override
  String get noTransactionsRecordedYet =>
      'Noch keine Transaktionen aufgezeichnet';

  @override
  String get startScanningToSeeHistory =>
      'Beginnen Sie mit dem Scannen von Produkten, um den Transaktionsverlauf zu sehen';

  @override
  String get export => 'Exportieren';

  @override
  String get noProductsScannedYet => 'Noch keine Produkte gescannt.';

  @override
  String lastUpdated(String date) {
    return 'Zuletzt aktualisiert: $date';
  }

  @override
  String get upgrades => 'Upgrades';

  @override
  String get premiumFeaturesComingSoon => 'Premium-Funktionen kommen bald';

  @override
  String get failedToSavePhoto => 'Foto konnte nicht gespeichert werden';

  @override
  String cameraError(String error) {
    return 'Kamera-Fehler: $error';
  }

  @override
  String errorSavingTransaction(String error) {
    return 'Fehler beim Speichern der Transaktion: $error';
  }

  @override
  String get additions => 'Zugänge';

  @override
  String get reductions => 'Abgänge';

  @override
  String get productInformation => 'Produktinformationen';

  @override
  String get resetAllStocksButton => 'Alle Bestände zurücksetzen';

  @override
  String get resetIndividualStock => 'Einzelnen Bestand zurücksetzen';

  @override
  String get deleteAllDataButton => 'Alle Daten löschen';

  @override
  String get removeAllData => 'Alle Daten entfernen';

  @override
  String get permanentDeletionWarning =>
      'DAUERHAFTES LÖSCHEN: Dies wird alle Produkte, Transaktionen, Abfragen und Verläufe vollständig entfernen. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get removeAllDataButton => 'ALLE DATEN ENTFERNEN';

  @override
  String get stockResetInformation => 'Bestandsrücksetzungs-Informationen';

  @override
  String get stockResetExplanation =>
      'Das Zurücksetzen von Beständen erstellt negative Transaktionen, die den Bestand jedes Produkts auf null bringen. Dies gewährleistet eine vollständige Prüfspur aller Bestandsbewegungen.';

  @override
  String get allStocksAtZero => 'Alle Bestände sind bei null';

  @override
  String get noProductsToReset =>
      'Derzeit haben keine Produkte Bestand zum Zurücksetzen';

  @override
  String get resetThisProductStock => 'Diesen Produktbestand zurücksetzen';

  @override
  String get pleaseEnterValidNumber => 'Bitte geben Sie eine gültige Zahl ein';

  @override
  String get productAttributes => 'Produktattribute';

  @override
  String get photos => 'Fotos';

  @override
  String photosCount(int count) {
    return 'Fotos ($count)';
  }

  @override
  String errorLoadingPhotos(String error) {
    return 'Fehler beim Laden der Fotos: $error';
  }

  @override
  String get transactionHistoryTitle => 'Transaktionsverlauf';

  @override
  String errorLoadingTransactionHistory(String error) {
    return 'Fehler beim Laden des Transaktionsverlaufs: $error';
  }

  @override
  String get retry => 'Wiederholen';

  @override
  String todayAt(String time) {
    return 'Heute um $time';
  }

  @override
  String get stockAddition => 'Bestandsaufstockung';

  @override
  String get stockReduction => 'Bestandsreduzierung';

  @override
  String get productInformationTitle => 'Produktinformationen';

  @override
  String productIdLabel(String productId) {
    return 'Produkt-ID: $productId';
  }

  @override
  String get productInfoDescription =>
      'Diese Ansicht zeigt den vollständigen Transaktionsverlauf für dieses Produkt.';

  @override
  String get positiveQuantitiesInfo =>
      '• Positive Mengen repräsentieren Bestandsaufstockungen';

  @override
  String get negativeQuantitiesInfo =>
      '• Negative Mengen repräsentieren Bestandsreduzierungen oder Zurücksetzungen';

  @override
  String get currentStockInfo =>
      '• Aktueller Bestand ist die Summe aller Transaktionen';

  @override
  String photoViewerTitle(int current, int total) {
    return 'Foto $current von $total';
  }
}
