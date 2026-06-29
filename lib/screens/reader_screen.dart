import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:md_editor/core/constants.dart';
import 'package:md_editor/core/theme_manager.dart';

class ReaderScreen extends StatefulWidget {
  final String filePath;
  final String fileName;

  const ReaderScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late TextEditingController _editController;
  late ScrollController _previewScrollController;
  late ScrollController _editScrollController;
  late FocusNode _editFocusNode;
  
  bool _isLoading = true;
  String _originalText = '';
  bool _isPreviewMode = true;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
    _previewScrollController = ScrollController();
    _editScrollController = ScrollController();
    _editFocusNode = FocusNode();
    _loadFile();
  }

  @override
  void dispose() {
    _editController.dispose();
    _previewScrollController.dispose();
    _editScrollController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final file = File(widget.filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() {
          _originalText = content;
          _editController.text = content;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File not found.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading file: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTabToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final backgroundColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusPill),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isPreviewMode = true;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _isPreviewMode ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusPill),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isPreviewMode 
                        ? Colors.white 
                        : textColor.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isPreviewMode = false;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _editFocusNode.requestFocus();
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: !_isPreviewMode ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusPill),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: !_isPreviewMode 
                        ? Colors.white 
                        : textColor.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markdownData = _editController.text;

    if (markdownData.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'This file is empty.',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Markdown(
        controller: _previewScrollController,
        data: markdownData,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: TextStyle(
            fontSize: 15,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            height: 1.5,
          ),
          h1: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          h2: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          h3: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        builders: {
          'pre': CodeBlockBuilder(isDark: isDark),
          'code': InlineCodeBuilder(isDark: isDark),
        },
      ),
    );
  }

  Widget _buildEditTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _editController,
        focusNode: _editFocusNode,
        scrollController: _editScrollController,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        style: GoogleFonts.getFont(
          'JetBrains Mono',
          fontSize: 14,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          textStyle: const TextStyle(fontFamily: 'monospace'),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Start writing markdown here...',
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkAppBar : AppColors.lightAppBar,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Save copy functionality coming in Step 5!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusButton),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Save Edits as Copy',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.fileName,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkAppBar : AppColors.lightAppBar,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () {
              ThemeManager().toggleTheme(!isDark);
            },
          ),
        ],
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
                _buildTabToggle(),
                Expanded(
                  child: IndexedStack(
                    index: _isPreviewMode ? 0 : 1,
                    children: [
                      _buildPreviewTab(),
                      _buildEditTab(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _isLoading ? null : _buildBottomBar(),
    );
  }
}

class CodeBlockBuilder extends MarkdownElementBuilder {
  final bool isDark;

  CodeBlockBuilder({required this.isDark});

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    String language = '';
    
    if (element.children != null && element.children!.isNotEmpty) {
      final firstChild = element.children!.first;
      if (firstChild is md.Element && firstChild.tag == 'code') {
        final className = firstChild.attributes['class'];
        if (className != null && className.startsWith('language-')) {
          language = className.substring('language-'.length);
        }
      }
    }
    
    if (language.isEmpty) {
      final className = element.attributes['class'];
      if (className != null && className.startsWith('language-')) {
        language = className.substring('language-'.length);
      }
    }

    final codeText = element.textContent.trimRight();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCodeBg : AppColors.lightCodeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: HighlightView(
            codeText,
            language: language.isNotEmpty ? language : 'plaintext',
            theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
            padding: const EdgeInsets.all(12),
            textStyle: GoogleFonts.getFont(
              'JetBrains Mono',
              fontSize: 13,
              textStyle: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
      ),
    );
  }
}

class InlineCodeBuilder extends MarkdownElementBuilder {
  final bool isDark;

  InlineCodeBuilder({required this.isDark});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCodeBg : AppColors.lightCodeBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        element.textContent,
        style: GoogleFonts.getFont(
          'JetBrains Mono',
          fontSize: 13,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          textStyle: const TextStyle(fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
