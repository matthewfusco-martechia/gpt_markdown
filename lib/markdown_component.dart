part of 'gpt_markdown.dart';

/// Markdown components
abstract class MarkdownComponent {
  static List<MarkdownComponent> get globalComponents => [
    CodeBlockMd(),
    LatexMathMultiLine(),
    NewLines(),
    BlockQuote(),
    TableMd(),
    HTag(),
    UnOrderedList(),
    OrderedList(),
    RadioButtonMd(),
    CheckBoxMd(),
    HrLine(),
    IndentMd(),
  ];

  static final List<MarkdownComponent> inlineComponents = [
    ATagMd(),
    ImageMd(),
    InlineCodeMd(),
    TableMd(),
    StrikeMd(),
    BoldMd(),
    ItalicMd(),
    UnderLineMd(),
    LatexMath(),
    LatexMathMultiLine(),
    HighlightedText(),
    SourceTag(),
  ];

  /// Generate widget for markdown widget
  static List<InlineSpan> generate(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
    bool includeGlobalComponents,
  ) {
    var components =
        includeGlobalComponents
            ? config.components ?? MarkdownComponent.globalComponents
            : config.inlineComponents ?? MarkdownComponent.inlineComponents;
    List<InlineSpan> spans = [];
    Iterable<String> regexes = components.map<String>((e) => e.exp.pattern);
    final combinedRegex = RegExp(
      regexes.join("|"),
      multiLine: true,
      dotAll: true,
    );
    text.splitMapJoin(
      combinedRegex,
      onMatch: (p0) {
        String element = p0[0] ?? "";
        for (var each in components) {
          var p = each.exp.pattern;
          var exp = RegExp(
            '^$p\$',
            multiLine: each.exp.isMultiLine,
            dotAll: each.exp.isDotAll,
          );
          if (exp.hasMatch(element)) {
            spans.add(each.span(context, element, config));
            return "";
          }
        }
        return "";
      },
      onNonMatch: (p0) {
        if (p0.isEmpty) {
          return "";
        }
        if (includeGlobalComponents) {
          var newSpans = generate(context, p0, config.copyWith(), false);
          spans.addAll(newSpans);
          return "";
        }
        spans.add(TextSpan(text: p0, style: config.style));
        return "";
      },
    );

    return spans;
  }

  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  );

  RegExp get exp;
  bool get inline;
}

/// Inline component
abstract class InlineMd extends MarkdownComponent {
  @override
  bool get inline => true;

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  );
}

/// Block component
abstract class BlockMd extends MarkdownComponent {
  @override
  bool get inline => false;

  @override
  RegExp get exp =>
      RegExp(r'^\ *?' + expString + r"$", dotAll: true, multiLine: true);

  String get expString;

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var matches = RegExp(r'^(?<spaces>\ \ +).*').firstMatch(text);
    var spaces = matches?.namedGroup('spaces');
    var length = spaces?.length ?? 0;
    var child = build(context, text, config);
    length = min(length, 4);
    if (length > 0) {
      child = UnorderedListView(
        spacing: length * 1.0,
        textDirection: config.textDirection,
        child: child,
      );
    }
    child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [Flexible(child: child)],
    );
    return WidgetSpan(
      child: child,
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
    );
  }

  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  );
}

