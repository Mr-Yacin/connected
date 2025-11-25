import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/models/report.dart';
import '../providers/moderation_provider.dart';

/// Bottom sheet for reporting content
class ReportBottomSheet extends ConsumerStatefulWidget {
  final String reporterId;
  final String reportedUserId;
  final ReportType reportType;
  final String? reportedContentId;

  const ReportBottomSheet({
    super.key,
    required this.reporterId,
    required this.reportedUserId,
    required this.reportType,
    this.reportedContentId,
  });

  @override
  ConsumerState<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends ConsumerState<ReportBottomSheet> {
  String? _selectedReason;
  final _customReasonController = TextEditingController();

  final List<String> _reportReasons = [
    'محتوى غير لائق',
    'تحرش أو إزعاج',
    'انتحال شخصية',
    'محتوى مضلل',
    'سلوك مسيء',
    'أخرى',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  void _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار سبب البلاغ')),
      );
      return;
    }

    String reason = _selectedReason!;
    if (_selectedReason == 'أخرى') {
      if (_customReasonController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء كتابة سبب البلاغ')),
        );
        return;
      }
      reason = _customReasonController.text.trim();
    }

    final report = Report(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reporterId: widget.reporterId,
      reportedUserId: widget.reportedUserId,
      reportedContentId: widget.reportedContentId,
      type: widget.reportType,
      reason: reason,
      createdAt: DateTime.now(),
    );

    await ref.read(moderationProvider.notifier).reportContent(report);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال البلاغ بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الإبلاغ عن محتوى',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Report reasons
          ...(_reportReasons.map((reason) {
            return RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                });
              },
            );
          }).toList()),

          // Custom reason text field
          if (_selectedReason == 'أخرى') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _customReasonController,
              decoration: const InputDecoration(
                labelText: 'اكتب السبب',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],

          const SizedBox(height: 20),

          // Submit button
          ElevatedButton(
            onPressed: _submitReport,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'إرسال البلاغ',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
