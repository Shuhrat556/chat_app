import 'package:flutter/material.dart';

class AuthTopDecoration extends StatelessWidget {
  const AuthTopDecoration({this.width = 250, super.key});

  final double width;
  static const _baseWidth = 250.0;
  static const _baseHeight = 142.0;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: width * (_baseHeight / _baseWidth),
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: _baseWidth,
            height: _baseHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(42),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7E4BFF), Color(0xFFA543F4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 40,
                  top: 24,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x44F8F4FF),
                    ),
                  ),
                ),
                Positioned(
                  right: 36,
                  bottom: 24,
                  child: Container(
                    width: 130,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E4F4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 78,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0x8D7B5AE6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          top: 7,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF433B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
