import 'dart:convert';

class RecentFile {
  final String filePath;
  final String fileName;
  final DateTime lastOpened;

  RecentFile({
    required this.filePath,
    required this.fileName,
    required this.lastOpened,
  });

  Map<String, dynamic> toMap() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'lastOpened': lastOpened.toIso8601String(),
    };
  }

  factory RecentFile.fromMap(Map<String, dynamic> map) {
    return RecentFile(
      filePath: map['filePath'] as String,
      fileName: map['fileName'] as String,
      lastOpened: DateTime.parse(map['lastOpened'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory RecentFile.fromJson(String source) =>
      RecentFile.fromMap(json.decode(source) as Map<String, dynamic>);
}
