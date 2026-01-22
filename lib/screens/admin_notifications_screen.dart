import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants.dart';
import '../../services/notification_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  bool _isLoading = false;
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return null;

    try {
      final bytes = await _pickedImage!.readAsBytes();
      final fileExt = _pickedImage!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'notifications/$fileName';

      await Supabase.instance.client.storage
          .from('notifications')
          .uploadBinary(filePath, bytes);

      final imageUrl = Supabase.instance.client.storage
          .from('notifications')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw 'فشل رفع الصورة: $e';
    }
  }

  Future<void> _sendInApp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();

      // 1. Upload Image (shared logic)
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage();
      }

      // 2. Insert into notifications table (In-App)
      await Supabase.instance.client.from('notifications').insert({
        'title': title,
        'body': body,
        'image_url': imageUrl, // Nullable
        'is_broadcast': true,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال الإشعار الداخلي بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
      _postSendCleanup();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الإرسال الداخلي: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPush() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();

      // 1. Upload Image (shared logic)
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage();
      }
      // Also save to Supabase for record keeping?
      // User said "separate", so maybe they want ONLY push?
      // Usually "record" is good practice.
      // But adhering strictly to "separation": Push is Push.
      // However, usually we want an audit trail.
      // Let's do JUST Push as requested, or maybe Insert but don't call it In-App?
      // Re-reading: "زرين واحد لارسال الاشعارات داخل التطبيق والثاني ارسالل اشعارات خارج التطبيق"
      // Interpretation:
      // Btn 1: Insert to Supabase (shows in App).
      // Btn 2: Send to FCM (shows in System).

      // Let's implement pure Push call here.

      final success = await NotificationService.sendPushNotification(
        title: title,
        body: body,
        imageUrl: imageUrl,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الإشعار الخارجي بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        _postSendCleanup();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل إرسال الإشعار الخارجي'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ غير متوقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _postSendCleanup() {
    _titleController.clear();
    _bodyController.clear();
    setState(() => _pickedImage = null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Basic localization handling or static text if translation missing

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إرسال إشعارات',
          style: TextStyle(
              color: Constants.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Constants.primaryColor),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'إرسال إشعار فوري للمستخدمين',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Image Picker Widget
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[50], // Lighter grey
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _pickedImage != null
                            ? Constants.primaryColor
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      image: _pickedImage != null
                          ? DecorationImage(
                              image: FileImage(File(_pickedImage!.path)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _pickedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  size: 40,
                                  color:
                                      Constants.primaryColor.withOpacity(0.5)),
                              const SizedBox(height: 10),
                              const Text('إرفاق صورة (اختياري)',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : Stack(
                            children: [
                              Positioned(
                                top: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _pickedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 20, color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _titleController,
                  cursorColor: Constants.primaryColor,
                  decoration: InputDecoration(
                    labelText: 'عنوان الإشعار',
                    labelStyle: TextStyle(color: Constants.primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Constants.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _bodyController,
                  maxLines: 4,
                  cursorColor: Constants.primaryColor,
                  decoration: InputDecoration(
                    labelText: 'نص الرسالة',
                    labelStyle: TextStyle(color: Constants.primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Constants.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    // زر إرسال داخل التطبيق
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _sendInApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange, // لون مميز للداخلي
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.notifications_active,
                            color: Colors.white),
                        label: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text(
                                'إرسال إشعار\nداخل التطبيق',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // زر إرسال خارج التطبيق
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _sendPush,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.notifications_active,
                            color: Colors.white),
                        label: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text(
                                'إرسال إشعار\nخارج التطبيق ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
