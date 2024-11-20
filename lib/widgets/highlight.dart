import 'package:flutter/material.dart';

class HighlightableWidget extends StatefulWidget {
  final Widget child;

  const HighlightableWidget({super.key, required this.child});

  @override
  HighlightableWidgetState createState() => HighlightableWidgetState();
}

class HighlightableWidgetState extends State<HighlightableWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Duration of one pulse
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse(); // Reverse the animation after reaching full opacity
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Call this method to start the highlight effect
  void highlight() {
    _controller.forward(from: 0.0); // Start the animation
    Future.delayed(const Duration(milliseconds: 1000), () {
      // Stop animation after 1 second (double pulse)
      _controller.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          FadeTransition(
            opacity: _animation,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5), // Semi-transparent overlay
                borderRadius: BorderRadius.circular(8), // Optional rounded corners
              ),
            ),
          ),
        ],
      ),
    );
  }
}
