import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AnalogGauge extends StatelessWidget {
  const AnalogGauge({
    required this.title,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.unit,
    required this.majorDivisions,
    this.decimalPlaces = 0,
    this.warningFrom,
    this.warningUntil,
    super.key,
  });

  final String title;
  final double value;
  final double minimum;
  final double maximum;
  final String unit;
  final int majorDivisions;
  final int decimalPlaces;
  final double? warningFrom;
  final double? warningUntil;

  @override
  Widget build(BuildContext context) {
    final displayValue = '${value.toStringAsFixed(decimalPlaces)}$unit';
    return Semantics(
      label: '$title $displayValue',
      child: AspectRatio(
        aspectRatio: 1,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(minimum, maximum)),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, _) => Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _AnalogGaugePainter(
                  value: animatedValue,
                  minimum: minimum,
                  maximum: maximum,
                  majorDivisions: majorDivisions,
                  warningFrom: warningFrom,
                  warningUntil: warningUntil,
                ),
              ),
              Align(
                alignment: const Alignment(0, -0.47),
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.paleGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.50),
                child: Text(
                  displayValue,
                  style: const TextStyle(
                    color: Color(0xFFF2E9CD),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalogGaugePainter extends CustomPainter {
  const _AnalogGaugePainter({
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.majorDivisions,
    required this.warningFrom,
    required this.warningUntil,
  });

  final double value;
  final double minimum;
  final double maximum;
  final int majorDivisions;
  final double? warningFrom;
  final double? warningUntil;

  static const _startAngle = math.pi * 0.75;
  static const _sweepAngle = math.pi * 1.5;
  static const _minorTicksPerDivision = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    _paintBezel(canvas, center, radius);
    _paintWarningArc(canvas, center, radius);
    _paintTicks(canvas, center, radius);
    _paintNeedle(canvas, center, radius);
  }

  void _paintBezel(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF25231C), Color(0xFF080807)],
          stops: [0, 0.78],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius - 2.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..shader = AppColors.metallicGold.createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );
    canvas.drawCircle(
      center,
      radius - 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF4D4635),
    );
  }

  void _paintWarningArc(Canvas canvas, Offset center, double radius) {
    final lowWarning = warningUntil;
    if (lowWarning != null) {
      final normalized = ((lowWarning - minimum) / (maximum - minimum)).clamp(
        0.0,
        1.0,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.79),
        _startAngle,
        _sweepAngle * normalized,
        false,
        Paint()
          ..color = const Color(0xFFB93228)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }

    final warning = warningFrom;
    if (warning == null) return;
    final normalized = ((warning - minimum) / (maximum - minimum)).clamp(
      0.0,
      1.0,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.79),
      _startAngle + (_sweepAngle * normalized),
      _sweepAngle * (1 - normalized),
      false,
      Paint()
        ..color = const Color(0xFFB93228)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  void _paintTicks(Canvas canvas, Offset center, double radius) {
    final totalMinorTicks = majorDivisions * _minorTicksPerDivision;
    for (var tick = 0; tick <= totalMinorTicks; tick++) {
      final isMajor = tick % _minorTicksPerDivision == 0;
      final fraction = tick / totalMinorTicks;
      final angle = _startAngle + (_sweepAngle * fraction);
      canvas.drawLine(
        _point(center, radius * (isMajor ? 0.68 : 0.74), angle),
        _point(center, radius * 0.82, angle),
        Paint()
          ..color = isMajor ? const Color(0xFFF0E4BF) : const Color(0xFF9E967D)
          ..strokeWidth = isMajor ? 2 : 1,
      );
      if (isMajor) {
        final labelValue = minimum + ((maximum - minimum) * fraction);
        _paintLabel(
          canvas,
          center,
          radius * 0.56,
          angle,
          labelValue.round().toString(),
        );
      }
    }
  }

  void _paintLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    String label,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFFD8CFB4),
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final point = _point(center, radius, angle);
    painter.paint(
      canvas,
      point - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _paintNeedle(Canvas canvas, Offset center, double radius) {
    final fraction = ((value - minimum) / (maximum - minimum)).clamp(0.0, 1.0);
    final angle = _startAngle + (_sweepAngle * fraction);
    canvas.drawLine(
      _point(center, radius * 0.11, angle + math.pi),
      _point(center, radius * 0.62, angle),
      Paint()
        ..color = AppColors.paleGold
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, radius * 0.075, Paint()..color = AppColors.gold);
    canvas.drawCircle(center, radius * 0.035, Paint()..color = AppColors.black);
  }

  Offset _point(Offset center, double radius, double angle) =>
      center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);

  @override
  bool shouldRepaint(_AnalogGaugePainter oldDelegate) =>
      value != oldDelegate.value ||
      minimum != oldDelegate.minimum ||
      maximum != oldDelegate.maximum ||
      warningFrom != oldDelegate.warningFrom ||
      warningUntil != oldDelegate.warningUntil;
}
