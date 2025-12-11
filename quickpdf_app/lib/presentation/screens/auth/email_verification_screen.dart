import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mock_auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _canResend = true;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        return _resendCountdown > 0;
      }
      return false;
    }).then((_) {
      if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      final authProvider = context.read<MockAuthProvider>();
      await authProvider.resendVerificationEmail(widget.email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doğrulama e-postası tekrar gönderildi'),
            backgroundColor: Colors.green,
          ),
        );
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final authProvider = context.read<MockAuthProvider>();
      final isVerified = await authProvider.checkEmailVerification();
      
      if (mounted) {
        if (isVerified) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('E-posta henüz doğrulanmamış'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-posta Doğrulama'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.email_outlined,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              'E-postanızı Doğrulayın',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Hesabınızı aktifleştirmek için ${widget.email} adresine gönderilen doğrulama linkine tıklayın.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Check verification button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkVerificationStatus,
                child: const Text('Doğrulamayı Kontrol Et'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Resend button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _canResend && !_isResending ? _resendVerificationEmail : null,
                child: _isResending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _canResend 
                            ? 'E-postayı Tekrar Gönder'
                            : 'Tekrar Gönder ($_resendCountdown)',
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Help text
            Text(
              'E-posta gelmedi mi? Spam klasörünüzü kontrol edin.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Change email
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('E-posta Adresini Değiştir'),
            ),
          ],
        ),
      ),
    );
  }
}