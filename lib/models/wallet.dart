class Wallet {
  final int? id;
  final String name;
  final double initialBalance;
  final bool isDefault;
  final int? userId;

  Wallet({
    this.id,
    required this.name,
    this.initialBalance = 0,
    this.isDefault = false,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': initialBalance,
      'isDefault': isDefault ? 1 : 0,
      'userId': userId,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'],
      name: map['name'],
      initialBalance: map['amount'] ?? 0,
      isDefault: map['isDefault'] == 1,
      userId: map['userId'],
    );
  }

  Wallet copyWith({
    int? id,
    String? name,
    double? initialBalance,
    bool? isDefault,
    int? userId,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      isDefault: isDefault ?? this.isDefault,
      userId: userId ?? this.userId,
    );
  }
}