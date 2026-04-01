import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'styled_page_scaffold.dart';
import 'booking_detail_page.dart';
import 'welcome_page.dart';
import 'utils/auth_utils.dart';

const _kAdminPinHash =
    'dbc135be34e6da3d3860d3b89c2a1e9bf4dc78a6439ca5a977e660207eaafe3c';

class LoginPage extends StatefulWidget {
  final void Function(String username) onLoginSuccess;
  final VoidCallback? onAdminLoginSuccess;
  final bool redirected;

  const LoginPage({
    required this.onLoginSuccess,
    this.onAdminLoginSuccess,
    this.redirected = false,
    Key? key,
  }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';

  @override
  void initState() {
    super.initState();
    if (widget.redirected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please log in to continue with your booking."),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final hashedPassword = hashPassword(password);

        // Regular user path
        final userResult = await FirebaseFirestore.instance
            .collection('Users')
            .where('username', isEqualTo: username)
            .where('password', isEqualTo: hashedPassword)
            .get();

        if (userResult.docs.isNotEmpty) {
          widget.onLoginSuccess(username);

          if (pendingBooking != null) {
            final hall = pendingBooking!['hall'];
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BookingDetailsPage(username: username, hallData: hall),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    WelcomePage(username: username, onLogout: () {}),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid username or password')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login error: ${e.toString()}')));
      }
    }
  }

  void _validatePin(BuildContext ctx, TextEditingController controller) {
    if (hashPassword(controller.text.trim()) == _kAdminPinHash) {
      Navigator.pop(ctx);
      widget.onAdminLoginSuccess?.call();
      Navigator.pushNamed(context, '/admin');
    } else {
      controller.clear();
    }
  }

  void _showAdminPinDialog() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (ctx) => Stack(
        children: [
          // Blur + dark scrim over the entire screen
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
          // Glassmorphic PIN card
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 260,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 4,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: 10,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••',
                        hintStyle: TextStyle(
                          color: Colors.white38,
                          fontSize: 20,
                          letterSpacing: 6,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                        counterText: '',
                      ),
                      onSubmitted: (_) => _validatePin(ctx, pinController),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _validatePin(ctx, pinController),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StyledPageScaffold(
      title: 'Login',
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white.withOpacity(0.95),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onLongPress: _showAdminPinDialog,
                      child: Image.asset(
                        'assets/images/LogoSpazio.png',
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Welcome to EventWize!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person),
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => username = val.trim(),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter username' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock),
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      onChanged: (val) => password = val.trim(),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter password' : null,
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Login', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text('Register Account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
