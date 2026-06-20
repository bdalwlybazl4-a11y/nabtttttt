import 'dart:ui';

import 'package:flutter/material.dart';

/// Bottom Navigation Bar فاخر عائم مع انحناءة وسطية وأيقونة مركزية طافية.
class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final centerIndex = items.isEmpty ? 0 : items.length ~/ 2;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        height: 96,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              top: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withOpacity(isDark ? .32 : .16),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: scheme.primary.withOpacity(isDark ? .24 : .16),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipPath(
                  clipper: _FloatingNavClipper(),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primary.withOpacity(isDark ? .20 : .10),
                            scheme.surface.withOpacity(isDark ? .76 : .92),
                            scheme.secondary.withOpacity(isDark ? .14 : .08),
                          ],
                        ),
                        border: Border.all(
                          color: scheme.primary.withOpacity(isDark ? .18 : .14),
                        ),
                      ),
                      child: Row(
                        children: List.generate(items.length, (index) {
                          if (index == centerIndex) {
                            return const Expanded(child: SizedBox.shrink());
                          }
                          return Expanded(
                            child: _NavPill(
                              item: items[index],
                              isActive: index == currentIndex,
                              onTap: () => onTap(index),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (items.isNotEmpty)
              Positioned(
                top: 0,
                child: _FloatingCenterAction(
                  item: items[centerIndex],
                  isActive: centerIndex == currentIndex,
                  onTap: () => onTap(centerIndex),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNavClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final center = size.width / 2;
    const notchWidth = 94.0;
    const notchDepth = 28.0;
    const radius = 34.0;

    path.moveTo(radius, 0);
    path.lineTo(center - notchWidth / 2, 0);
    path.cubicTo(
      center - 36,
      0,
      center - 34,
      notchDepth,
      center,
      notchDepth,
    );
    path.cubicTo(
      center + 34,
      notchDepth,
      center + 36,
      0,
      center + notchWidth / 2,
      0,
    );
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _FloatingCenterAction extends StatelessWidget {
  final BottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _FloatingCenterAction({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      selected: isActive,
      button: true,
      label: item.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isActive ? 1.08 : 1,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary,
                  Color.lerp(scheme.primary, scheme.secondary, .55)!,
                ],
              ),
              border: Border.all(color: scheme.onPrimary.withOpacity(.26), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withOpacity(isActive ? .42 : .28),
                  blurRadius: isActive ? 34 : 26,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: scheme.secondary.withOpacity(.18),
                  blurRadius: 22,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: scheme.onPrimary, size: 28),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
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

class _NavPill extends StatelessWidget {
  final BottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavPill({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeColor = scheme.primary;
    final inactiveColor = scheme.onSurface.withOpacity(.64);

    return Semantics(
      selected: isActive,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      activeColor.withOpacity(.20),
                      scheme.secondary.withOpacity(.10),
                    ],
                  )
                : null,
            border: Border.all(
              color: isActive ? activeColor.withOpacity(.26) : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.05 : 1,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: Icon(
                  item.icon,
                  color: isActive
                      ? activeColor
                      : inactiveColor.withOpacity(.78),
                  size: isActive ? 20 : 18,
                ),
              ),

              const SizedBox(height: 1),

              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 260),
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: isActive
                        ? activeColor
                        : inactiveColor.withOpacity(.78),
                    fontWeight:
                    isActive ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 9,
                    height: 1,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 1),

              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: isActive ? 18 : 4,
                height: 2,
                decoration: BoxDecoration(
                  color: isActive
                      ? activeColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final String label;
  final IconData icon;

  const BottomNavItem({
    required this.label,
    required this.icon,
  });
}

class AdvancedBottomNavBar extends ModernBottomNavBar {
  const AdvancedBottomNavBar({
    super.key,
    required super.currentIndex,
    required super.onTap,
    required super.items,
  });
}

class SimpleBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const SimpleBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) => ModernBottomNavBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: items,
      );
}
