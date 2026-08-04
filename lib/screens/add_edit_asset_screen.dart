import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/asset_service.dart';
import '../widgets/theme_toggle_button.dart';

class AddEditAssetScreen extends StatefulWidget {
  // if an existing asset is passed in, we're editing; if null, we're adding a new one
  final Asset? existingAsset;

  const AddEditAssetScreen({super.key, this.existingAsset});

  @override
  State<AddEditAssetScreen> createState() => _AddEditAssetScreenState();
}

class _AddEditAssetScreenState extends State<AddEditAssetScreen> {
  final _nameController = TextEditingController();
  final _assetService = AssetService();

  // the list of asset types the user can pick from
  final List<String> _assetTypes = [
    'Server',
    'Laptop',
    'Desktop',
    'Network Device',
    'Web Application',
  ];

  String _selectedType = 'Server';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // if we're editing, fill in the existing values
    if (widget.existingAsset != null) {
      _nameController.text = widget.existingAsset!.name;
      _selectedType = widget.existingAsset!.type;
    }
  }

  String? _formError;

  void _handleSave() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _formError = 'Asset name is required.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _formError = null;
    });

    if (widget.existingAsset == null) {
      // adding a brand new asset
      await _assetService.addAsset(_nameController.text.trim(), _selectedType);
    } else {
      // updating an asset that already exists
      await _assetService.updateAsset(
        widget.existingAsset!.id,
        _nameController.text.trim(),
        _selectedType,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAsset != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit asset' : 'Add asset'),
        actions: const [ThemeToggleButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing
                      ? 'Update asset details'
                      : 'Add to your security inventory',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use a clear, recognizable name so findings are easy to assign and track.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Asset name',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Asset type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _assetTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_formError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      _formError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                _isSaving
                    ? const CircularProgressIndicator()
                    : FilledButton.icon(
                        onPressed: _handleSave,
                        icon: Icon(
                          isEditing ? Icons.save_outlined : Icons.add_rounded,
                        ),
                        label: Text(isEditing ? 'Save changes' : 'Add asset'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
