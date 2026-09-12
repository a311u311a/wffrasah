import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants.dart';
import '../login_signup/widgets/snackbar.dart';

class AdminCouponProvidersScreen extends StatefulWidget {
  const AdminCouponProvidersScreen({super.key});

  @override
  State<AdminCouponProvidersScreen> createState() =>
      _AdminCouponProvidersScreenState();
}

class _AdminCouponProvidersScreenState
    extends State<AdminCouponProvidersScreen> {
  final _sb = Supabase.instance.client;
  final _name = TextEditingController();
  final _location = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await _sb.from('coupon_providers').select().order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    _editingId = row?['id']?.toString();
    _name.text = (row?['name'] ?? '').toString();
    _location.text = (row?['location'] ?? '').toString();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: kToolbarHeight + 30,
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _editingId == null ? 'إضافة موفر كوبونات' : 'تعديل الموفر',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Constants.primaryColor,
                ),
              ),
              const SizedBox(height: 15),
              const Divider(indent: 20, endIndent: 20),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      _providerInputField(
                        _name,
                        'اسم الموفر',
                        Icons.business_center_outlined,
                      ),
                      _providerInputField(
                        _location,
                        'الموقع',
                        Icons.language_outlined,
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            if (_name.text.trim().isEmpty) return;
                            final payload = {
                              'name': _name.text.trim(),
                              'location': _location.text.trim()
                            };
                            try {
                              if (_editingId == null) {
                                await _sb
                                    .from('coupon_providers')
                                    .insert(payload);
                              } else {
                                await _sb
                                    .from('coupon_providers')
                                    .update(payload)
                                    .eq('id', _editingId!);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                setState(() {
                                  _future = _load();
                                });
                              }
                            } catch (e) {
                              if (mounted) {
                                showSnackBar(context, 'خطأ: $e', isError: true);
                              }
                            }
                          },
                          child: Text(
                            _editingId == null ? 'حفظ الموفر' : 'حفظ التعديلات',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _providerInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Constants.primaryColor),
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.normal,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Constants.primaryColor, width: 1.4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: Text(
          'موفرو الكوبونات',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Constants.primaryColor),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Constants.primaryColor),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Constants.primaryColor,
                  Constants.primaryColor.withValues(alpha: 0.8),
                ]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Constants.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _edit(),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'إضافة موفر جديد',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا يوجد موفرو كوبونات'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (_, index) {
                    final row = snapshot.data![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: .04),
                                blurRadius: 15,
                                offset: const Offset(0, 8))
                          ]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Constants.primaryColor
                                      .withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.business_center_outlined,
                                    color: Constants.primaryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  row['name'].toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'تعديل',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _edit(row),
                              ),
                              IconButton(
                                tooltip: 'حذف',
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () => _delete(row),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('حذف موفر الكوبونات؟'),
              content: const Text('سيتم حذف الموفر من القائمة.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('إلغاء')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child:
                        const Text('حذف', style: TextStyle(color: Colors.red)))
              ],
            ));
    if (ok != true) return;
    try {
      await _sb.from('coupon_providers').delete().eq('id', row['id']);
      if (mounted) {
        setState(() {
          _future = _load();
        });
      }
    } catch (e) {
      if (mounted) showSnackBar(context, 'خطأ: $e', isError: true);
    }
  }
}
