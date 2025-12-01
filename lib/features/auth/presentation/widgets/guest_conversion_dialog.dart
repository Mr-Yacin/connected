import 'package:flutter/material.dart';

import '../screens/phone_input_screen.dart';

class GuestConversionDialog extends StatelessWidget {
  const GuestConversionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('حفظ الحساب'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أنت تستخدم حساب زائر حالياً. بياناتك (الملف الشخصي، القصص، الرسائل) مؤقتة وستفقدها إذا قمت بتسجيل الخروج.',
            ),
            SizedBox(height: 16),
            Text(
              'قم بربط رقم هاتفك الآن لحفظ بياناتك والوصول إليها من أي جهاز.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لاحقاً'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to phone input screen with conversion flag
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const PhoneInputScreen(isConvertingAccount: true),
                ),
              );
            },
            child: const Text('حفظ حسابي الآن'),
          ),
        ],
      ),
    );
  }
}
