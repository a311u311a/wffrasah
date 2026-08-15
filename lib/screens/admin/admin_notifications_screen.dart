import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../constants.dart';
import '../../../services/notification_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  final bool isEmbedded;
  const AdminNotificationsScreen({super.key, this.isEmbedded = false});

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

      final result = await NotificationService.sendPushNotificationDetailed(
        title: title,
        body: body,
        imageUrl: imageUrl,
      );

      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Push failed: ${result.message ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (result.success) {
        await Supabase.instance.client.from('notifications').insert({
          'title': title,
          'body': body,
          'image_url': imageUrl,
          'is_broadcast': true,
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
    if (widget.isEmbedded) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        body: _buildContent(),
      );
    }
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
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    const SizedBox(height: 16),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: _composerCard()),
                          const SizedBox(width: 16),
                          Expanded(flex: 5, child: _previewCard()),
                        ],
                      )
                    else ...[
                      _composerCard(),
                      const SizedBox(height: 16),
                      _previewCard(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Constants.primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.notifications_active_rounded,
            color: Constants.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإشعارات',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 3),
              Text(
                'إنشاء رسالة وإرسالها من لوحة الإدارة',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _composerCard() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(Icons.edit_notifications_rounded, 'محتوى الإشعار'),
          const SizedBox(height: 14),
          _imagePickerCard(),
          const SizedBox(height: 14),
          _inputField(
            controller: _titleController,
            label: 'عنوان الإشعار',
            icon: Icons.title_rounded,
            validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
          ),
          const SizedBox(height: 12),
          _inputField(
            controller: _bodyController,
            label: 'نص الرسالة',
            icon: Icons.subject_rounded,
            maxLines: 4,
            validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
          ),
          const SizedBox(height: 18),
          _actions(),
        ],
      ),
    );
  }

  Widget _previewCard() {
    final title = _titleController.text.trim().isEmpty
        ? 'عنوان الإشعار'
        : _titleController.text.trim();
    final body = _bodyController.text.trim().isEmpty
        ? 'سيظهر نص الرسالة هنا قبل الإرسال'
        : _bodyController.text.trim();

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(Icons.visibility_rounded, 'معاينة'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8E3FF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _previewThumb(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _infoTile(
            Icons.app_shortcut_rounded,
            'داخل التطبيق',
            'يحفظ الإشعار في مركز الإشعارات داخل التطبيق.',
          ),
          const SizedBox(height: 10),
          _infoTile(
            Icons.campaign_rounded,
            'خارج التطبيق',
            'يرسل Push Notification ثم يحفظ نسخة داخل التطبيق.',
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Constants.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _imagePickerCard() {
    final provider = _pickedImageProvider();
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: provider != null
                ? Constants.primaryColor.withValues(alpha: 0.45)
                : Colors.grey.shade200,
            width: 1.4,
          ),
          image: provider == null
              ? null
              : DecorationImage(image: provider, fit: BoxFit.cover),
        ),
        child: provider == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Constants.primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      color: Constants.primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'إرفاق صورة اختيارية',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    top: 10,
                    right: 10,
                    child: InkWell(
                      onTap: () => setState(() => _pickedImage = null),
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  ImageProvider? _pickedImageProvider() {
    if (_pickedImage == null) return null;
    if (kIsWeb) return NetworkImage(_pickedImage!.path);
    return FileImage(File(_pickedImage!.path));
  }

  Widget _previewThumb() {
    final provider = _pickedImageProvider();
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E3FF)),
        image: provider == null
            ? null
            : DecorationImage(image: provider, fit: BoxFit.cover),
      ),
      child: provider == null
          ? Icon(Icons.notifications_rounded, color: Constants.primaryColor)
          : null,
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      cursorColor: Constants.primaryColor,
      onChanged: (_) => setState(() {}),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Constants.primaryColor),
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Constants.primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _actions() {
    final loading = _isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        final inApp = _sendButton(
          label: 'داخل التطبيق',
          icon: Icons.app_shortcut_rounded,
          color: Colors.orange,
          onPressed: _isLoading ? null : _sendInApp,
          loading: loading,
        );
        final push = _sendButton(
          label: 'خارج التطبيق',
          icon: Icons.campaign_rounded,
          color: Constants.primaryColor,
          onPressed: _isLoading ? null : _sendPush,
          loading: loading,
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              inApp,
              const SizedBox(height: 10),
              push,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: inApp),
            const SizedBox(width: 12),
            Expanded(child: push),
          ],
        );
      },
    );
  }

  Widget _sendButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    Widget? loading,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: loading ?? Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Constants.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