/// Indent component
class IndentMd extends BlockMd {
  @override
  String get expString => (r"^(\ \ +)([^\n]+)$");
  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = this.exp.firstMatch(text);
    var conf = config.copyWith();
    return Directionality(
      textDirection: config.textDirection,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: config.getRich(
              TextSpan(
                children: MarkdownComponent.generate(
                  context,
                  match?[2]?.trim() ?? "",
                  conf,
                  false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Heading component
class HTag extends BlockMd {
  @override
  String get expString => (r"(?<hash>#{1,6})\ (?<data>[^\n]+?)$");
  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var theme = GptMarkdownTheme.of(context);
    var match = this.exp.firstMatch(text.trim());
    var headingLevel = match![1]!.length - 1; // 0-based index for array access
    
    // Use custom heading styles if provided, otherwise fall back to theme
    var customStyles = [
      config.h1Style,
      config.h2Style,
      config.h3Style,
      config.h4Style,
      config.h5Style,
      config.h6Style,
    ];
    
    var themeStyles = [
      theme.h1,
      theme.h2,
      theme.h3,
      theme.h4,
      theme.h5,
      theme.h6,
    ];
    
    var headingStyle = customStyles[headingLevel] ?? themeStyles[headingLevel];
    
    var conf = config.copyWith(
      style: headingStyle?.copyWith(color: config.style?.color),
    );
    return config.getRich(
      TextSpan(
        children: [
          ...(MarkdownComponent.generate(
            context,
            "${match.namedGroup('data')}",
            conf,
            false,
          )),
          if (match.namedGroup('hash')!.length == 1) ...[
            const TextSpan(
              text: "\n ",
              style: TextStyle(fontSize: 0, height: 0),
            ),
            WidgetSpan(
              child: CustomDivider(
                height: theme.hrLineThickness,
                color:
                    config.style?.color ??
                    Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class NewLines extends InlineMd {
  @override
  RegExp get exp => RegExp(r"\n\n+");
  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    return TextSpan(
      text: "\n\n",
      style: TextStyle(
        fontSize: config.style?.fontSize ?? 14,
        height: 1.15,
        color: config.style?.color,
      ),
    );
  }
}

/// Horizontal line component
class HrLine extends BlockMd {
  @override
  String get expString => (r"⸻|((--)[-]+)$");
  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var thickness = GptMarkdownTheme.of(context).hrLineThickness;
    var color = GptMarkdownTheme.of(context).hrLineColor;
    return CustomDivider(
      height: thickness,
      color: config.style?.color ?? color,
    );
  }
}

/// Checkbox component
class CheckBoxMd extends BlockMd {
  @override
  String get expString => (r"\[((?:\x|\ ))\]\ (\S[^\n]*?)$");

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = this.exp.firstMatch(text.trim());
    return CustomCb(
      value: ("${match?[1]}" == "x"),
      textDirection: config.textDirection,
      child: MdWidget(context, "${match?[2]}", false, config: config),
    );
  }
}

/// Radio Button component
class RadioButtonMd extends BlockMd {
  @override
  String get expString => (r"\(((?:\x|\ ))\)\ (\S[^\n]*)$");

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = this.exp.firstMatch(text.trim());
    return CustomRb(
      value: ("${match?[1]}" == "x"),
      textDirection: config.textDirection,
      child: MdWidget(context, "${match?[2]}", false, config: config),
    );
  }
}

/// Block quote component
class BlockQuote extends InlineMd {
  @override
  bool get inline => false;
  @override
  RegExp get exp =>
  // RegExp(r"(?<=\n\n)(\ +)(.+?)(?=\n\n)", dotAll: true, multiLine: true);
  RegExp(
    r"(?:(?:^)\ *>[^\n]+)(?:(?:\n)\ *>[^\n]+)*",
    dotAll: true,
    multiLine: true,
  );

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text);
    var dataBuilder = StringBuffer();
    var m = match?[0] ?? '';
    for (var each in m.split('\n')) {
      if (each.startsWith(RegExp(r'\ *>'))) {
        var subString = each.trimLeft().substring(1);
        if (subString.startsWith(' ')) {
          subString = subString.substring(1);
        }
        dataBuilder.writeln(subString);
      } else {
        dataBuilder.writeln(each);
      }
    }
    var data = dataBuilder.toString().trim();
    var child = TextSpan(
      children: MarkdownComponent.generate(context, data, config, true),
    );
    return TextSpan(
      children: [
        WidgetSpan(
          child: Directionality(
            textDirection: config.textDirection,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: BlockQuoteWidget(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                direction: config.textDirection,
                width: 3,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8.0),
                  child: config.getRich(child),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Unordered list component
class UnOrderedList extends BlockMd {
  @override
  String get expString => (r"(?:\-|\*)\ ([^\n]+)$");

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = this.exp.firstMatch(text);

    var child = MdWidget(context, "${match?[1]?.trim()}", true, config: config);

    return config.unOrderedListBuilder?.call(
          context,
          child,
          config.copyWith(),
        ) ??
        UnorderedListView(
          bulletColor:
              (config.style?.color ?? DefaultTextStyle.of(context).style.color),
          padding: 7,
          spacing: 10,
          bulletSize:
              0.3 *
              (config.style?.fontSize ??
                  DefaultTextStyle.of(context).style.fontSize ??
                  kDefaultFontSize),
          textDirection: config.textDirection,
          child: child,
        );
  }
}

/// Ordered list component
class OrderedList extends BlockMd {
  @override
  String get expString => (r"([0-9]+)\.\ ([^\n]+)$");

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = this.exp.firstMatch(text.trim());

    var no = "${match?[1]}";

    var child = MdWidget(context, "${match?[2]?.trim()}", true, config: config);
    return config.orderedListBuilder?.call(
          context,
          no,
          child,
          config.copyWith(),
        ) ??
        OrderedListView(
          no: "$no.",
          textDirection: config.textDirection,
          style: (config.style ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w100,
          ),
          child: child,
        );
  }
}

class InlineCodeMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r"`(?!`)(.+?)(?<!`)`(?!`)");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var codeText = match?[1] ?? "";

    if (config.inlineCodeBuilder != null) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: config.inlineCodeBuilder!(
          context,
          codeText,
          config.style ?? const TextStyle(),
        ),
      );
    }

    // Default inline code styling
    var style = config.style?.copyWith(
      fontFamily: 'monospace',
      backgroundColor: GptMarkdownTheme.of(context).highlightColor.withOpacity(0.1),
      fontSize: (config.style?.fontSize ?? 14) * 0.9,
    ) ?? TextStyle(
      fontFamily: 'monospace',
      backgroundColor: GptMarkdownTheme.of(context).highlightColor.withOpacity(0.1),
      fontSize: 12.6,
    );

    return TextSpan(text: codeText, style: style);
  }
}

class HighlightedText extends InlineMd {
  @override
  RegExp get exp => RegExp(r"==(.+?)==");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var highlightedText = match?[1] ?? "";

    if (config.highlightBuilder != null) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: config.highlightBuilder!(
          context,
          highlightedText,
          config.style ?? const TextStyle(),
        ),
      );
    }

    var style =
        config.style?.copyWith(
          fontWeight: FontWeight.bold,
          background:
              Paint()
                ..color = GptMarkdownTheme.of(context).highlightColor
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round,
        ) ??
        TextStyle(
          fontWeight: FontWeight.bold,
          background:
              Paint()
                ..color = GptMarkdownTheme.of(context).highlightColor
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round,
        );

    return TextSpan(text: highlightedText, style: style);
  }
}

/// Bold text component
class BoldMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r"(?<!\*)\*\*(?<!\s)(.+?)(?<!\s)\*\*(?!\*)");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var conf = config.copyWith(
      style:
          config.style?.copyWith(fontWeight: FontWeight.bold) ??
          const TextStyle(fontWeight: FontWeight.bold),
    );
    return TextSpan(
      children: MarkdownComponent.generate(
        context,
        "${match?[1]}",
        conf,
        false,
      ),
      style: conf.style,
    );
  }
}

class StrikeMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r"(?<!\*)\~\~(?<!\s)(.+?)(?<!\s)\~\~(?!\*)");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var conf = config.copyWith(
      style:
          config.style?.copyWith(
            decoration: TextDecoration.lineThrough,
            decorationColor: config.style?.color,
          ) ??
          const TextStyle(decoration: TextDecoration.lineThrough),
    );
    return TextSpan(
      children: MarkdownComponent.generate(
        context,
        "${match?[1]}",
        conf,
        false,
      ),
      style: conf.style,
    );
  }
}

/// Italic text component
class ItalicMd extends InlineMd {
  @override
  RegExp get exp =>
      RegExp(r"(?:(?<!\*)\*(?<!\s)(.+?)(?<!\s)\*(?!\*))", dotAll: true);

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var data = match?[1] ?? match?[2];
    var conf = config.copyWith(
      style: (config.style ?? const TextStyle()).copyWith(
        fontStyle: FontStyle.italic,
      ),
    );
    return TextSpan(
      children: MarkdownComponent.generate(context, "$data", conf, false),
      style: conf.style,
    );
  }
}

/// A stateful copy button widget for LaTeX content
class _LatexCopyButton extends StatefulWidget {
  final String latexContent;

  const _LatexCopyButton({super.key, required this.latexContent});

  @override
  State<_LatexCopyButton> createState() => _LatexCopyButtonState();
}

class _LatexCopyButtonState extends State<_LatexCopyButton> {
  bool isCopied = false;

