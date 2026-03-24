import 'dart:async';

import 'package:flutter/material.dart';

class LoadingDotsText extends StatefulWidget {
  const LoadingDotsText({
    super.key,
    required this.label,
    this.style,
    this.interval = const Duration(milliseconds: 350),
  });

  final String label;
  final TextStyle? style;
  final Duration interval;

  @override
  State<LoadingDotsText> createState() => _LoadingDotsTextState();
}

class _LoadingDotsTextState extends State<LoadingDotsText> {
  late final Timer _timer;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() {
        _dotCount = _dotCount == 3 ? 1 : _dotCount + 1;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: widget.style),
        const SizedBox(width: 2),
        SizedBox(
          width: 20,
          child: Text(
            '.' * _dotCount,
            style: widget.style,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}
