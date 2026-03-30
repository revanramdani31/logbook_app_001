import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id; // Disimpan sebagai String di Hive

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String date;

  @HiveField(4)
  final String authorId;

  @HiveField(5)
  final String teamId;

  @HiveField(6, defaultValue: 'Public')
  final String visibility; // 'Private' atau 'Public'

  @HiveField(7, defaultValue: 'Software')
  final String category; // Kategori log

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.authorId,
    required this.teamId,
    this.visibility = 'Public', // Default: Public
    this.category = 'Software', // Default: Software
  });

  // [REVERT] Membongkar BSON (Map) dari Cloud menjadi Object Flutter
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      // Konversi ObjectId ke String (oid)
      id: (map['_id'] as ObjectId?)?.oid,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      authorId: map['authorId'] ?? 'unknown_user', // Cegah error null
      teamId: map['teamId'] ?? 'no_team',
      visibility: map['visibility'] ?? 'Public', // Default Public
      category: map['category'] ?? 'Software', // Default Software
    );
  }

  // [CONVERT] Membungkus Object ke dalam "Kardus" (BSON) untuk dikirim ke Cloud
  Map<String, dynamic> toMap() => {
    '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
    'title': title,
    'description': description,
    'date': date,
    'authorId': authorId,
    'teamId': teamId,
    'visibility': visibility,
    'category': category,
  };
}
