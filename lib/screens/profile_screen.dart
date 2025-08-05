import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const ProfileScreen({required this.token, required this.user, Key? key}) 
      : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _userData;
  bool _isLoading = false;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final String _baseUrl = 'https://sinara.space';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Controllers for edit form
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _alamatController;
  late TextEditingController _umurController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _userData = Map.from(widget.user);
    
    // Initialize controllers with current user data
    _nameController = TextEditingController(text: _userData['name']);
    _emailController = TextEditingController(text: _userData['email']);
    _alamatController = TextEditingController(text: _userData['alamat']);
    _umurController = TextEditingController(text: _userData['umur'].toString());
    _phoneController = TextEditingController(text: _userData['phone']);

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();

    // Save initial auth data to TokenManager
    _initializeTokenManager();
  }

  Future<void> _initializeTokenManager() async {
    await TokenManager.saveAuthData(widget.token, widget.user);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    _umurController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'alamat': _alamatController.text,
          'umur': int.parse(_umurController.text),
          'phone': _phoneController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update TokenManager with new user data
        final newUserData = {
          ..._userData,
          'name': _nameController.text,
          'email': _emailController.text,
          'alamat': _alamatController.text,
          'umur': int.parse(_umurController.text),
          'phone': _phoneController.text,
        };
        
        await TokenManager.saveAuthData(widget.token, newUserData);

        setState(() {
          _userData = newUserData;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        String errorMessage = 'Gagal memperbarui profil';
        if (responseData.containsKey('message')) {
          errorMessage = responseData['message'];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final _passwordFormKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => FadeTransition(
        opacity: _fadeAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Ubah Password', style: TextStyle(color: Colors.blue[800])),
          content: Form(
            key: _passwordFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password Saat Ini',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password saat ini wajib diisi';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password baru wajib diisi';
                    }
                    if (value.length < 6) {
                      return 'Minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Password tidak cocok';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal', style: TextStyle(color: Colors.blue[600])),
            ),
            ElevatedButton(
              onPressed: () {
                if (_passwordFormKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: Text('Simpan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/update-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'current_password': currentPasswordController.text,
          'new_password': newPasswordController.text,
          'new_password_confirmation': confirmPasswordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Clear token and user data after password change
        await TokenManager.clearAuthData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password berhasil diperbarui. Silakan login kembali.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Navigate to LoginScreen
        await Future.delayed(Duration(seconds: 1));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        String errorMessage = 'Gagal memperbarui password';
        if (responseData.containsKey('message')) {
          errorMessage = responseData['message'];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => FadeTransition(
        opacity: _fadeAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Konfirmasi Logout', style: TextStyle(color: Colors.blue[800])),
          content: Text('Apakah Anda yakin ingin keluar dari akun ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal', style: TextStyle(color: Colors.blue[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Ya, Keluar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (shouldLogout != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/logout'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      // Clear TokenManager data regardless of API response
      await TokenManager.clearAuthData();

      if (response.statusCode == 200) {
        await _animationController.reverse();
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout berhasil'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        final responseData = jsonDecode(response.body);
        String errorMessage = 'Gagal logout';
        if (responseData.containsKey('message')) {
          errorMessage = responseData['message'];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // Clear TokenManager data even if API call fails
      await TokenManager.clearAuthData();
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Profil Pengguna', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.blue[600]))
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: _isEditing
                    ? _buildEditForm()
                    : _buildProfileView(),
              ),
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Hero(
            tag: 'profile-avatar',
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue[100],
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.blue[600],
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        Center(
          child: Text(
            _userData['name'],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            _userData['email'],
            style: TextStyle(color: Colors.blue[600]),
          ),
        ),
        SizedBox(height: 32),
        _buildProfileItem(Icons.person, 'Nama Lengkap', _userData['name']),
        _buildProfileItem(Icons.email, 'Email', _userData['email']),
        _buildProfileItem(Icons.home, 'Alamat', _userData['alamat']),
        _buildProfileItem(Icons.cake, 'Umur', _userData['umur'].toString()),
        _buildProfileItem(Icons.phone, 'Telepon', _userData['phone']),
        SizedBox(height: 24),
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _updatePassword,
            icon: Icon(Icons.lock),
            label: Text('Ubah Password'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _logout,
            icon: Icon(Icons.logout),
            label: Text('Keluar'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue[600]),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nama Lengkap',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Nama tidak boleh kosong';
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _alamatController,
            decoration: InputDecoration(
              labelText: 'Alamat',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Alamat tidak boleh kosong';
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _umurController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Umur',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Umur tidak boleh kosong';
              if (int.tryParse(value) == null) return 'Masukkan angka yang valid';
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Nomor Telepon',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Nomor telepon tidak boleh kosong';
              return null;
            },
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: Text('Batal', style: TextStyle(color: Colors.blue[600])),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.blue[600]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  child: Text('Simpan'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}