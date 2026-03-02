import 'package:mongo_dart/mongo_dart.dart'; // Wajib untuk menggunakan ObjectId

class LogModel {
  final ObjectId? id; // Tambahkan ini sebagai Primary Key MongoDB
  final String title;
  final String date;
  final String description;
  final String category;

  LogModel({
    this.id, // Bersifat opsional karena MongoDB bisa generate otomatis
    required this.title,
    required this.date,
    required this.description,
    required this.category,
  });

  // [REVERT] Membongkar BSON (Map) dari Cloud menjadi Object Flutter
  factory LogModel.fromMap(Map<String, dynamic> map) {
    ObjectId? objectId;
    if (map['_id'] != null) {
      if (map['_id'] is ObjectId) {
        objectId = map['_id'] as ObjectId;
      } else if (map['_id'] is String) {
        objectId = ObjectId.fromHexString(map['_id'] as String);
      }
    }

    return LogModel(
      id: objectId, // MongoDB menggunakan field '_id'
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
    );
  }

  // [CONVERT] Membungkus Object ke dalam "Kardus" (BSON) untuk dikirim ke Cloud
  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(), // Gunakan ID yang ada atau buat baru otomatis
      'title': title,
      'date': date,
      'description': description,
      'category': category,
    };
  }
}
