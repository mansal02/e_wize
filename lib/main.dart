import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'welcome_page.dart';
import 'profile_update_page.dart';
import 'admin_dashboard_page.dart';
import 'booking_detail_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(EventHallApp());
}

class EventHallApp extends StatefulWidget {
  @override
  _EventHallAppState createState() => _EventHallAppState();
}

class _EventHallAppState extends State<EventHallApp> {
  String? loggedInUser;
  bool isAdmin = false;

  void _onLoginSuccess(String username) {
    setState(() {
      loggedInUser = username;
    });
  }

  void _onAdminLoginSuccess() {
    setState(() {
      isAdmin = true;
    });
  }

  void _onLogout() {
    setState(() {
      loggedInUser = null;
      isAdmin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Hall Booking',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF42A5F5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
      ),

      home: WelcomePage(username: loggedInUser ?? '', onLogout: _onLogout),

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/register':
            return MaterialPageRoute(builder: (context) => RegisterPage());

          case '/profile':
            return MaterialPageRoute(
              builder: (context) =>
                  ProfileUpdatePage(username: loggedInUser ?? ''),
            );

          case '/booking':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => BookingDetailsPage(
                username: args['username'],
                hallData: args['hallData'],
              ),
            );

          case '/welcome':
            return MaterialPageRoute(
              builder: (context) => WelcomePage(
                username: loggedInUser ?? '',
                onLogout: _onLogout,
              ),
            );

          case '/admin':
            if (!isAdmin) {
              return MaterialPageRoute(
                builder: (_) => LoginPage(
                  onLoginSuccess: _onLoginSuccess,
                  onAdminLoginSuccess: _onAdminLoginSuccess,
                ),
              );
            }
            return MaterialPageRoute(
              builder: (context) => AdminDashboardPage(),
            );

          case '/login':
            final args = settings.arguments as Map<String, dynamic>?;

            return MaterialPageRoute(
              builder: (_) => LoginPage(
                onLoginSuccess: _onLoginSuccess,
                onAdminLoginSuccess: _onAdminLoginSuccess,
                redirected: args?['redirected'] ?? false,
              ),
            );

          default:
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: Text('Page Not Found')),
                body: Center(child: Text('404 - Page Not Found')),
              ),
            );
        }
      },
    );
  }
}
