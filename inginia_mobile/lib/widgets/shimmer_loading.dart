import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerLoading.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(12)),
       );

  const ShimmerLoading.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          decoration: ShapeDecoration(color: Colors.grey, shape: shapeBorder),
        ),
      ),
    );
  }
}

class MissionCardShimmer extends StatelessWidget {
  const MissionCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerLoading.rectangular(height: 20, width: 80),
              ShimmerLoading.rectangular(height: 20, width: 120),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ShimmerLoading.circular(width: 48, height: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading.rectangular(height: 16, width: 150),
                    const SizedBox(height: 8),
                    ShimmerLoading.rectangular(height: 14, width: 100),
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
