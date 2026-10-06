import 'package:flutter/material.dart';

class ScoreBadge extends StatelessWidget {
  final int score;
  final String label;
  final double size;

  const ScoreBadge({
    super.key,
    required this.score,
    this.label = 'Score',
    this.size = 56,
  });

  Color _getColor() {
    if (score >= 80) return const Color(0xFF10B981); // Emerald
    if (score >= 60) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Rose
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: size * 0.30,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                score >= 80
                    ? 'Excellent ATS'
                    : score >= 60
                        ? 'Good ATS'
                        : 'Needs work',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
