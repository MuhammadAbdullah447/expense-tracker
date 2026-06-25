import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ─── Offline persistence enable karo ───
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // ─── Auth state settle hone ka wait karo ───
  await FirebaseAuth.instance.authStateChanges().first;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: _AppConnector(  // wires the two providers together
        child: MaterialApp(
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF10B981),
            ),
            useMaterial3: true,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

// ─── Wires ExpenseProvider callbacks → NotificationProvider ───
class _AppConnector extends StatefulWidget {
  final Widget child;
  const _AppConnector({required this.child});

  @override
  State<_AppConnector> createState() => _AppConnectorState();
}

class _AppConnectorState extends State<_AppConnector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expense      = context.read<ExpenseProvider>();
      final notification = context.read<NotificationProvider>();

      expense.onExpenseAdded  = notification.onExpenseAdded;
      expense.onExpenseDeleted = notification.onExpenseDeleted;
      expense.onBudgetUpdated  = notification.onBudgetUpdated;
      expense.onCheckBudget = (spent, budget) => notification.checkBudgetAlerts(spent: spent, budget: budget);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}