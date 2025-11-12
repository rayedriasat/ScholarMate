/// Model for PDF metadata
class PDFMetadata {
  final String? title;
  final List<String> authors;
  final int? publicationYear;
  final String? journal;
  final String? conference;
  final String? doi;
  final String? isbn;
  final String? pmid;
  final String? arxivId;
  final String? abstract;
  final List<String> keywords;
  final String? pages;
  final String? volume;
  final String? issue;
  final String? publisher;
  final String? url;
  
  // File-specific metadata
  final String? fileId;
  final String? fileName;
  final int? fileSize;
  final DateTime? createdTime;
  final DateTime? modifiedTime;

  PDFMetadata({
    this.title,
    this.authors = const [],
    this.publicationYear,
    this.journal,
    this.conference,
    this.doi,
    this.isbn,
    this.pmid,
    this.arxivId,
    this.abstract,
    this.keywords = const [],
    this.pages,
    this.volume,
    this.issue,
    this.publisher,
    this.url,
    this.fileId,
    this.fileName,
    this.fileSize,
    this.createdTime,
    this.modifiedTime,
  });

  factory PDFMetadata.fromJson(Map<String, dynamic> json) {
    return PDFMetadata(
      title: json['title'] as String?,
      authors: (json['authors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      publicationYear: json['publication_year'] as int?,
      journal: json['journal'] as String?,
      conference: json['conference'] as String?,
      doi: json['doi'] as String?,
      isbn: json['isbn'] as String?,
      pmid: json['pmid'] as String?,
      arxivId: json['arxiv_id'] as String?,
      abstract: json['abstract'] as String?,
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      pages: json['pages'] as String?,
      volume: json['volume'] as String?,
      issue: json['issue'] as String?,
      publisher: json['publisher'] as String?,
      url: json['url'] as String?,
      fileId: json['file_id'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      createdTime: json['created_time'] != null
          ? DateTime.tryParse(json['created_time'] as String)
          : null,
      modifiedTime: json['modified_time'] != null
          ? DateTime.tryParse(json['modified_time'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'authors': authors,
      'publication_year': publicationYear,
      'journal': journal,
      'conference': conference,
      'doi': doi,
      'isbn': isbn,
      'pmid': pmid,
      'arxiv_id': arxivId,
      'abstract': abstract,
      'keywords': keywords,
      'pages': pages,
      'volume': volume,
      'issue': issue,
      'publisher': publisher,
      'url': url,
      'file_id': fileId,
      'file_name': fileName,
      'file_size': fileSize,
      'created_time': createdTime?.toIso8601String(),
      'modified_time': modifiedTime?.toIso8601String(),
    };
  }

  String get formattedAuthors {
    if (authors.isEmpty) return 'Unknown';
    if (authors.length == 1) return authors[0];
    if (authors.length == 2) return '${authors[0]} & ${authors[1]}';
    return '${authors[0]} et al.';
  }

  String get formattedFileSize {
    if (fileSize == null) return '';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = fileSize!.toDouble();
    int unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unitIndex]}';
  }
}

/// Model for citations in multiple formats
class Citation {
  final String apa;
  final String mla;
  final String chicago;
  final String bibtex;
  final String? harvard;
  final String? vancouver;
  final PDFMetadata? metadata;

  Citation({
    required this.apa,
    required this.mla,
    required this.chicago,
    required this.bibtex,
    this.harvard,
    this.vancouver,
    this.metadata,
  });

  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      apa: json['apa'] as String,
      mla: json['mla'] as String,
      chicago: json['chicago'] as String,
      bibtex: json['bibtex'] as String,
      harvard: json['harvard'] as String?,
      vancouver: json['vancouver'] as String?,
      metadata: json['metadata'] != null
          ? PDFMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apa': apa,
      'mla': mla,
      'chicago': chicago,
      'bibtex': bibtex,
      'harvard': harvard,
      'vancouver': vancouver,
      'metadata': metadata?.toJson(),
    };
  }
}
