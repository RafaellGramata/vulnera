import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/asset_service.dart';

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
      appBar: AppBar(title: Text(isEditing ? 'Edit Asset' : 'Add Asset')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Asset Name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Asset Type'),
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
                child: Text(_formError!, style: const TextStyle(color: Colors.red)),
              ),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleSave,
                    child: Text(isEditing ? 'Save Changes' : 'Add Asset'),
                  ),
          ],
        ),
      ),
    );
  }
}