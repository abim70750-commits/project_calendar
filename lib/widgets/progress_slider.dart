import 'package:flutter/material.dart';

/// Keeps the drag value locally and only persists when the finger lifts,
/// otherwise every pixel of movement would hit the database.
class ProgressSlider extends StatefulWidget {
  const ProgressSlider({
    super.key,
    required this.value,
    required this.onSaved,
    this.enabled = true,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onSaved;

  @override
  State<ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<ProgressSlider> {
  late double _current = widget.value.toDouble();

  @override
  void didUpdateWidget(covariant ProgressSlider old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _current = widget.value.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progres: ${_current.round()}%',
            style: Theme.of(context).textTheme.titleSmall),
        Slider(
          value: _current,
          min: 0,
          max: 100,
          divisions: 100,
          label: '${_current.round()}%',
          onChanged:
              widget.enabled ? (v) => setState(() => _current = v) : null,
          onChangeEnd: widget.enabled ? (v) => widget.onSaved(v.round()) : null,
        ),
      ],
    );
  }
}
