import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MwanachuomindShimmer extends StatelessWidget {
  const MwanachuomindShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: List.generate(
            6,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 12.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                        ),
                        Container(
                          width: double.infinity,
                          height: 12.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                        ),
                        Container(
                          width: 100.0,
                          height: 12.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MwanachuomindChatShimmer extends StatelessWidget {
  const MwanachuomindChatShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode
        ? Colors.grey[800]!.withValues(alpha: 0.3)
        : Colors.grey[300]!.withValues(alpha: 0.5);
    final highlightColor = isDarkMode
        ? Colors.grey[700]!.withValues(alpha: 0.2)
        : Colors.grey[100]!.withValues(alpha: 0.3);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final isAi = index % 2 == 0;
          return Align(
            alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: MediaQuery.of(context).size.width * 0.7,
              height: 60 + (index % 3 * 20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isAi ? Radius.zero : const Radius.circular(20),
                  bottomRight: !isAi ? Radius.zero : const Radius.circular(20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