  void handleCopy() async {
    try {
      if (widget.latexContent.isNotEmpty) {
        HapticFeedback.lightImpact();
        await Clipboard.setData(ClipboardData(text: widget.latexContent));
        if (mounted) {
          setState(() {
            isCopied = true;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                isCopied = false;
              });
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
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

/// A share button widget for LaTeX content
class _LatexShareButton extends StatelessWidget {
  final String latexContent;
  final String displayType;

  const _LatexShareButton({
    super.key,
    required this.latexContent,
    required this.displayType,
  });

  void handleShare(BuildContext context) async {
    try {
      if (latexContent.isEmpty) return;
      HapticFeedback.lightImpact();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'latex_${displayType.toLowerCase().replaceAll(' ', '_')}_$timestamp.tex';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsString(latexContent);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$displayType LaTeX file',
        subject: '$displayType LaTeX',
      );
    } catch (e) {
      debugPrint('LaTeX share failed: ${e.toString()}');
      // Fallback to text sharing
      try {
        await Share.share(
          latexContent,
          subject: '$displayType LaTeX',
        );
      } catch (fallbackError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to share: ${fallbackError.toString()}'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
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

/// Helper functions for enhanced LaTeX rendering
class _LatexRenderingHelpers {
  // Get appropriate display type label
  static String getLatexDisplayType(String content) {
    if (content.contains(RegExp(r'\\begin\{equation\}'))) return 'LaTeX Equation';
    if (content.contains(RegExp(r'\\begin\{align\}'))) return 'LaTeX Alignment';
    if (content.contains(RegExp(r'\\documentclass'))) return 'LaTeX Document';
    if (content.contains(RegExp(r'\\\[')) && content.contains(RegExp(r'\\\]'))) return 'LaTeX Display Math';
    if (content.contains(RegExp(r'\$\$'))) return 'LaTeX Math';
    return 'LaTeX Code';
  }

  // Show expanded view for LaTeX content
  static void showLatexExpandedView(BuildContext context, String latexData, String displayType, TextStyle style, {String Function(String)? workaround}) {
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
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                // Modal Header
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
                      // LaTeX badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          displayType.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF8A8A8A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Share button
                      _LatexShareButton(latexContent: latexData, displayType: displayType),
                      const SizedBox(width: 12),
                      // Copy button
                      _LatexCopyButton(latexContent: latexData),
                      const SizedBox(width: 12),
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
                    ],
                  ),
                ),
                // Expanded content
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F0F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: (() {
                          try {
                            final processedLatex = workaround != null ? workaround(latexData) : latexData;
                            return Math.tex(
                              processedLatex,
                              textStyle: TextStyle(
                                color: style.color ?? Colors.white,
                                fontSize: (style.fontSize ?? 16.0) * 1.3, // Expanded size
                              ),
                              mathStyle: MathStyle.display,
                              settings: const TexParserSettings(strict: Strict.ignore),
                            );
                          } catch (e) {
                            debugPrint('LaTeX rendering failed in expanded view: $e');
                            return Text(
                              'LaTeX Error: $e',
                              style: TextStyle(color: Colors.red[300], fontSize: 14),
                            );
                          }
                        })(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Build LaTeX content with proper rendering
  static Widget buildLatexContent(String content, TextStyle style, {bool isExpanded = false, String Function(String)? workaround}) {
    debugPrint('=== LaTeX Rendering Debug ===');
    debugPrint('Original content: "$content"');
    
    try {
      // Apply workaround function if provided, otherwise use content as-is
      String processedContent = workaround != null ? workaround(content) : content;
      debugPrint('After workaround: "$processedContent"');
      
      // Now remove LaTeX delimiters from the processed content
      String cleanContent = removeLatexDelimiters(processedContent);
      debugPrint('After delimiter removal: "$cleanContent"');
      
      // Skip if content is empty after cleaning
      if (cleanContent.trim().isEmpty) {
        debugPrint('Empty content after cleaning');
        return const Text('Empty LaTeX content', style: TextStyle(color: Colors.grey));
      }
      
      // Try to render the LaTeX with cleaned content
      debugPrint('Attempting to render LaTeX with Math.tex');
      final result = Math.tex(
        cleanContent,
        textStyle: TextStyle(
          color: style.color ?? Colors.white,
          fontSize: isExpanded ? (style.fontSize ?? 16.0) * 1.3 : (style.fontSize ?? 16.0),
        ),
        mathStyle: MathStyle.display,
        settings: const TexParserSettings(strict: Strict.ignore),
        options: MathOptions(
          fontSize: isExpanded ? (style.fontSize ?? 16.0) * 1.3 : (style.fontSize ?? 16.0),
          color: style.color ?? Colors.white,
        ),
      );
      debugPrint('LaTeX rendering successful');
      return result;
    } catch (e) {
      // Fallback to displaying raw LaTeX if rendering fails
      debugPrint('LaTeX rendering failed with error: $e');
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LaTeX Rendering Error',
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Error: $e',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              content,
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: style.fontSize ?? 14.0,
                color: const Color(0xFFE1E1E1),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }
  }

  // Comprehensive LaTeX delimiter removal
  static String removeLatexDelimiters(String content) {
    String cleanContent = content.trim();
    
    // Handle basic math delimiters with priority order - be more conservative
    // Handle \[ ... \] delimiters (display math)
    if (cleanContent.startsWith('\\[') && cleanContent.endsWith('\\]')) {
      cleanContent = cleanContent.substring(2, cleanContent.length - 2).trim();
    }
    // Handle \( ... \) delimiters (inline math)
    else if (cleanContent.startsWith('\\(') && cleanContent.endsWith('\\)')) {
      cleanContent = cleanContent.substring(2, cleanContent.length - 2).trim();
    }
    // Handle $$ ... $$ delimiters (display math)
    else if (cleanContent.startsWith('\$\$') && cleanContent.endsWith('\$\$')) {
      cleanContent = cleanContent.substring(2, cleanContent.length - 2).trim();
    }
    // Handle single $ ... $ delimiters (inline math)
    else if (cleanContent.startsWith('\$') && cleanContent.endsWith('\$') && cleanContent.length > 2) {
      cleanContent = cleanContent.substring(1, cleanContent.length - 1).trim();
    }
    
    // Only remove specific LaTeX environments that cause issues, preserve most content
    final environmentsToRemove = [
      'equation*',
      'align*', 
      'gather*',
      'multline*',
    ];
    
    // Remove only problematic environments
    for (final env in environmentsToRemove) {
      final beginPattern = RegExp('\\\\begin\\{$env\\}\\s*', multiLine: true);
      final endPattern = RegExp('\\s*\\\\end\\{$env\\}', multiLine: true);
      cleanContent = cleanContent.replaceAll(beginPattern, '');
      cleanContent = cleanContent.replaceAll(endPattern, '');
    }
    
    // Only clean up excessive whitespace, preserve LaTeX syntax
    cleanContent = cleanContent
        .replaceAll(RegExp(r'\n\s*\n'), ' ')  // Multiple newlines to single space
        .replaceAll(RegExp(r'\s+'), ' ')      // Multiple spaces to single space
        .trim();
    
    return cleanContent;
  }
}

class LatexMathMultiLine extends BlockMd {
  @override
  String get expString => (r"\ *\\\[((?:.)*?)\\\]|(\ *\\begin.*?\\end{.*?})|(?<!\\)\$\$((?:.)*?)\$\$(?!\\)");
  @override
  RegExp get exp => RegExp(expString, dotAll: true, multiLine: true);

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var p0 = exp.firstMatch(text.trim());
    String mathText = p0?[1] ?? p0?[2] ?? p0?[3] ?? '';
    var workaround = config.latexWorkaround ?? (String tex) => tex;

    // If custom latexBuilder is provided, use it
    if (config.latexBuilder != null) {
      return config.latexBuilder!(
        context,
        workaround(mathText),
        config.style ?? const TextStyle(),
        false,
      );
    }

    // TEMPORARY: Test original LaTeX rendering approach
    debugPrint('=== Testing Original LaTeX Approach ===');
    debugPrint('Raw mathText: "$mathText"');
    
    try {
      final processedMath = workaround(mathText);
      debugPrint('After workaround: "$processedMath"');
      
      debugPrint('Original approach successful, wrapping in container');
      
      // If that works, wrap it in our styled container
      final displayType = _LatexRenderingHelpers.getLatexDisplayType(mathText);
      
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badge and buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // LaTeX badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      displayType.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Expand button
                  InkWell(
                    onTap: () => _LatexRenderingHelpers.showLatexExpandedView(
                      context, 
                      mathText, 
                      displayType,
                      config.style ?? const TextStyle(),
                      workaround: workaround,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.open_in_full,
                        color: Color(0xFFA0A0A0),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Share button
                  _LatexShareButton(latexContent: mathText, displayType: displayType),
                  const SizedBox(width: 8),
                  // Copy button  
                  _LatexCopyButton(latexContent: mathText),
                ],
              ),
            ),
            // Content area - rendered LaTeX
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: (() {
                  try {
                    final processedMath = workaround(mathText);
                    return Math.tex(
                      processedMath,
                      textStyle: TextStyle(
                        color: config.style?.color ?? Colors.white,
                        fontSize: config.style?.fontSize ?? 16.0,
                      ),
                      mathStyle: MathStyle.display,
                      settings: const TexParserSettings(strict: Strict.ignore),
                    );
                  } catch (e) {
                    debugPrint('LaTeX rendering failed in second container: $e');
                    return Text(
                      'LaTeX Error: $e',
                      style: TextStyle(color: Colors.red[300], fontSize: 12),
                    );
                  }
                })(),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Original approach also failed: $e');
      
      // Fallback to our previous enhanced rendering approach
      final displayType = _LatexRenderingHelpers.getLatexDisplayType(mathText);
      
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badge and buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // LaTeX badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      displayType.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Expand button
                  InkWell(
                    onTap: () => _LatexRenderingHelpers.showLatexExpandedView(
                      context, 
                      mathText, 
                      displayType,
                      config.style ?? const TextStyle(),
                      workaround: workaround,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.open_in_full,
                        color: Color(0xFFA0A0A0),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Share button
                  _LatexShareButton(latexContent: mathText, displayType: displayType),
                  const SizedBox(width: 8),
                  // Copy button  
                  _LatexCopyButton(latexContent: mathText),
                ],
              ),
            ),
            // Content area - rendered LaTeX
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: (() {
                  try {
                    final processedMath = workaround(mathText);
                    return Math.tex(
                      processedMath,
                      textStyle: TextStyle(
                        color: config.style?.color ?? Colors.white,
                        fontSize: config.style?.fontSize ?? 16.0,
                      ),
                      mathStyle: MathStyle.display,
                      settings: const TexParserSettings(strict: Strict.ignore),
                    );
                  } catch (e) {
                    debugPrint('LaTeX rendering failed in second container: $e');
                    return Text(
                      'LaTeX Error: $e',
                      style: TextStyle(color: Colors.red[300], fontSize: 12),
                    );
                  }
                })(),
              ),
            ),
          ],
        ),
      );
    }
  }
}

