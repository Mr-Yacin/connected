import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_connect_app/core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
      appBar: AppBar(
        title: Text(
          'سياسة الخصوصية',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDarkMode ? Colors.white70 : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header illustration
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.primary.withValues(alpha: 0.05),
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.privacy_tip_outlined,
                            size: 80,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Title
                      Text(
                        'سياسة الخصوصية',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        'آخر تحديث: نوفمبر 2024',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Content sections
                      _buildSection(
                        title: '1. جمع المعلومات',
                        content: 'نقوم بجمع المعلومات التي تقدمها لنا مباشرة عند إنشاء حسابك، بما في ذلك اسمك والبريد الإلكتروني وأي معلومات أخرى تختار مشاركتها.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '2. استخدام المعلومات',
                        content: 'نستخدم المعلومات التي نجمعها لتقديم خدمتنا، وتحسينها، والتواصل معك بشأن حسابك، وتقديم الدعم الفني.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '3. مشاركة المعلومات',
                        content: 'لا نبيع معلوماتك أو نشاركها مع أطراف ثالثة لأغراض تسويقية. قد نشارك معلوماتك فقط كما هو موضح في هذه السياسة أو بموافقتك.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '4. أمان البيانات',
                        content: 'نتخذ تدابير أمنية معقولة لحماية معلوماتك من الوصول غير المصرح به أو التعديل أو الإفصاح.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '5. حقوقك',
                        content: 'لديك الحق في الوصول إلى معلوماتك وتصحيحها وحذفها. يمكنك إدارة حسابك وإعدادات الخصوصية من خلال التطبيق.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '6. التغييرات في هذه السياسة',
                        content: 'قد نحدث سياسة الخصوصية هذه من وقت لآخر. سنلزمك بأي تغييرات من خلال نشر السياسة المحدثة في هذا التطبيق.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '7. تواصل معنا',
                        content: 'إذا كان لديك أي أسئلة حول هذه سياسة الخصوصية، يمكنك التواصل معنا عبر البريد الإلكتروني.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      const SizedBox(height: 40),
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

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDarkMode 
                  ? Colors.white.withValues(alpha: 0.05) 
                  : Colors.black.withValues(alpha: 0.03),
              border: Border.all(
                color: isDarkMode 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}