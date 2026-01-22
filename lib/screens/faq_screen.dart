import 'package:flutter/material.dart';
import '../constants.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'الأسئلة الشائعة',
          style: TextStyle(
            fontSize: 18,
            color: Constants.primaryColor,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Constants.primaryColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: const [
                SizedBox(height: 10),
                FaqItem(
                  question: 'هل التطبيق مجاني؟',
                  answer:
                      'نعم، التطبيق مجاني بالكامل. نحن نحصل على عمولة بسيطة من المتاجر عند استخدامك للكوبونات عبر تطبيقنا، وهذا لا يؤثر على السعر الذي تدفعه.',
                ),
                FaqItem(
                  question: 'كيف أستخدم كود الخصم؟',
                  answer:
                      'ببساطة، اضغط على زر "نسخ الكود" ثم ألصقه في خانة الكوبون في صفحة الدفع بالمتجر.',
                ),
                FaqItem(
                  question: 'الكود لا يعمل، ماذا أفعل؟',
                  answer:
                      'تأكد من قراءة شروط استخدام الكوبون (مثل الحد الأدنى للطلب والمنتجات المشمولة). إذا استمرت المشكلة، فهذا يعني أن صلاحية الكود قد انتهت.',
                ),

                FaqItem(
                  question: 'هل يمكن استخدام كود الخصم أكثر من مرة؟',
                  answer:
                      'نعم. يختلف ذلك من متجر لآخر، ولكن في كثير من الحالات يمكن استخدام كود الخصم عدة مرات.',
                ),
                FaqItem(
                  question: 'هل يتم تحديث أكواد الخصم في التطبيق؟',
                  answer:
                      'نعم. يتم تحديث أكواد الخصم باستمرار لضمان توفير أحدث وأفضل العروض للمستخدمين.',
                ),
                // أضف المزيد من الأسئلة هنا
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              '© ${DateTime.now().year} جميع الحقوق محفوظة. كوبونات التخفيضات',
              style: TextStyle(
                  fontSize: 10, color: Colors.grey[400], fontFamily: 'Tajawal'),
            ),
          ),
        ],
      ),
    );
  }
}

class FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const FaqItem({super.key, required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              color: Constants
                  .primaryColor, // Changed to primaryColor for consistency
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                answer,
                textAlign: TextAlign.justify,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontFamily: 'Tajawal',
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
