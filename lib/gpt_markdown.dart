import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:gpt_markdown/custom_widgets/markdown_config.dart';

import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:gpt_markdown/custom_widgets/custom_divider.dart';
import 'package:gpt_markdown/custom_widgets/custom_error_image.dart';
import 'package:gpt_markdown/custom_widgets/custom_rb_cb.dart';
import 'package:gpt_markdown/custom_widgets/unordered_ordered_list.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;
import 'dart:io';

import 'custom_widgets/code_field.dart';
import 'custom_widgets/indent_widget.dart';
import 'custom_widgets/link_button.dart';
import 'custom_widgets/selectable_adapter.dart';

part 'theme.dart';
part 'markdown_component.dart';
part 'md_widget.dart';

/// This widget create a full markdown widget as a column view.
class GptMarkdown extends StatelessWidget {
  const GptMarkdown(
    this.data, {
    super.key,
    this.style,
    this.followLinkColor = false,
    this.textDirection = TextDirection.ltr,
    this.latexWorkaround,
    this.textAlign,
    this.imageBuilder,
    this.textScaler,
    this.onLinkTap,
    this.latexBuilder,
    this.codeBuilder,
    this.inlineCodeBuilder,
    this.sourceTagBuilder,
    this.highlightBuilder,
    this.linkBuilder,
    this.maxLines,
    this.overflow,
    this.orderedListBuilder,
    this.unOrderedListBuilder,
    this.tableBuilder,
    this.components,
    this.inlineComponents,
    this.h1Style,
    this.h2Style,
    this.h3Style,
    this.h4Style,
    this.h5Style,
    this.h6Style,
    this.useDollarSignsForLatex = false,
    this.selectable = true,
    this.selectionColor,
  });

  /// The direction of the text.
  final TextDirection textDirection;

  /// The data to be displayed.
  final String data;

  /// The style of the text.
  final TextStyle? style;

  /// The alignment of the text.
  final TextAlign? textAlign;

  /// The text scaler.
  final TextScaler? textScaler;

  /// The callback function to handle link clicks.
  final void Function(String url, String title)? onLinkTap;

  /// The LaTeX workaround.
  final String Function(String tex)? latexWorkaround;
  final int? maxLines;

  /// The overflow.
  final TextOverflow? overflow;

  /// The LaTeX builder.
  final LatexBuilder? latexBuilder;

  /// Whether to follow the link color.
  final bool followLinkColor;

  /// The code builder.
  final CodeBlockBuilder? codeBuilder;

  /// The inline code builder.
  final InlineCodeBuilder? inlineCodeBuilder;

  /// The source tag builder.
  final SourceTagBuilder? sourceTagBuilder;

  /// The highlight builder.
  final HighlightBuilder? highlightBuilder;

  /// The link builder.
  final LinkBuilder? linkBuilder;

  /// The image builder.
  final ImageBuilder? imageBuilder;

  /// The ordered list builder.
  final OrderedListBuilder? orderedListBuilder;

  /// The unordered list builder.
  final UnOrderedListBuilder? unOrderedListBuilder;

  /// Custom style for H1 headings. If not provided, uses theme default.
  final TextStyle? h1Style;

  /// Custom style for H2 headings. If not provided, uses theme default.
  final TextStyle? h2Style;

  /// Custom style for H3 headings. If not provided, uses theme default.
  final TextStyle? h3Style;

  /// Custom style for H4 headings. If not provided, uses theme default.
  final TextStyle? h4Style;

  /// Custom style for H5 headings. If not provided, uses theme default.
  final TextStyle? h5Style;

  /// Custom style for H6 headings. If not provided, uses theme default.
  final TextStyle? h6Style;

  /// Whether to use dollar signs for LaTeX.
  final bool useDollarSignsForLatex;

  /// Whether to make all text selectable.
  final bool selectable;

  /// The color used for text selection highlight.
  final Color? selectionColor;

  /// The table builder.
  final TableBuilder? tableBuilder;

  /// The list of components.
  ///  ```dart
  /// List<MarkdownComponent> components = [
  ///   CodeBlockMd(),
  ///   NewLines(),
  ///   BlockQuote(),
  ///   ImageMd(),
  ///   ATagMd(),
  ///   TableMd(),
  ///   HTag(),
  ///   UnOrderedList(),
  ///   OrderedList(),
  ///   RadioButtonMd(),
  ///   CheckBoxMd(),
  ///   HrLine(),
  ///   StrikeMd(),
  ///   BoldMd(),
  ///   ItalicMd(),
  ///   LatexMath(),
  ///   LatexMathMultiLine(),
  ///   HighlightedText(),
  ///   SourceTag(),
  ///   IndentMd(),
  /// ];
  /// ```
  final List<MarkdownComponent>? components;

