import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  // ─── Form & Controllers ───
  final _formKey                                  = GlobalKey<FormState>();
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ─── Focus Nodes ───
  final FocusNode _emailFocus    = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  // ─── State Variables ───
  bool _isLoading       = false;
  bool _passwordVisible = false;
  bool _rememberMe      = false;
  bool _emailValid      = false;

  // ─── Animation Controllers ───
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _iconController;
  late List<Animation<double>> _fieldAnimations;
  late Animation<double> _iconScaleAnimation;

  // ─── Colors ───
  static const primary     = Color(0xFF10B981);
  static const primaryDark = Color(0xFF059669);
  static const bgColor     = Color(0xFFF0FDF4);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecond  = Color(0xFF64748B);
  static const borderColor = Color(0xFFE2E8F0);
  static const errorColor  = Color(0xFFEF4444);

  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      duration: const Duration(milliseconds: 700),
    )..forward();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // ─── Icon bounce animation ───
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _iconController, curve: Curves.elasticOut),
    );

    // ─── Staggered field animations ───
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

  // ─── Real time validation ───
  void _addListeners() {
    _emailController.addListener(() {
      final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
      setState(() {
        _emailValid =
            emailRegex.hasMatch(_emailController.text.trim());
      });
    });
  }

  // ─── Login function ───
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      setState(() => _isLoading = true);

      try {
        await _auth.signInWithEmailAndPassword(
          email:    _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          HapticFeedback.heavyImpact();
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MainScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration:
              const Duration(milliseconds: 500),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String msg = 'Something went wrong. Please try again.';
        if (e.code == 'user-not-found') {
          msg = 'No account found with this email address.';
        } else if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          msg = 'Incorrect email or password. Please try again.';
        } else if (e.code == 'invalid-email') {
          msg = 'Please enter a valid email address.';
        } else if (e.code == 'too-many-requests') {
          msg = 'Too many failed attempts. Please try again later.';
        } else if (e.code == 'network-request-failed') {
          msg = 'No internet connection. Please check your network.';
        } else if (e.code == 'user-disabled') {
          msg = 'This account has been disabled. Contact support.';
        }
        if (mounted) {
          HapticFeedback.vibrate();
          _showErrorSnackbar(msg);
        }
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Reset password ───
  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackbar('Please enter your email first');
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(
          email: _emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Password reset email sent!',
                    style: GoogleFonts.poppins(
                        color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(e.message ?? 'Error sending reset email');
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
            Expanded(
              child: Text(msg,
                  style:
                  GoogleFonts.poppins(color: Colors.white)),
            ),
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
    _iconController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: FadeTransition(
          opacity: _fadeController,
          child: SingleChildScrollView(
            child: Column(
              children: [

                // ─── Header ───
                _buildHeader(),

                // ─── Form ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      24, 20, 24, 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        // ─── Email ───
                        _buildAnimatedField(
                            0, _buildEmailField()),
                        const SizedBox(height: 20),

                        // ─── Password ───
                        _buildAnimatedField(
                            1, _buildPasswordField()),
                        const SizedBox(height: 12),

                        // ─── Remember Me + Forgot ───
                        _buildAnimatedField(
                            2, _buildRememberRow()),
                        const SizedBox(height: 28),

                        // ─── Login Button ───
                        _buildAnimatedField(
                            3, _buildLoginButton()),
                        const SizedBox(height: 20),

                        // ─── Divider ───
                        _buildAnimatedField(
                            4, _buildDivider()),
                        const SizedBox(height: 20),

                        // ─── Quick Stats ───
                        _buildAnimatedField(
                            4, _buildQuickStats()),
                        const SizedBox(height: 24),

                        // ─── Signup Link ───
                        _buildAnimatedField(
                            5, _buildSignupLink()),
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
            offset: Offset(0, 24 * (1 - value)),
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
      padding: const EdgeInsets.fromLTRB(24, 55, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E3B),
            Color(0xFF065F46),
            Color(0xFF047857),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ─── Animated Icon ───
          ScaleTransition(
            scale: _iconScaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ─── Welcome text ───
          Text(
            'Welcome Back! 👋',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Login to track your expenses',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.75),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 24),

          // ─── Stats row in header ───
          Row(
            children: [
              _buildHeaderStat('🔒', 'Secure'),
              const SizedBox(width: 12),
              _buildHeaderStat('☁️', 'Cloud Sync'),
              const SizedBox(width: 12),
              _buildHeaderStat('📊', 'Analytics'),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Header stat chip ───
  Widget _buildHeaderStat(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
          textInputAction: TextInputAction.done,
          onEditingComplete: () =>
              FocusScope.of(context).unfocus(),
          style: GoogleFonts.poppins(
              color: textPrimary, fontSize: 14),
          decoration: _fieldDecoration(
            hint: 'Enter your password',
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

  // ─── Remember Me + Forgot Password ───
  Widget _buildRememberRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ─── Remember Me ───
        GestureDetector(
          onTap: () =>
              setState(() => _rememberMe = !_rememberMe),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _rememberMe ? primary : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                    _rememberMe ? primary : borderColor,
                    width: 1.5,
                  ),
                ),
                child: _rememberMe
                    ? const Icon(Icons.check,
                    color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Remember me',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: textSecond,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // ─── Forgot Password ───
        GestureDetector(
          onTap: _resetPassword,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            child: Text(
              'Forgot Password?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Login Button ───
  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _login,
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
            'Login',
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

  // ─── Quick Stats Section ───
  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('📈', 'Track', 'Expenses'),
          _buildVerticalDivider(),
          _buildStatItem('💰', 'Budget', 'Control'),
          _buildVerticalDivider(),
          _buildStatItem('📊', 'Visual', 'Reports'),
        ],
      ),
    );
  }

  // ─── Stat item ───
  Widget _buildStatItem(
      String emoji, String title, String subtitle) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
              fontSize: 10, color: textSecond),
        ),
      ],
    );
  }

  // ─── Vertical divider ───
  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: borderColor,
    );
  }

  // ─── Signup Link ───
  Widget _buildSignupLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const SignupScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
            transitionDuration:
            const Duration(milliseconds: 400),
          ),
        ),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
                fontSize: 14, color: textSecond),
            children: [
              const TextSpan(text: "Don't have an account? "),
              TextSpan(
                text: 'Sign Up',
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
        borderSide:
        const BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
        const BorderSide(color: errorColor, width: 1.5),
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