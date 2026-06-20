import 'package:flutter/material.dart';

/// 🎨 مساعدات الحركات والانتقالات
/// توفر أدوات سهلة لإضافة animations احترافية للتطبيق

/// ✅ Transition بسيط مع Fade
class FadePageTransition extends PageRouteBuilder {
  final Widget page;

  FadePageTransition({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// ✅ Transition مع Slide من اليمين
class SlideRightPageTransition extends PageRouteBuilder {
  final Widget page;

  SlideRightPageTransition({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end);
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

/// ✅ Transition مع Slide من اليسار
class SlideLeftPageTransition extends PageRouteBuilder {
  final Widget page;

  SlideLeftPageTransition({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(-1.0, 0.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end);
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

/// ✅ Transition مع Scale
class ScalePageTransition extends PageRouteBuilder {
  final Widget page;

  ScalePageTransition({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

/// ✅ Transition مع Rotate و Scale
class RotateScalePageTransition extends PageRouteBuilder {
  final Widget page;

  RotateScalePageTransition({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = 0.0;
      const end = 1.0;
      final tween = Tween(begin: begin, end: end);

      return ScaleTransition(
        scale: animation.drive(tween),
        child: RotationTransition(
          turns: animation.drive(tween),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 500),
  );
}

/// ✅ Widget يوفر حركة للزر عند الضغط
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration duration;

  const AnimatedButton({
    Key? key,
    required this.child,
    required this.onTap,
    this.duration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

/// ✅ Widget يوفر حركة عند ظهور العنصر
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const FadeInAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeInOut,
  }) : super(key: key);

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _offset = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

/// ✅ Widget يوفر حركة عند ظهور Card
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double elevation;
  final Color shadowColor;

  const AnimatedCard({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.elevation = 2,
    this.shadowColor = const Color(0x1F000000),
  }) : super(key: key);

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        transform: Matrix4.identity()
          ..translate(0, _isHovered ? -8 : 0),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor,
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 12 : 4),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// ✅ دالة للانتقال مع Fade
void navigateFade(BuildContext context, Widget page) {
  Navigator.of(context).push(FadePageTransition(page: page));
}

/// ✅ دالة للانتقال مع Slide من اليمين
void navigateSlideRight(BuildContext context, Widget page) {
  Navigator.of(context).push(SlideRightPageTransition(page: page));
}

/// ✅ دالة للانتقال مع Slide من اليسار
void navigateSlideLeft(BuildContext context, Widget page) {
  Navigator.of(context).push(SlideLeftPageTransition(page: page));
}

/// ✅ دالة للانتقال مع Scale
void navigateScale(BuildContext context, Widget page) {
  Navigator.of(context).push(ScalePageTransition(page: page));
}

/// ✅ Curve مخصص للحركات الناعمة
class CustomCurves {
  /// منحنى سلس جداً
  static final Curve smoothCurve = const Cubic(0.25, 0.46, 0.45, 0.94);

  /// منحنى مرتد
  static final Curve bouncyCurve = const Cubic(0.68, -0.55, 0.265, 1.55);

  /// منحنى سريع ثم بطيء
  static final Curve fastThenSlow = const Cubic(0.4, 0.0, 0.2, 1.0);

  /// منحنى بطيء ثم سريع
  static final Curve slowThenFast = const Cubic(0.25, 0.46, 0.45, 0.94);
}

/// ✅ تأثير النبض (Pulse Effect)
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  }) : super(key: key);

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: widget.minScale, end: widget.maxScale)
        .animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}
