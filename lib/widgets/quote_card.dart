import 'package:flutter/material.dart';

import '../core/quotes.dart';
import '../core/theme.dart';

/// 영어 명언 표시 위젯. 중앙 정렬 기본.
class QuoteCard extends StatelessWidget {
  final Quote quote;
  final bool compact;
  const QuoteCard({super.key, required this.quote, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '"${quote.text}"',
          style: compact
              ? HyphenTokens.caption.copyWith(
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.1,
                )
              : HyphenTokens.quote,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: compact ? HyphenTokens.sp1 : HyphenTokens.sp2),
        Text(
          '— ${quote.author}',
          style: HyphenTokens.micro,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