/// Italic text component
class LatexMath extends InlineMd {
  @override
  RegExp get exp => RegExp(
    [
      r"\\\((.*?)\\\)",
      r"(?<!\\)\$((?:\\.|[^$])*?)\$(?!\\)", // Add dollar sign support back
    ].join("|"),
    dotAll: true,
  );

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var p0 = exp.firstMatch(text.trim());
    p0?.group(0);
    String mathText = p0?[1]?.toString() ?? p0?[2]?.toString() ?? "";
    var workaround = config.latexWorkaround ?? (String tex) => tex;

    debugPrint('=== Inline LaTeX Debug ===');
    debugPrint('Raw text: "$text"');
    debugPrint('Extracted mathText: "$mathText"');

    // If custom latexBuilder is provided, use it
    if (config.latexBuilder != null) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: config.latexBuilder!(
          context,
          workaround(mathText),
          config.style ?? const TextStyle(),
          true,
        ),
      );
    }

    // Use simple inline LaTeX rendering (no complex container for inline math)
    try {
      final processedMath = workaround(mathText);
      debugPrint('After workaround: "$processedMath"');
      
      final result = Math.tex(
        processedMath,
        textStyle: TextStyle(
          color: config.style?.color ?? Colors.white,
          fontSize: config.style?.fontSize ?? 16.0,
        ),
        mathStyle: MathStyle.text, // Use text style for inline math
        settings: const TexParserSettings(strict: Strict.ignore),
      );
      
      debugPrint('Inline LaTeX rendering successful');
      
      return WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: result,
      );
    } catch (e) {
      debugPrint('Inline LaTeX rendering failed: $e');
      
      return WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: (() {
          try {
            final processedMath = workaround(mathText);
            return Math.tex(
              processedMath,
              textStyle: TextStyle(
                color: config.style?.color ?? Colors.white,
                fontSize: config.style?.fontSize ?? 16.0,
              ),
              mathStyle: MathStyle.text,
              settings: const TexParserSettings(strict: Strict.ignore),
            );
          } catch (e) {
            debugPrint('Inline LaTeX rendering failed: $e');
            return Text(
              'LaTeX Error',
              style: TextStyle(color: Colors.red[300], fontSize: 12),
            );
          }
        })(),
      );
    }
  }
}

