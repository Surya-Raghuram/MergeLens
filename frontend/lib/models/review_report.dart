class ReviewReport {
  final String id;
  final String repoName;
  final int prNumber;
  final String status;
  final String fileChangesSummary;
  final List<dynamic> structuralComments;
  final DateTime createdAt;

  ReviewReport({
    required this.id,
    required this.repoName,
    required this.prNumber,
    required this.status,
    required this.fileChangesSummary,
    required this.structuralComments,
    required this.createdAt,
  });

  factory ReviewReport.fromJson(Map<String, dynamic> json) {
    return ReviewReport(
      id: json['id'] ?? '',
      repoName: json['repo_name'] ?? 'Unknown Repo',
      prNumber: json['pr_number'] ?? 0,
      status: json['status'] ?? 'pending',
      fileChangesSummary: json['file_changes_summary'] ?? 'No summary available.',
      structuralComments: json['structural_comments'] ?? [],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}