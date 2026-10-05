import 'package:flutter/material.dart';

/// A coloured label that can be attached to many projects (many-to-many).
class Tag {
  /// Fixed palette so the editor needs no colour-picker dependency.
  static const List<String> palette = [
    '#E53935',
    '#FB8C00',
    '#FDD835',
    '#43A047',
    '#00897B',
    '#1E88E5',
    '#5E35B1',
    '#D81B60',
    '#6D4C41',
    '#546E7A',
  ];

  final String id;
  final String name;
  final String colorHex;
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.createdAt,
  });

  /// Malformed hex (e.g. from a hand-edited import) falls back to grey instead of throwing.
  Color get color {
    try {
      return Color(int.parse('FF${colorHex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Tag copyWith({String? name, String? colorHex}) => Tag(
        id: id,
        name: name ?? this.name,
        colorHex: colorHex ?? this.colorHex,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Tag.fromMap(Map<String, Object?> m) => Tag(
        id: m['id'] as String,
        name: m['name'] as String,
        colorHex: (m['colorHex'] as String?) ?? palette.first,
        createdAt: DateTime.tryParse((m['createdAt'] as String?) ?? '') ??
            DateTime.now(),
      );
}