/// source text component
class SourceTag extends InlineMd {
  @override
  RegExp get exp => RegExp(r"(?:【.*?)?\[(\d+?)\]");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var content = match?[1];
    if (content == null) {
      return const TextSpan();
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child:
            config.sourceTagBuilder?.call(
              context,
              content,
              const TextStyle(),
            ) ??
            SizedBox(
              width: 20,
              height: 20,
              child: Material(
                color: Theme.of(context).colorScheme.onInverseSurface,
                shape: const OvalBorder(),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    content,
                    // style: (style ?? const TextStyle()).copyWith(),
                    textDirection: config.textDirection,
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

/// Link text component
class ATagMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r"(?<!\!)\[.*\]\([^\s]*\)");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var bracketCount = 0;
    var start = 1;
    var end = 0;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == '[') {
        bracketCount++;
      } else if (text[i] == ']') {
        bracketCount--;
        if (bracketCount == 0) {
          end = i;
          break;
        }
      }
    }

    if (text[end + 1] != '(') {
      return const TextSpan();
    }

    // First try to find the basic pattern
    // final basicMatch = RegExp(r'(?<!\!)\[(.*)\]\(').firstMatch(text.trim());
    // if (basicMatch == null) {
    //   return const TextSpan();
    // }

    final linkText = text.substring(start, end);
    final urlStart = end + 2;

    // Now find the balanced closing parenthesis
    int parenCount = 0;
    int urlEnd = urlStart;

    for (int i = urlStart; i < text.length; i++) {
      final char = text[i];

      if (char == '(') {
        parenCount++;
      } else if (char == ')') {
        if (parenCount == 0) {
          // This is the closing parenthesis of the link
          urlEnd = i;
          break;
        } else {
          parenCount--;
        }
      }
    }

    if (urlEnd == urlStart) {
      // No closing parenthesis found
      return const TextSpan();
    }

    final url = text.substring(urlStart, urlEnd).trim();

    var builder = config.linkBuilder;

    var ending = text.substring(urlEnd + 1);

    var endingSpans = MarkdownComponent.generate(
      context,
      ending,
      config,
      false,
    );
    var theme = GptMarkdownTheme.of(context);
    var linkTextSpan = TextSpan(
      children: MarkdownComponent.generate(context, linkText, config, false),
      style: config.style?.copyWith(
        color: theme.linkColor,
        decorationColor: theme.linkColor,
      ),
    );

    // Use custom builder if provided
    WidgetSpan? child;
    if (builder != null) {
      child = WidgetSpan(
        child: GestureDetector(
          onTap: () => config.onLinkTap?.call(url, linkText),
          child: builder(
            context,
            linkTextSpan,
            url,
            config.style ?? const TextStyle(),
          ),
        ),
      );
    }

    // Default rendering
    child ??= WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: LinkButton(
        hoverColor: theme.linkHoverColor,
        color: theme.linkColor,
        onPressed: () {
          config.onLinkTap?.call(url, linkText);
        },
        text: linkText,
        config: config,
        child: config.getRich(linkTextSpan),
      ),
    );
    var textSpan = TextSpan(children: [child, ...endingSpans]);
    return textSpan;
  }
}

/// Image component
class ImageMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r"\!\[[^\[\]]*\]\([^\s]*\)");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    // First try to find the basic pattern
    final basicMatch = RegExp(r'\!\[([^\[\]]*)\]\(').firstMatch(text.trim());
    if (basicMatch == null) {
      return const TextSpan();
    }

    final altText = basicMatch.group(1) ?? '';
    final urlStart = basicMatch.end;

    // Now find the balanced closing parenthesis
    int parenCount = 0;
    int urlEnd = urlStart;

    for (int i = urlStart; i < text.length; i++) {
      final char = text[i];

      if (char == '(') {
        parenCount++;
      } else if (char == ')') {
        if (parenCount == 0) {
          // This is the closing parenthesis of the image
          urlEnd = i;
          break;
        } else {
          parenCount--;
        }
      }
    }

    if (urlEnd == urlStart) {
      // No closing parenthesis found
      return const TextSpan();
    }

    final url = text.substring(urlStart, urlEnd).trim();

    double? height;
    double? width;
    if (altText.isNotEmpty) {
      var size = RegExp(r"^([0-9]+)?x?([0-9]+)?").firstMatch(altText.trim());
      width = double.tryParse(size?[1]?.toString().trim() ?? 'a');
      height = double.tryParse(size?[2]?.toString().trim() ?? 'a');
    }

    final Widget image;
    if (config.imageBuilder != null) {
      image = config.imageBuilder!(context, url);
    } else {
      image = SizedBox(
        width: width,
        height: height,
        child: Image(
          image: NetworkImage(url),
          loadingBuilder: (
            BuildContext context,
            Widget child,
            ImageChunkEvent? loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }
            return CustomImageLoading(
              progress:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : 1,
            );
          },
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) {
            return const CustomImageError();
          },
        ),
      );
    }
    return WidgetSpan(alignment: PlaceholderAlignment.bottom, child: image);
  }
}

/// Table component
class TableMd extends BlockMd {
  @override
  String get expString =>
      (r"(((\|[^\n\|]+\|)((([^\n\|]+\|)+)?)\ *)(\n\ *(((\|[^\n\|]+\|)(([^\n\|]+\|)+)?))\ *)+)$");
  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    final List<Map<int, String>> value =
        text
            .split('\n')
            .map<Map<int, String>>(
              (e) =>
                  e
                      .trim()
                      .split('|')
                      .where((element) => element.isNotEmpty)
                      .toList()
                      .asMap(),
            )
            .toList();

    // Check if table has a header and separator row
    bool hasHeader = value.length >= 2;
    List<TextAlign> columnAlignments = [];

