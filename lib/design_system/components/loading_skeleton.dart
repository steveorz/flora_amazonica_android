import 'package:flutter/material.dart';

class LoadingSkeleton extends StatefulWidget {
  final double cornerRadius;
  final double width;
  final double height;

  const LoadingSkeleton({
    super.key,
    this.cornerRadius = 10,
    this.width = double.infinity,
    this.height = 100,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey.shade900 
        : Colors.grey.shade200;
        
    final highlightColor = Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey.shade800 
        : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.cornerRadius),
            gradient: LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(-1.0 + (_controller.value * 2.0), 0),
              end: Alignment(1.0 + (_controller.value * 2.0), 0),
              tileMode: TileMode.clamp,
            ),
          ),
        );
      },
    );
  }
}
