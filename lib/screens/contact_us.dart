import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../screens/login_signup/widgets/snackbar.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  Future<void> _sendEmail() async {
    final localizations = AppLocalizations.of(context);
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String message = _messageController.text.trim();

    if (name.isEmpty || email.isEmpty || message.isEmpty) {
      showSnackBar(
        context,
        localizations?.translate('fill_all_fields') ??
            'Please fill in all fields',
      );
      return;
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'help@rbhan.co',
      queryParameters: {
        'subject': '${localizations?.translate('contact_us')} - $name',
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
        showSnackBar(
          context,
          '${localizations?.translate('email_failed') ?? 'Failed to send email'}: $e',
          isError: true,
        );
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Constants.primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Constants.primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Constants.primaryColor,
        // تغيير لون أيقونة الرجوع (السهم) إلى الأبيض
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        toolbarHeight: 50,
        title: Text(
          localizations?.translate('contact_us') ?? 'Contact Us',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: _buildInputDecoration(
                  localizations?.translate('name') ?? 'Name', Icons.person),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: _buildInputDecoration(
                  localizations?.translate('email') ?? 'Email', Icons.email),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: _buildInputDecoration(
                  localizations?.translate('message') ?? 'Message',
                  Icons.message),
              maxLines: 5,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _sendEmail,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Constants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: Text(
                localizations?.translate('send') ?? 'Send',
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
