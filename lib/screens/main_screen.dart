import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'home_screen.dart';
import 'add_expense_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // ─── App open hone par expenses load karo ───
    Future.microtask(() =>
        context.read<ExpenseProvider>().loadExpenses());
  }

  // ─── Logout function ───
  Future<void> _logout() async {
    // Pehle data clear karo
    context.read<ExpenseProvider>().clearData();
    // Firebase Auth se logout
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const AddExpenseScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        title: const Text(
          'Expense Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1E3A5F),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        backgroundColor: const Color(0xFF1E3A5F),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => setState(() => _currentIndex = 1),
      )
          : null,
    );
  }

  // ─── Drawer UI ───
  Widget _buildDrawer() {
    // ─── Current user ka naam aur email ───
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E3A5F)),
            accountName: Text(
              user?.displayName ?? 'Muhammad Abdullah',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
                user?.email ?? 'muhammadabdullah495969@gmail.com'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person,
                  color: Color(0xFF1E3A5F), size: 36),
            ),
          ),
          _drawerItem(Icons.home, 'Home',
                  () => _closeDrawerAndGo(0)),
          _drawerItem(Icons.add_circle_outline, 'Add Expense',
                  () => _closeDrawerAndGo(1)),
          _drawerItem(Icons.bar_chart, 'Reports',
                  () => _closeDrawerAndGo(2)),
          _drawerItem(Icons.history, 'History', () {}),
          _drawerItem(Icons.settings, 'Settings', () {}),
          const Divider(),
          _drawerItem(
              Icons.info_outline, 'About App', _showAboutDialog),
          const Spacer(),

          // ─── Logout button ───
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: () {
                  Navigator.pop(context);
                  _showLogoutDialog();
                },
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Version 1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ─── Single drawer item ───
  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: const Color(0xFF1E3A5F)),
        title: Text(title),
        onTap: onTap,
      );

  // ─── Drawer band karo aur tab switch karo ───
  void _closeDrawerAndGo(int index) {
    Navigator.pop(context);
    setState(() => _currentIndex = index);
  }

  // ─── Logout confirm dialog ───
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ─── About app dialog ───
  void _showAboutDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About App'),
        content: const Text(
          'Personal Expense Tracker\nVersion 1.0.0\n\nTrack your daily expenses easily.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}