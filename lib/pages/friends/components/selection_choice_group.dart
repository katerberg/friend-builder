import 'package:flutter/material.dart';
import 'package:friend_builder/pages/friends/components/selection_choice_chip.dart';

class SelectionChoiceGroup extends StatelessWidget {
  final List<String> choices;
  final String label;
  final String selection;
  final void Function(String label, String choice) onSelect;

  const SelectionChoiceGroup({
    super.key,
    required this.label,
    required this.choices,
    required this.selection,
    required this.onSelect,
  });

  void _handleSelectionTap(String selectedItem) {
    onSelect(label, selectedItem);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 0, 8),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 8.0, // gap between adjacent chips
            runSpacing: 4.0, // gap between lines
            children: choices
                .map((c) => SelectionChoiceChip(
                    label: c, selection: selection, onTap: _handleSelectionTap))
                .toList()),
      ),
    ]);
  }
}
