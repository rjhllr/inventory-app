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
  final _scrollController = ScrollController();
  final Map<String, List<String>> _photoAnswers = {};
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, DateTime?> _dateValues = {};
  
  bool _isLoading = true;
  bool _isInitialized = false;
  bool _isSaving = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
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
    _scrollController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    for (final question in widget.questions) {
      if (question.inputType == 'text' || question.inputType == 'number') {
        _textControllers[question.id] = TextEditingController();
      }
      if (question.inputType == 'photo') {
        _photoAnswers[question.id] = [];
      }
      if (question.inputType == 'date') {
        _dateValues[question.id] = null;
      }
    }
  }

  Future<void> _fetchInitialValues() async {
    final dataSource = ref.read(dataSourceProvider);
    for (final q in widget.questions) {
      if (q.prefillLastInput) {
        final lastAnswer = await dataSource.getLastAnswerForQuestion(q.id);
        if (lastAnswer != null) {
          if (q.inputType == 'date') {
            _dateValues[q.id] = DateTime.tryParse(lastAnswer.value);
          } else if (q.inputType == 'photo') {
            _photoAnswers[q.id] = [];
          } else {
            _textControllers[q.id]?.text = lastAnswer.value;
          }
        }
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildQuantitySection() {
    if (!widget.promptForQuantity) return const SizedBox.shrink();
    
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.enterQuantity,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _quantity.toString(),
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _adjustQuantity(1),
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: () => _adjustQuantity(-1),
                      icon: const Icon(Icons.remove),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNumpad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 1.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        '1', '2', '3',
        '4', '5', '6',
        '7', '8', '9',
        'C', '0', '⌫',
      ].map((text) => _buildNumpadButton(text)).toList(),
    );
  }

  Widget _buildNumpadButton(String text) {
    final isSpecial = text == 'C' || text == '⌫';
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSpecial ? Colors.grey[300] : null,
          foregroundColor: isSpecial ? Colors.black : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () => _handleNumpadPress(text),
        child: Text(
          text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _handleNumpadPress(String value) {
    setState(() {
      if (value == 'C') {
        _quantity = 0;
      } else if (value == '⌫') {
        if (_quantity > 0) {
          _quantity = _quantity ~/ 10;
        }
      } else {
        final currentStr = _quantity.toString();
        if (currentStr.length < 6) {
          final newValue = int.tryParse(currentStr + value);
          if (newValue != null) {
            _quantity = newValue;
          }
        }
      }
    });
  }

  void _adjustQuantity(int delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(0, 999999);
    });
  }

  Widget _buildQuestionsSection() {
    if (widget.questions.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: widget.questions.map((question) => _buildQuestionCard(question)).toList(),
    );
  }

  Widget _buildQuestionCard(PromptQuestion question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildQuestionInput(question),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput(PromptQuestion question) {
    switch (question.inputType) {
      case 'number':
        return TextFormField(
          controller: _textControllers[question.id],
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: AppLocalizations.of(context)!.enterNumber,
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onEditingComplete: () => FocusScope.of(context).unfocus(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.pleaseEnterValue;
            }
            if (double.tryParse(value) == null) {
              return AppLocalizations.of(context)!.pleaseEnterValidNumber;
            }
            return null;
          },
        );
      case 'text':
        return TextFormField(
          controller: _textControllers[question.id],
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
        );
      case 'date':
        return _DateField(
          initialValue: _dateValues[question.id],
          onChanged: (date) {
            setState(() {
              _dateValues[question.id] = date;
            });
          },
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

  Future<void> _saveAndFinish() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Validate form
      if (!_formKey.currentState!.validate()) {
        setState(() => _isSaving = false);
        return;
      }
      
      // Collect answers
      final answers = <String, String>{};
      
      // Text and number inputs
      for (final entry in _textControllers.entries) {
        final value = entry.value.text.trim();
        if (value.isNotEmpty) {
          answers[entry.key] = value;
        }
      }
      
      // Date inputs
      for (final entry in _dateValues.entries) {
        final date = entry.value;
        if (date != null) {
          answers[entry.key] = date.toIso8601String();
        }
      }
      
      // Photo inputs
      for (final entry in _photoAnswers.entries) {
        if (entry.value.isNotEmpty) {
          answers[entry.key] = entry.value.join(',');
        }
      }
      
      final scanningVm = ref.read(scanningVmProvider);
      await scanningVm.saveTransaction(
        code: widget.productCode,
        quantity: _quantity,
        answers: answers,
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
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productPrefix(widget.productCode)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuantitySection(),
              _buildQuestionsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAndFinish,
            child: _isSaving 
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatefulWidget {
  final DateTime? initialValue;
  final Function(DateTime?) onChanged;

  const _DateField({
    this.initialValue,
    required this.onChanged,
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
          widget.onChanged(date);
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
        imageQuality: 85,
      );
      
      if (image != null) {
        if (mounted) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => _PhotoPreviewDialog(imagePath: image.path),
          );
          
          if (result == true) {
            final savedPath = await _savePhotoToAppDirectory(image.path);
            if (savedPath != null) {
              final newPhotos = [...widget.photos, savedPath];
              widget.onPhotosChanged(newPhotos);
              
              // Show success message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.photoTaken),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } else {
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

  void _showPhotoViewer(String photoPath) {
    showDialog(
      context: context,
      builder: (context) => _PhotoViewerDialog(
        imagePath: photoPath,
        title: AppLocalizations.of(context)!.photoViewerTitle(1, 1),
      ),
    );
  }

  Widget _buildPhotoWidget(String photoPath) {
    final file = File(photoPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.failedToLoadImage,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _takePhoto,
          icon: const Icon(Icons.camera_alt),
          label: Text(widget.photos.isEmpty ? l10n.takePhoto : l10n.addAnotherPhoto),
        ),
        const SizedBox(height: 16),
        if (widget.photos.isNotEmpty) ...[
          Text(
            l10n.photosCount(widget.photos.length),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.photos.length,
              itemBuilder: (context, index) {
                final photoPath = widget.photos[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
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
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoPreviewDialog extends StatelessWidget {
  final String imagePath;

  const _PhotoPreviewDialog({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(l10n.photoPreview),
              leading: const SizedBox.shrink(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n.retake),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(l10n.usePhoto),
                    ),
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

class _PhotoViewerDialog extends StatelessWidget {
  final String imagePath;
  final String title;

  const _PhotoViewerDialog({
    required this.imagePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              leading: const SizedBox.shrink(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 