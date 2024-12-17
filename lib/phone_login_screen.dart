import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'channels_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  _PhoneLoginScreenState createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();
  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;

  Future<void> _verifyPhoneNumber(AuthService authService) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!_codeSent) {
        await authService.verifyPhoneNumber(
          phoneNumber: _phoneController.text.trim(),
          verificationCompleted: (credential) async {
            // Auto-retrieval of the SMS code completed
            await _signInWithPhoneNumber(authService, credential.smsCode!);
          },
          verificationFailed: (exception) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification Failed: ${exception.message}')),
            );
          },
          codeSent: (verificationId, resendToken) {
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
            });
          },
          codeAutoRetrievalTimeout: (verificationId) {
            setState(() {
              _verificationId = verificationId;
            });
          },
        );
      } else {
        // Verify SMS Code
        await _signInWithPhoneNumber(authService, _smsController.text.trim());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

 Future<void> _signInWithPhoneNumber(AuthService authService, String smsCode) async {
  await authService.signInWithPhoneNumber(_verificationId!, smsCode);
  // Redirect to the main page (ChannelsScreen)
  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const  ChannelsScreen()), 
      (route) => false,
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(_codeSent ? 'Verify Code' : 'Phone Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_codeSent)
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (+1XXXXXXXXXX)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                if (_codeSent)
                  TextField(
                    controller: _smsController,
                    decoration: const InputDecoration(
                      labelText: 'SMS Code',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _verifyPhoneNumber(authService),
                  child: Text(_codeSent ? 'Verify Code' : 'Send Code'),
                ),
              ],
            ),
      ),
    );
  }
}