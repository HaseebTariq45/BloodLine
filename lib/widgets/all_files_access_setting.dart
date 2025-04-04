import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/storage_permission_handler.dart';

class AllFilesAccessSetting extends StatefulWidget {
  const AllFilesAccessSetting({Key? key}) : super(key: key);

  @override
  State<AllFilesAccessSetting> createState() => _AllFilesAccessSettingState();
}

class _AllFilesAccessSettingState extends State<AllFilesAccessSetting> {
  bool _hasPermission = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    if (!Platform.isAndroid) {
      setState(() {
        _loading = false;
        _hasPermission = true; // Not relevant for platforms other than Android
      });
      return;
    }

    final hasPermission = await StoragePermissionHandler.hasStoragePermission();
    
    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
        _loading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _loading = true;
    });
    
    await StoragePermissionHandler.showAllFilesAccessDialog(context);
    
    // Check again after user returns from settings
    await _checkPermission();
  }

  @override
  Widget build(BuildContext context) {
    // Only show this setting on Android
    if (!Platform.isAndroid) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'All Files Access',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _hasPermission ? Icons.check_circle : Icons.error_outline,
                    color: _hasPermission ? Colors.green : Colors.orange,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'App requires "All Files Access" permission to download and install updates.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _hasPermission ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasPermission ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                    color: _hasPermission ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _hasPermission
                          ? 'All Files Access permission granted'
                          : 'Permission not granted. Tap button below to grant.',
                      style: TextStyle(
                        color: _hasPermission ? Colors.green.shade700 : Colors.orange.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_hasPermission)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _requestPermission,
                  icon: const Icon(Icons.settings),
                  label: const Text('Grant Permission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 