import 'package:flutter/material.dart';

class Constants {
  // theme key
  static const String isDarkMode = 'isDarkMode';

  // Modern Purple Palette
  static Color primaryColor =
      const Color(0xFF6C63FF); // اللون الأساسي (قابل للتغيير ديناميكياً)

  static const Color accentColor =
      Color(0xFFFF6584); // لون ثانوي للتميز (وردي ناعم)
  static const Color backgroundColor =
      Color(0xFFF5F7FA); // خلفية رمادية فاتحة جداً
  static const Color surfaceColor = Colors.white; // لون البطاقات والعناصر
  static const Color textColor = Color(0xFF2A2D3E); // لون النصوص الرئيسي
  static const Color secondaryTextColor =
      Color(0xFF88889D); // لون النصوص الثانوي

  static const Map<String, dynamic> fcmServiceAccountJson = {
    "type": "service_account",
    "project_id": "coupon-d52b2",
    "private_key_id": "b696c9c058e29d84905cca963f9c9be4130c6e94",
    "private_key": r'''-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCmbiK33EyDsGuT
kLDJJGK0+XN92LPZ1HPG1dm01OdELvMPImR2reUoBzajnz9PLkKhtEWvEKBuFotE
IwWlhnCzpeZJqLJEYzvm7RU/skFY3bwNjGCeZ9joTNqpIaF6eGIB9jgr5r+6HTmB
RPT5UBVIu1ThJXjcyrH6peAyfvVt1H9EkaIpEpVZ792fmVU43qw5Cq0Zw1DUYYJJ
7HNvEbXkACN95Tf7rO+BlzEMRO8lqmxdlvdGBYtMEhJVGDqYrvHXe9WxSevnAMcz
Ic8vkN9qle2qpMTyJr4BqPHj7kb699MtvILLDRUxqwI1mr43AQMWh9PgsfApT/uL
6EWc3tYjAgMBAAECggEAH+b7s7fAWPvv2xUAtkXJv/wTJdvsucQuPz6N4UpwXFMN
l2iVzmQOCaq8UAf+GDz7W8jVFLZAsmmS34hBFFYdc2pJJvR124MUH/NxP8j5GsJC
QmyWtracTwcwYPxH2lSKIOskIFI2jUP92mgv9zxhIBR8tD29GcGm9S9ntvY8MIWc
gaGoNPlR7CnlIc/VtHXDySeKbYBDhyvup72zMQqObb/n/3BixO7iIFb1BocR9cvJ
pOXeX1hP2eFqRdA8uTjCko7srN4ba8bKnTeV95dg1kvOcii8xQ/YECf+WYJbQxAu
IBZgjk9sCNj3valWAKCdTW/XEa0KbFnw218BWoggqQKBgQDWLZzkViIYZyrzTrKJ
AoZOc/69TjBnN7PPU2x0Qyh6aeDMYUot5QTUNqgR1l+1tk/Y5OSflyMsPCrbt5IQ
RQn3GYjkCWiO5mKQAGuJ9OrctdAugCpESCBJLmPWrBt6jLXQQc3fZo8+/ckstIoA
vT9bXwoM7iw+dQMM5NaCGvFTqwKBgQDG7a/ggT42WUO+HJd0h4rZGYR2G0Ixu0G1
dKdT8IYyAVMI1RdNBirsNF0VvsXxt4nIfdTokTCJqzg+Z8GY62knTWvP3OiaEVq0
hfZykRh3NuTZV6H3XE0AuJLO1KYvcxaxo1hl0Pb1ChjIIixUKYu8cLR+A4aJrxOI
ddF8j3WPaQKBgQCJ7moh6w6eJKLWepIkBko0cCNYCujFMGxOUu1/mliRLWqmdOlu
0RThDioDAso0niqiBhbuaEkwjbcUNQ6OB8g5KGquYRjDHr/O+VZITECMz1I5ADU4
MDMKriOB9ujjbYcRja9l9gi+inZqogJWI4qP747rcN9xga3rOdyjgXJ1bQKBgFhD
IaQE9Ct9E7eITBLiCNMmpUUZ9xbFtPPj3FI8B+6r88GZeossT2MaIKsDSCRlgPa6
DftaYCTVGVFnC9jjqnZLvagupe2mAY7TWXOfuTE74/IjFbQA+hF10319kHbBI7KR
fSk/vDMg1boGn5CAFoX3o729prX0PkBvthEEPe7xAoGAb/ItHUJxzDo10tzUGGVv
1O1raRDD1TFb9jDSTzQR5iMnzOUi80SDO7pFRkyAVteA27z8MUtuBn+rYLq/lX9h
s+c8iKwgERMn1HhwK/WTFxPtmwg/0pnAudqu/AAQnVJBm1XvWB1ANzR3WKIXWdWy
aVoZMzDFI2zEIOo1jXJHbpI=
-----END PRIVATE KEY-----''',
    "client_email":
        "firebase-adminsdk-fbsvc@coupon-d52b2.iam.gserviceaccount.com",
    "client_id": "108303284120993469912",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40coupon-d52b2.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };
}
