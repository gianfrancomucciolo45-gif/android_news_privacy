class BookmarkGroup {
  final String id;
  final String name;
  final List<String> articleLinks; // Link degli articoli in questo gruppo

  BookmarkGroup({
    required this.id,
    required this.name,
    List<String>? articleLinks,
  }) : articleLinks = articleLinks ?? [];

  // Crea da JSON
  factory BookmarkGroup.fromJson(Map<String, dynamic> json) {
    return BookmarkGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      articleLinks: List<String>.from(json['articleLinks'] ?? []),
    );
  }

  // Converti in JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'articleLinks': articleLinks};
  }

  // Copia con modifiche
  BookmarkGroup copyWith({
    String? id,
    String? name,
    List<String>? articleLinks,
  }) {
    return BookmarkGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      articleLinks: articleLinks ?? this.articleLinks,
    );
  }
}
