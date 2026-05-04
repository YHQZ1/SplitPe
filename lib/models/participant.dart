class Participant {
  String name;
  double amount;

  Participant({required this.name, required this.amount});

  Participant copyWith({String? name, double? amount}) {
    return Participant(
      name: name ?? this.name,
      amount: amount ?? this.amount,
    );
  }
}