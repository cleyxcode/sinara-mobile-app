import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'article_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? user;

  HomeScreen({this.token, this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Article> articles = [];
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final String baseUrl = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _fetchArticles();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchArticles() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/articles'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> articlesJson = responseData['data'] ?? responseData;
        
        setState(() {
          articles = articlesJson.map((json) => Article.fromJson(json)).toList();
          _isLoading = false;
        });
        _animationController.forward(from: 0);
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }



  String? _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '$baseUrl/storage/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Artikel', style: TextStyle(fontWeight: FontWeight.w600)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.view_list,
              progress: _fadeAnimation,
              color: Colors.white,
            ),
            onPressed: _fetchArticles,
          ),
          
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            if (widget.user != null)
              Padding(
                padding: EdgeInsets.all(16),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.blue[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.user!['name'] ?? 'User',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: _buildArticlesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.blue[600],
          backgroundColor: Colors.blue[100],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: _hasError ? 1.0 : 0.0,
              duration: Duration(milliseconds: 500),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Gagal memuat artikel',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchArticles,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Coba Lagi', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    }

    if (articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: articles.isEmpty ? 1.0 : 0.0,
              duration: Duration(milliseconds: 500),
              child: Icon(
                Icons.article_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada artikel',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchArticles,
      color: Colors.blue[600],
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return AnimatedArticleCard(
            article: article,
            baseUrl: baseUrl,
            index: index,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailScreen(
                    article: article,
                    baseUrl: baseUrl,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AnimatedArticleCard extends StatefulWidget {
  final Article article;
  final String baseUrl;
  final int index;
  final VoidCallback onTap;

  const AnimatedArticleCard({
    Key? key,
    required this.article,
    required this.baseUrl,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  @override
  _AnimatedArticleCardState createState() => _AnimatedArticleCardState();
}

class _AnimatedArticleCardState extends State<AnimatedArticleCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '${widget.baseUrl}/storage/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _buildImageUrl(widget.article.image);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _isHovered ? 1.02 : _scaleAnimation.value,
            child: Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: _isHovered ? 8 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.grey[300]!, Colors.grey[400]!],
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported, size: 40, color: Colors.grey[600]),
                                      SizedBox(height: 8),
                                      Text(
                                        'Gambar tidak dapat dimuat',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.blue[600],
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.article.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.article.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                              SizedBox(width: 4),
                              Text(
                                _formatDate(widget.article.createdAt),
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                              Spacer(),
                              AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                transform: Matrix4.translationValues(_isHovered ? 5 : 0, 0, 0),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
}