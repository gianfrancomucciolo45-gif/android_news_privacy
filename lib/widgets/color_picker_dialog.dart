import 'package:flutter/material.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final String title;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.title,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color selectedColor;
  late double hue;
  late double saturation;
  late double lightness;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
    final hslColor = HSLColor.fromColor(selectedColor);
    hue = hslColor.hue;
    saturation = hslColor.saturation;
    lightness = hslColor.lightness;
  }

  void _updateColor() {
    setState(() {
      selectedColor = HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
    });
  }

  // Predefined colors
  static const List<Color> presetColors = [
    Color(0xFF6750A4), // Purple
    Color(0xFFEF5350), // Red
    Color(0xFFEC407A), // Pink
    Color(0xFFAB47BC), // Deep Purple
    Color(0xFF5C6BC0), // Indigo
    Color(0xFF42A5F5), // Blue
    Color(0xFF29B6F6), // Light Blue
    Color(0xFF26C6DA), // Cyan
    Color(0xFF26A69A), // Teal
    Color(0xFF66BB6A), // Green
    Color(0xFF9CCC65), // Light Green
    Color(0xFFD4E157), // Lime
    Color(0xFFFFEE58), // Yellow
    Color(0xFFFFCA28), // Amber
    Color(0xFFFFA726), // Orange
    Color(0xFFFF7043), // Deep Orange
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color preview
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Hue slider
            _buildSlider(
              label: 'Hue',
              value: hue,
              max: 360,
              onChanged: (value) {
                setState(() {
                  hue = value;
                  _updateColor();
                });
              },
              gradient: LinearGradient(
                colors: List.generate(
                  7,
                  (index) => HSLColor.fromAHSL(1.0, index * 60.0, 1.0, 0.5).toColor(),
                ),
              ),
            ),
            
            // Saturation slider
            _buildSlider(
              label: 'Saturation',
              value: saturation,
              max: 1,
              onChanged: (value) {
                setState(() {
                  saturation = value;
                  _updateColor();
                });
              },
              gradient: LinearGradient(
                colors: [
                  HSLColor.fromAHSL(1.0, hue, 0.0, lightness).toColor(),
                  HSLColor.fromAHSL(1.0, hue, 1.0, lightness).toColor(),
                ],
              ),
            ),
            
            // Lightness slider
            _buildSlider(
              label: 'Lightness',
              value: lightness,
              max: 1,
              onChanged: (value) {
                setState(() {
                  lightness = value;
                  _updateColor();
                });
              },
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  HSLColor.fromAHSL(1.0, hue, saturation, 0.5).toColor(),
                  Colors.white,
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            // Preset colors
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presetColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = color;
                      final hslColor = HSLColor.fromColor(color);
                      hue = hslColor.hue;
                      saturation = hslColor.saturation;
                      lightness = hslColor.lightness;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == color
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(selectedColor),
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
    required Gradient gradient,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Container(
          height: 32,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 32,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
            ),
            child: Slider(
              value: value,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
