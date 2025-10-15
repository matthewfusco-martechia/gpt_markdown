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
    // Parse LaTeX BEFORE markdown emphasis to avoid breaking math content
    LatexMath(),
    LatexMathMultiLine(),
    StrikeMd(),
    BoldMd(),
    ItalicMd(),
    UnderLineMd(),
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
    // DEBUG: Log what text is being processed
    if (text.contains('24') || text.contains('shares') || text.contains('*')) {
      print('🔥 CORE MARKDOWN DEBUG:');
      print('Processing text: "$text"');
      print('Combined regex pattern count: ${components.length}');
      print('Include global components: $includeGlobalComponents');
    }
    
    text.splitMapJoin(
      combinedRegex,
      onMatch: (p0) {
        String element = p0[0] ?? "";
        
        // DEBUG: Log matches for problematic content
        if (text.contains('24') || text.contains('shares') || text.contains('*')) {
          print('  📍 MATCH found: "$element"');
        }
        
        for (var each in components) {
          var p = each.exp.pattern;
          var exp = RegExp(
            '^$p\$',
            multiLine: each.exp.isMultiLine,
            dotAll: each.exp.isDotAll,
          );
          if (exp.hasMatch(element)) {
            if (text.contains('24') || text.contains('shares') || text.contains('*')) {
              print('    ✅ Component "${each.runtimeType}" processing: "$element"');
            }
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
        
        // DEBUG: Log non-matches for problematic content
        if ((text.contains('24') || text.contains('shares') || text.contains('*')) && p0.isNotEmpty) {
          print('  📝 NON-MATCH text: "$p0"');
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
    length = math.min(length, 4);
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
            fontWeight: FontWeight.w400,
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
    
    // DEBUG: Check if italic is causing the text merging issue
    if (match != null) {
      print('🎨 ITALIC COMPONENT DEBUG:');
      print('Input text: "$text"');
      print('Match found: "${match.group(0)}"');
      print('Extracted content: "$data"');
      print('This might be causing text merging!');
      print('========================');
    }
    
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
    var tableBuilder = config.tableBuilder;

    if (tableBuilder != null) {
      // Use custom table builder if provided
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

    // Advanced table implementation with expand, copy, share functionality
    final tableData = _parseTableData(text);
    if (tableData.isEmpty) return const SizedBox.shrink();

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0),
      ),
      child: Builder(
        builder: (context) => Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with table badge and buttons
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
                  // Table badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'TABLE',
                      style: TextStyle(
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
                    onTap: () => _showExpandedView(context, tableData, text, config),
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
                  const SizedBox(width: 4),
                  // Share button
                  _ShareButton(markdown: text),
                  const SizedBox(width: 4),
                  // Copy button
                  _CopyButton(code: text),
                ],
              ),
            ),
            // Separator
            Container(
              height: 1,
              color: const Color(0xFF2A2A2A),
            ),
            // Table content
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
                child: _buildTableContent(tableData, config, context, isModal: false),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  List<List<String>> _parseTableData(String markdown) {
    // Handle escaped newlines
    final processedMarkdown = markdown.replaceAll('\\n', '\n');

    final lines = processedMarkdown.trim().split('\n');

    final List<List<String>> tableData = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trim().isEmpty) {
        continue;
      }

      // Skip separator lines (lines with only dashes, pipes, colons, and spaces)
      if (RegExp(r'^[\|\-\s:]+$').hasMatch(line.trim())) {
        continue;
      }

      // Parse table row
      final cells = line
          .split('|')
          .map((cell) => cell.trim())
          .where((cell) => cell.isNotEmpty)
          .map((cell) {
        // Handle <br> tags in table cells
        return cell.replaceAll('<br>', '\n').replaceAll('<BR>', '\n');
      }).toList();

      if (cells.isNotEmpty) {
        tableData.add(cells);
      }
    }

    return tableData;
  }

  void _showExpandedView(BuildContext context, List<List<String>> tableData, String markdown, GptMarkdownConfig config) {
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
              child: Builder(
                builder: (context) => Column(
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
                        // Table badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'TABLE',
                            style: TextStyle(
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
                        const SizedBox(width: 4),
                        // Share button
                        _ShareButton(markdown: markdown),
                        const SizedBox(width: 4),
                        // Copy button
                        _CopyButton(code: markdown),
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
                          child: _buildTableContent(tableData, config, context, isModal: true),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTableContent(List<List<String>> tableData, GptMarkdownConfig config, BuildContext context, {bool isModal = false}) {
    if (tableData.isEmpty) return const SizedBox.shrink();

    final headers = tableData.first;
    final rows = tableData.length > 1 ? tableData.sublist(1) : <List<String>>[];

    // Calculate column widths for better alignment
    final List<double> columnWidths = [];
    for (int i = 0; i < headers.length; i++) {
      double maxWidth = 120; // minimum width

      // Check header width
      final headerText = _processMarkdownText(headers[i]);
      maxWidth = math.max(maxWidth, headerText.length * 8.0 + 32);

      // Check data cell widths
      for (final row in rows) {
        if (i < row.length) {
          final cellText = _processMarkdownText(row[i]);
          maxWidth = math.max(maxWidth, cellText.length * 8.0 + 32);
        }
      }

      // Cap maximum width to prevent extreme cases
      columnWidths.add(math.min(maxWidth, isModal ? 300 : 200));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: headers.asMap().entries.map((entry) {
                final index = entry.key;
                final header = entry.value;

                return Container(
                  width: columnWidths[index],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: index > 0
                        ? const Border(
                            left:
                                BorderSide(color: Color(0xFF2A2A2A), width: 1),
                          )
                        : null,
                  ),
                  child: _processCellContent(header, config, 14.0, context, isHeader: true),
                );
              }).toList(),
            ),
          ),
          // Data rows
          ...rows.asMap().entries.map((rowEntry) {
            final rowIndex = rowEntry.key;
            final row = rowEntry.value;
            return Container(
              decoration: BoxDecoration(
                color: rowIndex.isEven
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFF1F1F1F),
                border: const Border(
                  top: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: row.asMap().entries.map((cellEntry) {
                  final cellIndex = cellEntry.key;
                  final cell = cellEntry.value;

                  return Container(
                    width: cellIndex < columnWidths.length
                        ? columnWidths[cellIndex]
                        : 120,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: cellIndex > 0
                          ? const Border(
                              left: BorderSide(
                                  color: Color(0xFF2A2A2A), width: 1),
                            )
                          : null,
                    ),
                    child: _processCellContent(cell, config, config.style?.fontSize ?? 14.0, context),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Helper function to process markdown in cell text (for bold headers)
  String _processMarkdownText(String text) {
    // Convert **text** to just text (we'll apply bold styling separately).
    return text.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) => match.group(1) ?? '',
    );
  }

  // Helper function to check if text should be bold
  bool _shouldBeBold(String originalText) {
    return originalText.contains('**');
  }

  // Helper function to process markdown in cell text (for embedded code blocks)
  Widget _processCellContent(String text, GptMarkdownConfig config, double fontSize, BuildContext context, {bool isHeader = false}) {
    // Check if cell contains code blocks
    final codeBlockPattern = RegExp(r'```(\w*)\n?(.*?)\n?```', dotAll: true);
    final match = codeBlockPattern.firstMatch(text);

    if (match != null) {
      // Cell contains a code block
      final code = match.group(2) ?? '';

      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          code,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: fontSize * 0.85,
            color: Colors.white,
            height: 1.4,
          ),
        ),
      );
    }

    // Regular text cell - use MdWidget for proper markdown rendering
    final isBold = _shouldBeBold(text);

    return DefaultTextStyle(
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: isHeader
            ? (isBold ? FontWeight.bold : FontWeight.w600)
            : (isBold ? FontWeight.bold : FontWeight.normal),
        height: 1.4,
      ),
      child: MdWidget(
        context,
        text.trim(),
        false,
        config: config.copyWith(
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: isHeader
                ? (isBold ? FontWeight.bold : FontWeight.w600)
                : (isBold ? FontWeight.bold : FontWeight.normal),
          ),
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

    return config.codeBuilder?.call(context, name, codes, closed) ??
        CodeField(name: name, codes: codes);
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

class LatexMathMultiLine extends BlockMd {
  @override
  String get expString => (r"\ *\\\[((?:.)*?)\\\]|(\ *\\begin.*?\\end{.*?})");
  @override
  RegExp get exp => RegExp(expString, dotAll: true, multiLine: true);

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var p0 = exp.firstMatch(text.trim());
    String mathText = p0?[1] ?? p0?[2] ?? '';
    var workaround = config.latexWorkaround ?? (String tex) => tex;

    // Enhanced LaTeX builder with better options
    var builder =
        config.latexBuilder ??
        (BuildContext context, String tex, TextStyle textStyle, bool inline) =>
            SelectableAdapter(
              selectedText: tex,
              child: Math.tex(
                tex,
                textStyle: textStyle,
                mathStyle: MathStyle.display,
                textScaleFactor: 1,
                settings: const TexParserSettings(strict: Strict.ignore),
                options: MathOptions(
                  sizeUnderTextStyle: MathSize.large,
                  color:
                      config.style?.color ??
                      Theme.of(context).colorScheme.onSurface,
                  fontSize:
                      config.style?.fontSize ??
                      Theme.of(context).textTheme.bodyMedium?.fontSize,
                  mathFontOptions: FontOptions(
                    fontFamily: "Main",
                    fontWeight: config.style?.fontWeight ?? FontWeight.normal,
                    fontShape: FontStyle.normal,
                  ),
                  textFontOptions: FontOptions(
                    fontFamily: "Main",
                    fontWeight: config.style?.fontWeight ?? FontWeight.normal,
                    fontShape: FontStyle.normal,
                  ),
                  style: MathStyle.display,
                ),
                onErrorFallback: (err) {
                  return Text(
                    workaround(mathText),
                    textDirection: config.textDirection,
                    style: textStyle.copyWith(
                      color:
                          (!kDebugMode)
                              ? null
                              : Theme.of(context).colorScheme.error,
                    ),
                  );
                },
              ),
            );
    return builder(
      context,
      workaround(mathText),
      config.style ?? const TextStyle(),
      false,
    );
  }
}

/// Inline LaTeX component
class LatexMath extends InlineMd {
  @override
  RegExp get exp => RegExp(
    [
      r"\\\((.*?)\\\)",
      r"(?<!\\)\$([^\s\n$]+)\$(?!\\)",
    ].join("|"),
    dotAll: true,
  );

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
    return false;
  }

  /// Check if content has LaTeX mathematical indicators
  bool _hasLatexIndicators(String content) {
    // LaTeX commands like \alpha, \frac, etc.
    if (content.contains(RegExp(r'\\[a-zA-Z]+'))) {
      return true;
    }
    // Math symbols and operators with variables
    if (content.contains(RegExp(r'[\^_{}]')) || 
        content.contains(RegExp(r'[αβγδεζηθικλμνξοπρστυφχψω]'))) {
      return true;
    }
    // Mathematical operators with variables
    if (content.contains(RegExp(r'[+\-*/=<>≤≥≠∑∏∫]')) &&
        content.contains(RegExp(r'[a-zA-Z]'))) {
      return true;
    }
    return false;
  }

  /// Smart detection: determine if dollar-sign content should be treated as LaTeX
  bool _shouldProcessAsLatex(String content, bool isDollarPattern) {
    // Always process \(...\) format
    if (content.isEmpty) return false;
    
    // Always process \(...\) patterns regardless of settings
    if (!isDollarPattern) return true;
    
    // For $...$ patterns, use smart detection
    // If it looks like currency, don't process as LaTeX
    if (_looksLikeCurrency(content)) return false;
    
    // If it has clear LaTeX indicators, process as LaTeX
    if (_hasLatexIndicators(content)) return true;
    
    // For ambiguous cases in $...$ patterns, default to LaTeX
    // (This only runs when auto-detection has enabled dollar signs)
    return true;
  }

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var p0 = exp.firstMatch(text.trim());
    String mathText = p0?[1]?.toString() ?? p0?[2]?.toString() ?? "";
    
    // DEBUG: Print what the LaTeX component is actually finding
    if (p0 != null) {
      print('🔍 LATEX COMPONENT DEBUG:');
      print('Input text: "$text"');
      print('Match found: "${p0.group(0)}"');
      print('Extracted content: "$mathText"');
      print('Is LaTeX pattern: ${p0?[1] != null}');
      print('Is Dollar pattern: ${p0?[2] != null}');
      print('Should process as LaTeX: ${_shouldProcessAsLatex(mathText, p0?[2] != null)}');
      print('========================');
    }
    
    // Smart detection: check if this should be processed as LaTeX
    bool isLatexPattern = p0?[1] != null; // \(...\) format
    bool isDollarPattern = p0?[2] != null; // $...$ format
    
    if (!_shouldProcessAsLatex(mathText, isDollarPattern)) {
      // Return original text unchanged for currency/non-math content
      return TextSpan(text: text, style: config.style);
    }
    
    var workaround = config.latexWorkaround ?? (String tex) => tex;
    
    // Enhanced LaTeX builder with better options
    var builder =
        config.latexBuilder ??
        (BuildContext context, String tex, TextStyle textStyle, bool inline) =>
            SelectableAdapter(
              selectedText: tex,
              child: Math.tex(
                tex,
                textStyle: textStyle,
                mathStyle: MathStyle.text,
                textScaleFactor: 1,
                settings: const TexParserSettings(strict: Strict.ignore),
                options: MathOptions(
                  sizeUnderTextStyle: MathSize.large,
                  color:
                      config.style?.color ??
                      Theme.of(context).colorScheme.onSurface,
                  fontSize:
                      config.style?.fontSize ??
                      Theme.of(context).textTheme.bodyMedium?.fontSize,
                  mathFontOptions: FontOptions(
                    fontFamily: "Main",
                    fontWeight: config.style?.fontWeight ?? FontWeight.normal,
                    fontShape: FontStyle.normal,
                  ),
                  textFontOptions: FontOptions(
                    fontFamily: "Main",
                    fontWeight: config.style?.fontWeight ?? FontWeight.normal,
                    fontShape: FontStyle.normal,
                  ),
                  style: MathStyle.text,
                ),
                onErrorFallback: (err) {
                  return Text(
                    workaround(mathText),
                    textDirection: config.textDirection,
                    style: textStyle.copyWith(
                      color:
                          (!kDebugMode)
                              ? null
                              : Theme.of(context).colorScheme.error,
                    ),
                  );
                },
              ),
            );
    
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: builder(
        context,
        workaround(mathText),
        config.style ?? const TextStyle(),
        true,
      ),
    );
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

/// A share button widget for tables
class _ShareButton extends StatelessWidget {
  final String markdown;

  const _ShareButton({Key? key, required this.markdown}) : super(key: key);

  // Convert markdown table to CSV format (optimized)
  String _tableToCSV(String markdown) {
    try {
      final lines = markdown.trim().split('\n');
      final List<String> csvLines = [];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        // Skip separator lines (lines with only dashes and pipes) - optimized check
        if (RegExp(r'^[|\-\s]+$').hasMatch(line)) continue;

        // Parse table row - more efficient splitting
        final cells = line
            .split('|')
            .map((cell) => cell.trim())
            .where((cell) => cell.isNotEmpty)
            .toList();

        if (cells.isNotEmpty) {
          // Clean up cells and escape quotes for CSV - optimized processing
          final cleanCells = cells.map((cell) {
            // Remove markdown formatting like **text** - single regex for better performance
            // Properly strip **bold** markdown by capturing inner text.
            String cleanCell = cell.replaceAllMapped(
              RegExp(r'\*\*(.*?)\*\*'),
              (match) => match.group(1) ?? '',
            );

            // Escape quotes and wrap in quotes if contains comma, quotes, or newlines
            if (cleanCell.contains(',') ||
                cleanCell.contains('"') ||
                cleanCell.contains('\n')) {
              cleanCell = '"${cleanCell.replaceAll('"', '""')}"';
            }
            return cleanCell;
          }).toList();

          csvLines.add(cleanCells.join(','));
        }
      }

      return csvLines.join('\n');
    } catch (e) {
      debugPrint('CSV conversion failed: $e');
      // Fallback: return original markdown
      return markdown;
    }
  }

  void handleShare(BuildContext context) async {
    try {
      if (markdown.isEmpty) return;
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
                Text('Converting table to CSV...'),
              ],
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Convert markdown table to CSV (moved after user feedback)
      final csvContent = _tableToCSV(markdown);

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'table_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${tempDir.path}/$fileName');

      // Write CSV content to file
      await file.writeAsString(csvContent);

      // Share the CSV file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Table data',
        subject: 'Table Export',
      );
    } catch (e) {
      debugPrint('Table share failed: ${e.toString()}');
      // Fallback to text sharing
      await Share.share(
        'Table:\n\n$markdown',
        subject: 'Table Data',
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
