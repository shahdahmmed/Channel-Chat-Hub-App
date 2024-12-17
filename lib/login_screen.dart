import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'phone_login_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

Future<void> logFirstTimeLogin(User? user) async {
  // Ensure the user is not null before accessing metadata
  if (user != null) {
    print('\n');
    print(user.metadata?.creationTime);
    print(user.metadata?.lastSignInTime);
    print('\n');
    // Check if this is the user's first login by comparing creation time and last sign-in time
    if (user.metadata?.creationTime == user.metadata?.lastSignInTime) {
      // Enable Analytics collection
      await _analytics.setAnalyticsCollectionEnabled(true);
      
      // Log the first time login event
      await _analytics.logEvent(
        name: 'first_time_login',
        parameters: {
          'user_id': user.uid?? 'No ID available',  // Use null-aware operator for displayName
          'email': user.email ?? 'No email available', // Fallback if email is null
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print("First-Time Login Event Logged");
    }
  } else {
    print("User is null");
  }
}



  Future<void> _handleEmailAuthentication(AuthService authService) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLogin) {
        // Sign In
        final user = await authService.signIn(
          email: email, 
          password: password
        );

        if (user != null) {
          // Handle successful sign in
          _showSuccessSnackBar('Successfully signed in');
           await logFirstTimeLogin(user);
        } else {
          // Handle sign in failure
          _showErrorSnackBar('Sign in failed');
        }
      } else {
        // Sign Up
        final user = await authService.signUp(
          email: email, 
          password: password
        );

        if (user != null) {
          // Handle successful sign up
          _showSuccessSnackBar('Successfully signed up');
          await logFirstTimeLogin(user);
        } else {
          // Handle sign up failure
          _showErrorSnackBar('Sign up failed');
        }
      }
        
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }





 Future<void> _handlePhoneSignIn(AuthService authService) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PhoneLoginScreen(),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _handleGoogleSignIn(AuthService authService) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await authService.signInWithGoogle();

      if (user != null) {
        // Handle successful Google sign in
        _showSuccessSnackBar('Successfully signed in with Google');
         await logFirstTimeLogin(user);
      } else {
        // Handle sign in failure
        _showErrorSnackBar('Google sign in failed');
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _handleEmailAuthentication(authService),
                  child: Text(_isLogin ? 'Login' : 'Sign Up'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _handleGoogleSignIn(authService),
                  child: const Text('Sign in with Google'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the phone login screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PhoneLoginScreen(),
                      ),
                    );
                  },
                  child: const Text('Sign in with Phone Number'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(_isLogin
                      ? 'Need an account? Sign Up'
                      : 'Already have an account? Login'),
                ),
              ],
            ),
      ),
    );
  }
}