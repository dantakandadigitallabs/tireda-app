import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Description text that clamps to [maxLines] and shows an inline
/// "See More" / "See Less" link at the cut-off point (same line as the text).
///
/// The link color uses [AppThemeData.primary4] so it picks up the Firebase
/// brand color, falling back to the declared primary4 default.
class ExpandableText extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final String fontFamily;
  final int maxLines;
  final double? height;

  const ExpandableText({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 14,
    this.fontFamily = FontFamily.regular,
    this.maxLines = 3,
    this.height,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;
  // Single recognizer reused across builds. Its onTap is reassigned on every
  // build so it always reflects the *current* expanded state — otherwise the
  // closure captured on first build keeps toggling to the same direction.
  final TapGestureRecognizer _recognizer = TapGestureRecognizer();

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  void initState() {
    super.initState();
    _recognizer.onTap = _toggle;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: widget.fontSize,
      fontFamily: widget.fontFamily,
      color: widget.color,
      height: widget.height,
    );
    final linkStyle = TextStyle(
      fontSize: widget.fontSize,
      fontFamily: FontFamily.bold,
      color: AppThemeData.primary4,
      height: widget.height,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final textDir = Directionality.of(context);

        // Does the full text overflow the line cap?
        final fullTp = TextPainter(
          text: TextSpan(text: widget.text, style: textStyle),
          maxLines: widget.maxLines,
          textDirection: textDir,
        )..layout(maxWidth: maxWidth);
        final overflows = fullTp.didExceedMaxLines;

        if (!overflows) {
          return Text(widget.text, style: textStyle);
        }

        // Non-breaking space keeps "See More" / "See Less" together on one line.
        final seeMore = 'See More'.tr.replaceAll(' ', ' ');
        final seeLess = 'See Less'.tr.replaceAll(' ', ' ');

        if (_expanded) {
          return Text.rich(
            TextSpan(children: [
              TextSpan(text: '${widget.text}  ', style: textStyle),
              TextSpan(text: seeLess, style: linkStyle, recognizer: _recognizer),
            ]),
          );
        }

        // Binary search the longest prefix that still fits within maxLines
        // once the ellipsis + link tail is appended. The span structure used
        // for measurement matches the one used for rendering exactly.
        InlineSpan buildSpans(String prefix) => TextSpan(children: [
              TextSpan(text: prefix, style: textStyle),
              TextSpan(text: '… ', style: textStyle),
              TextSpan(text: seeMore, style: linkStyle),
            ]);

        int low = 0;
        int high = widget.text.length;
        while (low < high) {
          final mid = (low + high + 1) >> 1;
          final probe = TextPainter(
            text: buildSpans(widget.text.substring(0, mid)),
            maxLines: widget.maxLines,
            textDirection: textDir,
          )..layout(maxWidth: maxWidth);
          if (probe.didExceedMaxLines) {
            high = mid - 1;
          } else {
            low = mid;
          }
        }

        var cutoff = low;
        while (cutoff > 0 &&
            (widget.text.codeUnitAt(cutoff - 1) == 0x20 ||
                widget.text.codeUnitAt(cutoff - 1) == 0x0A)) {
          cutoff--;
        }

        return Text.rich(
          TextSpan(children: [
            TextSpan(text: widget.text.substring(0, cutoff), style: textStyle),
            TextSpan(text: '… ', style: textStyle),
            TextSpan(text: seeMore, style: linkStyle, recognizer: _recognizer),
          ]),
        );
      },
    );
  }
}
