import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A stateful copy button widget that handles copy state properly
class _CopyButton extends StatefulWidget {
  final String code;

  const _CopyButton({Key? key, required this.code}) : super(key: key);

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool isCopied = false;

  void handleCopy() async {
    final String codeToCopy = widget.code;
    try {
      if (codeToCopy.isNotEmpty) {
        HapticFeedback.lightImpact();
        await Clipboard.setData(ClipboardData(text: codeToCopy));
        setState(() {
          isCopied = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              isCopied = false;
            });
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: handleCopy,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          isCopied ? Icons.check : Icons.copy_outlined,
          color: isCopied ? const Color(0xFF4CAF50) : const Color(0xFFA0A0A0),
          size: 18,
        ),
      ),
    );
  }
}

/// A share button widget for code blocks
class _ShareButton extends StatelessWidget {
  final String code;
  final String language;

  const _ShareButton({Key? key, required this.code, required this.language})
      : super(key: key);

  // Language to file extension mapping
  static const Map<String, String> _languageExtensions = {
    'javascript': 'js',
    'js': 'js',
    'jsx': 'jsx',
    'typescript': 'ts',
    'ts': 'ts',
    'tsx': 'tsx',
    'python': 'py',
    'py': 'py',
    'java': 'java',
    'kotlin': 'kt',
    'kt': 'kt',
    'swift': 'swift',
    'dart': 'dart',
    'c': 'c',
    'cpp': 'cpp',
    'c++': 'cpp',
    'csharp': 'cs',
    'cs': 'cs',
    'c#': 'cs',
    'go': 'go',
    'rust': 'rs',
    'rs': 'rs',
    'ruby': 'rb',
    'rb': 'rb',
    'php': 'php',
    'html': 'html',
    'css': 'css',
    'json': 'json',
    'yaml': 'yaml',
    'yml': 'yml',
    'sql': 'sql',
    'bash': 'sh',
    'sh': 'sh',
    'shell': 'sh',
    'plaintext': 'txt',
    'text': 'txt',
  };

  void handleShare(BuildContext context) async {
    try {
      if (code.isEmpty) return;
      HapticFeedback.lightImpact();

      // Show immediate user feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Preparing file for sharing...'),
              ],
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Use simpler filename for better performance
      final ext = _languageExtensions[language.toLowerCase()] ?? 'txt';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${language.toLowerCase()}_$timestamp.$ext';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsString(code);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${language.toUpperCase()} code file',
        subject: '${language.toUpperCase()} Code',
      );
    } catch (e) {
      debugPrint('Share failed: ${e.toString()}');
      // Fallback to text sharing
      await Share.share(
        'Code (${language.toUpperCase()}):\n\n$code',
        subject: '${language.toUpperCase()} Code',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => handleShare(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Icon(
          Icons.share_outlined,
          color: Color(0xFFA0A0A0),
          size: 18,
        ),
      ),
    );
  }
}

class CodeField extends StatelessWidget {
  const CodeField({
    Key? key,
    required this.name,
    required this.codes,
    this.fontSize = 14.0,
  }) : super(key: key);

  final String name;
  final String codes;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with language badge and buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Language badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (name.isEmpty ? 'CODE' : name).toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Expand button
                  InkWell(
                    onTap: () => _showExpandedView(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.open_in_full,
                        color: Color(0xFFA0A0A0),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Share button
                  _ShareButton(code: codes, language: name),
                  const SizedBox(width: 12),
                  // Copy button
                  _CopyButton(code: codes),
                ],
              ),
            ),
            // Separator
            Container(
              height: 1,
              color: const Color(0xFF2A2A2A),
            ),
            // Code content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: HighlightView(
                  codes,
                  language: name.toLowerCase(),
                  theme: _getSyntaxTheme(),
                  textStyle: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: fontSize,
                    height: 1.6,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpandedView(BuildContext context) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: Column(
                children: [
                  // Modal Header
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Language badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (name.isEmpty ? 'CODE' : name).toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF8A8A8A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Close button
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(modalContext).pop();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFFA0A0A0),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Share button
                        _ShareButton(code: codes, language: name),
                        const SizedBox(width: 12),
                        // Copy button
                        _CopyButton(code: codes),
                      ],
                    ),
                  ),
                  Container(height: 1, color: const Color(0xFF2A2A2A)),
                  // Modal Content
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: SingleChildScrollView(
                        controller: controller,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: HighlightView(
                            codes,
                            language: name.toLowerCase(),
                            theme: _getSyntaxTheme(),
                            textStyle: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: fontSize,
                              height: 1.6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, TextStyle> _getSyntaxTheme() {
    return {
      'root': const TextStyle(
        backgroundColor: Color(0xFF1A1A1A),
        color: Colors.white,
      ),
      'keyword': const TextStyle(color: Color(0xFFC678DD)),
      'built_in': const TextStyle(color: Color(0xFF61AFEF)),
      'class': const TextStyle(color: Color(0xFF61AFEF)),
      'string': const TextStyle(color: Color(0xFF98C379)),
      'number': const TextStyle(color: Color(0xFFD19A66)),
      'comment': const TextStyle(
        color: Color(0xFF5C6370),
        fontStyle: FontStyle.italic,
      ),
      'title': const TextStyle(color: Color(0xFFE5C07B)),
      'meta': const TextStyle(color: Color(0xFFE5C07B)),
      'tag': const TextStyle(color: Color(0xFFE06C75)),
      'attr': const TextStyle(color: Color(0xFFD19A66)),
      'attr-name': const TextStyle(color: Color(0xFFD19A66)),
      'type': const TextStyle(color: Color(0xFF61AFEF)),
      'function': const TextStyle(color: Color(0xFF61AFEF)),
      'variable': const TextStyle(color: Color(0xFFE06C75)),
    };
  }
}
