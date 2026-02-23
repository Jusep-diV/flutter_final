import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final VoidCallback? onHomeTap;
  final VoidCallback? onSettingsTap;

  const BottomNav({
    super.key,
    this.onHomeTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.orange,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onHomeTap,
              child: Center(
                child: Image.asset(
                  'assets/images/home.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onSettingsTap,
              child: Center(
                child: Image.asset(
                  'assets/images/settings.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}