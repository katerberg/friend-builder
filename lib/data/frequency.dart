class Frequency {
  String type;
  int value;

  Frequency({
    required this.type,
    required this.value,
  });

  factory Frequency.fromType(String type) {
    switch (type) {
      case 'Weekly':
        return Frequency(type: type, value: 7);
      case 'Monthly':
        return Frequency(type: type, value: 31);
      case 'Quarterly':
        return Frequency(type: type, value: 91);
      case 'Yearly':
        return Frequency(type: type, value: 365);
      case 'Custom':
        return Frequency(
            type: type,
            value:
                14); // Always overwritten by value from contact scheduling dialog
      default:
        return Frequency(type: 'Yearly', value: 365);
    }
  }

  factory Frequency.fromJson(Map<String, dynamic> json) {
    return Frequency(
      type: json['type'] ?? 'Weekly',
      value: json['value'] ?? 7,
    );
  }

  factory Frequency.fromString(String frequencyString) {
    return Frequency.fromType(frequencyString);
  }

  factory Frequency.fromValue(int value) {
    return Frequency(type: 'Custom', value: value);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
    };
  }

  @override
  String toString() {
    return type;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Frequency && other.type == type && other.value == value;
  }

  @override
  int get hashCode => type.hashCode ^ value.hashCode;
}
