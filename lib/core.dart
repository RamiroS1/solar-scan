import 'dart:ui';
import 'package:flutter/material.dart';

/// Tokens del sistema de diseno v1.0 (light glass).
class T {
  static const bg = Color(0xFFEEF1F5);
  static const bg2 = Color(0xFFF7F9FB);
  static const ink = Color(0xFF0C1B2E);
  static const ink70 = Color(0xA80C1B2E);
  static const ink45 = Color(0x730C1B2E);
  static const ink25 = Color(0x400C1B2E);
  static const hair = Color(0x170C1B2E);

  static const volt = Color(0xFF2563EB);
  static const iris = Color(0xFF6C5CE0);
  static const silicon = Color(0xFF1B3F8F);
  static const sun = Color(0xFFFFA51F);
  static const clay = Color(0xFFE4573D);
  static const go = Color(0xFF10855A);

  static const edge = Color(0xEBFFFFFF);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [volt, iris],
  );

  /// Gradiente real de un modulo monocristalino.
  static const module = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3465DE), Color(0xFF1B3F8F), Color(0xFF6250CE)],
    stops: [0, .5, 1],
  );

  static const mono = 'monospace';

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: volt, surface: bg2),
      scaffoldBackgroundColor: bg,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ink,
      ),
    );
  }
}

/// Fondo con las dos manchas de luz que el vidrio refracta.
class Ambient extends StatelessWidget {
  final Widget child;
  const Ambient({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: T.bg)),
        Positioned(
          top: -140,
          right: -120,
          child: _Blob(color: T.volt.withOpacity(.30), size: 340),
        ),
        Positioned(
          bottom: -160,
          left: -120,
          child: _Blob(color: T.iris.withOpacity(.26), size: 360),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
        ),
      ),
    );
  }
}

/// Superficie de vidrio esmerilado. Es el contenedor base de toda la app.
class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? border;
  final VoidCallback? onTap;

  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
    this.radius = 20,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(.74),
                Colors.white.withOpacity(.54),
              ],
            ),
            border: Border.all(color: border ?? T.edge, width: border != null ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0E2A4E).withOpacity(.13),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: r,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Boton principal con el degradado del modulo.
class Primary extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double height;
  const Primary({super.key, required this.label, this.onTap, this.height = 52});

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Opacity(
      opacity: on ? 1 : .45,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: T.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: on
                ? [BoxShadow(color: T.volt.withOpacity(.42), blurRadius: 20, offset: const Offset(0, 10))]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: height > 60 ? 18 : 15,
              letterSpacing: -.2,
            ),
          ),
        ),
      ),
    );
  }
}

class Ghost extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const Ghost({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: T.edge),
        ),
        child: Text(label,
            style: const TextStyle(
                color: T.ink, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}

/// Cifra medida: siempre monoespaciada, para que los digitos no bailen.
class Readout extends StatelessWidget {
  final String value;
  final String? unit;
  final double size;
  final Color? color;
  const Readout(this.value, {super.key, this.unit, this.size = 34, this.color});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: T.mono,
          fontWeight: FontWeight.w700,
          fontSize: size,
          height: 1,
          letterSpacing: -1,
          color: color ?? T.ink,
        ),
        children: [
          if (unit != null)
            TextSpan(
              text: '  $unit',
              style: TextStyle(
                fontFamily: T.mono,
                fontWeight: FontWeight.w400,
                fontSize: size * .4,
                color: T.ink45,
                letterSpacing: 0,
              ),
            ),
        ],
      ),
    );
  }
}

class Chip2 extends StatelessWidget {
  final String label;
  final Color color;
  const Chip2(this.label, {super.key, this.color = T.ink70});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color == T.ink70 ? Colors.white.withOpacity(.7) : color.withOpacity(.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
            color: color == T.ink70 ? T.edge : color.withOpacity(.45)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontFamily: T.mono, fontSize: 10, color: color == T.ink70 ? T.ink70 : color)),
      ]),
    );
  }
}

class KV extends StatelessWidget {
  final String k;
  final String v;
  final Color? color;
  const KV(this.k, this.v, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: T.hair)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontSize: 12.5, color: T.ink45)),
          Text(v,
              style: TextStyle(
                  fontFamily: T.mono,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: color ?? T.ink)),
        ],
      ),
    );
  }
}

class Label extends StatelessWidget {
  final String text;
  const Label(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontFamily: T.mono, fontSize: 9, letterSpacing: 1.6, color: T.ink45),
      );
}

class H1 extends StatelessWidget {
  final String text;
  const H1(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.8, height: 1.1));
}
