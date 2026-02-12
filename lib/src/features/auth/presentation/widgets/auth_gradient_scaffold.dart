import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthGradientScaffold extends StatelessWidget {
  const AuthGradientScaffold({required this.child, this.footerText, super.key});

  final Widget child;
  final String? footerText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF070C24), Color(0xFF666079), Color(0xFFE2DAEF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -106.w,
              top: 160.h,
              child: _GlowCircle(
                size: 286.w,
                color: const Color(0xFF1B2E59).withValues(alpha: 0.45),
              ),
            ),
            Positioned(
              right: -88.w,
              bottom: 88.h,
              child: _GlowCircle(
                size: 248.w,
                color: const Color(0xFF7D5BCE).withValues(alpha: 0.35),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(child: child),
                  if (footerText != null) ...[
                    Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Text(
                        footerText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5B6483),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}
