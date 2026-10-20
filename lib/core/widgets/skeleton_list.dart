import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

enum SkeletonType { list, card }

class SkeletonList extends StatelessWidget {
  final SkeletonType type;
  final int itemCount;

  const SkeletonList({
    super.key,
    this.type = SkeletonType.list,
    this.itemCount = 6,
  });

  const SkeletonList.cards({
    super.key,
    this.itemCount = 4,
  }) : type = SkeletonType.card;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surfaceContainerLow;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return type == SkeletonType.list
              ? _buildListTileSkeleton(baseColor)
              : _buildCardSkeleton(baseColor);
        },
      ),
    );
  }

  /// Hình dạng hàng danh sách (dành cho MenuScreen)
  Widget _buildListTileSkeleton(Color boxColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Khối ảnh vuông bo góc
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 12),
        // Các dòng chữ giả
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Hình dạng khối thẻ (dành cho StaffScreen & OrderTrackingScreen)
  Widget _buildCardSkeleton(Color boxColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: boxColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 120,
                height: 18,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: 70,
                height: 24,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 180,
            height: 14,
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}