    if (hasHeader) {
      // Parse alignment from the separator row (second row)
      var separatorRow = value[1];
      columnAlignments = List.generate(separatorRow.length, (index) {
        String separator = separatorRow[index] ?? "";
        separator = separator.trim();

        // Check for alignment indicators
        bool hasLeftColon = separator.startsWith(':');
        bool hasRightColon = separator.endsWith(':');

        if (hasLeftColon && hasRightColon) {
          return TextAlign.center;
        } else if (hasRightColon) {
          return TextAlign.right;
        } else if (hasLeftColon) {
          return TextAlign.left;
        } else {
          return TextAlign.left; // Default alignment
        }
      });
    }

    int maxCol = 0;
    for (final each in value) {
      if (maxCol < each.keys.length) {
        maxCol = each.keys.length;
      }
    }

    if (maxCol == 0) {
      return Text("", style: config.style);
    }

    // Ensure we have alignment for all columns
    while (columnAlignments.length < maxCol) {
      columnAlignments.add(TextAlign.left);
    }

    var tableBuilder = config.tableBuilder;

    if (tableBuilder != null) {
      var customTable =
          List<CustomTableRow?>.generate(value.length, (index) {
            var isHeader = index == 0;
            var row = value[index];
            if (row.isEmpty) {
              return null;
            }
            if (index == 1) {
              return null;
            }
            var fields = List<CustomTableField>.generate(maxCol, (index) {
              var field = row[index];
              return CustomTableField(
                data: field ?? "",
                alignment: columnAlignments[index],
              );
            });
            return CustomTableRow(isHeader: isHeader, fields: fields);
          }).nonNulls.toList();
      return tableBuilder(
        context,
        customTable,
        config.style ?? const TextStyle(),
        config,
      );
    }

