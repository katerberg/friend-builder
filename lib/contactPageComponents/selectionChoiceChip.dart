import 'package:flutter/material.dart';

class SelectionChoiceChip extends StatelessWidget {
  final String label;
  final String selection;
  final void Function(String) onTap;

  SelectionChoiceChip({
    @required this.label,
    @required this.selection,
    @required this.onTap,
  });

  bool _isSelected() => selection == label;

  @override
  Widget build(BuildContext context) {
    print(_isSelected());
    print(Theme.of(context).accentColor);
    return ChoiceChip(
      shape: StadiumBorder(
          side: BorderSide(
              color: _isSelected()
                  ? Theme.of(context).accentColor
                  : Color(0xffcccccc))),
      // shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.all(Radius.elliptical(19999, 99999)),
      //     side: BorderSide()),
      backgroundColor: Colors.white,
      label: Text(label),
      selected: selection == label,
      onSelected: (bool) => onTap(label),
    );
  }
}
