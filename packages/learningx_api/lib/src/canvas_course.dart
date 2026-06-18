class CanvasCourse {
  const CanvasCourse({
    required this.id,
    required this.name,
    this.courseCode,
    this.htmlUrl,
    this.gradesHtmlUrl,
    this.currentScore,
    this.currentGrade,
    this.finalScore,
    this.finalGrade,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String? courseCode;
  final String? htmlUrl;
  final String? gradesHtmlUrl;
  final num? currentScore;
  final String? currentGrade;
  final num? finalScore;
  final String? finalGrade;
  final bool isFavorite;

  factory CanvasCourse.fromJson(Map<String, dynamic> json) {
    final enrollment = _firstStudentEnrollment(json['enrollments']);
    final grades = _mapFrom(enrollment?['grades']) ?? _mapFrom(json['grades']);

    return CanvasCourse(
      id: _stringFrom(json['id']) ?? '',
      name:
          _stringFrom(json['name']) ??
          _stringFrom(json['course_code']) ??
          'Untitled course',
      courseCode: _stringFrom(json['course_code']),
      htmlUrl: _stringFrom(json['html_url']),
      gradesHtmlUrl: _stringFrom(grades?['html_url']),
      currentScore: _numFrom(grades?['current_score'] ?? json['current_score']),
      currentGrade: _stringFrom(
        grades?['current_grade'] ?? json['current_grade'],
      ),
      finalScore: _numFrom(grades?['final_score'] ?? json['final_score']),
      finalGrade: _stringFrom(grades?['final_grade'] ?? json['final_grade']),
      isFavorite: json['is_favorite'] == true || json['favorite'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'course_code': courseCode,
      'html_url': htmlUrl,
      'grades_html_url': gradesHtmlUrl,
      'current_score': currentScore,
      'current_grade': currentGrade,
      'final_score': finalScore,
      'final_grade': finalGrade,
      'is_favorite': isFavorite,
    };
  }
}

Map<String, dynamic>? _firstStudentEnrollment(Object? value) {
  if (value is! List) return null;
  Map<String, dynamic>? fallback;
  for (final row in value) {
    final enrollment = _mapFrom(row);
    if (enrollment == null) continue;
    fallback ??= enrollment;
    if (_stringFrom(enrollment['type']) == 'StudentEnrollment') {
      return enrollment;
    }
  }
  return fallback;
}

Map<String, dynamic>? _mapFrom(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _stringFrom(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return value.toString();
}

num? _numFrom(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}
