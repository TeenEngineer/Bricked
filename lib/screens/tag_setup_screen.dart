import 'package:flutter/material.dart';
import '../models/nfc_tag.dart';
import '../services/storage_service.dart';

class TagSetupScreen extends StatefulWidget {
  final String tagId;

  const TagSetupScreen({super.key, required this.tagId});

  @override
  State<TagSetupScreen> createState() => _TagSetupScreenState();
}

class _TagSetupScreenState extends State<TagSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final StorageService _storageService = StorageService();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveTag() async {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a tag name')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final tag = NFCTag(
        id: widget.tagId,
        name: name,
        createdAt: DateTime.now(),
      );

      await _storageService.setActiveTag(tag);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving tag: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup NFC Tag'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tag Scanned Successfully!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Text(
              'Tag ID: ${widget.tagId}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tag Name',
                hintText: 'e.g., My Key Tag',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (_) => _saveTag(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Give this tag a name so you can easily identify it later.',
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTag,
                child: _isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Saving...'),
                        ],
                      )
                    : const Text('Save Tag'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
