// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import 'package:ff_theme/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:gpt_markdown/gpt_markdown.dart';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// Represents one <think> segment that may or may not be complete
// endIndex includes the closing tag when present; null if streaming/open
class _ThinkSegment {
  final int startIndex;
  final int? endIndex;
  final bool? completeAttr; // From complete="true|false", if present
  final String content; // Inner content between <think> and </think> or end

  _ThinkSegment({
    required this.startIndex,
    required this.endIndex,
    required this.completeAttr,
    required this.content,
  });
}

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
    this.selectable = true,
    this.selectionColor,
  });

  final double? width;
  final double? height;
  final String data;
  final double fontSize;
  final Color mdcolor;
  final Color iconFillColor;
  final Color iconBorderColor;
  final Color linkContainerColor;
  final bool selectable;
  final Color? selectionColor;

  @override
  State<MarkdownWidget> createState() => _MarkdownWidgetState();
}

class _MarkdownWidgetState extends State<MarkdownWidget> {
  // Cache the main (non-think) markdown to avoid rebuilding on every token
  String _cachedMainSource = '';
  Widget? _cachedMainWidget;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(MarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Invalidate cache when source changes
    if (oldWidget.data != widget.data) {
      _cachedMainSource = '';
      _cachedMainWidget = null;
    }
  }

  List<_ThinkSegment> _parseThinkSegments(String data) {
    final segments = <_ThinkSegment>[];
    int searchFrom = 0;

    while (true) {
      final openIdx = data.indexOf('<think', searchFrom);
      if (openIdx == -1) break;

      final tagEnd = data.indexOf('>', openIdx);
      if (tagEnd == -1) {
        // Malformed open tag; stop parsing to avoid infinite loop
        break;
      }

      final openTag = data.substring(openIdx, tagEnd + 1);
      bool? completeAttr;
      final completeMatch =
          RegExp(r'complete="(true|false)"').firstMatch(openTag);
      if (completeMatch != null) {
        completeAttr = completeMatch.group(1) == 'true';
      }

      final closeIdx = data.indexOf('</think>', tagEnd + 1);
      final endIdx = closeIdx == -1 ? null : closeIdx + '</think>'.length;
      final contentEnd = closeIdx == -1 ? data.length : closeIdx;
      final innerContent = data.substring(tagEnd + 1, contentEnd);

      segments.add(_ThinkSegment(
        startIndex: openIdx,
        endIndex: endIdx,
        completeAttr: completeAttr,
        content: innerContent,
      ));

      // Continue after this segment; if streaming (no close), we're at end
      searchFrom = endIdx ?? data.length;
    }

    return segments;
  }

