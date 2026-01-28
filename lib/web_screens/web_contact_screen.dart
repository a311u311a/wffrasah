import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// صفحة اتصل بنا للويب - محدثة
class WebContactScreen extends StatefulWidget {
  const WebContactScreen({super.key});

  @override
  State<WebContactScreen> createState() => _WebContactScreenState();
}

class _WebContactScreenState extends State<WebContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  Future<void> _sendEmail() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String message = _messageController.text.trim();

    if (name.isEmpty || email.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول',
              style: TextStyle(fontFamily: 'Tajawal')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'help@rbhan.co',
      queryParameters: {
        'subject': 'اتصل بنا - $name',
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Could not launch $emailLaunchUri';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إرسال البريد الإلكتروني: $e',
                style: const TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const WebNavigationBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: ResponsivePadding.page(context),
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(context),
                  const SizedBox(height: 40),

                  // Contact Form Container
                  Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 700),
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'أرسل لنا رسالة',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                                color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          TextField(
                            controller: _nameController,
                            decoration:
                                _buildInputDecoration('الاسم', Icons.person),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _emailController,
                            decoration: _buildInputDecoration(
                                'البريد الإلكتروني', Icons.email),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _messageController,
                            decoration:
                                _buildInputDecoration('الرسالة', Icons.message),
                            maxLines: 5,
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _sendEmail,
                              icon: const Icon(Icons.send_rounded),
                              label: const Text(
                                'إرسال',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Constants.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'تواصل معنا',
            style: TextStyle(
              fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'نحن هنا لمساعدتك، لا تتردد في التواصل معنا',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Tajawal'),
      prefixIcon: Icon(icon, color: Constants.primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Constants.primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
