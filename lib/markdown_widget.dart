import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

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
      print('Think block isComplete: $isComplete');
      print('Data ends with: ${widget.data.substring(widget.data.length - 50)}');

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
    String _latexWorkaround(String tex) {
      // Convert markdown bold/italic to LaTeX text variants inside math
      String processed = tex;

      // 1) Bold **...** -> \textbf{...}
      processed = processed.replaceAllMapped(
        RegExp(r"\*\*(.+?)\*\*", dotAll: true),
        (m) => "\\textbf{${m[1] ?? ''}}",
      );

      // 2) Italic *...* -> \textit{...} (only single-star emphasis)
      processed = processed.replaceAllMapped(
        RegExp(r"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)", dotAll: true),
        (m) => "\\textit{${m[1] ?? ''}}",
      );

      // 3) Remaining asterisks are likely multiplication -> \times
      processed = processed.replaceAllMapped(
        RegExp(r"(?<!\\)\*"),
        (m) => " \\times ",
      );

      // 4) Currency signs inside math must be escaped
      processed = processed.replaceAllMapped(
        RegExp(r"(?<!\\)\$"),
        (m) => r"\$",
      );

      // 5) Normalize stray markdown underscores inside math to text italic
      processed = processed.replaceAllMapped(
        RegExp(r"__(.+?)__", dotAll: true),
        (m) => "\\textbf{${m[1] ?? ''}}",
      );
      processed = processed.replaceAllMapped(
        RegExp(r"_(.+?)_", dotAll: true),
        (m) => "\\textit{${m[1] ?? ''}}",
      );

      return processed;
    }

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
        fontSize: widget.fontSize * 1.2,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      h2Style: TextStyle(
        color: widget.mdcolor,
        fontSize: widget.fontSize * 1.15,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      h3Style: TextStyle(
        color: widget.mdcolor,
        fontSize: widget.fontSize * 1,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      h4Style: TextStyle(
        color: widget.mdcolor,
        fontSize: widget.fontSize * 1,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      h5Style: TextStyle(
        color: widget.mdcolor,
        fontSize: widget.fontSize * 1,
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
        return GestureDetector(
          onTap: () async {
            if (url != null) {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: widget.iconFillColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.iconBorderColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.link,
                  size: widget.fontSize * 0.8,
                  color: widget.mdcolor.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  label.toPlainText(),
                  style: TextStyle(
                    color: widget.mdcolor,
                    fontFamily: 'Courier New',
                    fontSize: widget.fontSize * 0.9,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      // Enhanced LaTeX rendering is now built-in!
      // The package automatically provides professional dark UI with copy/share/expand
      useDollarSignsForLatex: true, // Support both \(...\) and $...$ syntax
      latexWorkaround: _latexWorkaround,
    );
  }
}

// ThinkBlock widget that mirrors Cursor's thinking interface exactly
class ThinkBlock extends StatefulWidget {
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
  State<ThinkBlock> createState() => _ThinkBlockState();
}

class _ThinkBlockState extends State<ThinkBlock> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        _rotationController.forward();
      } else {
        _animationController.reverse();
        _rotationController.reverse();
      }
    });
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final bool isThinking = !widget.isComplete;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: isThinking ? null : _toggle, // Disable tap while thinking
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF000000), // Black header background
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  if (isThinking)
                    // Show spinner and "Thinking..." text
                    ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFFD1D5DB)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Thinking...',
                      style: TextStyle(
                        color: const Color(0xFFD1D5DB),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ]
                  else
                    // Show icon, "Thoughts" text, and chevron when complete
                    ...[
                    Icon(
                      Icons.psychology_outlined,
                      color: const Color(0xFFD1D5DB),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Thoughts',
                      style: TextStyle(
                        color: const Color(0xFFD1D5DB),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * -math.pi,
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Only build the expandable content area if thinking is complete
          if (!isThinking)
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1.0,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0E0E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF242424),
                    width: 1,
                  ),
                ),
                child: widget.contentWidget ??
                    Text(
                      widget.content,
                      style: TextStyle(
                        color: const Color(0xFFD1D5DB),
                        fontSize: widget.fontSize * 0.9,
                        height: 1.5,
                      ),
                    ),
              ),
            ),
        ],
      ),
    );
  }
} 