import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that displays code with syntax highlighting and multiple action buttons.
///
/// The [CodeField] widget takes a [name] parameter which is displayed as a label
/// above the code block, and a [codes] parameter containing the actual code text
/// to display.
///
/// Features:
/// - Displays code in a Material container with rounded corners
/// - Shows the code language/name as a label
/// - Provides expand, share, and copy buttons
/// - Visual feedback when code is copied
/// - Enhanced syntax highlighting
/// - Themed colors that adapt to light/dark mode
class CodeField extends StatefulWidget {
  const CodeField({super.key, required this.name, required this.codes});
  final String name;
  final String codes;

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  bool _copied = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.onInverseSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Enhanced header with multiple action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800]?.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text(
                  widget.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                // Expand button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                // Share button
                IconButton(
                  onPressed: () {
                    // TODO: Implement share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Share functionality coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.share,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                // Copy button
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: widget.codes),
                    ).then((value) {
                      setState(() {
                        _copied = true;
                      });
                    });
                    await Future.delayed(const Duration(seconds: 2));
                    setState(() {
                      _copied = false;
                    });
                  },
                  icon: Icon(
                    (_copied) ? Icons.check : Icons.copy,
                    size: 18,
                    color: _copied ? Colors.green[400] : Colors.grey[400],
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          // Code content with syntax highlighting
          Container(
            constraints: _isExpanded 
              ? null 
              : const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildSyntaxHighlightedCode(widget.codes),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyntaxHighlightedCode(String code) {
    // Enhanced syntax highlighting
    final lines = code.split('\n');
    return SelectableText.rich(
      TextSpan(
        children: lines.asMap().entries.map((entry) {
          int index = entry.key;
          String line = entry.value;
          
          return TextSpan(
            children: [
              _highlightLine(line),
              if (index < lines.length - 1) const TextSpan(text: '\n'),
            ],
          );
        }).toList(),
      ),
      style: TextStyle(
        fontFamily: 'JetBrainsMono',
        package: "gpt_markdown",
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  TextSpan _highlightLine(String line) {
    // Simple syntax highlighting for Python
    final spans = <TextSpan>[];
    final keywords = ['import', 'def', 'class', 'if', 'else', 'elif', 'for', 'while', 'try', 'except', 'with', 'as', 'return'];
    final words = line.split(' ');
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      Color? color;
      FontWeight? fontWeight;
      FontStyle? fontStyle;
      
      // Keywords
      if (keywords.contains(word.replaceAll(RegExp(r'[^\w]'), ''))) {
        color = Colors.purple[300];
        fontWeight = FontWeight.bold;
      }
      // Strings
      else if (word.contains("'") || word.contains('"')) {
        color = Colors.green[300];
      }
      // Comments
      else if (word.startsWith('#')) {
        color = Colors.grey[500];
        fontStyle = FontStyle.italic;
      }
      // Function calls
      else if (word.contains('(')) {
        color = Colors.blue[300];
      }
      // Constants/variables in caps
      else if (word.toUpperCase() == word && word.length > 1 && RegExp(r'^[A-Z_]+$').hasMatch(word)) {
        color = Colors.cyan[300];
        fontWeight = FontWeight.w600;
      }
      // Default text color
      else {
        color = Colors.grey[200];
      }
      
      spans.add(TextSpan(
        text: word + (i < words.length - 1 ? ' ' : ''),
        style: TextStyle(
          color: color,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
        ),
      ));
    }
    
    return TextSpan(children: spans);
  }
}
