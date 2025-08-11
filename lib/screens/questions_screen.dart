import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuestionsScreen extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? user;

  QuestionsScreen({this.token, this.user});

  @override
  _QuestionsScreenState createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  List<Question> questions = [];
  Map<int, int> answers = {};
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSubmitting = false;
  
  ScrollController _scrollController = ScrollController();
  bool _isHeaderVisible = true;

  final String baseUrl = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final shouldShowHeader = _scrollController.offset < 100;
      if (shouldShowHeader != _isHeaderVisible) {
        setState(() {
          _isHeaderVisible = shouldShowHeader;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/questions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> questionsJson = responseData['data'] ?? responseData;
        
        setState(() {
          questions = questionsJson.map((json) => Question.fromJson(json)).toList();
          questions.sort((a, b) => a.order.compareTo(b.order));
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        _showSnackBar('Gagal memuat pertanyaan', Colors.red);
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      _showSnackBar('Terjadi kesalahan: $e', Colors.red);
    }
  }

  Future<void> _submitAnswers() async {
    if (widget.token == null) {
      _showSnackBar('Token tidak ditemukan. Silakan login ulang.', Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      List<Map<String, dynamic>> responses = [];
      
      answers.forEach((questionId, selectedOptionIndex) {
        responses.add({
          'question_id': questionId,
          'selected_option': selectedOptionIndex,
        });
      });

      final requestBody = {
        'responses': responses,
        'session_id': 'flutter_${DateTime.now().millisecondsSinceEpoch}',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/responses/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final testResult = responseData['data']['test_result'];
        _showResultDialog(testResult);
      } else if (response.statusCode == 409) {
        _showSnackBar(responseData['message'], Colors.orange);
        final existingResponse = responseData['data']['existing_response'];
        _showResultDialog(existingResponse);
      } else {
        _showSnackBar(responseData['message'] ?? 'Gagal mengirim jawaban', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e', Colors.red);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    final totalScore = result['total_score'];
    final riskLevel = result['risk_level'];
    final recommendations = result['recommendations'];

    Color getRiskColor(String risk) {
      switch (risk.toLowerCase()) {
        case 'rendah':
          return Colors.green;
        case 'sedang-tinggi':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    IconData getRiskIcon(String risk) {
      switch (risk.toLowerCase()) {
        case 'rendah':
          return Icons.check_circle;
        case 'sedang-tinggi':
          return Icons.error;
        default:
          return Icons.help;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: getRiskColor(riskLevel).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                getRiskIcon(riskLevel),
                color: getRiskColor(riskLevel),
                size: 28,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Hasil Skrining',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: getRiskColor(riskLevel),
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skor Total
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'Skor Total',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$totalScore',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: getRiskColor(riskLevel),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Tingkat Risiko
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      getRiskColor(riskLevel).withOpacity(0.1),
                      getRiskColor(riskLevel).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: getRiskColor(riskLevel).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Tingkat Risiko',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      riskLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: getRiskColor(riskLevel),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Rekomendasi
              Text(
                'Rekomendasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Text(
                  recommendations ?? 'Tidak ada rekomendasi',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  answers.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: getRiskColor(riskLevel),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'SELESAI',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _selectAnswer(int questionId, int optionIndex) {
    setState(() {
      answers[questionId] = optionIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  color: Colors.blue[600],
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Memuat pertanyaan...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Gagal memuat pertanyaan',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Coba Lagi',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.quiz_outlined,
                  size: 64,
                  color: Colors.blue[400],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Belum ada pertanyaan',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.grey[50]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: _isHeaderVisible ? null : 0,
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: _isHeaderVisible ? 1.0 : 0.0,
                  child: _buildHeader(),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: _buildProgressSection(),
            ),

            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final question = questions[index];
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.only(bottom: 16),
                      child: QuestionCard(
                        question: question,
                        selectedOptionIndex: answers[question.id],
                        onAnswerSelected: (optionIndex) => _selectAnswer(question.id, optionIndex),
                      ),
                    );
                  },
                  childCount: questions.length,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.9), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: _buildSubmitButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
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
                    icon: Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey[700],
                  ),
                ),
                Spacer(),
                Text(
                  'Kuesioner Kesehatan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Spacer(),
                Container(
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
                    icon: Icon(Icons.refresh, size: 20),
                    onPressed: _fetchQuestions,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'SINARA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'KANKER SERVIKS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Sistem riset diagnosis masalah pada kesehatan dan pengamatan alami kesehatan keputihan dengan berbagai kasus.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final progress = answers.length / questions.length;
    
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress Kuesioner',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${answers.length} dari ${questions.length} pertanyaan',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[500]!, Colors.blue[600]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isComplete = answers.length == questions.length;
    
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isComplete && !_isSubmitting ? _submitAnswers : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isComplete ? Colors.blue[600] : Colors.grey[400],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isComplete ? 8 : 2,
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'MENGIRIM...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              )
            : Text(
                isComplete 
                    ? 'DAPATKAN HASIL' 
                    : 'JAWAB SEMUA PERTANYAAN (${answers.length}/${questions.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

class Question {
  final int id;
  final String category;
  final int order;
  final String questionText;
  final List<QuestionOption> options;
  final bool isActive;

  Question({
    required this.id,
    required this.category,
    required this.order,
    required this.questionText,
    required this.options,
    required this.isActive,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final List<dynamic> optionsJson = json['options'] is String 
        ? jsonDecode(json['options']) 
        : json['options'];
        
    return Question(
      id: json['id'],
      category: json['category'],
      order: json['order'],
      questionText: json['question_text'],
      options: optionsJson.map((option) => QuestionOption.fromJson(option)).toList(),
      isActive: json['is_active'] ?? true,
    );
  }
}

class QuestionOption {
  final String text;
  final int score;

  QuestionOption({
    required this.text,
    required this.score,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      text: json['text'],
      score: json['score'],
    );
  }
}

class QuestionCard extends StatelessWidget {
  final Question question;
  final int? selectedOptionIndex;
  final Function(int) onAnswerSelected;

  const QuestionCard({
    Key? key,
    required this.question,
    this.selectedOptionIndex,
    required this.onAnswerSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.blue[100]!.withOpacity(0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[500]!, Colors.blue[600]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${question.order}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            question.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pertanyaan ${question.order}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.questionText,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24),

                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = selectedOptionIndex == index;
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onAnswerSelected(index),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: isSelected 
                                  ? LinearGradient(
                                      colors: [Colors.blue[500]!.withOpacity(0.1), Colors.blue[600]!.withOpacity(0.1)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ] : null,
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isSelected 
                                        ? LinearGradient(
                                            colors: [Colors.blue[500]!, Colors.blue[600]!],
                                          )
                                        : null,
                                    color: isSelected ? null : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? Colors.transparent : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option.text,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? Colors.blue[700] : Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}