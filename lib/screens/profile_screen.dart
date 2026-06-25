import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {

  // ─── Animation ───
  late AnimationController _fadeController;
  late Animation<double>   _fadeAnimation;

  // ─── Firebase ───
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Controllers ───
  final TextEditingController _nameController =
  TextEditingController();

  bool _isEditingName = false;
  bool _isLoading     = false;

  // ─── Get real user name ───
  String _getUserName(User? user) {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return 'User';
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
        parent: _fadeController, curve: Curves.easeIn));

    _nameController.text = _getUserName(_auth.currentUser);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ─── Password change ───
  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user?.email == null) return;

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(
          email: user!.email!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Password reset email sent to ${user.email}',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}',
                style: GoogleFonts.poppins(
                    color: Colors.white)),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user     = _auth.currentUser;
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [

              // ─── Header ───
              _buildHeader(user),

              const SizedBox(height: 20),

              // ─── Stats Cards ───
              _buildStatsRow(provider),

              const SizedBox(height: 20),

              // ─── Account Info ───
              _buildSection(
                icon:  Icons.person_outline_rounded,
                color: AppColors.primary,
                title: 'Account Information',
                items: [
                  _buildInfoTile(
                    icon:     Icons.person_outline_rounded,
                    iconColor: AppColors.primary,
                    title:    'Full Name',
                    value: _getUserName(user),
                  ),
                  _buildInfoTile(
                    icon:     Icons.email_outlined,
                    iconColor: const Color(0xFF6366F1),
                    title:    'Email',
                    value:    user?.email ??
                        AppConstants.developerEmail,
                  ),
                  _buildInfoTile(
                    icon:     Icons.calendar_today_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    title:    'Member Since',
                    value:    _getMemberSince(user),
                  ),
                  _buildInfoTile(
                    icon:     Icons.verified_outlined,
                    iconColor: AppColors.primary,
                    title:    'Account Status',
                    value:    'Active ✅',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ─── Security ───
              _buildSection(
                icon:  Icons.security_outlined,
                color: const Color(0xFF6366F1),
                title: 'Security',
                items: [
                  _buildActionTile(
                    icon:      Icons.lock_outline_rounded,
                    iconColor: const Color(0xFF6366F1),
                    iconBg:    const Color(0xFFEEF2FF),
                    title:     'Change Password',
                    subtitle:  'Send password reset email',
                    onTap:     _showPasswordChangeDialog,
                  ),
                  _buildActionTile(
                    icon:      Icons.shield_outlined,
                    iconColor: AppColors.primary,
                    iconBg:    AppColors.primaryLight,
                    title:     'Two-Factor Auth',
                    subtitle:  'Coming soon',
                    onTap:     () => _showComingSoon(
                        '2FA will be available soon'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ─── Expense Summary ───
              _buildSection(
                icon:  Icons.bar_chart_outlined,
                color: const Color(0xFFF59E0B),
                title: 'Expense Summary',
                items: [
                  _buildStatTile(
                    icon:      Icons.receipt_outlined,
                    iconColor: const Color(0xFF2196F3),
                    iconBg:    const Color(0xFFE3F2FD),
                    title:     'Total Expenses',
                    value:
                    '${provider.expenses.length} records',
                  ),
                  _buildStatTile(
                    icon:      Icons.payments_outlined,
                    iconColor: AppColors.errorColor,
                    iconBg:    const Color(0xFFFFEBEE),
                    title:     'Total Spent',
                    value:
                    'Rs. ${AppConstants.formatAmount(provider.totalSpent)}',
                  ),
                  _buildStatTile(
                    icon:      Icons.savings_outlined,
                    iconColor: AppColors.primary,
                    iconBg:    AppColors.primaryLight,
                    title:     'Remaining Budget',
                    value:
                    'Rs. ${AppConstants.formatAmount(provider.remaining.abs())}',
                  ),
                  _buildStatTile(
                    icon:      Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBg:    const Color(0xFFEDE9FE),
                    title:     'Monthly Budget',
                    value:
                    'Rs. ${AppConstants.formatAmount(provider.budget)}',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ─── App Info ───
              _buildSection(
                icon:  Icons.info_outline_rounded,
                color: AppColors.textSecond,
                title: 'App Information',
                items: [
                  _buildInfoTile(
                    icon:     Icons.app_settings_alt_outlined,
                    iconColor: AppColors.textSecond,
                    title:    'App Version',
                    value:    AppConstants.appVersion,
                  ),
                  _buildInfoTile(
                    icon:     Icons.school_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    title:    'Course',
                    value:    'Mobile App Dev',
                  ),
                  _buildInfoTile(
                    icon:     Icons.code_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    title:    'Built With',
                    value:    'Flutter + Firebase',
                  ),
                ],
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(User? user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16,
          20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [

          // ─── Back button row ───
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Text('My Profile',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Avatar ───
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 3),
                ),
                child: Center(
                  child: Text(
                    (user?.email ?? 'M')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              // ─── Online indicator ───
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            _getUserName(user),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            user?.email ?? AppConstants.developerEmail,
            style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 12),

          // ─── Verified badge ───
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text('Verified Account',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Row ───
  Widget _buildStatsRow(ExpenseProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard(
            '📊',
            '${provider.expenses.length}',
            'Expenses',
            AppColors.primary,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            '💰',
            'Rs.${AppConstants.formatAmount(provider.totalSpent)}',
            'Spent',
            AppColors.errorColor,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            '🏦',
            'Rs.${AppConstants.formatAmount(provider.budget)}',
            'Budget',
            const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji,
                style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textSecond)),
          ],
        ),
      ),
    );
  }

  // ─── Section ───
  Widget _buildSection({
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                left: 4, bottom: 10),
            child: Row(
              children: [
                Icon(icon, color: color, size: 15),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    )),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final i    = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    item,
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        indent: 56,
                        color: Colors.grey.shade100,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info Tile ───
  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecond,
          )),
      subtitle: Text(value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          )),
    );
  }

  // ─── Stat Tile ───
  Widget _buildStatTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecond,
          )),
      trailing: Text(value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: iconColor,
          )),
    );
  }

  // ─── Action Tile ───
  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          )),
      subtitle: Text(subtitle,
          style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecond)),
      trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Color(0xFF94A3B8)),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }

  // ─── Password Change Dialog ───
  void _showPasswordChangeDialog() {
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
                color: const Color(0xFF6366F1)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 10),
            Text('Change Password',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                )),
          ],
        ),
        content: Text(
          'A password reset link will be sent to your email address.\n\n${_auth.currentUser?.email ?? ''}',
          style: GoogleFonts.poppins(
              fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecond)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _changePassword();
            },
            child: Text('Send Reset Email',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Coming Soon Snackbar ───
  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(message,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 13)),
          ],
        ),
        backgroundColor: AppColors.textSecond,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Member since date ───
  String _getMemberSince(User? user) {
    if (user?.metadata.creationTime == null) {
      return 'May 2026';
    }
    final date = user!.metadata.creationTime!;
    final months = AppConstants.monthNames;
    return '${months[date.month - 1]} ${date.year}';
  }
}