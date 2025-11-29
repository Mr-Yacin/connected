import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Settings screen for managing user preferences and account
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Transparent to show animated container behind
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDarkMode
              ? Brightness.light
              : Brightness.dark,
        ),
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [AppColors.darkSurface, const Color(0xFF1a1a1a)]
                : [AppColors.lightSurface, const Color(0xFFF8F9FA)],
          ),
        ),
        child: SafeArea(
          child: settingsState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Error message
                            if (settingsState.error != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.red.withOpacity(0.1),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade400,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        settingsState.error!,
                                        style: TextStyle(
                                          color: Colors.red.shade400,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          settingsNotifier.clearError(),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.red.shade400,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Appearance Section
                            _buildSectionHeader('المظهر', isDarkMode),
                            _buildSettingsCard(
                              children: [
                                _buildThemeSelector(context, ref, isDarkMode),
                              ],
                              isDarkMode: isDarkMode,
                            ),

                            const SizedBox(height: 24),

                            // Account Section
                            _buildSectionHeader('الحساب', isDarkMode),
                            _buildSettingsCard(
                              children: [
                                _buildNavigationTile(
                                  title: 'المستخدمين المحظورين',
                                  subtitle: 'إدارة قائمة الحظر',
                                  icon: Icons.block,
                                  iconColor: Colors.orange,
                                  onTap: () => context.push('/blocked-users'),
                                  isDarkMode: isDarkMode,
                                ),
                                _buildDivider(isDarkMode),
                                _buildNavigationTile(
                                  title: 'حذف الحساب',
                                  subtitle: 'حذف حسابك وجميع بياناتك نهائياً',
                                  icon: Icons.delete_forever,
                                  iconColor: Colors.red,
                                  textColor: Colors.red,
                                  onTap: () => _showDeleteAccountDialog(
                                    context,
                                    currentUser?.uid ?? '',
                                    settingsNotifier,
                                  ),
                                  isDarkMode: isDarkMode,
                                ),
                              ],
                              isDarkMode: isDarkMode,
                            ),

                            const SizedBox(height: 24),

                            // About Section
                            _buildSectionHeader('حول التطبيق', isDarkMode),
                            _buildSettingsCard(
                              children: [
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: AppColors.primary.withOpacity(0.1),
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    'الإصدار',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '1.0.0',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                                _buildDivider(isDarkMode),
                                _buildNavigationTile(
                                  title: 'سياسة الخصوصية',
                                  subtitle: 'عرض سياسة الخصوصية',
                                  icon: Icons.privacy_tip_outlined,
                                  onTap: () =>
                                      context.push('/settings/privacy'),
                                  isDarkMode: isDarkMode,
                                ),
                                _buildDivider(isDarkMode),
                                _buildNavigationTile(
                                  title: 'شروط الاستخدام',
                                  subtitle: 'عرض شروط الخدمة',
                                  icon: Icons.description_outlined,
                                  onTap: () => context.push('/settings/terms'),
                                  isDarkMode: isDarkMode,
                                ),
                              ],
                              isDarkMode: isDarkMode,
                            ),

                            const SizedBox(height: 32),

                            // Sign Out Button
                            _buildSignOutButton(context, isDarkMode),

                            // Bottom padding to avoid conflicts with mobile navigation
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // Theme selector widget
  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    bool isDarkMode,
  ) {
    final currentThemeOption = ref.watch(currentThemeOptionProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: Icon(Icons.palette, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وضع المظهر',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'اختر شكل تطبيقك المفضل',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ThemeOption.values.map((option) {
              final isSelected = currentThemeOption == option;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Don't await to prevent navigation disruption
                    themeNotifier.setThemeOption(option);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.only(
                      right: option == ThemeOption.system ? 0 : 4,
                      left: option == ThemeOption.dark ? 0 : 4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? AppColors.primary
                          : isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.1),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getThemeIcon(option),
                          color: isSelected
                              ? Colors.white
                              : isDarkMode
                              ? Colors.white70
                              : Colors.black54,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getThemeLabel(option),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (currentThemeOption == ThemeOption.system)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'سيتم تبديل المظهر تلقائياً حسب إعدادات جهازك',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _getThemeIcon(ThemeOption option) {
    switch (option) {
      case ThemeOption.system:
        return Icons.settings_brightness;
      case ThemeOption.light:
        return Icons.light_mode;
      case ThemeOption.dark:
        return Icons.dark_mode;
    }
  }

  String _getThemeLabel(ThemeOption option) {
    switch (option) {
      case ThemeOption.system:
        return 'النظام';
      case ThemeOption.light:
        return 'فاتح';
      case ThemeOption.dark:
        return 'داكن';
    }
  }

  // Helper methods for modern UI components
  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required List<Widget> children,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.primary.withOpacity(0.1),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withOpacity(0.3),
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.shade300,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Function() onTap,
    Color? iconColor,
    Color? textColor,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? (isDarkMode ? Colors.white : Colors.black87),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
      ),
      trailing: Icon(
        Icons.arrow_back_ios,
        size: 16,
        color: isDarkMode ? Colors.white54 : Colors.black54,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDarkMode
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.1),
    );
  }

  Widget _buildSignOutButton(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        onPressed: () => _showSignOutDialog(context),
        icon: Icon(Icons.logout, size: 20),
        label: Text(
          'تسجيل الخروج',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) => AlertDialog(
          title: const Text('تأكيد تسجيل الخروج'),
          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'جاري تسجيل الخروج...',
                              style: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                try {
                  // ✅ Use proper AuthNotifier signOut method
                  final authNotifier = ref.read(authNotifierProvider.notifier);
                  await authNotifier.signOut();

                  // Add delay to ensure auth state is fully settled
                  await Future.delayed(const Duration(milliseconds: 300));

                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close loading dialog
                    context.go('/auth/phone');
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل تسجيل الخروج: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
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
                builder: (context) => Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'جاري حذف الحساب...',
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
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
                  context.go('/auth/phone');
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
