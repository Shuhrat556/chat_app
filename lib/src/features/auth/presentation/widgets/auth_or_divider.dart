import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.h,
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF8E95AD),
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1.h,
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }
}
