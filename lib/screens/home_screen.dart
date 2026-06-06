import 'dart:async';
import 'package:flutter/material.dart';
import '../models/nfc_tag.dart';
import '../services/nfc_service.dart';
import '../services/storage_service.dart';
import '../services/background_nfc_service.dart';
import '../services/app_lock_service.dart';
import 'tag_setup_screen.dart';
import 'apps_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NFCService _nfcService = NFCService();
  final StorageService _storageService = StorageService();
  final BackgroundNFCService _backgroundNFCService = BackgroundNFCService();
  final AppLockService _appLockService = AppLockService();
  
  NFCTag? _activeTag;
  bool _isLoading = true;
  bool _isScanning = false;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    _loadActiveTag();
    _checkMonitoringStatus();
  }

  @override
  void dispose() {
    _backgroundNFCService.stopMonitoring();
    super.dispose();
  }

  Future<void> _checkMonitoringStatus() async {
    final isMonitoring = _backgroundNFCService.isMonitoring;
    setState(() {
      _isMonitoring = isMonitoring;
    });
  }

  Future<void> _toggleMonitoring() async {
    if (_isMonitoring) {
      await _backgroundNFCService.stopMonitoring();
      await _appLockService.setServiceEnabled(false);
      setState(() {
        _isMonitoring = false;
      });
    } else {
      if (_activeTag == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please configure an NFC tag first')),
        );
        return;
      }
      unawaited(_backgroundNFCService.startMonitoring());
      await _appLockService.setServiceEnabled(true);
      setState(() {
        _isMonitoring = true;
      });
    }
  }

  Future<void> _emergencyUnlock() async {
    await _backgroundNFCService.stopMonitoring();
    await _appLockService.setServiceEnabled(false);
    await _storageService.setAllAppLockStatuses(false);
    await _appLockService.emergencyUnlock();
    setState(() {
      _isMonitoring = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency unlock activated - all apps unlocked')),
    );
  }

  Future<void> _loadActiveTag() async {
    final tag = await _storageService.getActiveTag();
    setState(() {
      _activeTag = tag;
      _isLoading = false;
    });
  }

  Future<void> _scanNewTag() async {
    final isAvailable = await _nfcService.isNFCAvailable();
    if (!isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC is not available on this device')),
        );
      }
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      final tagId = await _nfcService.scanTag();
      
      if (tagId != null && mounted) {
        // Navigate to tag setup screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TagSetupScreen(tagId: tagId),
          ),
        );

        if (result == true) {
          await _loadActiveTag();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning tag: $e')),
        );
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _clearTag() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear NFC Tag'),
        content: const Text('Are you sure you want to remove the current NFC tag?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.clearActiveTag();
      await _loadActiveTag();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bricked'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNFCSection(),
                  const SizedBox(height: 16),
                  _buildMonitoringSection(),
                  const SizedBox(height: 24),
                  _buildAppsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildNFCSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NFC Tag',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_activeTag != null)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _clearTag,
                    tooltip: 'Remove tag',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_activeTag != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tag Name: ${_activeTag!.name}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tag ID: ${_activeTag!.id}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Added: ${_activeTag!.createdAt.toString().split('.')[0]}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              )
            else
              const Text(
                'No NFC tag configured',
                style: TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isScanning ? null : _scanNewTag,
                child: _isScanning
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Scanning...'),
                        ],
                      )
                    : Text(_activeTag == null ? 'Scan New Tag' : 'Change Tag'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Background Monitoring',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Icon(
                  _isMonitoring ? Icons.sensors : Icons.sensors_off,
                  color: _isMonitoring ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _isMonitoring
                  ? 'Monitoring for NFC tag taps. Apps will lock/unlock when tag is detected.'
                  : 'Background monitoring is disabled. Enable to automatically lock/unlock apps when NFC tag is tapped.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleMonitoring,
                icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
                label: Text(_isMonitoring ? 'Stop Monitoring' : 'Start Monitoring'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isMonitoring ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _emergencyUnlock,
                icon: const Icon(Icons.lock_open),
                label: const Text('Emergency Unlock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use if you\'re locked out of apps',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Locked Apps',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _activeTag == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppsScreen(),
                          ),
                        ).then((_) => setState(() {}));
                      },
                icon: const Icon(Icons.apps),
                label: const Text('Manage Apps'),
              ),
            ),
            if (_activeTag == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Configure an NFC tag first',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
