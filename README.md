# LogBook App - Implementasi Single Responsibility Principle (SRP)


### . **Keuntungan SRP Saat Menambah Fitur History Logger**

#### ✅ **Mudah Dikembangkan**
- Tambahkan `_history`, `_getTime()`, dan `recentHistory` **hanya di Controller**
- Tidak perlu mengubah struktur View sama sekali
- Fitur baru tidak mengganggu kode yang sudah ada

#### ✅ **Tidak Ada Coupling (Keterkaitan Erat)**
- View tidak perlu tahu bagaimana history disimpan atau diformat
- Controller tidak perlu tahu warna atau icon apa yang digunakan
- Keduanya berkomunikasi melalui interface yang jelas

#### ✅ **Mudah Dimodifikasi**
- Ingin ubah format waktu? Edit `_getTime()` di Controller saja
- Ingin ubah warna log? Edit `getColorForLogType()` di View saja
- Ingin limit 10 riwayat? Edit `recentHistory` di Controller saja

```dart
// Contoh: Mudah mengubah limit riwayat
List<LogEntry> get recentHistory {
  return _history.take(10).toList(); // Ubah dari 5 ke 10
}
```

#### ✅ **Type-Safe dengan Enum**
```dart
enum LogType { tambah, kurang, reset }

class LogEntry {
  final LogType type;
  final String message;
  final String time;
}
```
- Tidak ada string hardcoded yang rawan typo
- IDE bisa auto-complete
- Compiler bisa catch error


#### ✅ **Reusable (Bisa Dipakai Ulang)**
`CounterController` bisa digunakan di:
- Mobile app (Flutter)
- Web app
- Desktop app
- CLI app
- View yang berbeda (list view, card view, dll)

---
