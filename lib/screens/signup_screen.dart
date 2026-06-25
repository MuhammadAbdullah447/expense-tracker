import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {

  // ─── Form & Controllers ───
  final _formKey                                  = GlobalKey<FormState>();
  final TextEditingController _nameController     = TextEditingController();
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController  = TextEditingController();

  // ─── Focus Nodes ───
  final FocusNode _nameFocus     = FocusNode();
  final FocusNode _emailFocus    = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus  = FocusNode();

  // ─── State Variables ───
  bool _isLoading          = false;
  bool _passwordVisible    = false;
  bool _confirmVisible     = false;
  bool _nameValid          = false;
  bool _emailValid         = false;
  bool _confirmValid       = false;
  String _passwordStrength = '';
  int _strengthLevel       = 0;

  // ─── Animation Controllers ───
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late List<Animation<double>> _fieldAnimations;

  // ─── Colors ───
  static const primary    = Color(0xFF10B981);
  static const primaryDark= Color(0xFF059669);
  static const bgColor    = Color(0xFFF0FDF4);
  static const textPrimary= Color(0xFF0F172A);
  static const textSecond = Color(0xFF64748B);
  static const borderColor= Color(0xFFE2E8F0);
  static const errorColor = Color(0xFFEF4444);

  final FirebaseAuth      _auth      = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _addListeners();
  }

  // ─── Animations initialize ───
  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // ─── Staggered animations for each field ───
    _fieldAnimations = List.generate(6, (index) {
      final start = index * 0.12;
      final end   = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
  }

  // ─── Real time validation listeners ───
  void _addListeners() {
    _nameController.addListener(() {
      setState(() {
        _nameValid = _nameController.text.trim().length >= 3;
      });
    });

    _emailController.addListener(() {
      final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
      setState(() {
        _emailValid = emailRegex.hasMatch(_emailController.text.trim());
      });
    });

    _passwordController.addListener(() {
      _checkPasswordStrength(_passwordController.text);
    });

    _confirmController.addListener(() {
      setState(() {
        _confirmValid = _confirmController.text == _passwordController.text &&
            _confirmController.text.isNotEmpty;
      });
    });
  }

  // ─── Password strength checker ───
  void _checkPasswordStrength(String password) {
    int strength = 0;
    String label = '';

    if (password.length >= 6) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#\$&*~]'))) strength++;

    if (strength <= 1) label = 'Weak';
    else if (strength == 2) label = 'Fair';
    else if (strength == 3) label = 'Good';
    else label = 'Strong';

    setState(() {
      _strengthLevel   = strength;
      _passwordStrength = password.isEmpty ? '' : label;
    });
  }

  // ─── Signup function ───
  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      setState(() => _isLoading = true);

      try {
        final UserCredential cred =
        await _auth.createUserWithEmailAndPassword(
          email:    _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await cred.user!.updateDisplayName(_nameController.text.trim());

        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'name':      _nameController.text.trim(),
          'email':     _emailController.text.trim(),
          'budget':    50000,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          HapticFeedback.heavyImpact();
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MainScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Something went wrong. Please try again.';
        if (e.code == 'email-already-in-use') {
          message = 'An account already exists with this email.';
        } else if (e.code == 'weak-password') {
          message = 'Password is too weak. Use at least 6 characters.';
        } else if (e.code == 'invalid-email') {
          message = 'Please enter a valid email address.';
        } else if (e.code == 'network-request-failed') {
          message = 'No internet connection. Please check your network.';
        } else if (e.code == 'operation-not-allowed') {
          message = 'Email/password accounts are not enabled.';
        }
        if (mounted) {
          HapticFeedback.vibrate();
          _showErrorSnackbar(message);
        }
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg,
                style: GoogleFonts.poppins(color: Colors.white))),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ─── Keyboard dismiss on tap outside ───
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: FadeTransition(
          opacity: _fadeController,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ─── Top Header ───
                _buildHeader(),

                // ─── Form Card ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ─── Full Name ───
                        _buildAnimatedField(0, _buildNameField()),
                        const SizedBox(height: 20),

                        // ─── Email ───
                        _buildAnimatedField(1, _buildEmailField()),
                        const SizedBox(height: 20),

                        // ─── Password ───
                        _buildAnimatedField(2, _buildPasswordField()),

                        // ─── Strength Indicator ───
                        if (_passwordStrength.isNotEmpty)
                          _buildAnimatedField(3,
                              _buildStrengthIndicator()),

                        const SizedBox(height: 20),

                        // ─── Confirm Password ───
                        _buildAnimatedField(4,
                            _buildConfirmPasswordField()),
                        const SizedBox(height: 32),

                        // ─── Signup Button ───
                        _buildAnimatedField(5, _buildSignupButton()),
                        const SizedBox(height: 20),

                        // ─── Terms ───
                        _buildTermsText(),
                        const SizedBox(height: 20),

                        // ─── Divider ───
                        _buildDivider(),
                        const SizedBox(height: 20),

                        // ─── Login Link ───
                        _buildLoginLink(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Staggered animation wrapper ───
  Widget _buildAnimatedField(int index, Widget child) {
    return AnimatedBuilder(
      animation: _fieldAnimations[index.clamp(0, 5)],
      builder: (context, _) {
        final value = _fieldAnimations[index.clamp(0, 5)].value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  // ─── Header ───
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 55, 24, 35),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF047857)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Icon ───
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Create Account',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Start tracking your expenses today',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.75),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Name Field ───
  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Full Name'),
        const SizedBox(height: 8),
        TextFormField(
          controller:  _nameController,
          focusNode:   _nameFocus,
          textInputAction: TextInputAction.next,
          onEditingComplete: () =>
              FocusScope.of(context).requestFocus(_emailFocus),
          style: GoogleFonts.poppins(
              color: textPrimary, fontSize: 14),
          decoration: _fieldDecoration(
            hint:   'Enter your full name',
            icon:   Icons.person_outline,
            isValid: _nameValid,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            if (value.trim().length < 3) {
              return 'Name must be at least 3 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─── Email Field ───
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Email Address'),
        const SizedBox(height: 8),
        TextFormField(
          controller:      _emailController,
          focusNode:       _emailFocus,
          keyboardType:    TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onEditingComplete: () =>
              FocusScope.of(context).requestFocus(_passwordFocus),
          style: GoogleFonts.poppins(
              color: textPrimary, fontSize: 14),
          decoration: _fieldDecoration(
            hint:    'Enter your email',
            icon:    Icons.email_outlined,
            isValid: _emailValid,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter email';
            }
            final regex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
            if (!regex.hasMatch(value.trim())) {
              return 'Enter valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─── Password Field ───
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Password'),
        const SizedBox(height: 8),
        TextFormField(
          controller:      _passwordController,
          focusNode:       _passwordFocus,
          obscureText:     !_passwordVisible,
          textInputAction: TextInputAction.next,
          onEditingComplete: () =>
              FocusScope.of(context).requestFocus(_confirmFocus),
          style: GoogleFonts.poppins(
              color: textPrimary, fontSize: 14),
          decoration: _fieldDecoration(
            hint: 'Min 6 characters',
            icon: Icons.lock_outline,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: textSecond,
                size: 20,
              ),
              onPressed: () => setState(
                      () => _passwordVisible = !_passwordVisible),
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
        ),
      ],
    );
  }

  // ─── Password Strength Indicator ───
  Widget _buildStrengthIndicator() {
    final colors = [
      Colors.transparent,
      errorColor,
      Colors.orange,
      Colors.amber,
      primary,
    ];

    final strengthColor = colors[_strengthLevel.clamp(0, 4)];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Progress bars ───
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: index < _strengthLevel
                        ? strengthColor
                        : borderColor,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          // ─── Label ───
          Row(
            children: [
              Icon(
                _strengthLevel >= 4
                    ? Icons.check_circle
                    : Icons.info_outline,
                size: 14,
                color: strengthColor,
              ),
              const SizedBox(width: 4),
              Text(
                'Password strength: $_passwordStrength',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: strengthColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Confirm Password Field ───
  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Confirm Password'),
        const SizedBox(height: 8),
        TextFormField(
          controller:      _confirmController,
          focusNode:       _confirmFocus,
          obscureText:     !_confirmVisible,
          textInputAction: TextInputAction.done,
          onEditingComplete: () =>
              FocusScope.of(context).unfocus(),
          style: GoogleFonts.poppins(
              color: textPrimary, fontSize: 14),
          decoration: _fieldDecoration(
            hint:    'Re-enter your password',
            icon:    Icons.lock_outline,
            isValid: _confirmValid,
          ).copyWith(
            suffixIcon: _confirmController.text.isEmpty
                ? IconButton(
              icon: Icon(
                _confirmVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: textSecond,
                size: 20,
              ),
              onPressed: () => setState(
                      () => _confirmVisible = !_confirmVisible),
            )
                : Icon(
              _confirmValid
                  ? Icons.check_circle
                  : Icons.cancel,
              color: _confirmValid ? primary : errorColor,
              size: 22,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please confirm password';
            }
            if (value.trim() != _passwordController.text.trim()) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─── Signup Button ───
  Widget _buildSignupButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _signup,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? null
              : const LinearGradient(
            colors: [primary, primaryDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          color: _isLoading ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isLoading
              ? []
              : [
            BoxShadow(
              color: primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
              : Text(
            'Create Account',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Terms Text ───
  Widget _buildTermsText() {
    return Center(
      child: Text(
        'By creating an account, you agree to our\nTerms of Service and Privacy Policy',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: textSecond,
          height: 1.6,
        ),
      ),
    );
  }

  // ─── Divider ───
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
            child: Divider(color: borderColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: GoogleFonts.poppins(
                fontSize: 13, color: textSecond),
          ),
        ),
        Expanded(
            child: Divider(color: borderColor, thickness: 1)),
      ],
    );
  }

  // ─── Login Link ───
  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
                fontSize: 14, color: textSecond),
            children: [
              const TextSpan(text: 'Already have an account? '),
              TextSpan(
                text: 'Login',
                style: GoogleFonts.poppins(
                  color: primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Label widget ───
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    );
  }

  // ─── Reusable field decoration ───
  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    bool isValid = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
          color: textSecond.withOpacity(0.6), fontSize: 13),
      prefixIcon: Icon(icon, color: textSecond, size: 20),
      suffixIcon: isValid
          ? const Icon(Icons.check_circle,
          color: primary, size: 20)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      errorStyle: GoogleFonts.poppins(
          fontSize: 11, color: errorColor),
    );
  }
}