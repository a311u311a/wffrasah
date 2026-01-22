import 'package:flutter/material.dart';
import '../../models/coupon.dart';

class EditCouponScreen extends StatelessWidget {
  final Coupon coupon;
  const EditCouponScreen({super.key, required this.coupon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Coupon: ${coupon.code}')),
      body: const Center(child: Text('Edit Coupon Form Goes Here')),
    );
  }
}
