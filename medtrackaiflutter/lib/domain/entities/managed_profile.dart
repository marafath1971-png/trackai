import 'package:flutter/foundation.dart';

@immutable
class ManagedProfile {
  final String id;
  final String name;
  final String relation; // e.g., 'Child', 'Parent', 'Spouse'
  final String avatar;   // Emoji or icon name
  final String? colorAccent;
  final bool isCritical; // Prioritize alerts for this member
  final DateTime? dateOfBirth;
  final String? gender;
  final String? notes;

  const ManagedProfile({
    required this.id,
    required this.name,
    required this.relation,
    this.avatar = '👨‍⚕️',
    this.colorAccent,
    this.isCritical = false,
    this.dateOfBirth,
    this.gender,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relation': relation,
        'avatar': avatar,
        'colorAccent': colorAccent,
        'isCritical': isCritical,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'notes': notes,
      };

  factory ManagedProfile.fromJson(Map<String, dynamic> j) => ManagedProfile(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        relation: j['relation'] ?? '',
        avatar: j['avatar'] ?? '👤',
        colorAccent: j['colorAccent'],
        isCritical: j['isCritical'] ?? false,
        dateOfBirth: j['dateOfBirth'] != null ? DateTime.parse(j['dateOfBirth']) : null,
        gender: j['gender'],
        notes: j['notes'],
      );

  ManagedProfile copyWith({
    String? id,
    String? name,
    String? relation,
    String? avatar,
    String? colorAccent,
    bool? isCritical,
    DateTime? dateOfBirth,
    String? gender,
    String? notes,
  }) =>
      ManagedProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        relation: relation ?? this.relation,
        avatar: avatar ?? this.avatar,
        colorAccent: colorAccent ?? this.colorAccent,
        isCritical: isCritical ?? this.isCritical,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        notes: notes ?? this.notes,
      );
}
