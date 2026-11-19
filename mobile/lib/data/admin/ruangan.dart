import 'package:flutter/foundation.dart';

import 'jadwal.dart';

class RuanganRepository extends ChangeNotifier {
  RuanganRepository({List<Ruangan>? seedData})
    : _items = List.of(seedData ?? JadwalMasterData.ruangan);

  final List<Ruangan> _items;

  List<Ruangan> getAll() => List.unmodifiable(_items);

  bool exists(String kode) =>
      _items.any((item) => item.kode.toLowerCase() == kode.toLowerCase());

  void add(Ruangan ruangan) {
    _items.add(ruangan);
    notifyListeners();
  }
}

final ruanganRepository = RuanganRepository();
