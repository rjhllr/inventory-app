// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Inventory App';

  @override
  String get homeTitle => 'Inventory App';

  @override
  String get startStockTaking => 'Start Stock-taking';

  @override
  String get resetStocksData => 'Reset Stocks / Data';

  @override
  String get stockTakingSettings => 'Stock-taking Settings';

  @override
  String get productDatabase => 'Product Database';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get exportCSV => 'Export CSV';

  @override
  String get exportInventoryData => 'Export inventory data as ZIP file';

  @override
  String get scanning => 'Scanning';

  @override
  String get turnOffFlash => 'Turn off flash';

  @override
  String get turnOnFlash => 'Turn on flash';

  @override
  String get error => 'Error';

  @override
  String errorMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get promptForQuantity => 'Prompt for Quantity';

  @override
  String get additionalPrompts => 'Additional Prompts';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get type => 'Type';

  @override
  String get mode => 'Mode';

  @override
  String get loading => 'Loading...';

  @override
  String get transactionDetails => 'Transaction Details';

  @override
  String get product => 'Product';

  @override
  String get timestamp => 'Timestamp';

  @override
  String get thisTransaction => 'This Transaction';

  @override
  String get currentTotal => 'Current Total';

  @override
  String get setNewTotalCount => 'Set New Total Count:';

  @override
  String get totalCount => 'Total Count';

  @override
  String get enterDesiredTotal => 'Enter desired total';

  @override
  String get set => 'Set';

  @override
  String get attributes => 'Attributes';

  @override
  String get close => 'Close';

  @override
  String totalCountSetTo(int total, String difference) {
    return 'Total count set to $total ($difference)';
  }

  @override
  String get editPrompt => 'Edit Prompt';

  @override
  String get addPrompt => 'Add Prompt';

  @override
  String get save => 'Save';

  @override
  String get label => 'Label';

  @override
  String get labelHelperText =>
      'This will be shown to users when prompting for input';

  @override
  String get pleaseEnterLabel => 'Please enter a label';

  @override
  String get inputType => 'Input Type';

  @override
  String get selectInputTypeDescription =>
      'Select what type of input users will provide:';

  @override
  String get askMode => 'Ask Mode';

  @override
  String get chooseAskModeDescription => 'Choose when to ask this question:';

  @override
  String get prefillLastInput => 'Prefill last input';

  @override
  String get prefillLastInputDescription =>
      'Automatically populate with the last entered value';

  @override
  String get updatePrompt => 'Update Prompt';

  @override
  String get inputTypeText => 'Text';

  @override
  String get inputTypeNumber => 'Number';

  @override
  String get inputTypePhoto => 'Photo';

  @override
  String get inputTypeDate => 'Date';

  @override
  String get inputTypeTextDescription => 'Free-form text input';

  @override
  String get inputTypeNumberDescription => 'Numeric input only';

  @override
  String get inputTypePhotoDescription => 'Camera capture';

  @override
  String get inputTypeDateDescription => 'Date picker';

  @override
  String get askModeOnce => 'Once per product';

  @override
  String get askModeEveryS => 'Every scan';

  @override
  String get askModeOnceDescription =>
      'Ask only the first time a product is scanned';

  @override
  String get askModeEveryScanDescription =>
      'Ask every time a product is scanned';

  @override
  String errorSavingPrompt(String error) {
    return 'Error saving prompt: $error';
  }

  @override
  String productPrefix(String productCode) {
    return 'Product: $productCode';
  }

  @override
  String get enterQuantity => 'Enter Quantity';

  @override
  String get next => 'Next';

  @override
  String get finish => 'Finish';

  @override
  String get required => 'Required';

  @override
  String get optional => 'Optional';

  @override
  String get previous => 'Previous';

  @override
  String get photo => 'Photo';

  @override
  String get photoPreview => 'Photo Preview';

  @override
  String get usePhoto => 'Use Photo';

  @override
  String get retake => 'Retake';

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get addAnotherPhoto => 'Add Another Photo';

  @override
  String get enterText => 'Enter text';

  @override
  String get enterNumber => 'Enter number';

  @override
  String get selectDate => 'Select date';

  @override
  String get pleaseEnterValue => 'Please enter a value';

  @override
  String get exportInformation => 'Export Information';

  @override
  String get generateExport => 'Generate Export';

  @override
  String get generatingExport => 'Generating export...';

  @override
  String get exportCompletedSuccessfully => 'Export completed successfully!';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get exportFormat => 'Export Format';

  @override
  String get exportDescription =>
      'The export will generate a ZIP file containing:';

  @override
  String get productsCsv => 'products.csv';

  @override
  String get productsCsvDescription =>
      'Contains all product information including:';

  @override
  String get productId => 'Product ID';

  @override
  String get createdAtTimestamp => 'Created At timestamp';

  @override
  String get updatedAtTimestamp => 'Updated At timestamp';

  @override
  String get oncePerProductAnswers =>
      'All \"once per product\" prompt question answers';

  @override
  String get transactionsCsv => 'transactions.csv';

  @override
  String get transactionsCsvDescription =>
      'Contains all transaction/scan records including:';

  @override
  String get transactionId => 'Transaction ID';

  @override
  String get quantityScanned => 'Quantity scanned';

  @override
  String get allPromptAnswers => 'All prompt answers';

  @override
  String get imagesFolder => 'images/ folder';

  @override
  String get imagesFolderDescription =>
      'Contains all photos captured during scanning:';

  @override
  String get photosFromPrompts => 'Photos from photo-type prompt questions';

  @override
  String get filesReferencedInCsv =>
      'Files referenced in CSV as \"images/filename.jpg\"';

  @override
  String get originalFilenames => 'Original file names preserved';

  @override
  String get fileNaming => 'File Naming';

  @override
  String get exportFilenamePattern =>
      'Export files are named: inventory_export_YYYYMMDD_HHMMSS.zip';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get actionCannotBeUndone => 'THIS ACTION CANNOT BE UNDONE!';

  @override
  String get willPermanentlyDelete => 'This will permanently delete:';

  @override
  String get allScannedProducts => 'All scanned products';

  @override
  String get allTransactionHistory => 'All transaction history';

  @override
  String get allCustomPromptQuestions => 'All custom prompt questions';

  @override
  String get absolutelySureToContinue =>
      'Are you absolutely sure you want to continue?';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteAllCaps => 'DELETE ALL';

  @override
  String get allDataPermanentlyDeleted =>
      'All data has been permanently deleted';

  @override
  String failedToDeleteData(String error) {
    return 'Failed to delete data: $error';
  }

  @override
  String get resetAllStocks => 'Reset All Stocks';

  @override
  String get resetAllStocksDescription =>
      'This will create negative transactions to bring all product stocks to zero. The transaction history will be preserved for audit purposes.\n\nAre you sure you want to continue?';

  @override
  String get resetAll => 'Reset All';

  @override
  String get allStocksResetToZero => 'All stocks have been reset to zero';

  @override
  String get resetProductStock => 'Reset Product Stock';

  @override
  String resetProductStockDescription(String productId) {
    return 'This will create a negative transaction to bring the stock of \"$productId\" to zero. The transaction history will be preserved for audit purposes.\n\nAre you sure you want to continue?';
  }

  @override
  String get reset => 'Reset';

  @override
  String stockResetToZero(String productId) {
    return 'Stock for \"$productId\" has been reset to zero';
  }

  @override
  String get noTransactionHistoryYet => 'No transaction history yet';

  @override
  String get scanProductToSeeHistory =>
      'Scan this product to see its transaction history here';

  @override
  String get stockSummary => 'Stock Summary';

  @override
  String get currentStock => 'Current Stock';

  @override
  String get totalTransactions => 'Total Transactions';

  @override
  String get positive => 'Positive';

  @override
  String get negative => 'Negative';

  @override
  String get neutral => 'Neutral';

  @override
  String get fileNotFound => 'File not found';

  @override
  String get noTransactionsRecordedYet => 'No transactions recorded yet';

  @override
  String get startScanningToSeeHistory =>
      'Start scanning products to see transaction history';

  @override
  String get export => 'Export';

  @override
  String get noProductsScannedYet => 'No products scanned yet.';

  @override
  String lastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get upgrades => 'Upgrades';

  @override
  String get premiumFeaturesComingSoon => 'Premium features coming soon';

  @override
  String get failedToSavePhoto => 'Failed to save photo';

  @override
  String cameraError(String error) {
    return 'Camera error: $error';
  }

  @override
  String errorSavingTransaction(String error) {
    return 'Error saving transaction: $error';
  }

  @override
  String get additions => 'Additions';

  @override
  String get reductions => 'Reductions';

  @override
  String get productInformation => 'Product Information';

  @override
  String get resetAllStocksButton => 'Reset All Stocks';

  @override
  String get resetIndividualStock => 'Reset Individual Stock';

  @override
  String get deleteAllDataButton => 'Delete All Data';

  @override
  String get removeAllData => 'Remove All Data';

  @override
  String get permanentDeletionWarning =>
      'PERMANENT DELETION: This will completely remove all products, transactions, prompt questions, and history. This action cannot be undone.';

  @override
  String get removeAllDataButton => 'REMOVE ALL DATA';

  @override
  String get stockResetInformation => 'Stock Reset Information';

  @override
  String get stockResetExplanation =>
      'Resetting stocks creates negative transactions that bring each product\'s stock to zero. This maintains a complete audit trail of all stock movements.';

  @override
  String get allStocksAtZero => 'All stocks are at zero';

  @override
  String get noProductsToReset => 'No products currently have stock to reset';

  @override
  String get resetThisProductStock => 'Reset this product stock';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get productAttributes => 'Product Attributes';

  @override
  String get photos => 'Photos';

  @override
  String photosCount(int count) {
    return 'Photos ($count)';
  }

  @override
  String errorLoadingPhotos(String error) {
    return 'Error loading photos: $error';
  }

  @override
  String get transactionHistoryTitle => 'Transaction History';

  @override
  String errorLoadingTransactionHistory(String error) {
    return 'Error loading transaction history: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String todayAt(String time) {
    return 'Today at $time';
  }

  @override
  String get stockAddition => 'Stock addition';

  @override
  String get stockReduction => 'Stock reduction';

  @override
  String get productInformationTitle => 'Product Information';

  @override
  String productIdLabel(String productId) {
    return 'Product ID: $productId';
  }

  @override
  String get productInfoDescription =>
      'This screen shows the complete transaction history for this product.';

  @override
  String get positiveQuantitiesInfo =>
      '• Positive quantities represent stock additions';

  @override
  String get negativeQuantitiesInfo =>
      '• Negative quantities represent stock reductions or resets';

  @override
  String get currentStockInfo =>
      '• Current stock is the sum of all transactions';

  @override
  String photoViewerTitle(int current, int total) {
    return 'Photo $current of $total';
  }

  @override
  String get photoTaken => 'Photo taken';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get viewPhoto => 'View Photo';

  @override
  String get detailsTab => 'Details';

  @override
  String get transactionsTab => 'Transactions';

  @override
  String get seeAll => 'See all';

  @override
  String valuesListTitle(String attribute) {
    return 'Values for $attribute';
  }
}
