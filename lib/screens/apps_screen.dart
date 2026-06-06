import 'package:flutter/material.dart';
import '../models/locked_app.dart';
import '../services/storage_service.dart';
import '../services/app_lock_service.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  final StorageService _storageService = StorageService();
  final AppLockService _appLockService = AppLockService();
  List<LockedApp> _lockedApps = [];
  List<Map<String, String>> _installedApps = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lockedApps = await _storageService.getLockedApps();
      final installedApps = await _appLockService.getInstalledApps();

      setState(() {
        _lockedApps = lockedApps;
        _installedApps = installedApps;
        _isLoading = false;
      });
      
      // Sync with native service after loading
      await _updateNativeService();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading apps: $e')),
        );
      }
    }
  }

  Future<void> _toggleAppLock(String packageName, String appName) async {
    final existingApp = _lockedApps.firstWhere(
      (app) => app.packageName == packageName,
      orElse: () => LockedApp(
        packageName: packageName,
        appName: appName,
        isLocked: false,
      ),
    );

    final newStatus = !existingApp.isLocked;
    final updatedApp = existingApp.copyWith(isLocked: newStatus);

    if (newStatus) {
      await _storageService.addLockedApp(updatedApp);
    } else {
      await _storageService.removeLockedApp(packageName);
    }

    await _loadData();
  }

  Future<void> _updateNativeService() async {
    final lockedPackageNames = _lockedApps
        .where((app) => app.isLocked)
        .map((app) => app.packageName)
        .toList();
    
    await _appLockService.updateLockedApps(lockedPackageNames);
  }

  bool _isAppLocked(String packageName) {
    return _lockedApps.any((app) => app.packageName == packageName && app.isLocked);
  }

  List<Map<String, String>> get _filteredApps {
    if (_searchQuery.isEmpty) return _installedApps;
    return _installedApps
        .where((app) =>
            app['appName']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            app['packageName']!.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Locked Apps'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search apps',
                      hintText: 'Search by name or package',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _filteredApps.isEmpty
                      ? const Center(
                          child: Text('No apps found'),
                        )
                      : ListView.builder(
                          itemCount: _filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = _filteredApps[index];
                            final packageName = app['packageName']!;
                            final appName = app['appName']!;
                            final isLocked = _isAppLocked(packageName);

                            return SwitchListTile(
                              title: Text(appName),
                              subtitle: Text(packageName),
                              value: isLocked,
                              onChanged: (value) {
                                _toggleAppLock(packageName, appName);
                              },
                              secondary: Icon(
                                isLocked ? Icons.lock : Icons.lock_open,
                                color: isLocked ? Colors.red : Colors.green,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
