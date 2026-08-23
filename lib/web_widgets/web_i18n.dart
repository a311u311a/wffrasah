import 'package:flutter/widgets.dart';

bool webIsArabic(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

TextDirection webTextDirection(BuildContext context) =>
    webIsArabic(context) ? TextDirection.rtl : TextDirection.ltr;

String webText(BuildContext context, String ar, String en) =>
    webIsArabic(context) ? ar : en;
