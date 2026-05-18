import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart';
import 'login_screen.dart';
// ─── Import add karo ───
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ─── Animation Controllers ───
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  // ─── Animations ───
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _navigateToNext();
  }

  // ─── Animations initialize karo ───
  void _initAnimations() {

    // Fade in — poori screen
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Slide up — text ke liye
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    // Scale — icon ke liye
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _scaleController, curve: Curves.elasticOut),
    );

    // Pulse — icon glow effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  // ─── Animations sequence mein start karo ───
  void _startAnimations() async {
    // Icon pehle scale hoga
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) _scaleController.forward();

    // Phir fade in
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _fadeController.forward();

    // Phir text slide up
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _slideController.forward();
  }

  // ─── 3 second baad navigate karo ───
  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final User? user = FirebaseAuth.instance.currentUser;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        user != null ? const MainScreen() : const OnboardingScreen(),
        // ─── Smooth fade transition ───
        transitionsBuilder: (context, animation, secondary, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // ─── Gradient background ───
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDF4), // Light green
              Color(0xFFDCFCE7), // Soft green
              Color(0xFFBBF7D0), // Medium green
            ],
          ),
        ),
        child: Stack(
          children: [

            // ─── Decorative circles background ───
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF059669).withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.3,
              left: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(0.05),
                ),
              ),
            ),

            // ─── Main Content ───
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // ─── Icon Section ───
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: _buildIconSection(),
                      ),
                    ),

                    SizedBox(height: size.height * 0.05),

                    // ─── Text Section — Slide up ───
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildTextSection(),
                      ),
                    ),

                    SizedBox(height: size.height * 0.08),

                    // ─── Features row ───
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildFeaturesRow(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Bottom Section ───
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildBottomSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Icon Section ───
  Widget _buildIconSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981).withOpacity(0.1),
          ),
        ),
        // Middle ring
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981).withOpacity(0.15),
          ),
        ),
        // Inner icon container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF10B981),
                Color(0xFF059669),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.4),
                blurRadius: 25,
                spreadRadius: 5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ─── Text Section ───
  Widget _buildTextSection() {
    return Column(
      children: [
        // ─── Main Title — Google Fonts Poppins ───
        Text(
          'Expense Tracker',
          style: GoogleFonts.poppins(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF064E3B),
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 10),

        // ─── Subtitle ───
        Text(
          'Track. Save. Grow.',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF047857),
            letterSpacing: 3.0,
          ),
        ),

        const SizedBox(height: 20),

        // ─── Divider line ───
        Container(
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Features Row ───
  Widget _buildFeaturesRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFeatureChip(Icons.shield_outlined, 'Secure'),
        const SizedBox(width: 16),
        _buildFeatureChip(Icons.bar_chart, 'Analytics'),
        const SizedBox(width: 16),
        _buildFeatureChip(Icons.notifications_outlined, 'Alerts'),
      ],
    );
  }

  // ─── Feature Chip ───
  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF10B981)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF064E3B),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Section ───
  Widget _buildBottomSection() {
    return Column(
      children: [
        // ─── Loading dots ───
        _buildLoadingDots(),

        const SizedBox(height: 16),

        // ─── Version ───
        Text(
          'v1.0.0',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF047857).withOpacity(0.6),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ─── Animated Loading Dots ───
// ─── Animated Loading Dots ───
  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            // ─── Staggered delay per dot ───
            final delay  = index * 0.25;
            final value  = (_pulseController.value - delay)
                .clamp(0.0, 1.0);
            final sine   = (value * 3.14159).clamp(0.0, 3.14159);
            final bounce = (sine < 0 ? 0.0 : sine) * 8;

            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, -bounce),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(
                        0.4 + value * 0.6),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}