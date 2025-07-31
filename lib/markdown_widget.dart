import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'dart:math' as math;

class MarkdownWidget extends StatefulWidget {
  const MarkdownWidget({
    super.key,
    this.width,
    this.height,
    required this.data,
    required this.fontSize,
    required this.mdcolor,
    required this.iconFillColor,
    required this.iconBorderColor,
    required this.linkContainerColor,
  });

  final double? width;
  final double? height;
  final String data;
  final double fontSize;
  final Color mdcolor;
  final Color iconFillColor;
  final Color iconBorderColor;
  final Color linkContainerColor;

  @override
  State<MarkdownWidget> createState() => _MarkdownWidgetState();
}

class _MarkdownWidgetState extends State<MarkdownWidget> {
  List<bool> _thinkBlockStates = [];

  @override
  void initState() {
    super.initState();
    _initializeThinkBlockStates();
  }

  @override
  void didUpdateWidget(MarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _initializeThinkBlockStates();
    }
  }

  void _initializeThinkBlockStates() {
    final thinkBlockPattern = RegExp(
        r'<think(?:\s+complete="(true|false)")?\s*>(.*?)</think>',
        dotAll: true);
    final matches = thinkBlockPattern.allMatches(widget.data).toList();
    _thinkBlockStates = List.generate(matches.length, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging
    print('=== MARKDOWN PROCESSING ===');
    print('Input length: ${widget.data.length}');
    print('Contains <think>: ${widget.data.contains('<think>')}');

    // Extract think content and main content
    final thinkContent = _extractThinkContent(widget.data);
    final mainContent = _removeThinkTags(widget.data);

    print('Think content length: ${thinkContent.length}');
    print('Main content length: ${mainContent.length}');

    final widgets = <Widget>[];

    // Add think block if present
    if (widget.data.contains('<think>')) {
      print('Adding think block');
      final isComplete = widget.data.contains('</think>');

      while (_thinkBlockStates.isEmpty) {
        _thinkBlockStates.add(false);
      }

      widgets.add(ThinkBlock(
        content: thinkContent,
        isComplete: isComplete,
        fontSize: widget.fontSize,
        onToggle: () {
          if (mounted) {
            setState(() {
              _thinkBlockStates[0] = !_thinkBlockStates[0];
            });
          }
        },
        contentWidget: thinkContent.isNotEmpty
            ? _buildEnhancedMarkdown(thinkContent)
            : null,
      ));
    }

    // Add main content
    if (mainContent.trim().isNotEmpty) {
      print('Adding main content');
      print(
          'Main content preview: ${mainContent.substring(0, math.min(50, mainContent.length))}...');
      widgets.add(_buildEnhancedMarkdown(mainContent));
    }

    print('Total widgets created: ${widgets.length}');
    print('=== END PROCESSING ===');

    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: widgets,
      ),
    );
  }

  String _extractThinkContent(String content) {
    final match = RegExp(
            r'<think(?:\s+complete="(?:true|false)")?\s*>(.*?)</think>',
            dotAll: true)
        .firstMatch(content);
    return match?.group(1)?.trim() ?? '';
  }

  String _removeThinkTags(String content) {
    return content
        .replaceAll(
            RegExp(r'<think(?:\s+complete="(?:true|false)")?\s*>.*?</think>',
                dotAll: true),
            '')
        .trim();
  }

  Widget _buildEnhancedMarkdown(String content) {
    return GptMarkdown(
      content,
      style: TextStyle(
        color: widget.mdcolor,
        fontSize: widget.fontSize,
        height: 1.5,
      ),
      // Enhanced heading styles with proper hierarchy
      h1Style: TextStyle(
        color: widget.mdcolor,
        fontSize: widget.fontSize * 1.8,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      h2Style: TextStyle(
        color: widget.mdcolor,
        fontSize: widget.fontSize * 1.6,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      h3Style: TextStyle(
        color: widget.mdcolor,
        fontSize: widget.fontSize * 1.4,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      h4Style: TextStyle(
        color: widget.mdcolor,
        fontSize: widget.fontSize * 1.2,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      h5Style: TextStyle(
        color: widget.mdcolor,
        fontSize: widget.fontSize * 1.1,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      h6Style: TextStyle(
        color: widget.mdcolor,
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      // Custom inline code styling
      inlineCodeBuilder: (context, code, style) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: widget.iconFillColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: widget.iconBorderColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            code,
            style: TextStyle(
              color: widget.mdcolor,
              fontFamily: 'Courier New',
              fontSize: widget.fontSize * 0.9,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        );
      },
      // Custom code block styling removed - now uses enhanced CodeField
      // Custom link styling
      linkBuilder: (context, label, url, style) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: widget.linkContainerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text.rich(
            label,
            style: style.copyWith(
              color: widget.linkContainerColor,
              decoration: TextDecoration.underline,
              decorationColor: widget.linkContainerColor.withOpacity(0.5),
            ),
          ),
        );
      },
      // Enhanced LaTeX rendering is now built-in!
      // The package automatically provides professional dark UI with copy/share/expand
      useDollarSignsForLatex: true, // Support both \(...\) and $...$ syntax
    );
  }
}

// ThinkBlock widget (you'll need to implement this based on your existing logic)
class ThinkBlock extends StatelessWidget {
  final String content;
  final bool isComplete;
  final double fontSize;
  final VoidCallback onToggle;
  final Widget? contentWidget;

  const ThinkBlock({
    super.key,
    required this.content,
    required this.isComplete,
    required this.fontSize,
    required this.onToggle,
    this.contentWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Implement your think block UI here
    // This is a placeholder - customize based on your existing design
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: Colors.blue,
                size: fontSize,
              ),
              const SizedBox(width: 8),
              Text(
                'Think Block',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onToggle,
                icon: const Icon(Icons.expand_more),
                color: Colors.blue,
              ),
            ],
          ),
          if (contentWidget != null) ...[
            const SizedBox(height: 8),
            contentWidget!,
          ],
        ],
      ),
    );
  }
} 