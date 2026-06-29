import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:md_editor/core/constants.dart';
import 'package:md_editor/core/theme_manager.dart';
import 'package:md_editor/models/recent_file.dart';
import 'package:md_editor/screens/reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _recentFilesKey = 'recent_files';
  List<RecentFile> _recentFiles = [];
  bool _isLoading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  Future<void> _loadRecentFiles() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_recentFilesKey);
      if (jsonList != null) {
        setState(() {
          _recentFiles = jsonList.map((item) => RecentFile.fromJson(item)).toList();
          _recentFiles.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
        });
      }
    } catch (e) {
      debugPrint("Error loading recent files: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _recentFiles.map((file) => file.toJson()).toList();
      await prefs.setStringList(_recentFilesKey, jsonList);
    } catch (e) {
      debugPrint("Error saving recent files: $e");
    }
  }

  Future<void> _addOrUpdateRecentFile(String filePath, String fileName) async {
    final now = DateTime.now();
    final index = _recentFiles.indexWhere((file) => file.filePath == filePath);
    
    setState(() {
      if (index != -1) {
        _recentFiles.removeAt(index);
      }
      _recentFiles.insert(0, RecentFile(filePath: filePath, fileName: fileName, lastOpened: now));
    });
    
    await _saveRecentFiles();
  }

  Future<void> _removeRecentFile(RecentFile file) async {
    setState(() {
      _recentFiles.removeWhere((item) => item.filePath == file.filePath);
    });
    await _saveRecentFiles();
  }

  Future<void> _openFilePicker() async {
    final status = await Permission.storage.status;
    if (status.isPermanentlyDenied) {
      setState(() {
        _permissionDenied = true;
      });
      return;
    }

    if (!status.isGranted) {
      final result = await Permission.storage.request();
      if (result.isPermanentlyDenied) {
        setState(() {
          _permissionDenied = true;
        });
        return;
      }
      if (!result.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission is required to access local files.')),
          );
        }
        return;
      }
    }

    setState(() {
      _permissionDenied = false;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        
        _navigateToReader(filePath, fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  void _navigateToReader(String filePath, String fileName) async {
    final file = File(filePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File no longer available')),
        );
      }
      setState(() {
        _recentFiles.removeWhere((item) => item.filePath == filePath);
      });
      await _saveRecentFiles();
      return;
    }

    await _addOrUpdateRecentFile(filePath, fileName);

    if (!mounted) return;
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReaderScreen(
          filePath: filePath,
          fileName: fileName,
        ),
      ),
    );
    
    _loadRecentFiles();
  }

  void _showRemoveDialog(RecentFile file) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          title: Text(
            'Remove from Recents?',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to remove "${file.fileName}" from the recent files list?\n\nThis will not delete the file from your device.',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusCard),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _removeRecentFile(file);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  Widget _buildPermissionBanner() {
    if (!_permissionDenied) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusCard),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Storage Access Required',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'To open and read local Markdown files, this app requires storage access permissions. Please enable it in the app settings.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await openAppSettings();
              final status = await Permission.storage.status;
              if (status.isGranted) {
                setState(() {
                  _permissionDenied = false;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusButton),
              ),
            ),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFileItem(RecentFile file) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusCard),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          Icons.description_outlined,
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        ),
        title: Text(
          file.fileName,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              file.filePath,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Opened: ${_formatTimestamp(file.lastOpened)}',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToReader(file.filePath, file.fileName),
        onLongPress: () => _showRemoveDialog(file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text(
          'Markdown Editor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkAppBar : AppColors.lightAppBar,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              ThemeManager().toggleTheme(!isDark);
            },
          ),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1.0,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPermissionBanner(),
                Expanded(
                  child: _recentFiles.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'No files opened yet. Tap + to open a Markdown file.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: _recentFiles.length,
                          itemBuilder: (context, index) {
                            return _buildRecentFileItem(_recentFiles[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openFilePicker,
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusCard),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
