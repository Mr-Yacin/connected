import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'dart:convert';

/// Settings screen for managing user preferences and account
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات'), centerTitle: true),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Error message
                if (settingsState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                settingsState.error!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => settingsNotifier.clearError(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Appearance Section
                _buildSectionTitle('المظهر'),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('الوضع الداكن'),
                        subtitle: const Text('تفعيل الوضع الداكن للتطبيق'),
                        value: settingsState.preferences.isDarkMode,
                        onChanged: (value) async {
                          await settingsNotifier.toggleDarkMode();
                        },
                        secondary: Icon(
                          settingsState.preferences.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: AppColors.primary,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.language, color: AppColors.primary),
                        title: const Text('اللغة'),
                        subtitle: Text(
                          settingsState.preferences.language == 'ar'
                              ? 'العربية'
                              : 'English',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showLanguageDialog(
                          context,
                          settingsState.preferences.language,
                          settingsNotifier,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Account Management Section
                _buildSectionTitle('إدارة الحساب'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.download, color: AppColors.primary),
                        title: const Text('تصدير البيانات'),
                        subtitle: const Text('تحميل نسخة من بياناتك'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _exportUserData(
                          context,
                          currentUser?.uid ?? '',
                          settingsNotifier,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.block, color: Colors.orange),
                        title: const Text('المستخدمين المحظورين'),
                        subtitle: const Text('إدارة قائمة الحظر'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.push('/blocked-users'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        title: const Text(
                          'حذف الحساب',
                          style: TextStyle(color: Colors.red),
                        ),
                        subtitle: const Text('حذف حسابك وجميع بياناتك نهائياً'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showDeleteAccountDialog(
                          context,
                          currentUser?.uid ?? '',
                          settingsNotifier,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // About Section
                _buildSectionTitle('حول التطبيق'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                        ),
                        title: const Text('الإصدار'),
                        subtitle: const Text('1.0.0'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.privacy_tip_outlined,
                          color: AppColors.primary,
                        ),
                        title: const Text('سياسة الخصوصية'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigate to privacy policy
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.description_outlined,
                          color: AppColors.primary,
                        ),
                        title: const Text('شروط الاستخدام'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigate to terms of service
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Out Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/auth');
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('تسجيل الخروج'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    String currentLanguage,
    SettingsNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر اللغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('العربية'),
              value: 'ar',
              groupValue: currentLanguage,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.changeLanguage(value);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: currentLanguage,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.changeLanguage(value);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportUserData(
    BuildContext context,
    String userId,
    SettingsNotifier notifier,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تصدير البيانات...'),
                ],
              ),
            ),
          ),
        ),
      );

      final data = await notifier.exportUserData(userId);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show success dialog with data preview
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تم تصدير البيانات'),
            content: SingleChildScrollView(
              child: Text(
                const JsonEncoder.withIndent('  ').convert(data),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تصدير البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog(
    BuildContext context,
    String userId,
    SettingsNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد حذف الحساب'),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف حسابك؟\n\n'
          'سيتم حذف جميع بياناتك بشكل نهائي ولا يمكن التراجع عن هذا الإجراء.\n\n'
          'تشمل البيانات المحذوفة:\n'
          '• الملف الشخصي\n'
          '• الرسائل\n'
          '• القصص\n'
          '• البلاغات والحظر',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close confirmation dialog

              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('جاري حذف الحساب...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                await notifier.deleteAccount(userId);

                if (context.mounted) {
                  Navigator.of(context).pop(); // Close loading dialog
                  Navigator.of(context).pushReplacementNamed('/auth');
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل حذف الحساب: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );
  }
}
