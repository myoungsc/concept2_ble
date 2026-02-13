import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CountdownOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const CountdownOverlay({super.key, required this.onComplete});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  int _count = 5;
  bool _showGo = false;
  Timer? _timer;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 2.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_count > 1) {
        setState(() => _count--);
        _animController.reset();
        _animController.forward();
      } else {
        timer.cancel();
        setState(() => _showGo = true);
        _animController.reset();
        _animController.forward();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _count <= 3 && !_showGo;

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Text(
            _showGo ? 'GO!' : '$_count',
            key: ValueKey(_showGo ? 'go' : _count),
            style: OlympicTextStyles.headline(
              fontSize: _showGo ? 160 : 240,
              color: _showGo
                  ? OlympicColors.statusFinished
                  : isUrgent
                      ? OlympicColors.redOlympic
                      : OlympicColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
