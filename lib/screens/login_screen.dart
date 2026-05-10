import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import 'main_screen.dart';

// ─── Login Screen — Firebase Auth ✅ ───
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  // Form key — validation ke liye
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State variables
  bool _isLoading       = false;
  bool _passwordVisible = false;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Login function — Firebase Auth ───
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Login successful — main screen pe jao
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        // Error handle karo
        String message = 'Something went wrong';
        if (e.code == 'user-not-found') {
          message = 'No account found with this email';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email address';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Reset password function ───
  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Password reset email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Error sending reset email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [

            // ─── Top header ───
            _buildHeader(),

            // ─── Form ───
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Email field
                    _buildLabel('Email'),
                    _buildEmailField(),
                    const SizedBox(height: 16),

                    // Password field
                    _buildLabel('Password'),
                    _buildPasswordField(),
                    const SizedBox(height: 8),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Color(0xFF1E3A5F)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login button
                    _buildLoginButton(),

                    const SizedBox(height: 16),

                    // Signup link
                    _buildSignupLink(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A5F),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome Back!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Login to track your expenses',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ─── Label ───
  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Color(0xFF1E3A5F),
      ),
    ),
  );

  // ─── Email field ───
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _inputDecoration('Enter your email', Icons.email_outlined),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter email';
        }
        // Email regex validation
        final RegExp emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
        if (!emailRegex.hasMatch(value.trim())) {
          return 'Enter valid email address';
        }
        return null;
      },
    );
  }

  // ─── Password field ───
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_passwordVisible,
      decoration: _inputDecoration(
        'Enter your password',
        Icons.lock_outlined,
      ).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () =>
              setState(() => _passwordVisible = !_passwordVisible),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter password';
        }
        if (value.trim().length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  // ─── Login button ───
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A5F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
        ),
        onPressed: _isLoading ? null : _login,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          'Login',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ─── Signup link ───
  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignupScreen()),
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(
              color: Color(0xFF1E3A5F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Reusable input decoration ───
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF1E3A5F)),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: Color(0xFF1E3A5F), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}