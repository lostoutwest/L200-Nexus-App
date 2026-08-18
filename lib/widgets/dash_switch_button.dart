import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DashSwitchButton extends StatelessWidget {
  const DashSwitchButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.illuminated = false,
    this.glowColor,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool illuminated;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final activeGlow = glowColor ?? (illuminated ? AppColors.paleGold : null);
    final lampColor = activeGlow ?? const Color(0xFF4A4029);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.metallicGold,
                boxShadow: [
                  const BoxShadow(
                    color: Colors.black87,
                    blurRadius: 12,
                    offset: Offset(0, 7),
                  ),
                  if (activeGlow != null)
                    BoxShadow(
                      color: activeGlow.withValues(alpha: 0.38),
                      blurRadius: 22,
                    ),
                ],
              ),
              child: Material(
                color: AppColors.black,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  customBorder: const CircleBorder(),
                  splashColor: AppColors.gold.withValues(alpha: 0.24),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: activeGlow == null
                                ? const [Color(0xFF26241D), Color(0xFF090908)]
                                : [
                                    activeGlow.withValues(alpha: 0.78),
                                    activeGlow.withValues(alpha: 0.30),
                                    const Color(0xFF090908),
                                  ],
                            stops: activeGlow == null
                                ? null
                                : const [0, 0.55, 1],
                          ),
                          border: Border.all(color: const Color(0xFF4E4838)),
                          boxShadow: activeGlow == null
                              ? null
                              : [
                                  BoxShadow(
                                    color: activeGlow.withValues(alpha: 0.62),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                        ),
                      ),
                      Icon(icon, size: 38, color: AppColors.paleGold),
                      Positioned(
                        bottom: 14,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: lampColor,
                            shape: BoxShape.circle,
                            boxShadow: activeGlow != null
                                ? [BoxShadow(color: activeGlow, blurRadius: 8)]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: enabled ? AppColors.paleGold : Colors.white30,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
