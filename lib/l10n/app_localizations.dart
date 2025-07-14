import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Inventory App'**
  String get appTitle;

  /// Title for the home screen
  ///
  /// In en, this message translates to:
  /// **'Inventory App'**
  String get homeTitle;

  /// Button text to start stock-taking
  ///
  /// In en, this message translates to:
  /// **'Start Stock-taking'**
  String get startStockTaking;

  /// Title for reset stocks screen
  ///
  /// In en, this message translates to:
  /// **'Reset Stocks / Data'**
  String get resetStocksData;

  /// Button text for stock-taking settings
  ///
  /// In en, this message translates to:
  /// **'Stock-taking Settings'**
  String get stockTakingSettings;

  /// Button text for product database
  ///
  /// In en, this message translates to:
  /// **'Product Database'**
  String get productDatabase;

  /// Title for transaction history section
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// Button text to export CSV
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCSV;

  /// Description for export functionality
  ///
  /// In en, this message translates to:
  /// **'Export inventory data as ZIP file'**
  String get exportInventoryData;

  /// Title for scanning screen
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get scanning;

  /// Tooltip for turning off flash
  ///
  /// In en, this message translates to:
  /// **'Turn off flash'**
  String get turnOffFlash;

  /// Tooltip for turning on flash
  ///
  /// In en, this message translates to:
  /// **'Turn on flash'**
  String get turnOnFlash;

  /// Generic error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Error message with placeholder
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorMessage(String message);

  /// Setting label for quantity prompt
  ///
  /// In en, this message translates to:
  /// **'Prompt for Quantity'**
  String get promptForQuantity;

  /// Section title for additional prompts
  ///
  /// In en, this message translates to:
  /// **'Additional Prompts'**
  String get additionalPrompts;

  /// Button text to add something
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Button text to edit something
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Button text to delete something
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Label for type field
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// Label for mode field
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Title for transaction details dialog
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// Label for product field
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// Label for timestamp field
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get timestamp;

  /// Label for current transaction
  ///
  /// In en, this message translates to:
  /// **'This Transaction'**
  String get thisTransaction;

  /// Label for current total count
  ///
  /// In en, this message translates to:
  /// **'Current Total'**
  String get currentTotal;

  /// Label for setting new total count
  ///
  /// In en, this message translates to:
  /// **'Set New Total Count:'**
  String get setNewTotalCount;

  /// Label for total count field
  ///
  /// In en, this message translates to:
  /// **'Total Count'**
  String get totalCount;

  /// Hint text for total count field
  ///
  /// In en, this message translates to:
  /// **'Enter desired total'**
  String get enterDesiredTotal;

  /// Button text to set a value
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// Label for attributes section
  ///
  /// In en, this message translates to:
  /// **'Attributes'**
  String get attributes;

  /// Button text to close dialog
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Success message when setting total count
  ///
  /// In en, this message translates to:
  /// **'Total count set to {total} ({difference})'**
  String totalCountSetTo(int total, String difference);

  /// Title for editing an existing prompt
  ///
  /// In en, this message translates to:
  /// **'Edit Prompt'**
  String get editPrompt;

  /// Title for adding a new prompt
  ///
  /// In en, this message translates to:
  /// **'Add Prompt'**
  String get addPrompt;

  /// Button text to save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Label for prompt label field
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// Helper text for prompt label field
  ///
  /// In en, this message translates to:
  /// **'This will be shown to users when prompting for input'**
  String get labelHelperText;

  /// Validation message for empty label field
  ///
  /// In en, this message translates to:
  /// **'Please enter a label'**
  String get pleaseEnterLabel;

  /// Section title for input type selection
  ///
  /// In en, this message translates to:
  /// **'Input Type'**
  String get inputType;

  /// Description for input type selection
  ///
  /// In en, this message translates to:
  /// **'Select what type of input users will provide:'**
  String get selectInputTypeDescription;

  /// Section title for ask mode selection
  ///
  /// In en, this message translates to:
  /// **'Ask Mode'**
  String get askMode;

  /// Description for ask mode selection
  ///
  /// In en, this message translates to:
  /// **'Choose when to ask this question:'**
  String get chooseAskModeDescription;

  /// Switch label for prefilling last input
  ///
  /// In en, this message translates to:
  /// **'Prefill last input'**
  String get prefillLastInput;

  /// Description for prefill last input switch
  ///
  /// In en, this message translates to:
  /// **'Automatically populate with the last entered value'**
  String get prefillLastInputDescription;

  /// Button text to update existing prompt
  ///
  /// In en, this message translates to:
  /// **'Update Prompt'**
  String get updatePrompt;

  /// Text input type label
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get inputTypeText;

  /// Number input type label
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get inputTypeNumber;

  /// Photo input type label
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get inputTypePhoto;

  /// Date input type label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get inputTypeDate;

  /// Description for text input type
  ///
  /// In en, this message translates to:
  /// **'Free-form text input'**
  String get inputTypeTextDescription;

  /// Description for number input type
  ///
  /// In en, this message translates to:
  /// **'Numeric input only'**
  String get inputTypeNumberDescription;

  /// Description for photo input type
  ///
  /// In en, this message translates to:
  /// **'Camera capture'**
  String get inputTypePhotoDescription;

  /// Description for date input type
  ///
  /// In en, this message translates to:
  /// **'Date picker'**
  String get inputTypeDateDescription;

  /// Ask mode: once per product label
  ///
  /// In en, this message translates to:
  /// **'Once per product'**
  String get askModeOnce;

  /// Ask mode: every scan label
  ///
  /// In en, this message translates to:
  /// **'Every scan'**
  String get askModeEveryS;

  /// Description for once per product ask mode
  ///
  /// In en, this message translates to:
  /// **'Ask only the first time a product is scanned'**
  String get askModeOnceDescription;

  /// Description for every scan ask mode
  ///
  /// In en, this message translates to:
  /// **'Ask every time a product is scanned'**
  String get askModeEveryScanDescription;

  /// Error message when saving prompt fails
  ///
  /// In en, this message translates to:
  /// **'Error saving prompt: {error}'**
  String errorSavingPrompt(String error);

  /// Product label with code
  ///
  /// In en, this message translates to:
  /// **'Product: {productCode}'**
  String productPrefix(String productCode);

  /// Title for quantity input page
  ///
  /// In en, this message translates to:
  /// **'Enter Quantity'**
  String get enterQuantity;

  /// Button text to proceed to next step
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Button text to finish the process
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// Label for required fields
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// Label for optional fields
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// Button text to go to previous page
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Label for photo section
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// Title for photo preview dialog
  ///
  /// In en, this message translates to:
  /// **'Photo Preview'**
  String get photoPreview;

  /// Button text to confirm photo usage
  ///
  /// In en, this message translates to:
  /// **'Use Photo'**
  String get usePhoto;

  /// Button text to retake a photo
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// Error message when image cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// Button text to take a photo
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Button text to add another photo
  ///
  /// In en, this message translates to:
  /// **'Add Another Photo'**
  String get addAnotherPhoto;

  /// Placeholder for text input
  ///
  /// In en, this message translates to:
  /// **'Enter text'**
  String get enterText;

  /// Placeholder for number input
  ///
  /// In en, this message translates to:
  /// **'Enter number'**
  String get enterNumber;

  /// Placeholder for date selection
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// Validation message for empty required fields
  ///
  /// In en, this message translates to:
  /// **'Please enter a value'**
  String get pleaseEnterValue;

  /// Title for export information screen
  ///
  /// In en, this message translates to:
  /// **'Export Information'**
  String get exportInformation;

  /// Button text to generate export
  ///
  /// In en, this message translates to:
  /// **'Generate Export'**
  String get generateExport;

  /// Loading message while generating export
  ///
  /// In en, this message translates to:
  /// **'Generating export...'**
  String get generatingExport;

  /// Success message for completed export
  ///
  /// In en, this message translates to:
  /// **'Export completed successfully!'**
  String get exportCompletedSuccessfully;

  /// Error message when export fails
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// Section title for export format explanation
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get exportFormat;

  /// Description of export contents
  ///
  /// In en, this message translates to:
  /// **'The export will generate a ZIP file containing:'**
  String get exportDescription;

  /// Name of products CSV file
  ///
  /// In en, this message translates to:
  /// **'products.csv'**
  String get productsCsv;

  /// Description of products CSV contents
  ///
  /// In en, this message translates to:
  /// **'Contains all product information including:'**
  String get productsCsvDescription;

  /// Product ID field label
  ///
  /// In en, this message translates to:
  /// **'Product ID'**
  String get productId;

  /// Created at timestamp field label
  ///
  /// In en, this message translates to:
  /// **'Created At timestamp'**
  String get createdAtTimestamp;

  /// Updated at timestamp field label
  ///
  /// In en, this message translates to:
  /// **'Updated At timestamp'**
  String get updatedAtTimestamp;

  /// Description for once per product answers in export
  ///
  /// In en, this message translates to:
  /// **'All \"once per product\" prompt question answers'**
  String get oncePerProductAnswers;

  /// Name of transactions CSV file
  ///
  /// In en, this message translates to:
  /// **'transactions.csv'**
  String get transactionsCsv;

  /// Description of transactions CSV contents
  ///
  /// In en, this message translates to:
  /// **'Contains all transaction/scan records including:'**
  String get transactionsCsvDescription;

  /// Transaction ID field label
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// Quantity scanned field label
  ///
  /// In en, this message translates to:
  /// **'Quantity scanned'**
  String get quantityScanned;

  /// List item: all prompt answers
  ///
  /// In en, this message translates to:
  /// **'All prompt answers'**
  String get allPromptAnswers;

  /// Name of images folder in export
  ///
  /// In en, this message translates to:
  /// **'images/ folder'**
  String get imagesFolder;

  /// Description of images folder contents
  ///
  /// In en, this message translates to:
  /// **'Contains all photos captured during scanning:'**
  String get imagesFolderDescription;

  /// Description of photo prompt images
  ///
  /// In en, this message translates to:
  /// **'Photos from photo-type prompt questions'**
  String get photosFromPrompts;

  /// Description of how files are referenced
  ///
  /// In en, this message translates to:
  /// **'Files referenced in CSV as \"images/filename.jpg\"'**
  String get filesReferencedInCsv;

  /// Description of filename preservation
  ///
  /// In en, this message translates to:
  /// **'Original file names preserved'**
  String get originalFilenames;

  /// Section title for file naming explanation
  ///
  /// In en, this message translates to:
  /// **'File Naming'**
  String get fileNaming;

  /// Explanation of export filename pattern
  ///
  /// In en, this message translates to:
  /// **'Export files are named: inventory_export_YYYYMMDD_HHMMSS.zip'**
  String get exportFilenamePattern;

  /// Title for delete all data dialog
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// Warning that action cannot be undone
  ///
  /// In en, this message translates to:
  /// **'THIS ACTION CANNOT BE UNDONE!'**
  String get actionCannotBeUndone;

  /// Description of what will be deleted
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete:'**
  String get willPermanentlyDelete;

  /// List item: all scanned products
  ///
  /// In en, this message translates to:
  /// **'All scanned products'**
  String get allScannedProducts;

  /// List item: all transaction history
  ///
  /// In en, this message translates to:
  /// **'All transaction history'**
  String get allTransactionHistory;

  /// List item: all custom prompt questions
  ///
  /// In en, this message translates to:
  /// **'All custom prompt questions'**
  String get allCustomPromptQuestions;

  /// Confirmation question for dangerous action
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure you want to continue?'**
  String get absolutelySureToContinue;

  /// Button text to cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button text to confirm deletion (all caps)
  ///
  /// In en, this message translates to:
  /// **'DELETE ALL'**
  String get deleteAllCaps;

  /// Success message after deleting all data
  ///
  /// In en, this message translates to:
  /// **'All data has been permanently deleted'**
  String get allDataPermanentlyDeleted;

  /// Error message when data deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete data: {error}'**
  String failedToDeleteData(String error);

  /// Title for reset all stocks dialog
  ///
  /// In en, this message translates to:
  /// **'Reset All Stocks'**
  String get resetAllStocks;

  /// Description of what resetting all stocks does
  ///
  /// In en, this message translates to:
  /// **'This will create negative transactions to bring all product stocks to zero. The transaction history will be preserved for audit purposes.\n\nAre you sure you want to continue?'**
  String get resetAllStocksDescription;

  /// Button text to reset all stocks
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get resetAll;

  /// Success message after resetting all stocks
  ///
  /// In en, this message translates to:
  /// **'All stocks have been reset to zero'**
  String get allStocksResetToZero;

  /// Title for reset product stock dialog
  ///
  /// In en, this message translates to:
  /// **'Reset Product Stock'**
  String get resetProductStock;

  /// Description of what resetting product stock does
  ///
  /// In en, this message translates to:
  /// **'This will create a negative transaction to bring the stock of \"{productId}\" to zero. The transaction history will be preserved for audit purposes.\n\nAre you sure you want to continue?'**
  String resetProductStockDescription(String productId);

  /// Button text to reset stock
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Success message after resetting product stock
  ///
  /// In en, this message translates to:
  /// **'Stock for \"{productId}\" has been reset to zero'**
  String stockResetToZero(String productId);

  /// Message when product has no transactions
  ///
  /// In en, this message translates to:
  /// **'No transaction history yet'**
  String get noTransactionHistoryYet;

  /// Instruction to scan product to see history
  ///
  /// In en, this message translates to:
  /// **'Scan this product to see its transaction history here'**
  String get scanProductToSeeHistory;

  /// Title for stock summary section
  ///
  /// In en, this message translates to:
  /// **'Stock Summary'**
  String get stockSummary;

  /// Label for current stock amount
  ///
  /// In en, this message translates to:
  /// **'Current Stock'**
  String get currentStock;

  /// Label for total number of transactions
  ///
  /// In en, this message translates to:
  /// **'Total Transactions'**
  String get totalTransactions;

  /// Label for positive transactions
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get positive;

  /// Label for negative transactions
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get negative;

  /// Label for neutral transactions
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get neutral;

  /// Error message when file cannot be found
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get fileNotFound;

  /// Message when no transactions exist
  ///
  /// In en, this message translates to:
  /// **'No transactions recorded yet'**
  String get noTransactionsRecordedYet;

  /// Instruction to start scanning to see history
  ///
  /// In en, this message translates to:
  /// **'Start scanning products to see transaction history'**
  String get startScanningToSeeHistory;

  /// Button text for export action
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Message when no products have been scanned
  ///
  /// In en, this message translates to:
  /// **'No products scanned yet.'**
  String get noProductsScannedYet;

  /// Label showing when product was last updated
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String lastUpdated(String date);

  /// Title for upgrades screen
  ///
  /// In en, this message translates to:
  /// **'Upgrades'**
  String get upgrades;

  /// Message about upcoming premium features
  ///
  /// In en, this message translates to:
  /// **'Premium features coming soon'**
  String get premiumFeaturesComingSoon;

  /// Error message when photo save fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save photo'**
  String get failedToSavePhoto;

  /// Error message for camera issues
  ///
  /// In en, this message translates to:
  /// **'Camera error: {error}'**
  String cameraError(String error);

  /// Error message when saving transaction fails
  ///
  /// In en, this message translates to:
  /// **'Error saving transaction: {error}'**
  String errorSavingTransaction(String error);

  /// Label for positive transaction additions
  ///
  /// In en, this message translates to:
  /// **'Additions'**
  String get additions;

  /// Label for negative transaction reductions
  ///
  /// In en, this message translates to:
  /// **'Reductions'**
  String get reductions;

  /// Title for product information dialog
  ///
  /// In en, this message translates to:
  /// **'Product Information'**
  String get productInformation;

  /// Button text to reset all stocks
  ///
  /// In en, this message translates to:
  /// **'Reset All Stocks'**
  String get resetAllStocksButton;

  /// Button text to reset individual stock
  ///
  /// In en, this message translates to:
  /// **'Reset Individual Stock'**
  String get resetIndividualStock;

  /// Button text to delete all data
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllDataButton;

  /// Title for remove all data section
  ///
  /// In en, this message translates to:
  /// **'Remove All Data'**
  String get removeAllData;

  /// Warning message for permanent deletion
  ///
  /// In en, this message translates to:
  /// **'PERMANENT DELETION: This will completely remove all products, transactions, prompt questions, and history. This action cannot be undone.'**
  String get permanentDeletionWarning;

  /// Button text to remove all data (caps)
  ///
  /// In en, this message translates to:
  /// **'REMOVE ALL DATA'**
  String get removeAllDataButton;

  /// Title for stock reset information section
  ///
  /// In en, this message translates to:
  /// **'Stock Reset Information'**
  String get stockResetInformation;

  /// Explanation of how stock reset works
  ///
  /// In en, this message translates to:
  /// **'Resetting stocks creates negative transactions that bring each product\'s stock to zero. This maintains a complete audit trail of all stock movements.'**
  String get stockResetExplanation;

  /// Message when all stocks are at zero
  ///
  /// In en, this message translates to:
  /// **'All stocks are at zero'**
  String get allStocksAtZero;

  /// Message when no products need reset
  ///
  /// In en, this message translates to:
  /// **'No products currently have stock to reset'**
  String get noProductsToReset;

  /// Tooltip for reset product button
  ///
  /// In en, this message translates to:
  /// **'Reset this product stock'**
  String get resetThisProductStock;

  /// Validation message for invalid number
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// Title for product attributes section
  ///
  /// In en, this message translates to:
  /// **'Product Attributes'**
  String get productAttributes;

  /// Title for photos section
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// Title for photos section with count
  ///
  /// In en, this message translates to:
  /// **'Photos ({count})'**
  String photosCount(int count);

  /// Error message when photos fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading photos: {error}'**
  String errorLoadingPhotos(String error);

  /// Title for transaction history section
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistoryTitle;

  /// Error message when transaction history fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading transaction history: {error}'**
  String errorLoadingTransactionHistory(String error);

  /// Button text to retry an operation
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Time format for today's transactions
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String todayAt(String time);

  /// Description for positive stock transaction
  ///
  /// In en, this message translates to:
  /// **'Stock addition'**
  String get stockAddition;

  /// Description for negative stock transaction
  ///
  /// In en, this message translates to:
  /// **'Stock reduction'**
  String get stockReduction;

  /// Title for product information dialog
  ///
  /// In en, this message translates to:
  /// **'Product Information'**
  String get productInformationTitle;

  /// Label showing product ID
  ///
  /// In en, this message translates to:
  /// **'Product ID: {productId}'**
  String productIdLabel(String productId);

  /// Description of product info screen
  ///
  /// In en, this message translates to:
  /// **'This screen shows the complete transaction history for this product.'**
  String get productInfoDescription;

  /// Info about positive quantities
  ///
  /// In en, this message translates to:
  /// **'• Positive quantities represent stock additions'**
  String get positiveQuantitiesInfo;

  /// Info about negative quantities
  ///
  /// In en, this message translates to:
  /// **'• Negative quantities represent stock reductions or resets'**
  String get negativeQuantitiesInfo;

  /// Info about current stock calculation
  ///
  /// In en, this message translates to:
  /// **'• Current stock is the sum of all transactions'**
  String get currentStockInfo;

  /// Title for photo viewer dialog
  ///
  /// In en, this message translates to:
  /// **'Photo {current} of {total}'**
  String photoViewerTitle(int current, int total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
