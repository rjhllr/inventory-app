import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_database.dart';
import '../view_models/settings_vm.dart';

class AddPromptScreen extends ConsumerStatefulWidget {
  final PromptQuestion? question;
  
  const AddPromptScreen({super.key, this.question});

  @override
  ConsumerState<AddPromptScreen> createState() => _AddPromptScreenState();
}

class _AddPromptScreenState extends ConsumerState<AddPromptScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  InputType _inputType = InputType.text;
  AskMode _askMode = AskMode.every_scan;
  bool _prefillLastInput = false;
  
  bool get _isEditing => widget.question != null;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _labelController = TextEditingController(text: q?.label ?? '');
    if (q != null) {
      _inputType = InputType.values.firstWhere((e) => e.name == q.inputType);
      _askMode = AskMode.values.firstWhere((e) => e.name == q.askMode);
      _prefillLastInput = q.prefillLastInput;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _savePrompt() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final settingsVm = ref.read(settingsVmProvider);
      await settingsVm.saveQuestion(
        id: widget.question?.id,
        label: _labelController.text,
        inputType: _inputType,
        askMode: _askMode,
        prefillLastInput: _prefillLastInput,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving prompt: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Prompt' : 'Add Prompt'),
        actions: [
          TextButton(
            onPressed: _savePrompt,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label field
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  border: OutlineInputBorder(),
                  helperText: 'This will be shown to users when prompting for input',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a label';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Input Type Section
              Text(
                'Input Type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Select what type of input users will provide:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              _buildInputTypeSelector(),
              
              const SizedBox(height: 24),
              
              // Ask Mode Section
              Text(
                'Ask Mode',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose when to ask this question:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              _buildAskModeSelector(),
              
              const SizedBox(height: 24),
              
              // Prefill option
              Card(
                child: SwitchListTile(
                  title: const Text('Prefill last input'),
                  subtitle: const Text('Automatically populate with the last entered value'),
                  value: _prefillLastInput,
                  onChanged: (value) => setState(() => _prefillLastInput = value),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePrompt,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_isEditing ? 'Update Prompt' : 'Add Prompt'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: InputType.values.map((type) {
        final isSelected = _inputType == type;
        return _buildOptionButton(
          icon: _getInputTypeIcon(type),
          label: _getInputTypeLabel(type),
          description: _getInputTypeDescription(type),
          isSelected: isSelected,
          onTap: () => setState(() => _inputType = type),
        );
      }).toList(),
    );
  }

  Widget _buildAskModeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AskMode.values.map((mode) {
        final isSelected = _askMode == mode;
        return _buildOptionButton(
          icon: _getAskModeIcon(mode),
          label: _getAskModeLabel(mode),
          description: _getAskModeDescription(mode),
          isSelected: isSelected,
          onTap: () => setState(() => _askMode = mode),
        );
      }).toList(),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getInputTypeIcon(InputType type) {
    switch (type) {
      case InputType.text:
        return Icons.text_fields;
      case InputType.number:
        return Icons.numbers;
      case InputType.photo:
        return Icons.camera_alt;
      case InputType.date:
        return Icons.calendar_today;
    }
  }

  String _getInputTypeLabel(InputType type) {
    switch (type) {
      case InputType.text:
        return 'Text';
      case InputType.number:
        return 'Number';
      case InputType.photo:
        return 'Photo';
      case InputType.date:
        return 'Date';
    }
  }

  String _getInputTypeDescription(InputType type) {
    switch (type) {
      case InputType.text:
        return 'Free-form text input';
      case InputType.number:
        return 'Numeric input only';
      case InputType.photo:
        return 'Camera capture';
      case InputType.date:
        return 'Date picker';
    }
  }

  IconData _getAskModeIcon(AskMode mode) {
    switch (mode) {
      case AskMode.once:
        return Icons.looks_one;
      case AskMode.every_scan:
        return Icons.repeat;
    }
  }

  String _getAskModeLabel(AskMode mode) {
    switch (mode) {
      case AskMode.once:
        return 'Once per product';
      case AskMode.every_scan:
        return 'Every scan';
    }
  }

  String _getAskModeDescription(AskMode mode) {
    switch (mode) {
      case AskMode.once:
        return 'Ask only the first time a product is scanned';
      case AskMode.every_scan:
        return 'Ask every time a product is scanned';
    }
  }
} 