    final controller = ScrollController();
    return Scrollbar(
      controller: controller,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        child: Table(
          textDirection: config.textDirection,
          defaultColumnWidth: CustomTableColumnWidth(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(
            width: 1,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          children:
              value
                  .asMap()
                  .entries
                  .where((entry) {
                    // Skip the separator row (second row) from rendering
                    if (hasHeader && entry.key == 1) {
                      return false;
                    }
                    return true;
                  })
                  .map<TableRow>(
                    (entry) => TableRow(
                      decoration:
                          (hasHeader && entry.key == 0)
                              ? BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              )
                              : null,
                      children: List.generate(maxCol, (index) {
                        var e = entry.value;
                        String data = e[index] ?? "";
                        if (RegExp(r"^:?--+:?$").hasMatch(data.trim()) ||
                            data.trim().isEmpty) {
                          return const SizedBox();
                        }

                        // Apply alignment based on column alignment
                        Widget content = Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: MdWidget(
                            context,
                            (e[index] ?? "").trim(),
                            false,
                            config: config,
                          ),
                        );

                        // Wrap with alignment widget
                        switch (columnAlignments[index]) {
                          case TextAlign.center:
                            content = Center(child: content);
                            break;
                          case TextAlign.right:
                            content = Align(
                              alignment: Alignment.centerRight,
                              child: content,
                            );
                            break;
                          case TextAlign.left:
                          default:
                            content = Align(
                              alignment: Alignment.centerLeft,
                              child: content,
                            );
                            break;
                        }

                        return content;
                      }),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

class CodeBlockMd extends BlockMd {
  @override
  String get expString => r"```(.*?)\n((.*?)(:?\n\s*?```)|(.*)(:?\n```)?)$";
  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    String codes = this.exp.firstMatch(text)?[2] ?? "";
    String name = this.exp.firstMatch(text)?[1] ?? "";
    codes = codes.replaceAll(r"```", "").trim();
    bool closed = text.endsWith("```");

    // Special handling for LaTeX code blocks
    if (name.toLowerCase() == 'latex' || name.toLowerCase() == 'tex') {
      return _buildLatexCodeBlock(context, codes, config);
    }

    return config.codeBuilder?.call(context, name, codes, closed) ??
        CodeField(name: name, codes: codes);
  }

  // Build LaTeX code block with proper rendering
  Widget _buildLatexCodeBlock(BuildContext context, String latexContent, GptMarkdownConfig config) {
    final displayType = _LatexRenderingHelpers.getLatexDisplayType(latexContent);
    final workaround = config.latexWorkaround ?? (String tex) => tex;
    
    return Material(
      color: Theme.of(context).colorScheme.onInverseSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row with language name and action buttons
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Text(displayType.toUpperCase()),
              ),
              const Spacer(),
              // Expand button
              IconButton(
                iconSize: 16,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _LatexRenderingHelpers.showLatexExpandedView(
                  context, 
                  latexContent, 
                  displayType,
                  config.style ?? const TextStyle(),
                  workaround: workaround,
                ),
                icon: Icon(
                  Icons.open_in_full,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                tooltip: 'Expand',
              ),
              // Share button
              IconButton(
                iconSize: 16,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () async {
                  try {
                    if (latexContent.isEmpty) return;
                    HapticFeedback.lightImpact();

                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    final fileName = 'latex_${displayType.toLowerCase().replaceAll(' ', '_')}_$timestamp.tex';

                    final tempDir = await getTemporaryDirectory();
                    final file = File('${tempDir.path}/$fileName');

                    await file.writeAsString(latexContent);

                    await Share.shareXFiles(
                      [XFile(file.path)],
                      text: '$displayType LaTeX file',
                      subject: '$displayType LaTeX',
                    );
                  } catch (e) {
                    debugPrint('LaTeX share failed: ${e.toString()}');
                    // Fallback to text sharing
                    try {
                      await Share.share(
                        latexContent,
                        subject: '$displayType LaTeX',
                      );
                    } catch (fallbackError) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to share: ${fallbackError.toString()}'),
                            backgroundColor: Colors.red[700],
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  }
                },
                icon: Icon(
                  Icons.share_outlined,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                tooltip: 'Share',
              ),
              // Copy button
              IconButton(
                iconSize: 16,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: latexContent));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('LaTeX copied to clipboard'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: Icon(
                  Icons.copy_outlined,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                tooltip: 'Copy',
              ),
            ],
          ),
          const Divider(height: 1),
          // Content area with rendered LaTeX
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: (() {
              try {
                // Clean the LaTeX content to extract just math expressions
                final cleanedLatex = _cleanLatexDocument(latexContent);
                final processedLatex = workaround(cleanedLatex);
                return Math.tex(
                  processedLatex,
                  textStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: config.style?.fontSize ?? 16.0,
                  ),
                  mathStyle: MathStyle.display,
                  settings: const TexParserSettings(strict: Strict.ignore),
                );
              } catch (e) {
                debugPrint('LaTeX rendering failed in code block: $e');
                return Text(
                  'LaTeX Error: $e',
                  style: TextStyle(
                    color: Colors.red[300],
                    fontSize: 12,
                    fontFamily: 'JetBrainsMono',
                  ),
                );
              }
            })(),
          ),
        ],
      ),
    );
  }

  // Clean LaTeX document content to extract just mathematical expressions
  String _cleanLatexDocument(String latexContent) {
    String cleaned = latexContent.trim();
    
    // Remove document structure commands
    final documentCommands = [
      r'\\documentclass\{[^}]*\}',
      r'\\usepackage\{[^}]*\}',
      r'\\begin\{document\}',
      r'\\end\{document\}',
      r'\\title\{[^}]*\}',
      r'\\author\{[^}]*\}',
      r'\\date\{[^}]*\}',
      r'\\maketitle',
    ];
    
    for (final cmd in documentCommands) {
      cleaned = cleaned.replaceAll(RegExp(cmd, multiLine: true), '');
    }
    
    // Extract content from equation environments and combine them
    final equations = <String>[];
    
    // Extract from \begin{equation}...\end{equation}
    final equationRegex = RegExp(r'\\begin\{equation\}(.*?)\\end\{equation\}', multiLine: true, dotAll: true);
    final equationMatches = equationRegex.allMatches(cleaned);
    for (final match in equationMatches) {
      final content = match.group(1)?.trim();
      if (content != null && content.isNotEmpty) {
        equations.add(content);
      }
    }
    
    // Extract from \begin{align}...\end{align}
    final alignRegex = RegExp(r'\\begin\{align\}(.*?)\\end\{align\}', multiLine: true, dotAll: true);
    final alignMatches = alignRegex.allMatches(cleaned);
    for (final match in alignMatches) {
      final content = match.group(1)?.trim();
      if (content != null && content.isNotEmpty) {
        equations.add(content);
      }
    }
    
    // Extract from other math environments
    final mathEnvs = ['gather', 'multline', 'alignat', 'flalign'];
    for (final env in mathEnvs) {
      final envRegex = RegExp(r'\\begin\{' + env + r'\}(.*?)\\end\{' + env + r'\}', multiLine: true, dotAll: true);
      final envMatches = envRegex.allMatches(cleaned);
      for (final match in envMatches) {
        final content = match.group(1)?.trim();
        if (content != null && content.isNotEmpty) {
          equations.add(content);
        }
      }
    }
    
    // If we found equations, combine them with line breaks
    if (equations.isNotEmpty) {
      return equations.join('\\\\\n');
    }
    
    // If no specific environments found, remove any remaining unwanted commands and return cleaned content
    cleaned = cleaned
        .replaceAll(RegExp(r'\\begin\{[^}]*\}'), '')
        .replaceAll(RegExp(r'\\end\{[^}]*\}'), '')
        .replaceAll(RegExp(r'\n\s*\n'), '\\\\\n') // Replace double newlines with math line breaks
        .trim();
    
    return cleaned.isEmpty ? latexContent : cleaned; // Fallback to original if cleaning failed
  }
}

class UnderLineMd extends InlineMd {
  @override
  RegExp get exp =>
      RegExp(r"<u>(.*?)(?:</u>|$)", multiLine: true, dotAll: true);

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var conf = config.copyWith(
      style: (config.style ?? const TextStyle()).copyWith(
        decoration: TextDecoration.underline,
        decorationColor: config.style?.color,
      ),
    );
    return TextSpan(
      children: MarkdownComponent.generate(
        context,
        "${match?[1]}",
        conf,
        false,
      ),
      style: conf.style,
    );
  }
}

class CustomTableField {
  final String data;
  final TextAlign alignment;

  CustomTableField({required this.data, this.alignment = TextAlign.left});
}

class CustomTableRow {
  final bool isHeader;
  final List<CustomTableField> fields;

  CustomTableRow({this.isHeader = false, required this.fields});
}
