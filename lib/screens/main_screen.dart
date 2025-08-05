import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'questions_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  static String? _memoryToken;
  static Map<String, dynamic>? _memoryUser;

  static Future<void> saveAuthData(String token, Map<String, dynamic> user) async {
    _memoryToken = token;
    _memoryUser = user;
    print('TokenManager: Data saved - Token: $token, User: $user');
  }

  static Future<String?> getToken() async {
    print('TokenManager: Retrieved token: $_memoryToken');
    return _memoryToken;
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    print('TokenManager: Retrieved user: $_memoryUser');
    return _memoryUser;
  }

  static Future<void> clearAuthData() async {
    _memoryToken = null;
    _memoryUser = null;
    print('TokenManager: Auth data cleared');
  }

  static Future<bool> isLoggedIn() async {
    final isLoggedIn = _memoryToken != null && _memoryToken!.isNotEmpty;
    print('TokenManager: Is logged in: $isLoggedIn');
    return isLoggedIn;
  }
}

class MainScreen extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? user;

  MainScreen({this.token, this.user});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    print('MainScreen: Initializing auth...');
    
    try {
      // Prioritaskan data dari widget parameter
      _token = widget.token;
      _user = widget.user;
      
      print('MainScreen: Widget token: ${widget.token}');
      print('MainScreen: Widget user: ${widget.user}');
      
      // Jika tidak ada token dari widget, coba ambil dari route arguments
      if (_token == null || _user == null) {
        print('MainScreen: No widget data, checking route arguments...');
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          _token = _token ?? args['token'];
          _user = _user ?? args['user'];
          print('MainScreen: Route args token: ${args['token']}');
          print('MainScreen: Route args user: ${args['user']}');
        }
      }
      
      // Jika masih tidak ada, coba ambil dari TokenManager
      if (_token == null || _user == null) {
        print('MainScreen: No data found, checking TokenManager...');
        final token = await TokenManager.getToken();
        final user = await TokenManager.getUserData();
        _token = _token ?? token;
        _user = _user ?? user;
        print('MainScreen: TokenManager token: $token');
        print('MainScreen: TokenManager user: $user');
      }
      
      print('MainScreen: Final token: $_token');
      print('MainScreen: Final user: $_user');
      
      setState(() {
        _isLoading = false;
        _hasError = _token == null;
      });
      
    } catch (e) {
      print('MainScreen: Error initializing auth: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    // Clear token menggunakan TokenManager
    await TokenManager.clearAuthData();
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.green[600],
              ),
              SizedBox(height: 16),
              Text(
                'Memuat data...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Error state - Token tidak ada
    if (_hasError || _token == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Error'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                SizedBox(height: 16),
                Text(
                  'Token tidak ditemukan!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Silakan login ulang',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                
                // Debug info
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug Info:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Widget Token: ${widget.token}',
                        style: TextStyle(fontSize: 10),
                      ),
                      Text(
                        'Widget User: ${widget.user}',
                        style: TextStyle(fontSize: 10),
                      ),
                      Text(
                        'Final Token: $_token',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Login Ulang'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Success state - Token ada
    final List<Widget> pages = [
      HomeScreen(token: _token!, user: _user!),
      QuestionsScreen(token: _token!, user: _user!),
      ProfileScreen(token: _token!, user: _user!),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green[600],
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 11,
          ),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: _selectedIndex == 0
                      ? Colors.green[600]!.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _selectedIndex == 0 ? Icons.article : Icons.article_outlined,
                  size: 24,
                ),
              ),
              label: 'Artikel',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: _selectedIndex == 1
                      ? Colors.green[600]!.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _selectedIndex == 1 ? Icons.quiz : Icons.quiz_outlined,
                  size: 24,
                ),
              ),
              label: 'Kuesioner',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: _selectedIndex == 2
                      ? Colors.green[600]!.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _selectedIndex == 2 ? Icons.person : Icons.person_outline,
                  size: 24,
                ),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}