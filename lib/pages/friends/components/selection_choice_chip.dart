import 'package:flutter/material.dart';

class SelectionChoiceChip extends StatelessWidget {
  final String label;
  final String selection;
  final void Function(String) onTap;

  const SelectionChoiceChip({
    super.key,
    required this.label,
    required this.selection,
    required this.onTap,
  });

  bool _isSelected() => selection == label;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      shape: StadiumBorder(
          side: BorderSide(
              color: _isSelected()
                  ? Theme.of(context).colorScheme.secondary
                  : const Color(0xffcccccc))),
      backgroundColor: Colors.white,
      label: Text(label),
      selected: selection == label,
      onSelected: (boolValue) => onTap(label),
    );
  }
}
