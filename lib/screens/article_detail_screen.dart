// lib/screens/article_detail_screen.dart
import 'package:flutter/material.dart';

class Article {
  final int id;
  final String title;
  final String content;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  Article({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      image: json['image'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class ArticleDetailScreen extends StatelessWidget {
  final Article article;
  final String baseUrl;

  const ArticleDetailScreen({
    Key? key,
    required this.article,
    required this.baseUrl,
  }) : super(key: key);

  String? _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '$baseUrl/storage/$cleanPath';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  List<String> _splitContentForImage(String content) {
    // Split content into paragraphs
    final paragraphs = content.split('\n\n');
    if (paragraphs.length <= 2) {
      // If too few paragraphs, split by sentence count
      final sentences = content.split('. ');
      if (sentences.length >= 4) {
        final midPoint = (sentences.length / 2).floor();
        return [
          sentences.sublist(0, midPoint).join('. ') + '.',
          sentences.sublist(midPoint).join('. ')
        ];
      }
      return [content, ''];
    }
    
    final midPoint = (paragraphs.length / 2).floor();
    return [
      paragraphs.sublist(0, midPoint).join('\n\n'),
      paragraphs.sublist(midPoint).join('\n\n')
    ];
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _buildImageUrl(article.image);
    final contentParts = _splitContentForImage(article.content);
    final hasSecondPart = contentParts.length > 1 && contentParts[1].isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey[800],
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 60, bottom: 16, right: 16),
              title: Text(
                'Article',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[50]!,
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
            leading: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => Navigator.pop(context),
                color: Colors.grey[700],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article Header Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          article.title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            height: 1.3,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 20),

                        // Meta information
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: Colors.blue[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    _formatDate(article.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: Colors.green[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${_estimateReadingTime(article.content)} min baca',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Content Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First part of content
                        if (contentParts[0].isNotEmpty)
                          Text(
                            contentParts[0],
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.8,
                              color: Colors.grey[700],
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.justify,
                          ),

                        // Image in the middle (if exists)
                        if (imageUrl != null) ...[
                          SizedBox(height: 32),
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(maxHeight: 250),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Gambar tidak dapat dimuat',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 32),
                        ],

                        // Second part of content (if exists)
                        if (hasSecondPart)
                          Text(
                            contentParts[1],
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.8,
                              color: Colors.grey[700],
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.justify,
                          ),

                        // If no image, show full content
                        if (imageUrl == null && contentParts.length == 1)
                          Text(
                            article.content,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.8,
                              color: Colors.grey[700],
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Publication Info Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue[50]!,
                          Colors.indigo[50]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue[100]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: Colors.blue[600],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dipublikasikan pada',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '${article.createdAt.day}/${article.createdAt.month}/${article.createdAt.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _estimateReadingTime(String content) {
    // Asumsi rata-rata kecepatan baca 200 kata per menit
    final wordCount = content.split(' ').length;
    final readingTime = (wordCount / 200).ceil();
    return readingTime < 1 ? 1 : readingTime;
  }
}