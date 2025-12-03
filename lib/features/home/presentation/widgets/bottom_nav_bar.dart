import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Bottom navigation bar widget for the main app
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: _StoriesIcon(isActive: false),
          activeIcon: _StoriesIcon(isActive: true),
          label: 'القصص',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.shuffle),
          activeIcon: Icon(CupertinoIcons.shuffle_thick),
          label: 'الشفل',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'المحادثات',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'الملف الشخصي',
        ),
      ],
    );
  }
}

/// Custom Instagram-style stories icon with dashed circle and plus
class _StoriesIcon extends StatelessWidget {
  final bool isActive;

  const _StoriesIcon({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive 
        ? Theme.of(context).colorScheme.primary 
        : Colors.grey;
    
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _StoriesIconPainter(
          color: color,
          isActive: isActive,
        ),
      ),
    );
  }
}

/// Custom painter for Instagram-style stories icon
class _StoriesIconPainter extends CustomPainter {
  final Color color;
  final bool isActive;

  _StoriesIconPainter({required this.color, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Draw dashed circle
    const dashCount = 8;
    const dashAngle = (2 * 3.14159) / dashCount;
    const gapRatio = 0.4;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapRatio);
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Draw plus sign in center
    final plusPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final plusSize = size.width * 0.35;
    
    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - plusSize / 2, center.dy),
      Offset(center.dx + plusSize / 2, center.dy),
      plusPaint,
    );
    
    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - plusSize / 2),
      Offset(center.dx, center.dy + plusSize / 2),
      plusPaint,
    );
  }

  @override
  bool shouldRepaint(_StoriesIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isActive != isActive;
  }
}
