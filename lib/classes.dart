import 'package:flutter/foundation.dart';

class Ufficio {
  String nome;
  List<String> headers;
  List<List<String>> entries;
  late int hash;

  Ufficio({required this.nome, required this.headers, required this.entries}) : hash = nome.hashCode ^ headers.hashCode ^ entries.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Ufficio && //
        other.nome == nome && //
        listEquals(other.headers, headers) && //
        listEquals(other.entries, entries);
  }

  @override
  int get hashCode => nome.hashCode ^ headers.hashCode ^ entries.hashCode;
}
