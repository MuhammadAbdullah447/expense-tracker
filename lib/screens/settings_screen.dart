import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {

  // ─── Settings State ───
  bool _notificationsEnabled = true;
  bool _budgetAlerts         = true;
  bool _weeklyReport         = false;
  bool _darkMode             = false;
  String _currency           = 'PKR (Rs.)';
  String _language           = 'English';

  // ─── Animation ───
  late AnimationController _fadeController;
  late Animation<double>   _fadeAnimation;

  // ─── Colors ───
  static const primary     = Color(0xFF10B981);
  static const primaryDark = Color(0xFF059669);
  static const bgColor     = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecond  = Color(0xFF64748B);
  static const errorColor  = Color(0xFFEF4444);
  static const cardColor   = Colors.white;

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [

              // ─── Header ───
              _buildHeader(),

              const SizedBox(height: 20),

              // ─── Budget Settings ───
              _buildSection(
                icon:  Icons.account_balance_wallet_outlined,
                color: primary,
                title: 'Budget',
                items: [
                  _buildBudgetTile(),
                  _buildResetBudgetTile(),
                ],
              ),

              const SizedBox(height: 16),

              // ─── Notifications ───
              _buildSection(
                icon:  Icons.notifications_outlined,
                color: const Color(0xFF6366F1),
                title: 'Notifications',
                items: [
                  _buildSwitchTile(
                    icon:     Icons.notifications_active_outlined,
                    iconColor: const Color(0xFF6366F1),
                    title:    'Enable Notifications',
                    subtitle: 'Get expense reminders',
                    value:    _notificationsEnabled,
                    onChanged: (val) => setState(
                            () => _notificationsEnabled = val),
                  ),
                  _buildSwitchTile(
                    icon:     Icons.warning_amber_outlined,
                    iconColor: Colors.orange,
                    title:    'Budget Alerts',
                    subtitle: 'Alert when 80% budget used',
                    value:    _budgetAlerts,
                    onChanged: (val) =>
                        setState(() => _budgetAlerts = val),
                  ),
                  _buildSwitchTile(
                    icon:     Icons.bar_chart_outlined,
                    iconColor: primary,
                    title:    'Weekly Report',
                    subtitle: 'Get weekly spending summary',
                    value:    _weeklyReport,
                    onChanged: (val) =>
                        setState(() => _weeklyReport = val),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ─── Preferences ───
              _buildSection(
                icon:  Icons.tune_outlined,
                color: const Color(0xFFF59E0B),
                title: 'Preferences',
                items: [
                  _buildDropdownTile(
                    icon:      Icons.attach_money,
                    iconColor: const Color(0xFF10B981),
                    title:     'Currency',
                    value:     _currency,
                    options:   [
                      'PKR (Rs.)',
                      'USD (\$)',
                      'EUR (€)',
                      'GBP (£)',
                    ],
                    onChanged: (val) =>
                        setState(() => _currency = val!),
                  ),
                  _buildDropdownTile(
                    icon:      Icons.language_outlined,
                    iconColor: const Color(0xFF2196F3),
                    title:     'Language',
                    value:     _language,
                    options:   ['English', 'Urdu'],
                    onChanged: (val) =>
                        setState(() => _language = val!),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ─── Data Management ───
              _buildSection(
                icon:  Icons.storage_outlined,
                color: const Color(0xFF8B5CF6),
                title: 'Data Management',
                items: [
                  _buildActionTile(
                    icon:      Icons.download_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBg:    const Color(0xFFEDE9FE),
                    title:     'Export Data',
                    subtitle:  'Export expenses as CSV',
                    onTap:     _showExportDialog,
                  ),
                  _buildActionTile(
                    icon:      Icons.delete_sweep_outlined,
                    iconColor: errorColor,
                    iconBg:    const Color(0xFFFFEBEE),
                    title:     'Clear All Expenses',
                    subtitle:  'Delete all expense records',
                    onTap:     _showClearDataDialog,
                    isDestructive: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ─── About ───
              _buildSection(
                icon:  Icons.info_outline,
                color: textSecond,
                title: 'About',
                items: [
                  _buildInfoTile(
                      'App Version', 'v1.0.0'),
                  _buildInfoTile(
                      'Developer', 'Muhammad Abdullah'),
                  _buildInfoTile(
                      'Course', 'Mobile Application Development'),
                  _buildActionTile(
                    icon:      Icons.star_outline_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg:    const Color(0xFFFFF8E1),
                    title:     'Rate App',
                    subtitle:  'Share your feedback',
                    onTap:     () {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            '⭐ Thank you for your support!',
                            style: GoogleFonts.poppins(
                                color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFFF59E0B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
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
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 28),
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
          bottomLeft:  Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
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
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  )),
              Text('Customize your experience',
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Section wrapper ───
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
          // ─── Section Title ───
          Padding(
            padding: const EdgeInsets.only(
                left: 4, bottom: 10),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    )),
              ],
            ),
          ),

          // ─── Items Card ───
          Container(
            decoration: BoxDecoration(
              color: cardColor,
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

  // ─── Budget Tile ───
  Widget _buildBudgetTile() {
    final provider = context.watch<ExpenseProvider>();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.edit_outlined,
            color: primary, size: 18),
      ),
      title: Text('Monthly Budget',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          )),
      subtitle: Text(
        'Rs. ${provider.budget.toStringAsFixed(0)}',
        style: GoogleFonts.poppins(
            fontSize: 12, color: primary,
            fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Color(0xFF94A3B8)),
      onTap: () => _showBudgetDialog(provider),
    );
  }

  // ─── Reset Budget Tile ───
  Widget _buildResetBudgetTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.refresh_rounded,
            color: Colors.orange, size: 18),
      ),
      title: Text('Reset Budget',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          )),
      subtitle: Text('Reset to default Rs. 50,000',
          style: GoogleFonts.poppins(
              fontSize: 12, color: textSecond)),
      trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Color(0xFF94A3B8)),
      onTap: () {
        HapticFeedback.lightImpact();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Reset Budget',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700)),
            content: Text(
                'Reset monthly budget to Rs. 50,000?',
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
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10)),
                ),
                onPressed: () {
                  context
                      .read<ExpenseProvider>()
                      .updateBudget(50000);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ Budget reset to Rs. 50,000',
                        style: GoogleFonts.poppins(
                            color: Colors.white),
                      ),
                      backgroundColor: primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
                child: Text('Reset',
                    style: GoogleFonts.poppins()),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Switch Tile ───
  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          )),
      subtitle: Text(subtitle,
          style: GoogleFonts.poppins(
              fontSize: 11, color: textSecond)),
      trailing: Switch(
        value:            value,
        onChanged:        (val) {
          HapticFeedback.lightImpact();
          onChanged(val);
        },
        activeColor:      primary,
        activeTrackColor: primary.withOpacity(0.3),
      ),
    );
  }

  // ─── Dropdown Tile ───
  Widget _buildDropdownTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          )),
      trailing: DropdownButton<String>(
        value:          value,
        underline:      const SizedBox(),
        icon:           const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF94A3B8)),
        style:          GoogleFonts.poppins(
            fontSize: 13,
            color: primary,
            fontWeight: FontWeight.w600),
        items: options.map((option) =>
            DropdownMenuItem(
              value: option,
              child: Text(option,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: textPrimary)),
            )).toList(),
        onChanged: (val) {
          HapticFeedback.lightImpact();
          onChanged(val);
        },
      ),
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
    bool isDestructive = false,
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
            color: isDestructive ? errorColor : textPrimary,
          )),
      subtitle: Text(subtitle,
          style: GoogleFonts.poppins(
              fontSize: 11, color: textSecond)),
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

  // ─── Info Tile ───
  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      title: Text(title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textSecond,
          )),
      trailing: Text(value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          )),
    );
  }

  // ─── Budget Dialog ───
  void _showBudgetDialog(ExpenseProvider provider) {
    final controller = TextEditingController(
        text: provider.budget.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Set Monthly Budget',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 16)),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(
                          color: Colors.grey.shade200)),
                ),
                child: Text('Rs.',
                    style: GoogleFonts.poppins(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    )),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
                  autofocus: true,
                  style: GoogleFonts.poppins(fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 50000',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style:
                GoogleFonts.poppins(color: textSecond)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final val =
              double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                provider.updateBudget(val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Budget updated!',
                        style: GoogleFonts.poppins(
                            color: Colors.white)),
                    backgroundColor: primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            child: Text('Save',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Export Dialog ───
  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Export Data',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700)),
        content: Text(
          'Export feature will be available in the next update.',
          style: GoogleFonts.poppins(fontSize: 14),
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
                style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  // ─── Clear Data Dialog ───
  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Clear All Expenses',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: errorColor)),
        content: Text(
          'This will permanently delete ALL your expense records. This action cannot be undone!',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: textSecond)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '🗑️ All expenses cleared!',
                    style: GoogleFonts.poppins(
                        color: Colors.white),
                  ),
                  backgroundColor: errorColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            child: Text('Clear All',
                style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}