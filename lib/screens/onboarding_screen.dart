import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {

  // ─── Page Controller ───
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ─── Animation Controllers ───
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double>   _fadeAnimation;
  late Animation<Offset>   _slideAnimation;

  // ─── Colors ───
  static const primary     = Color(0xFF10B981);
  static const primaryDark = Color(0xFF059669);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecond  = Color(0xFF64748B);

  // ─── Onboarding Data ───
  final List<Map<String, dynamic>> _pages = [
    {
      'gradient': [Color(0xFF064E3B), Color(0xFF065F46)],
      'icon':     Icons.account_balance_wallet_outlined,
      'emoji':    '💰',
      'title':    'Track Every Rupee',
      'subtitle': 'Record your daily expenses easily and stay on top of your spending habits.',
      'features': [
        '✅ Add expenses in seconds',
        '✅ Categorize your spending',
        '✅ Add notes to each expense',
      ],
    },
    {
      'gradient': [Color(0xFF1E3A5F), Color(0xFF2D5A8E)],
      'icon':     Icons.bar_chart_rounded,
      'emoji':    '📊',
      'title':    'Visual Analytics',
      'subtitle': 'Beautiful charts and reports help you understand where your money goes.',
      'features': [
        '✅ Pie charts by category',
        '✅ Monthly trend charts',
        '✅ Smart spending insights',
      ],
    },
    {
      'gradient': [Color(0xFF4A1D96), Color(0xFF6D28D9)],
      'icon':     Icons.savings_outlined,
      'emoji':    '🎯',
      'title':    'Budget Control',
      'subtitle': 'Set monthly budgets and get alerts before you overspend.',
      'features': [
        '✅ Set monthly budget',
        '✅ Over-budget warnings',
        '✅ Remaining balance tracker',
      ],
    },
    {
      'gradient': [Color(0xFF065F46), Color(0xFF047857)],
      'icon':     Icons.cloud_done_outlined,
      'emoji':    '☁️',
      'title':    'Secure & Synced',
      'subtitle': 'Your data is safely stored in the cloud and synced across all your devices.',
      'features': [
        '✅ Firebase cloud storage',
        '✅ Secure authentication',
        '✅ Access anywhere, anytime',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
        parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideController, curve: Curves.easeOut));
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    HapticFeedback.heavyImpact();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    // ─── Re-animate on page change ───
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // ─── Page View ───
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) =>
                _buildPage(_pages[index]),
          ),

          // ─── Bottom Controls ───
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  // ─── Single Page ───
  Widget _buildPage(Map<String, dynamic> page) {
    final gradient = page['gradient'] as List<Color>;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  28, 40, 28, 160),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  // ─── Skip button ───
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: _navigateToLogin,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.15),
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white
                                  .withOpacity(0.3)),
                        ),
                        child: Text('Skip',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ─── Icon ───
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius:
                      BorderRadius.circular(28),
                      border: Border.all(
                          color: Colors.white
                              .withOpacity(0.25),
                          width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Text(
                          page['emoji'] as String,
                          style: const TextStyle(
                              fontSize: 36),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ─── Title ───
                  Text(
                    page['title'] as String,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── Subtitle ───
                  Text(
                    page['subtitle'] as String,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ─── Features ───
                  ...(page['features'] as List<String>)
                      .map((feature) => Padding(
                    padding: const EdgeInsets.only(
                        bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.15),
                            borderRadius:
                            BorderRadius.circular(
                                8),
                          ),
                          child: Center(
                            child: Text(
                              feature
                                  .substring(0, 2),
                              style: const TextStyle(
                                  fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          feature.substring(2).trim(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bottom Controls ───
  Widget _buildBottomControls() {
    final isLast = _currentPage == _pages.length - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        children: [

          // ─── Page Indicators ───
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
                  (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(
                    horizontal: 4),
                width: index == _currentPage ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentPage
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─── Next / Get Started Button ───
          GestureDetector(
            onTap: _nextPage,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? 'Get Started' : 'Next',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: (_pages[_currentPage]
                      ['gradient']
                      as List<Color>)[0],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLast
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    color: (_pages[_currentPage]['gradient']
                    as List<Color>)[0],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (!isLast) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _navigateToLogin,
              child: Text(
                'Already have an account? Login',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}