import 'package:flutter/material.dart';

import '../model/artwork_model.dart';

class ContinueColoringCard extends StatelessWidget {
  final ArtworkModel artwork;
  final VoidCallback? onTap;

  const ContinueColoringCard({
    super.key,
    required this.artwork,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(18),
              child: Image.asset(
                artwork.imagePath,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.primaryColorDark,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Đã hoàn thành ${(artwork.progress * 100).toInt()}%",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: artwork.progress,
                      minHeight: 8,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: artwork.progress >= 0.05
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Text(
                      artwork.progress >= 0.05
                          ? "⏸ Đang tô"
                          : "▶ Chưa bắt đầu",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            artwork.progress >= 0.05
                                ? Colors.green
                                : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}