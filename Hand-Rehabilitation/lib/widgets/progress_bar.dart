import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AnimatedProgressBar extends StatelessWidget {
  final String label;
  final double value; // 0.0 to 1.0
  final Color color;

  const AnimatedProgressBar({
    Key? key,
    required this.label,
    required this.value,
    this.color = AppTheme.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${(value * 90).toInt()}°', style: const TextStyle(color: Colors.grey)), // Assuming 90 is max angle
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 12,
                width: MediaQuery.of(context).size.width * value * 0.85, // roughly
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
