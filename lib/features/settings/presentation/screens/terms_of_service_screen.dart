import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_connect_app/core/theme/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
      appBar: AppBar(
        title: Text(
          'شروط الخدمة',
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
                              AppColors.primary.withOpacity(0.1),
                              AppColors.primary.withOpacity(0.05),
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.description_outlined,
                            size: 80,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Title
                      Text(
                        'شروط الخدمة',
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
                        title: '1. قبول الشروط',
                        content: 'باستخدام هذا التطبيق، فإنك توافق على الالتزام بهذه الشروط والأحكام. إذا كنت لا توافق على هذه الشروط، يرجى عدم استخدام التطبيق.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '2. استخدام الخدمة',
                        content: 'يجب عليك استخدام الخدمة بشكل مسؤول وبطريقة تتوافق مع جميع القوانين المعمول بها. يُحظر بشدة الاستخدام غير القانوني أو الضار.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '3. حساب المستخدم',
                        content: 'أنت مسؤول عن الحفاظ على سرية معلومات حسابك وكلمة المرور الخاصة بك. أنت مسؤول عن جميع الأنشطة التي تحدث ضمن حسابك.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '4. المحتوى الخاص بالمستخدم',
                        content: 'تحتفظ بملكية المحتوى الذي تنشره. بمنحنا ترخيصاً لاستخدام المحتوى الذي تنشره لتقديم الخدمة وتحسينها.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '5. السلوك المحظور',
                        content: 'يُحظر التمييز أو المضايقة أو إرسال برامج ضارة أو انتهاك حقوق الآخرين أو إساءة استخدام الخدمة بأي شكل من الأشكال.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '6. الملكية الفكرية',
                        content: 'التطبيق ومحتويه محمية بموجب قوانين حقوق الطبع والنشر والعلامات التجارية وغيرها من قوانين الملكية الفكرية.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '7. إنهاء الخدمة',
                        content: 'نحن نحتفظ بالحق في تعليق أو إنهاء حسابك إذا انتهكت هذه الشروط. يمكنك أيضاً إغلاق حسابك في أي وقت.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '8. إخلاء المسؤولية',
                        content: 'يتم تقديم الخدمة "كما هي" دون أي ضمانات. نحن لا نضمن عدم انقطاع الخدمة أو خلوهنا من الأخطاء.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '9. حد المسؤولية',
                        content: 'نحن غير مسؤولين عن أي أضرار غير مباشرة أو عرضية أو تبعية تنشأ عن استخدامك للخدمة.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '10. التغييرات في الشروط',
                        content: 'قد نقوم بتحديث هذه الشروط من وقت لآخر. سيتم إعلامك بأي تغييرات مهمة من خلال التطبيق.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '11. القانون الحاكم',
                        content: 'تخضع هذه الشروط لقوانين الدولة المعمول بها. أي نزاع سيتم حله وفقاً للقوانين المحلية.',
                        isDarkMode: isDarkMode,
                      ),
                      
                      _buildSection(
                        title: '12. تواصل معنا',
                        content: 'إذا كان لديك أي أسئلة حول هذه الشروط، يمكنك التواصل معنا عبر البريد الإلكتروني.',
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
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.black.withOpacity(0.03),
              border: Border.all(
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.black.withOpacity(0.1),
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