class Video {
  final int id;
  final String title;
  final String videoUrl;
  final String? thumbnailUrl; // Tanda tanya artinya boleh kosong (null)
  final String status;
  final DateTime createdAt;

  Video({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.status,
    required this.createdAt,
  });

  // Fungsi buat mengubah data JSON dari Supabase jadi Object Video
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'],
      title: json['title'],
      videoUrl: json['video_url'], // Harus sama persis kayak nama kolom di Supabase
      thumbnailUrl: json['thumbnail_url'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}