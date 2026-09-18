import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/models/review_report.dart';
import 'package:frontend/theme/theme.dart';

class PRReviewDetailScreen extends StatelessWidget {
  const PRReviewDetailScreen({super.key, required this.report});

  final ReviewReport report;

  @override
  Widget build(BuildContext context) {
    final List<ReviewInlineComment> inlineComments =
        report.inlineComments.isNotEmpty
            ? report.inlineComments
            : report.structuralComments
                .whereType<Map<String, dynamic>>()
                .map(
                  (item) => ReviewInlineComment(
                    filePath: item['file_path']?.toString() ??
                        item['path']?.toString() ??
                        'Unknown file',
                    line: item['line'] is int
                        ? item['line'] as int
                        : int.tryParse('${item['line']}') ?? 0,
                    comment: item['comment']?.toString() ??
                        item['body']?.toString() ??
                        '',
                  ),
                )
                .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('PR #${report.prNumber} Review'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool wide = constraints.maxWidth >= 1100;
          final content = SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(report: report),
                const SizedBox(height: 16),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _SummaryCard(report: report)),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _FilesCard(report: report)),
                    ],
                  )
                else ...[
                  _SummaryCard(report: report),
                  const SizedBox(height: 16),
                  _FilesCard(report: report),
                ],
                const SizedBox(height: 16),
                _InlineCommentsCard(comments: inlineComments),
              ],
            ),
          );

          return content;
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.report});

  final ReviewReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.repoName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Pull Request #${report.prNumber}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            _StatusBadge(status: report.status),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final ReviewReport report;

  @override
  Widget build(BuildContext context) {
    final MarkdownStyleSheet styleSheet =
        MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: Theme.of(context)
          .textTheme
          .bodyLarge
          ?.copyWith(height: 1.55, color: AppColors.textPrimary),
      h1: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary),
      h2: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary),
      h3: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(left: BorderSide(color: AppColors.accent, width: 4)),
        borderRadius: BorderRadius.circular(8),
      ),
      blockquotePadding: const EdgeInsets.all(14),
      codeblockPadding: const EdgeInsets.all(14),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFF101214),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      code: GoogleFonts.jetBrainsMono(
        fontSize: 13,
        color: const Color(0xFFF8FAFC),
        backgroundColor: const Color(0x00000000),
      ),
      blockSpacing: 14,
      listBullet: Theme.of(context)
          .textTheme
          .bodyLarge
          ?.copyWith(color: AppColors.accent),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Architectural Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.accent, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            MarkdownBody(
              data: report.architecturalSummary,
              styleSheet: styleSheet,
              selectable: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilesCard extends StatelessWidget {
  const _FilesCard({required this.report});

  final ReviewReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Files Changed',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (report.filesChanged.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'No file metadata available yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              Column(
                children: report.filesChanged.map((file) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.insert_drive_file_rounded,
                                  size: 18, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  file.path,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _MetaChip(label: file.changeType),
                              _MetaChip(label: '+${file.additions}'),
                              _MetaChip(label: '-${file.deletions}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineCommentsCard extends StatelessWidget {
  const _InlineCommentsCard({required this.comments});

  final List<ReviewInlineComment> comments;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inline Comments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (comments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'No inline comments were captured for this review.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              Column(
                children: comments.map((comment) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: AppColors.accent.withOpacity(0.35)),
                            ),
                            child: Text(
                              '${comment.line}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.filePath,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.comment,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        height: 1.45,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final String normalized = status.toLowerCase();
    Color color = AppColors.textSecondary;
    if (normalized == 'completed') {
      color = AppColors.success;
    } else if (normalized == 'processing' || normalized == 'queued') {
      color = AppColors.warning;
    } else if (normalized == 'failed') {
      color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        _formatStatus(normalized),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatStatus(String value) {
    if (value.isEmpty) {
      return 'Unknown';
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
