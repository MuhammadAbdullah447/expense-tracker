import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'home_screen.dart';
import 'add_expense_screen.dart';
import 'reports_screen.dart';
import 'login_screen.dart';
import 'search_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin {

  int _currentIndex = 0;

  // ─── Animation for FAB ───
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  // ─── Colors ───
  static const primary     = Color(0xFF10B981);
  static const primaryDark = Color(0xFF059669);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecond  = Color(0xFF64748B);
  static const inactive    = Color(0xFF94A3B8);

  // ─── Screen titles ───
  final List<String> _titles = ['Dashboard', 'Reports'];

  // ─── Nav items ───
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_outlined,     'activeIcon': Icons.home_rounded,    'label': 'Home'},
    {'icon': Icons.bar_chart_outlined,'activeIcon': Icons.bar_chart_rounded,'label': 'Reports'},
  ];

  @override
  void initState() {
    super.initState();

    // ─── Auth ready hone ke baad load karo ───
    Future.microtask(() async {
      await FirebaseAuth.instance.authStateChanges().first;
      if (mounted) {
        context.read<ExpenseProvider>().loadExpenses();
      }
    });

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // ─── Logout ───
  Future<void> _logout() async {
    context.read<ExpenseProvider>().clearData();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ─── Jab tak data load nahi hota, sirf spinner dikhao ───
    final isLoading = context.watch<ExpenseProvider>().isLoading;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: primary,
            strokeWidth: 3,
          ),
        ),
      );
    }

    final List<Widget> screens = [
      const HomeScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // ─── Custom AppBar ───
      appBar: _buildAppBar(),

      // ─── Body ───
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // ─── Bottom Nav ───
      bottomNavigationBar: _buildBottomNav(),

      // ─── FAB ───
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.endFloat,
    );
  }

  // ─── Custom AppBar ───
  PreferredSizeWidget _buildAppBar() {
    final user = FirebaseAuth.instance.currentUser;

    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children: [

                // ─── Menu / Drawer ───
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Scaffold.of(context).openDrawer();
                  },
                  child: Builder(
                    builder: (context) => GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Scaffold.of(context).openDrawer();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // ─── Title ───
                Expanded(
                  child: Text(
                    _titles[_currentIndex],
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // ─── Search ───
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) =>
                        const SearchScreen(),
                        transitionsBuilder:
                            (_, anim, __, child) =>
                            FadeTransition(
                                opacity: anim,
                                child: child),
                        transitionDuration:
                        const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: textPrimary,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ─── Avatar ───
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showProfileSheet();
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primary, primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        // ─── First letter of email ───
                        (user?.email ?? 'M')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  // ─── Bottom Nav ───
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft:  Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft:  Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            HapticFeedback.lightImpact();
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.white,
          selectedItemColor: primary,
          unselectedItemColor: inactive,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          iconSize: 24,
          items: _navItems.map((item) {
            final isActive = _navItems.indexOf(item) ==
                _currentIndex;
            return BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? primary.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isActive
                      ? item['activeIcon']
                      : item['icon'],
                  size: 24,
                ),
              ),
              label: item['label'],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── FAB ───
  Widget _buildFAB() {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.heavyImpact();
        _fabController.forward();
      },
      onTapUp: (_) {
        _fabController.reverse();
        Future.delayed(
          const Duration(milliseconds: 100),
          _navigateToAddExpense,
        );
      },
      onTapCancel: () => _fabController.reverse(),
      child: ScaleTransition(
        scale: _fabAnimation,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primary, primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.45),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  // ─── Navigate to Add Expense ───
  void _navigateToAddExpense() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Scaffold(
          // ─── Same AppBar as main screen ───
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [

                      // ─── Back button ───
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: textPrimary,
                            size: 20,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // ─── Title ───
                      Expanded(
                        child: Text(
                          'Add Expense',
                          style: GoogleFonts.poppins(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      // ─── Search ───
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                const SearchScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            color: textPrimary,
                            size: 20,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ─── Avatar ───
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showProfileSheet();
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primary, primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              (FirebaseAuth.instance
                                  .currentUser
                                  ?.email ??
                                  'M')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: const AddExpenseScreen(),
        ),
        transitionsBuilder: (_, anim, __, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  // ─── Profile Bottom Sheet ───
  void _showProfileSheet() {
    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      // ─── Yeh add karo — sheet scrollable ho jaye ───
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft:  Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ─── Handle ───
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ─── Avatar ───
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primaryDark],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (user?.email ?? 'M')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    user?.displayName ?? user?.email?.split('@')[0] ?? 'User',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),

                  Text(
                    user?.email ??
                        'muhammadabdullah495969@gmail.com',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: textSecond),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),

                  // ─── Menu Items ───
                  _buildSheetItem(
                    Icons.person_outline_rounded,
                    'My Profile',
                    primary,
                        () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),

                  _buildSheetItem(
                    Icons.settings_outlined,
                    'Settings',
                    textSecond,
                        () => Navigator.pop(ctx),
                  ),
                  // _buildSheetItem(
                  //   Icons.help_outline_rounded,
                  //   'Help & Support',
                  //   textSecond,
                  //       () => Navigator.pop(ctx),
                  // ),
                  _buildSheetItem(
                    Icons.info_outline_rounded,
                    'About App',
                    textSecond,
                        () {
                      Navigator.pop(ctx);
                      _showAboutDialog();
                    },
                  ),

                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),

                  // ─── Logout ───
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showLogoutDialog();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.red.shade100),
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: Colors.red.shade600,
                              size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Safe area bottom padding ───
                  SizedBox(
                      height: MediaQuery.of(context)
                          .padding
                          .bottom +
                          16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetItem(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          )),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: Color(0xFF94A3B8)),
      contentPadding: EdgeInsets.zero,
    );
  }

  // ─── Drawer ───
  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ─── Header ───
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 24),
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2),
                  ),
                  child: Center(
                    child: Text(
                      (user?.email ?? 'M')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                    user?.displayName ?? user?.email?.split('@')[0] ?? 'User',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
                Text(
                  user?.email ?? 'muhammadabdullah495969@gmail.com',
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ─── Nav Items ───
          _buildDrawerItem(
            Icons.home_rounded, 'Dashboard', 0 == _currentIndex,
                () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
          ),
          _buildDrawerItem(
            Icons.bar_chart_rounded, 'Reports', 1 == _currentIndex,
                () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            },
          ),
          _buildDrawerItem(
            Icons.add_circle_outline_rounded, 'Add Expense', false,
                () {
              Navigator.pop(context);
              _navigateToAddExpense();
            },
          ),
          _buildDrawerItem(
            Icons.search_rounded, 'Search', false,
                () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SearchScreen()),
              );
            },
          ),

          const Divider(indent: 16, endIndent: 16),
          _buildDrawerItem(
            Icons.history_rounded, 'History', false,
                () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const HistoryScreen()),
              );
            },
          ),
          _buildDrawerItem(
            Icons.settings_outlined, 'Settings', false,
                () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen()),
              );
            },
          ),
          _buildDrawerItem(
            Icons.info_outline_rounded, 'About', false,
                () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),

          const Spacer(),

          // ─── Logout ───
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog();
              },
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.red.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: Colors.red.shade600, size: 18),
                    const SizedBox(width: 8),
                    Text('Logout',
                        style: GoogleFonts.poppins(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('v1.0.0',
                style: GoogleFonts.poppins(
                    color: Colors.grey, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title,
      bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 2),
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive
                ? primary.withOpacity(0.12)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: isActive ? primary : textSecond,
              size: 18),
        ),
        title: Text(title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isActive
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: isActive ? primary : textPrimary,
            )),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        tileColor: isActive
            ? primary.withOpacity(0.06)
            : Colors.transparent,
      ),
    );
  }

  // ─── Logout Dialog ───
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: textSecond)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: Text('Logout',
                style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  // ─── About Dialog ───
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text('About App',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ],
        ),
        content: Text(
          'Personal Expense Tracker\nVersion 1.0.0\n\nTrack your daily expenses easily with beautiful analytics and smart insights.',
          style: GoogleFonts.poppins(
              fontSize: 13, height: 1.6),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}