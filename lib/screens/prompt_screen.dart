import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

import '../data/app_database.dart';
import '../providers.dart';
import '../view_models/scanning_vm.dart';
import '../l10n/app_localizations.dart';

class PromptScreen extends ConsumerStatefulWidget {
  final String productCode;
  final List<PromptQuestion> questions;
  final bool promptForQuantity;

  const PromptScreen({
    super.key,
    required this.productCode,
    required this.questions,
    required this.promptForQuantity,
  });

  @override
  ConsumerState<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends ConsumerState<PromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _answers = {};
  final Map<String, dynamic> _initialValues = {};
  final Map<String, List<String>> _photoAnswers = {}; // For storing multiple photos
  bool _isLoading = true;
  bool _isInitialized = false;
  int _quantity = 1;
  
  late PageController _pageController;
  int _currentPage = 0;
  List<Widget>? _pages; // Make this nullable and build lazily

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _fetchInitialValues();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialValues() async {
    final dataSource = ref.read(dataSourceProvider);
    for (final q in widget.questions) {
      if (q.prefillLastInput) {
        final lastAnswer = await dataSource.getLastAnswerForQuestion(q.id);
        if (lastAnswer != null) {
          if (q.inputType == 'date') {
            _initialValues[q.id] = DateTime.tryParse(lastAnswer.value);
          } else if (q.inputType == 'photo') {
            // For photos, we'll start with empty list since we want fresh photos
            _photoAnswers[q.id] = [];
          } else {
            _initialValues[q.id] = lastAnswer.value;
          }
        }
      }
      
      // Initialize photo answers for photo questions
      if (q.inputType == 'photo') {
        _photoAnswers[q.id] = [];
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  int get _totalPageCount {
    int count = 0;
    if (widget.promptForQuantity) count++;
    count += widget.questions.length;
    return count;
  }

  List<Widget> _buildPages() {
    if (_pages != null) return _pages!;
    
    _pages = [];
    
    // Add quantity page if needed
    if (widget.promptForQuantity) {
      _pages!.add(_buildQuantityPage());
    }
    
    // Add pages for each question
    for (final question in widget.questions) {
      _pages!.add(_buildQuestionPage(question));
    }
    
    return _pages!;
  }

  Widget _buildQuantityPage() {
    final pages = _buildPages();
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productPrefix(widget.productCode)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPageCount,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.enterQuantity,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _quantity.toString(),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildNumpad(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _nextPage,
            child: Text(l10n.next),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPage(PromptQuestion question) {
    final pages = _buildPages();
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productPrefix(widget.productCode)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPageCount,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.label,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: _buildQuestionInput(question),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              if (_currentPage > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousPage,
                    child: Text(l10n.previous),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLastPage() ? _saveAndFinish : _nextPage,
                  child: Text(_isLastPage() ? l10n.save : l10n.next),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionInput(PromptQuestion question) {
    switch (question.inputType) {
      case 'number':
        return TextFormField(
          initialValue: _initialValues[question.id]?.toString(),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: AppLocalizations.of(context)!.enterNumber,
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.pleaseEnterValue;
            }
            if (double.tryParse(value) == null) {
              return AppLocalizations.of(context)!.pleaseEnterValidNumber;
            }
            return null;
          },
          onSaved: (value) => _answers[question.id] = value ?? '',
        );
      case 'text':
        return TextFormField(
          initialValue: _initialValues[question.id]?.toString(),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: AppLocalizations.of(context)!.enterText,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.pleaseEnterValue;
            }
            return null;
          },
          onSaved: (value) => _answers[question.id] = value ?? '',
        );
      case 'date':
        return _DateField(
          initialValue: _initialValues[question.id] as DateTime?,
          onSaved: (value) => _answers[question.id] = value.toIso8601String(),
        );
      case 'photo':
        return _PhotoField(
          photos: _photoAnswers[question.id] ?? [],
          onPhotosChanged: (photos) {
            setState(() {
              _photoAnswers[question.id] = photos;
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNumpad() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumpadButton('1'),
              _buildNumpadButton('2'),
              _buildNumpadButton('3'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumpadButton('4'),
              _buildNumpadButton('5'),
              _buildNumpadButton('6'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumpadButton('7'),
              _buildNumpadButton('8'),
              _buildNumpadButton('9'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumpadButton('C', isSpecial: true),
              _buildNumpadButton('0'),
              _buildNumpadButton('⌫', isSpecial: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(String text, {bool isSpecial = false}) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSpecial ? Colors.grey[300] : null,
          foregroundColor: isSpecial ? Colors.black : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        onPressed: () => _handleNumpadPress(text),
        child: Text(
          text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _handleNumpadPress(String value) {
    setState(() {
      if (value == 'C') {
        _quantity = 0;
      } else if (value == '⌫') {
        _quantity = _quantity ~/ 10;
      } else {
        final currentStr = _quantity.toString();
        if (currentStr.length < 6) { // Reasonable limit
          _quantity = int.parse(currentStr + value);
        }
      }
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isLastPage() {
    return _currentPage == _totalPageCount - 1;
  }

  Future<void> _saveAndFinish() async {
    try {
      // Validate form if we have text/number inputs
      if (widget.questions.any((q) => q.inputType == 'text' || q.inputType == 'number' || q.inputType == 'date')) {
        if (!_formKey.currentState!.validate()) {
          return;
        }
        _formKey.currentState!.save();
      }
      
      // Convert photo answers to comma-separated paths
      for (final entry in _photoAnswers.entries) {
        if (entry.value.isNotEmpty) {
          _answers[entry.key] = entry.value.join(',');
        }
      }
      
      final scanningVm = ref.read(scanningVmProvider);
      await scanningVm.saveTransaction(
        code: widget.productCode,
        quantity: _quantity,
        answers: _answers,
      );
      
      if (mounted) {
        Navigator.of(context).pop({'success': true});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSavingTransaction(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final pages = _buildPages();
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemCount: pages.length,
      itemBuilder: (context, index) => pages[index],
    );
  }
}

class _DateField extends StatefulWidget {
  final DateTime? initialValue;
  final Function(DateTime) onSaved;

  const _DateField({
    this.initialValue,
    required this.onSaved,
  });

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
          widget.onSaved(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 12),
            Text(
              _selectedDate != null
                  ? _formatDate(_selectedDate!)
                  : AppLocalizations.of(context)!.selectDate,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final locale = AppLocalizations.of(context)!.localeName;
    if (locale == 'de') {
      return DateFormat('dd.MM.yyyy').format(date);
    } else {
      return DateFormat('MM/dd/yyyy').format(date);
    }
  }
}

class _PhotoField extends StatefulWidget {
  final List<String> photos;
  final Function(List<String>) onPhotosChanged;

  const _PhotoField({
    required this.photos,
    required this.onPhotosChanged,
  });

  @override
  State<_PhotoField> createState() => _PhotoFieldState();
}

class _PhotoFieldState extends State<_PhotoField> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      
      if (image != null) {
        // Show preview dialog
        if (mounted) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => _PhotoPreviewDialog(imagePath: image.path),
          );
          
          if (result == true) {
            // Save the photo permanently
            final savedPath = await _savePhotoToAppDirectory(image.path);
            if (savedPath != null) {
              final newPhotos = [...widget.photos, savedPath];
              widget.onPhotosChanged(newPhotos);
            } else {
              // Show error message if save failed
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.failedToSavePhoto)),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      // Handle camera permission or other errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cameraError(e.toString()))),
        );
      }
    }
  }

  Future<String?> _savePhotoToAppDirectory(String tempPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = path.join(photosDir.path, fileName);
      
      // Check if temp file exists before copying
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.copy(savedPath);
        return savedPath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _removePhoto(int index) {
    if (index >= 0 && index < widget.photos.length) {
      final newPhotos = [...widget.photos];
      newPhotos.removeAt(index);
      widget.onPhotosChanged(newPhotos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.photos.isNotEmpty) ...[
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: widget.photos.length,
              itemBuilder: (context, index) {
                final photoPath = widget.photos[index];
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _showPhotoViewer(photoPath),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildPhotoWidget(photoPath),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: Text(widget.photos.isEmpty ? AppLocalizations.of(context)!.takePhoto : AppLocalizations.of(context)!.addAnotherPhoto),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoWidget(String photoPath) {
    try {
      final file = File(photoPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            );
          },
        );
      } else {
        return const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
        );
      }
    } catch (e) {
      return const Center(
        child: Icon(Icons.error, size: 48, color: Colors.red),
      );
    }
  }

  void _showPhotoViewer(String photoPath) {
    if (File(photoPath).existsSync()) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(AppLocalizations.of(context)!.photo),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Expanded(
                  child: Image.file(
                    File(photoPath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(AppLocalizations.of(context)!.failedToLoadImage),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

class _PhotoPreviewDialog extends StatelessWidget {
  final String imagePath;

  const _PhotoPreviewDialog({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(AppLocalizations.of(context)!.photoPreview),
              automaticallyImplyLeading: false,
            ),
            Expanded(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(AppLocalizations.of(context)!.retake),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(AppLocalizations.of(context)!.usePhoto),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 