import 'package:flutter/material.dart';

/// Widget per evidenziare termini di ricerca nel testo
class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int maxLines;
  final TextOverflow overflow;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.highlightStyle,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final defaultStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    final defaultHighlightStyle = highlightStyle ??
        TextStyle(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        );

    final spans = _buildSpans(text, query, defaultStyle!, defaultHighlightStyle);

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  List<TextSpan> _buildSpans(String text, String query, TextStyle normalStyle, TextStyle highlightStyle) {
    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index >= 0) {
      // Aggiungi testo normale prima del match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: normalStyle,
        ));
      }

      // Aggiungi testo evidenziato
      final end = index + query.length;
      spans.add(TextSpan(
        text: text.substring(index, end),
        style: highlightStyle,
      ));

      start = end;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // Aggiungi testo rimanente
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: normalStyle,
      ));
    }

    return spans;
  }
}
