/// Model for RAG indexing job status
class IndexingJob {
  final String jobId;
  final String userId;
  final String fileId;
  final String status; // pending, processing, completed, failed
  final int chunksProcessed;
  final int? totalChunks;
  final double progressPercentage;
  final String? errorMessage;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  IndexingJob({
    required this.jobId,
    required this.userId,
    required this.fileId,
    required this.status,
    this.chunksProcessed = 0,
    this.totalChunks,
    this.progressPercentage = 0.0,
    this.errorMessage,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
  });

  factory IndexingJob.fromJson(Map<String, dynamic> json) {
    return IndexingJob(
      jobId: json['job_id'] as String,
      userId: json['user_id'] as String,
      fileId: json['file_id'] as String,
      status: json['status'] as String,
      chunksProcessed: json['chunks_processed'] as int? ?? 0,
      totalChunks: json['total_chunks'] as int?,
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      errorMessage: json['error_message'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'user_id': userId,
      'file_id': fileId,
      'status': status,
      'chunks_processed': chunksProcessed,
      'total_chunks': totalChunks,
      'progress_percentage': progressPercentage,
      'error_message': errorMessage,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isActive => isPending || isProcessing;
}