  /// The list of inline components.
  ///  ```dart
  /// List<MarkdownComponent> inlineComponents = [
  ///   ImageMd(),
  ///   ATagMd(),
  ///   InlineCodeMd(),
  ///   TableMd(),
  ///   StrikeMd(),
  ///   BoldMd(),
  ///   ItalicMd(),
  ///   LatexMath(),
  ///   LatexMathMultiLine(),
  ///   HighlightedText(),
  ///   SourceTag(),
  /// ];
  /// ```
  final List<MarkdownComponent>? inlineComponents;

  /// A method to remove extra lines inside block LaTeX.
  // String _removeExtraLinesInsideBlockLatex(String text) {
  //   return text.replaceAllMapped(
  //     RegExp(r"\\\[(.*?)\\\]", multiLine: true, dotAll: true),
  //     (match) {
  //       String content = match[0] ?? "";
  //       return content.replaceAllMapped(RegExp(r"\n[\n\ ]+"), (match) => "\n");
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    String tex = data.trim();
    if (useDollarSignsForLatex) {
      tex = tex.replaceAllMapped(
        RegExp(r"(?<!\\)\$\$(.*?)(?<!\\)\$\$", dotAll: true),
        (match) => "\\[${match[1] ?? ""}\\]",
      );
      if (!tex.contains(r"\(")) {
        tex = tex.replaceAllMapped(
          RegExp(r"(?<!\\)\$(.*?)(?<!\\)\$"),
          (match) => "\\(${match[1] ?? ""}\\)",
        );
        tex = tex.splitMapJoin(
          RegExp(r"\[.*?\]|\(.*?\)"),
          onNonMatch: (p0) {
            return p0.replaceAll("\\\$", "\$");
          },
        );
      }
    }
    // tex = _removeExtraLinesInsideBlockLatex(tex);
    Widget markdownWidget = ClipRRect(
      child: MdWidget(
        context,
        tex,
        true,
        config: GptMarkdownConfig(
          textDirection: textDirection,
          style: style,
          onLinkTap: onLinkTap,
          textAlign: textAlign,
          textScaler: textScaler,
          followLinkColor: followLinkColor,
          latexWorkaround: latexWorkaround,
          latexBuilder: latexBuilder,
          codeBuilder: codeBuilder,
          inlineCodeBuilder: inlineCodeBuilder,
          maxLines: maxLines,
          overflow: overflow,
          sourceTagBuilder: sourceTagBuilder,
          highlightBuilder: highlightBuilder,
          linkBuilder: linkBuilder,
          imageBuilder: imageBuilder,
          orderedListBuilder: orderedListBuilder,
          unOrderedListBuilder: unOrderedListBuilder,
          components: components,
          inlineComponents: inlineComponents,
          tableBuilder: tableBuilder,
          h1Style: h1Style,
          h2Style: h2Style,
          h3Style: h3Style,
          h4Style: h4Style,
          h5Style: h5Style,
          h6Style: h6Style,
        ),
      ),
    );

    // Wrap with SelectionArea if selectable is true
    if (selectable) {
      return _CustomSelectableArea(
        selectionColor: selectionColor,
        child: markdownWidget,
      );
    }

    return markdownWidget;
  }
}

/// Custom SelectionArea that properly handles iOS selection handle colors
class _CustomSelectableArea extends StatelessWidget {
  const _CustomSelectableArea({
    required this.child,
    this.selectionColor,
  });

  final Widget child;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    if (selectionColor == null) {
      return SelectionArea(child: child);
    }

    // For iOS, we need to wrap with CupertinoTheme to override selection handles
    if (!kIsWeb && Platform.isIOS) {
      return CupertinoTheme(
        data: CupertinoTheme.of(context).copyWith(
          primaryColor: selectionColor!,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            primaryColor: selectionColor!,
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: selectionColor!,
              secondary: selectionColor!,
            ),
            textSelectionTheme: TextSelectionThemeData(
              selectionColor: selectionColor!.withOpacity(0.3),
              selectionHandleColor: selectionColor!,
              cursorColor: selectionColor!,
            ),
            cupertinoOverrideTheme: CupertinoThemeData(
              primaryColor: selectionColor!,
            ),
          ),
          child: SelectionArea(child: child),
        ),
      );
    }

    // For Android and other platforms
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: selectionColor!,
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: selectionColor!,
          secondary: selectionColor!,
        ),
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: selectionColor!.withOpacity(0.3),
          selectionHandleColor: selectionColor!,
          cursorColor: selectionColor!,
        ),
      ),
      child: SelectionArea(child: child),
    );
  }
}

