class Video {
  final int id;
  final String url;
  final String user;
  final String caption;
  int likes;
  final int shares;
  var comments;

  Video({
    required this.id,
    required this.url,
    required this.user,
    required this.caption,
    required this.likes,
    required this.shares,
    required this.comments,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'user': user,
      'caption': caption,
      'likes': likes,
      'shares': shares,
      'comments': comments,
    };
  }

  factory Video.fromUrl(String url, var json) {
    return Video(
      id: json['id'],
      url: url,
      user: json['user'],
      caption: json['caption'],
      likes: json['likes'],
      shares: json['shares'],
      comments: json['comments'] as List,
    );
  }
  // Optionally, add a fromJson factory constructor to easily convert JSON back to a Video instance
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'],
      url: json['url'],
      user: json['user'],
      caption: json['caption'],
      likes: json['likes'],
      shares: json['shares'],
      comments: json['comments'] as List,
    );
  }
}
