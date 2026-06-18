class AnnouncementItem {
  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.courseId,
    required this.courseName,
    required this.postedAt,
    this.messagePreview,
    this.htmlUrl,
    this.authorName,
  });

  final String id;
  final String title;
  final String courseId;
  final String courseName;
  final DateTime postedAt;
  final String? messagePreview;
  final String? htmlUrl;
  final String? authorName;

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    final contextCode = _stringFrom(json['context_code']);
    final contextCourseId =
        contextCode != null && contextCode.startsWith('course_')
        ? contextCode.substring('course_'.length)
        : null;
    final message =
        _stringFrom(json['message_preview']) ?? _plainText(json['message']);

    return AnnouncementItem(
      id: _stringFrom(json['id']) ?? '',
      title: _stringFrom(json['title']) ?? 'Untitled announcement',
      courseId: _stringFrom(json['course_id']) ?? contextCourseId ?? '',
      courseName: _stringFrom(json['course_name']) ?? 'Unknown course',
      postedAt:
          _dateFrom(json['posted_at']) ??
          _dateFrom(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      messagePreview: message,
      htmlUrl: _stringFrom(json['html_url']),
      authorName:
          _stringFrom(json['user_name']) ?? _stringFrom(json['author_name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'course_id': courseId,
      'course_name': courseName,
      'posted_at': postedAt.toUtc().toIso8601String(),
      'message_preview': messagePreview,
      'html_url': htmlUrl,
      'author_name': authorName,
    };
  }
}

String? _stringFrom(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return value.toString();
}

DateTime? _dateFrom(Object? value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

String? _plainText(Object? value) {
  final raw = _stringFrom(value);
  if (raw == null) return null;
  final withoutTags = raw
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (withoutTags.isEmpty) return null;
  return withoutTags.length <= 160
      ? withoutTags
      : '${withoutTags.substring(0, 160)}...';
}
