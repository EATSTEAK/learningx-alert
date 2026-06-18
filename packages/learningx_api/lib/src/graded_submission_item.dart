enum SubmissionStatus {
  submitted,
  unsubmitted,
  graded,
  pendingReview,
  missing,
  unknown,
}

class GradedSubmissionItem {
  const GradedSubmissionItem({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.assignmentId,
    required this.assignmentName,
    required this.status,
    this.score,
    this.grade,
    this.pointsPossible,
    this.submittedAt,
    this.gradedAt,
    this.htmlUrl,
    this.late = false,
    this.missing = false,
  });

  final String id;
  final String courseId;
  final String courseName;
  final String assignmentId;
  final String assignmentName;
  final SubmissionStatus status;
  final num? score;
  final String? grade;
  final num? pointsPossible;
  final DateTime? submittedAt;
  final DateTime? gradedAt;
  final String? htmlUrl;
  final bool late;
  final bool missing;

  bool get isGraded =>
      status == SubmissionStatus.graded || grade != null || score != null;

  factory GradedSubmissionItem.fromJson(Map<String, dynamic> json) {
    final assignment = _mapFrom(json['assignment']);
    final assignmentId =
        _stringFrom(json['assignment_id']) ??
        _stringFrom(assignment?['id']) ??
        '';
    final courseId =
        _stringFrom(json['course_id']) ??
        _stringFrom(assignment?['course_id']) ??
        '';
    final status = _statusFrom(
      workflowState: _stringFrom(json['workflow_state']),
      missing: json['missing'] == true,
    );

    return GradedSubmissionItem(
      id: _stringFrom(json['id']) ?? '$courseId:$assignmentId',
      courseId: courseId,
      courseName: _stringFrom(json['course_name']) ?? 'Unknown course',
      assignmentId: assignmentId,
      assignmentName:
          _stringFrom(json['assignment_name']) ??
          _stringFrom(assignment?['name']) ??
          _stringFrom(assignment?['title']) ??
          'Untitled assignment',
      status: status,
      score: _numFrom(json['score']),
      grade: _stringFrom(json['grade']),
      pointsPossible: _numFrom(
        json['points_possible'] ?? assignment?['points_possible'],
      ),
      submittedAt: _dateFrom(json['submitted_at']),
      gradedAt: _dateFrom(json['graded_at']) ?? _dateFrom(json['updated_at']),
      htmlUrl:
          _stringFrom(json['html_url']) ??
          _stringFrom(assignment?['html_url']) ??
          _stringFrom(json['preview_url']),
      late: json['late'] == true,
      missing: json['missing'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'course_name': courseName,
      'assignment_id': assignmentId,
      'assignment_name': assignmentName,
      'workflow_state': status.name,
      'score': score,
      'grade': grade,
      'points_possible': pointsPossible,
      'submitted_at': submittedAt?.toUtc().toIso8601String(),
      'graded_at': gradedAt?.toUtc().toIso8601String(),
      'html_url': htmlUrl,
      'late': late,
      'missing': missing,
    };
  }
}

SubmissionStatus _statusFrom({
  required String? workflowState,
  required bool missing,
}) {
  if (missing) return SubmissionStatus.missing;
  return switch (workflowState) {
    'submitted' => SubmissionStatus.submitted,
    'unsubmitted' => SubmissionStatus.unsubmitted,
    'graded' => SubmissionStatus.graded,
    'pending_review' => SubmissionStatus.pendingReview,
    'pendingReview' => SubmissionStatus.pendingReview,
    'missing' => SubmissionStatus.missing,
    _ => SubmissionStatus.unknown,
  };
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

DateTime? _dateFrom(Object? value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
