class ReviewReport {
  final String id;
  final String repoName;
  final int prNumber;
  final String status;
  final String fileChangesSummary;
  final String architecturalSummary;
  final List<ReviewFileChange> filesChanged;
  final List<dynamic> structuralComments;
  final List<ReviewInlineComment> inlineComments;
  final DateTime createdAt;

  ReviewReport({
    required this.id,
    required this.repoName,
    required this.prNumber,
    required this.status,
    required this.fileChangesSummary,
    required this.architecturalSummary,
    required this.filesChanged,
    required this.structuralComments,
    required this.inlineComments,
    required this.createdAt,
  });

  factory ReviewReport.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawFiles =
        json['changed_files'] ?? json['files_changed'] ?? [];
    final List<dynamic> rawInlineComments = json['inline_comments'] ?? [];

    return ReviewReport(
      id: json['id'] ?? '',
      repoName: json['repo_name'] ?? 'Unknown Repo',
      prNumber: json['pr_number'] ?? 0,
      status: json['status'] ?? 'pending',
      fileChangesSummary:
          json['file_changes_summary'] ?? 'No summary available.',
      architecturalSummary: json['architectural_summary'] ??
          json['file_changes_summary'] ??
          'No summary available.',
      filesChanged:
          rawFiles.map((item) => ReviewFileChange.fromJson(item)).toList(),
      structuralComments: json['structural_comments'] ?? [],
      inlineComments: rawInlineComments
          .map((item) => ReviewInlineComment.fromJson(item))
          .toList(),
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ReviewFileChange {
  final String path;
  final String changeType;
  final int additions;
  final int deletions;

  ReviewFileChange({
    required this.path,
    required this.changeType,
    required this.additions,
    required this.deletions,
  });

  factory ReviewFileChange.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return ReviewFileChange(
        path: json['path'] ?? json['file_path'] ?? 'Unknown file',
        changeType: json['change_type'] ?? json['type'] ?? 'modified',
        additions: json['additions'] ?? 0,
        deletions: json['deletions'] ?? 0,
      );
    }

    return ReviewFileChange(
      path: json?.toString() ?? 'Unknown file',
      changeType: 'modified',
      additions: 0,
      deletions: 0,
    );
  }
}

class ReviewInlineComment {
  final String filePath;
  final int line;
  final String comment;
  final String severity;
  final String title;

  ReviewInlineComment({
    required this.filePath,
    required this.line,
    required this.comment,
    this.severity = 'info',
    this.title = 'Review note',
  });

  factory ReviewInlineComment.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final String normalizedSeverity = (json['severity'] ?? json['level'] ?? 'info')
          .toString()
          .toLowerCase();
      final String normalizedComment =
          json['comment']?.toString() ?? json['body']?.toString() ?? '';

      return ReviewInlineComment(
        filePath: json['file_path'] ?? json['path'] ?? 'Unknown file',
        line: json['line'] is int
            ? json['line'] as int
            : int.tryParse('${json['line']}') ?? 0,
        comment: normalizedComment,
        severity: normalizedSeverity,
        title: json['title']?.toString() ??
            json['summary']?.toString() ??
            'Review note',
      );
    }

    return ReviewInlineComment(
      filePath: 'Unknown file',
      line: 0,
      comment: json?.toString() ?? '',
    );
  }
}