  String _stripThinkSegments(String data, List<_ThinkSegment> segments) {
    if (segments.isEmpty) return data.trim();
    final buffer = StringBuffer();
    int cursor = 0;

    for (final seg in segments) {
      final end = seg.endIndex ?? data.length;
      if (cursor < seg.startIndex) {
        buffer.write(data.substring(cursor, seg.startIndex));
      }
      cursor = end;
    }
    if (cursor < data.length) {
      buffer.write(data.substring(cursor));
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging
    print('=== MARKDOWN PROCESSING ===');
    print('Input length: ${widget.data.length}');
    print('Contains <think>: ${widget.data.contains('<think>')}');

    // Extract all think segments (supports streaming/incomplete) and main content
    final thinkSegments = _parseThinkSegments(widget.data);
    final mainContent = _stripThinkSegments(widget.data, thinkSegments);

    final totalThinkLength =
        thinkSegments.fold<int>(0, (sum, seg) => sum + seg.content.length);
    print('Think content total length: $totalThinkLength');
    print('Main content length: ${mainContent.length}');

    final widgets = <Widget>[];

    // Add a ThinkBlock for each parsed segment, streaming-safe
    for (final seg in thinkSegments) {
      final isComplete = seg.completeAttr ?? (seg.endIndex != null);
      print('Adding think block (complete=$isComplete)');
      final safeTailStart = math.max(0, widget.data.length - 50);
      print('Data ends with: ${widget.data.substring(safeTailStart)}');

      widgets.add(ThinkBlock(
        content: seg.content.trim(),
        isComplete: isComplete,
        fontSize: widget.fontSize,
        onToggle: () {},
        contentWidget: seg.content.trim().isNotEmpty
            ? _buildEnhancedMarkdown(seg.content)
            : null,
      ));
    }

    // Add main content
    if (mainContent.trim().isNotEmpty) {
      print('Adding main content');
      print(
          'Main content preview: ${mainContent.substring(0, math.min(50, mainContent.length))}...');
      if (_cachedMainSource != mainContent) {
        _cachedMainSource = mainContent;
        _cachedMainWidget = _buildEnhancedMarkdown(mainContent);
      }
      if (_cachedMainWidget != null) {
        widgets.add(_cachedMainWidget!);
      }
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

  /// Automatically determine if math mode should be enabled based on content analysis
  bool _shouldAutoEnableMathMode(String content) {
    // FOR NOW: Be extremely conservative - only enable math mode for very obvious cases
    // Check if content has clear LaTeX commands that are unambiguous
    
    // Only enable if we find LaTeX commands like \frac, \sum, \alpha, etc.
    if (content.contains(RegExp(r'\\[a-zA-Z]+'))) {
      return true;
    }
    
    // Only enable if we find Greek letters
    if (content.contains(RegExp(r'[αβγδεζηθικλμνξοπρστυφχψω]'))) {
      return true;
    }
    
    // Only enable if we find clear math notation like superscripts/subscripts
    if (content.contains(RegExp(r'[\^_{}]'))) {
      return true;
    }
    
    // Only enable if we find mathematical symbols
    if (content.contains(RegExp(r'[≤≥≠∑∏∫]'))) {
      return true;
    }
    
    // For everything else (including all financial content), stay in currency mode
    return false;
  }

  /// Check if content looks like currency (not math)
  bool _looksLikeCurrency(String content) {
    // Pure numbers with optional formatting
    if (RegExp(r'^\d+(?:[,.]?\d+)*(?:\.\d{2})?[KMB]?$').hasMatch(content)) {
      return true;
    }
    // Number ranges like "50-100" or "50 - 100"
    if (RegExp(r'^\d+(?:[,.]?\d+)*(?:\s*-\s*\d+(?:[,.]?\d+)*)?$').hasMatch(content)) {
      return true;
    }
    // Numbers with common currency context words
    if (RegExp(r'^\d+(?:[,.]?\d+)*(?:\.\d{2})?\s*(?:per|each|total|worth|spent|cost|price|value)', caseSensitive: false).hasMatch(content)) {
      return true;
    }
    // Decimal numbers (likely currency)
    if (RegExp(r'^\d+\.\d{2}$').hasMatch(content)) {
      return true;
    }
    return false;
  }

  /// Check if content has VERY strong/obvious LaTeX mathematical indicators
  bool _hasStrongLatexIndicators(String content) {
    // LaTeX commands like \alpha, \frac, \sum, etc. - VERY obvious math
    if (content.contains(RegExp(r'\\[a-zA-Z]+'))) {
      return true;
    }
    // Greek letters - VERY obvious math
    if (content.contains(RegExp(r'[αβγδεζηθικλμνξοπρστυφχψω]'))) {
      return true;
    }
    // Math notation like superscripts, subscripts, fractions - VERY obvious
    if (content.contains(RegExp(r'[\^_{}]'))) {
      return true;
    }
    // Mathematical symbols - VERY obvious math
    if (content.contains(RegExp(r'[≤≥≠∑∏∫]'))) {
      return true;
    }
    return false;
  }

  /// Check if content has LaTeX mathematical indicators (legacy - keeping for compatibility)
  bool _hasLatexIndicators(String content) {
    return _hasStrongLatexIndicators(content);
  }

  /// Check if content has mathematical variables (simple heuristic)
  bool _hasMathVariables(String content) {
    // Has variables and is not just currency abbreviation
    return content.contains(RegExp(r'[a-zA-Z]')) && // Has letters
           content.length > 1 && // Not just single letter
           !RegExp(r'^\d+[KMB]?$').hasMatch(content) && // Not currency abbreviation
           !RegExp(r'^[A-Z]+$').hasMatch(content); // Not just acronym
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
            if (url == null) return;

            final href = url.toString();
            final uri = Uri.tryParse(href);

            if (uri == null || !uri.hasScheme) {
              // Nothing to do for invalid/relative links
              return;
            }

            final isHttp = uri.scheme == 'http' || uri.scheme == 'https';

            // iOS + http(s): keep user in-app via SFSafariViewController
            if (!kIsWeb && Platform.isIOS && isHttp) {
              await openInSafariVC(href);
              return;
            }

            // Fallback (Android, web, desktop, or non-http schemes): default handler
            if (await canLaunchUrl(uri)) {
              await launchUrl(
                uri,
                // externalApplication avoids partial in-app behavior on some platforms
                mode: LaunchMode.externalApplication,
              );
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

      // DEBUG: Force disable ALL dollar sign processing to isolate the issue
      // This will prevent any $...$ patterns from being processed as LaTeX
      useDollarSignsForLatex: false,
      
      // Selection parameters
      selectable: widget.selectable,
      selectionColor: widget.selectionColor,
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
  late AnimationController _shimmerController;
  bool _prevIsThinking = false;

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
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1470),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController.dispose();
    _shimmerController.dispose();
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

    // Manage shimmer lifecycle based on thinking state
    if (_prevIsThinking != isThinking) {
      if (isThinking) {
        _shimmerController.repeat();
        // Ensure content is visible while thinking
        _animationController.value = 1.0;
        _rotationController.value = 0.0;
        _isExpanded = true;
      } else {
        _shimmerController.stop();
        // Collapse after completion until user expands
        _animationController.value = 0.0;
        _rotationController.value = 0.0;
        _isExpanded = false;
      }
      _prevIsThinking = isThinking;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: isThinking ? null : _toggle, // Disable tap while thinking
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF000000), // Black header background
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  // Flush-left label inside the header
                  const SizedBox(width: 0),
                  _ShimmerText(
                    enabled: isThinking,
                    controller: _shimmerController,
                    text: isThinking ? 'Thinking...' : 'Thoughts',
                    style: const TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * -math.pi,
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          // Content area: visible while thinking; collapsible after completion
          if (isThinking)
            LayoutBuilder(
              builder: (context, constraints) {
                final maxPanelHeight =
                    math.min(MediaQuery.of(context).size.height * 0.45, 360.0);
                return Container(
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
                  constraints: BoxConstraints(
                    maxHeight: maxPanelHeight,
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
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
                );
              },
            )
          else
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

class _ShimmerText extends StatelessWidget {
  final bool enabled;
  final AnimationController controller;
  final String text;
  final TextStyle style;

  const _ShimmerText({
    required this.enabled,
    required this.controller,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return Text(text, style: style);

    const shimmerColor = Color(0x80FFFFFF); // #80FFFFFF
    const angleDegrees = 30.0;
    const angleRadians = angleDegrees * (math.pi / 180.0);

    return AnimatedBuilder(
      animation: CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            final width = bounds.width;
            final band = width * 0.3;
            final t = controller.value; // 0..1
            final travel = width + band;
            final pos = t * travel - band; // sweep across horizontally

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                shimmerColor,
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(angleRadians),
            ).createShader(Rect.fromLTWH(pos, 0, band, bounds.height));
          },
          blendMode: BlendMode.srcATop,
          child: Text(text, style: style),
        );
      },
    );
  }
}