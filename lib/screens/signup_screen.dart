import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';

// ─── Signup Screen — Firebase Auth ✅ ───
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController     = TextEditingController();
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController  = TextEditingController();

  bool _isLoading       = false;
  bool _passwordVisible = false;

  final FirebaseAuth      _auth      = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ─── Signup function — Firebase Auth + Firestore ───
  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Firebase Auth mein user banao
        final UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Firestore mein user data save karo
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name':      _nameController.text.trim(),
          'email':     _emailController.text.trim(),
          'budget':    50000,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Signup successful — main screen pe jao
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Something went wrong';
        if (e.code == 'email-already-in-use') {
          message = 'Account already exists with this email';
        } else if (e.code == 'weak-password') {
          message = 'Password is too weak';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Full Name'),
                    _buildNameField(),
                    const SizedBox(height: 16),

                    _buildLabel('Email'),
                    _buildEmailField(),
                    const SizedBox(height: 16),

                    _buildLabel('Password'),
                    _buildPasswordField(),
                    const SizedBox(height: 16),

                    _buildLabel('Confirm Password'),
                    _buildConfirmPasswordField(),
                    const SizedBox(height: 30),

                    _buildSignupButton(),
                    const SizedBox(height: 16),
                    _buildLoginLink(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            'Create Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start tracking your expenses today',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

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

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: _inputDecoration('Enter your full name', Icons.person_outlined),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your name';
        }
        if (value.trim().length < 3) {
          return 'Name must be at least 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _inputDecoration('Enter your email', Icons.email_outlined),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter email';
        }
        final RegExp emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
        if (!emailRegex.hasMatch(value.trim())) {
          return 'Enter valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_passwordVisible,
      decoration: _inputDecoration(
        'Enter password (min 6 chars)',
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

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmController,
      obscureText: true,
      decoration:
      _inputDecoration('Confirm your password', Icons.lock_outlined),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please confirm password';
        }
        if (value.trim() != _passwordController.text.trim()) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildSignupButton() {
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
        onPressed: _isLoading ? null : _signup,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          'Create Account',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? '),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Login',
            style: TextStyle(
              color: Color(0xFF1E3A5F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

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