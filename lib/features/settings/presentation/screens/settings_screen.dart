import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../providers/settings_provider.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/theme_option.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/current_user_profile_provider.dart';

// Local state providers for notification settings
final _notificationSettingProvider = StateProvider.family<bool, bool>((ref, initialValue) => initialValue);
final _isUpdatingNotificationProvider = StateProvider<bool>((ref) => false);

/// Settings screen for managing user preferences and account
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentUser = FirebaseAuth.instance.currentUser;

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
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              Theme.of(context).brightness == Brightness.dark
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
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
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
                                  color: Colors.red.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3),
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
                            _buildSectionHeader(context, 'المظهر'),
                            _buildSettingsCard(
                              context: context,
                              children: [_buildThemeSelector(context, ref)],
                            ),

                            const SizedBox(height: 24),

                            // Notifications Section
                            _buildSectionHeader(context, 'الإشعارات'),
                            _buildSettingsCard(
                              context: context,
                              children: [
                                _buildNotificationSettings(context, ref),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Account Section
                            _buildSectionHeader(context, 'الحساب'),
                            _buildSettingsCard(
                              context: context,
                              children: [
                                _buildNavigationTile(
                                  context: context,
                                  title: 'المستخدمين المحظورين',
                                  subtitle: 'إدارة قائمة الحظر',
                                  icon: Icons.block,
                                  iconColor: Colors.orange,
                                  onTap: () => context.push('/blocked-users'),
                                ),
                                _buildDivider(context),
                                _buildNavigationTile(
                                  context: context,
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
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // About Section
                            _buildSectionHeader(context, 'حول التطبيق'),
                            _buildSettingsCard(
                              context: context,
                              children: [
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    'الإصدار',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  subtitle: Text(
                                    '1.0.0',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                _buildDivider(context),
                                _buildNavigationTile(
                                  context: context,
                                  title: 'سياسة الخصوصية',
                                  subtitle: 'عرض سياسة الخصوصية',
                                  icon: Icons.privacy_tip_outlined,
                                  onTap: () =>
                                      context.push('/settings/privacy'),
                                ),
                                _buildDivider(context),
                                _buildNavigationTile(
                                  context: context,
                                  title: 'شروط الاستخدام',
                                  subtitle: 'عرض شروط الخدمة',
                                  icon: Icons.description_outlined,
                                  onTap: () => context.push('/settings/terms'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // Sign Out Button
                            _buildSignOutButton(context),

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

  // Notification settings widget
  Widget _buildNotificationSettings(BuildContext context, WidgetRef ref) {
    final currentUserProfile = ref.watch(currentUserProfileProvider).profile;
    
    if (currentUserProfile == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        // Use local state for immediate UI update
        final notifyOnProfileView = ref.watch(
          _notificationSettingProvider(currentUserProfile.notifyOnProfileView),
        );
        final isUpdating = ref.watch(_isUpdatingNotificationProvider);

        return Column(
          children: [
            SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              title: Text(
                'إشعارات زيارة البروفايل',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                'استلم إشعار عند زيارة شخص لملفك الشخصي',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              value: notifyOnProfileView,
              onChanged: isUpdating
                  ? null
                  : (value) async {
                      // Cache notifiers before async operations
                      final notificationSettingNotifier = ref.read(
                        _notificationSettingProvider(currentUserProfile.notifyOnProfileView).notifier,
                      );
                      final isUpdatingNotifier = ref.read(_isUpdatingNotificationProvider.notifier);
                      final settingsNotifier = ref.read(settingsProvider.notifier);
                      final profileNotifier = ref.read(currentUserProfileProvider.notifier);

                      // Update UI immediately
                      notificationSettingNotifier.state = value;
                      isUpdatingNotifier.state = true;

                      try {
                        // Update Firestore
                        await settingsNotifier.updateNotificationSetting('notifyOnProfileView', value);

                        // Refresh profile
                        await profileNotifier.loadCurrentUserProfile();

                        if (context.mounted) {
                          SnackbarHelper.showSuccess(
                            context,
                            value ? 'تم تفعيل الإشعارات' : 'تم تعطيل الإشعارات',
                          );
                        }
                      } catch (e) {
                        // Revert on error
                        notificationSettingNotifier.state = !value;
                        
                        if (context.mounted) {
                          SnackbarHelper.showError(
                            context,
                            'فشل في تحديث الإعدادات',
                          );
                        }
                      } finally {
                        isUpdatingNotifier.state = false;
                      }
                    },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Theme.of(context).dividerColor,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يمكنك التحكم في الإشعارات التي تستلمها من التطبيق',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Theme selector widget
  Widget _buildThemeSelector(BuildContext context, WidgetRef ref) {
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
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وضع المظهر',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'اختر شكل تطبيقك المفضل',
                      style: Theme.of(context).textTheme.bodyMedium,
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
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).cardTheme.color,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getThemeIcon(option),
                          color: isSelected
                              ? Colors.white
                              : Theme.of(
                                  context,
                                ).iconTheme.color?.withValues(alpha: 0.7),
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
                                : Theme.of(context).textTheme.bodyMedium?.color,
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
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'سيتم تبديل المظهر تلقائياً حسب إعدادات جهازك',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
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
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildNavigationTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Function() onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: (iconColor ?? Theme.of(context).colorScheme.primary)
              .withValues(alpha: 0.1),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: textColor),
      ),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      trailing: Icon(
        Icons.arrow_back_ios,
        size: 16,
        color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
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
                  final authNotifier = ref.read(authNotifierProvider.notifier);
                  await authNotifier.signOut();
                  await Future.delayed(const Duration(milliseconds: 300));

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    context.go('/auth/phone');
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
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
              Navigator.of(context).pop();

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
                  Navigator.of(context).pop();
                  context.go('/auth/phone');
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  SnackbarHelper.showError(context, 'فشل حذف الحساب: $e');
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
