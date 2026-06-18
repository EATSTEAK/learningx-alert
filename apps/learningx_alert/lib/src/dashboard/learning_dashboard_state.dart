import 'package:learningx_api/learningx_api.dart';

enum DashboardSection { courses, deadlines, announcements, grades }

class DashboardSectionError {
  const DashboardSectionError({
    required this.section,
    required this.message,
    this.courseName,
  });

  final DashboardSection section;
  final String message;
  final String? courseName;

  String get displayText {
    final prefix = courseName == null
        ? section.label
        : '${section.label}($courseName)';
    return '$prefix: $message';
  }
}

class LearningDashboardState {
  const LearningDashboardState({
    required this.courses,
    required this.deadlines,
    required this.announcements,
    required this.gradedSubmissions,
    required this.lastSyncAt,
    this.sectionErrors = const [],
    this.newAnnouncementIds = const {},
    this.changedGradeIds = const {},
    this.changedDeadlineIds = const {},
  });

  factory LearningDashboardState.empty() {
    return const LearningDashboardState(
      courses: [],
      deadlines: [],
      announcements: [],
      gradedSubmissions: [],
      lastSyncAt: null,
    );
  }

  final List<CanvasCourse> courses;
  final List<LearningItem> deadlines;
  final List<AnnouncementItem> announcements;
  final List<GradedSubmissionItem> gradedSubmissions;
  final DateTime? lastSyncAt;
  final List<DashboardSectionError> sectionErrors;
  final Set<String> newAnnouncementIds;
  final Set<String> changedGradeIds;
  final Set<String> changedDeadlineIds;

  bool get hasSectionErrors => sectionErrors.isNotEmpty;

  bool get hasData {
    return deadlines.isNotEmpty ||
        announcements.isNotEmpty ||
        gradedSubmissions.isNotEmpty;
  }
}

extension DashboardSectionLabel on DashboardSection {
  String get label {
    return switch (this) {
      DashboardSection.courses => '과목',
      DashboardSection.deadlines => '마감',
      DashboardSection.announcements => '공지',
      DashboardSection.grades => '성적',
    };
  }
}
