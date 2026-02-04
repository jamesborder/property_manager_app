class Player {

  final String id;

  int cash;

  Player({required this.id, this.cash = 1500});

  bool canAfford(int amount) => cash >= amount;

}
