import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:instrunment_app/telemetry/flight_telemetry.dart';
import 'package:instrunment_app/theme/instrument_palette.dart';

class InstrumentPanel extends StatelessWidget {
  const InstrumentPanel({
    super.key,
    required this.map,
    required this.status,
    required this.isStale,
    this.frame,
    this.navigationLabel,
    this.navigationDistanceKilometers,
    this.onRecenter,
    this.showAttribution = true,
  });

  final Widget map;
  final FlightTelemetry? frame;
  final String status;
  final bool isStale;
  final String? navigationLabel;
  final double? navigationDistanceKilometers;
  final VoidCallback? onRecenter;
  final bool showAttribution;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tapeWidth = (constraints.maxWidth * 0.15)
            .clamp(58.0, 76.0)
            .toDouble();
        const headerHeight = 96.0;
        const footerHeight = 82.0;
        final currentFrame = frame;
        final altitudeAboveGround = currentFrame == null
            ? 0.0
            : math
                  .max(
                    0,
                    currentFrame.altitudeMeters -
                        currentFrame.groundLevelMeters,
                  )
                  .toDouble();
        final activeColor = isStale || currentFrame == null
            ? InstrumentPalette.inactive
            : InstrumentPalette.accent;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: InstrumentPalette.background,
            border: Border.all(color: InstrumentPalette.line),
          ),
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(child: map),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: headerHeight,
                  child: _HeaderOverlay(
                    frame: currentFrame,
                    status: status,
                    isStale: isStale,
                    navigationLabel: navigationLabel,
                    navigationDistanceKilometers: navigationDistanceKilometers,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: headerHeight,
                  bottom: footerHeight,
                  width: tapeWidth,
                  child: _VerticalTape(
                    label: 'ALT',
                    unit: 'm AGL',
                    value: altitudeAboveGround,
                    interval: 1,
                    leftSide: true,
                    accent: activeColor,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: headerHeight,
                  bottom: footerHeight,
                  width: tapeWidth,
                  child: _VerticalTape(
                    label: 'IAS',
                    unit: 'm/s',
                    value: currentFrame?.airspeedMetersPerSecond ?? 0,
                    interval: 1,
                    leftSide: false,
                    accent: activeColor,
                  ),
                ),
                if (currentFrame != null)
                  Positioned(
                    left: tapeWidth,
                    right: tapeWidth,
                    top: headerHeight,
                    bottom: footerHeight,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _AircraftReticlePainter(
                          color: isStale
                              ? InstrumentPalette.inactive
                              : InstrumentPalette.accent,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: footerHeight,
                  child: _PedalingGauge(frame: currentFrame),
                ),
                if (showAttribution)
                  Positioned(
                    left: tapeWidth + 8,
                    bottom: footerHeight + 5,
                    child: const _MapAttribution(),
                  ),
                if (onRecenter != null)
                  Positioned(
                    right: tapeWidth + 10,
                    bottom: footerHeight + 10,
                    child: _RecenterButton(onPressed: onRecenter!),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderOverlay extends StatelessWidget {
  const _HeaderOverlay({
    required this.frame,
    required this.status,
    required this.isStale,
    required this.navigationLabel,
    required this.navigationDistanceKilometers,
  });

  final FlightTelemetry? frame;
  final String status;
  final bool isStale;
  final String? navigationLabel;
  final double? navigationDistanceKilometers;

  @override
  Widget build(BuildContext context) {
    final statusColor = isStale || status == 'RX ERROR'
        ? InstrumentPalette.danger
        : frame == null
        ? InstrumentPalette.inactive
        : InstrumentPalette.accent;
    final headingDegrees = frame == null
        ? null
        : ((frame!.yawRadians * 180 / math.pi + 360) % 360).round() % 360;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [InstrumentPalette.surface, InstrumentPalette.surfaceMuted],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: InstrumentPalette.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _StatusChip(label: status, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AttitudeRibbon(
                      rollRadians: frame?.rollRadians ?? 0,
                      pitchRadians: frame?.pitchRadians ?? 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 58,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'HDG',
                          style: TextStyle(
                            color: InstrumentPalette.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          headingDegrees == null
                              ? '---°'
                              : '${headingDegrees.toString().padLeft(3, '0')}°',
                          style: const TextStyle(
                            color: InstrumentPalette.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _NavigationReadout(
              label: navigationLabel,
              distanceKilometers: navigationDistanceKilometers,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 108),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: InstrumentPalette.surfaceRaised,
        border: Border.all(color: InstrumentPalette.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: InstrumentPalette.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttitudeRibbon extends StatelessWidget {
  const _AttitudeRibbon({
    required this.rollRadians,
    required this.pitchRadians,
  });

  final double rollRadians;
  final double pitchRadians;

  @override
  Widget build(BuildContext context) {
    final pitchDegrees = pitchRadians * 180 / math.pi;
    final pitchOffset = (pitchDegrees / 15).clamp(-1.0, 1.0).toDouble() * 7;

    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned(
          top: 1,
          child: SizedBox(
            width: 44,
            child: Divider(
              height: 2,
              thickness: 2,
              color: InstrumentPalette.textSecondary,
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, pitchOffset),
          child: Transform.rotate(
            angle: -rollRadians,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.arrow_right,
                  size: 17,
                  color: InstrumentPalette.accent,
                ),
                SizedBox(
                  width: 62,
                  child: Divider(
                    height: 2,
                    thickness: 2,
                    color: InstrumentPalette.accent,
                  ),
                ),
                SizedBox(width: 14),
                SizedBox(
                  width: 62,
                  child: Divider(
                    height: 2,
                    thickness: 2,
                    color: InstrumentPalette.accent,
                  ),
                ),
                Icon(
                  Icons.arrow_left,
                  size: 17,
                  color: InstrumentPalette.accent,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: InstrumentPalette.surfaceRaised,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'ROLL ${(rollRadians * 180 / math.pi).toStringAsFixed(1)}°   '
              'PITCH ${pitchDegrees.toStringAsFixed(1)}°',
              style: const TextStyle(
                color: InstrumentPalette.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavigationReadout extends StatelessWidget {
  const _NavigationReadout({
    required this.label,
    required this.distanceKilometers,
  });

  final String? label;
  final double? distanceKilometers;

  @override
  Widget build(BuildContext context) {
    final hasSelection = label != null && distanceKilometers != null;
    return Container(
      height: 23,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: InstrumentPalette.surfaceMuted,
        border: Border(top: BorderSide(color: InstrumentPalette.lineSoft)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'NAV',
            style: TextStyle(
              color: InstrumentPalette.accent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hasSelection
                ? '$label  ${distanceKilometers!.toStringAsFixed(1)} km'
                : 'タップで追加・長押しで選択',
            style: TextStyle(
              color: hasSelection
                  ? InstrumentPalette.textPrimary
                  : InstrumentPalette.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalTape extends StatelessWidget {
  const _VerticalTape({
    required this.label,
    required this.unit,
    required this.value,
    required this.interval,
    required this.leftSide,
    required this.accent,
  });

  final String label;
  final String unit;
  final double value;
  final double interval;
  final bool leftSide;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VerticalTapePainter(
        label: label,
        unit: unit,
        value: value,
        interval: interval,
        leftSide: leftSide,
        accent: accent,
        fontFamily: DefaultTextStyle.of(context).style.fontFamily,
      ),
    );
  }
}

class _VerticalTapePainter extends CustomPainter {
  const _VerticalTapePainter({
    required this.label,
    required this.unit,
    required this.value,
    required this.interval,
    required this.leftSide,
    required this.accent,
    required this.fontFamily,
  });

  final String label;
  final String unit;
  final double value;
  final double interval;
  final bool leftSide;
  final Color accent;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = InstrumentPalette.surface,
    );
    final axisX = leftSide ? size.width - 3 : 3.0;
    canvas.drawLine(
      Offset(axisX, 0),
      Offset(axisX, size.height),
      Paint()
        ..color = InstrumentPalette.line
        ..strokeWidth = 1,
    );

    _drawText(
      canvas,
      '$label\n$unit',
      Offset(leftSide ? 5 : 9, 8),
      const TextStyle(
        color: InstrumentPalette.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
    );

    final centerY = size.height / 2;
    const spacing = 42.0;
    for (var offset = -5; offset <= 5; offset++) {
      final y = centerY - offset * spacing;
      if (y < 44 || y > size.height - 8) {
        continue;
      }
      final tickValue = value + offset * interval;
      if (tickValue < 0) {
        continue;
      }
      final isMajor = offset.isEven;
      final tickLength = isMajor ? 15.0 : 9.0;
      final fromX = leftSide ? axisX - tickLength : axisX;
      final toX = leftSide ? axisX : axisX + tickLength;
      canvas.drawLine(
        Offset(fromX, y),
        Offset(toX, y),
        Paint()
          ..color = isMajor
              ? InstrumentPalette.textSecondary
              : InstrumentPalette.line
          ..strokeWidth = isMajor ? 2 : 1,
      );
      if (isMajor && offset != 0) {
        final text = tickValue.toStringAsFixed(tickValue >= 10 ? 0 : 1);
        _drawText(
          canvas,
          text,
          Offset(leftSide ? 5 : 20, y - 7),
          const TextStyle(
            color: InstrumentPalette.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        );
      }
    }

    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, centerY - 16, size.width - 12, 32),
      const Radius.circular(3),
    );
    canvas.drawRRect(box, Paint()..color = accent);
    final pointer = Path();
    if (leftSide) {
      pointer
        ..moveTo(size.width - 6, centerY - 6)
        ..lineTo(size.width, centerY)
        ..lineTo(size.width - 6, centerY + 6);
    } else {
      pointer
        ..moveTo(6, centerY - 6)
        ..lineTo(0, centerY)
        ..lineTo(6, centerY + 6);
    }
    pointer.close();
    canvas.drawPath(pointer, Paint()..color = accent);
    _drawCenteredText(
      canvas,
      value.toStringAsFixed(value >= 10 ? 0 : 1),
      Offset(size.width / 2, centerY),
      const TextStyle(
        color: InstrumentPalette.background,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(fontFamily: fontFamily),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(fontFamily: fontFamily),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _VerticalTapePainter oldDelegate) {
    return label != oldDelegate.label ||
        unit != oldDelegate.unit ||
        value != oldDelegate.value ||
        interval != oldDelegate.interval ||
        leftSide != oldDelegate.leftSide ||
        accent != oldDelegate.accent ||
        fontFamily != oldDelegate.fontFamily;
  }
}

class _AircraftReticlePainter extends CustomPainter {
  const _AircraftReticlePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center.translate(0, -72), center.translate(0, -10), paint);
    canvas.drawLine(center.translate(-34, 0), center.translate(-7, 0), paint);
    canvas.drawLine(center.translate(7, 0), center.translate(34, 0), paint);
    canvas.drawLine(center.translate(0, -7), center.translate(0, 10), paint);
    final aircraft = Path()
      ..moveTo(center.dx, center.dy - 13)
      ..lineTo(center.dx - 7, center.dy + 5)
      ..lineTo(center.dx, center.dy + 1)
      ..lineTo(center.dx + 7, center.dy + 5)
      ..close();
    canvas.drawPath(
      aircraft,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _AircraftReticlePainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

class _PedalingGauge extends StatelessWidget {
  const _PedalingGauge({required this.frame});

  final FlightTelemetry? frame;

  @override
  Widget build(BuildContext context) {
    final cadence = frame?.pedalCadenceRpm;
    final value = cadence ?? frame?.pedalPowerWatts ?? 0;
    final maximum = cadence == null ? 400.0 : 150.0;
    final fraction = (value / maximum).clamp(0.0, 1.0).toDouble();
    final label = cadence == null ? 'POWER' : 'CADENCE';
    final unit = cadence == null ? 'W' : 'RPM';

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: InstrumentPalette.surface,
        border: Border(top: BorderSide(color: InstrumentPalette.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 7),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: InstrumentPalette.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${value.toStringAsFixed(0)} $unit',
                    style: const TextStyle(
                      color: InstrumentPalette.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 9,
                      backgroundColor: InstrumentPalette.surfaceRaised,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        InstrumentPalette.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '0',
                        style: TextStyle(
                          color: InstrumentPalette.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                      if (cadence != null)
                        Text(
                          '${frame!.pedalPowerWatts.toStringAsFixed(0)} W',
                          style: const TextStyle(
                            color: InstrumentPalette.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      Text(
                        maximum.toStringAsFixed(0),
                        style: const TextStyle(
                          color: InstrumentPalette.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: InstrumentPalette.surface.withValues(alpha: 0.82),
        border: Border.all(color: InstrumentPalette.lineSoft),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          '© OpenStreetMap contributors',
          style: TextStyle(color: InstrumentPalette.textSecondary, fontSize: 8),
        ),
      ),
    );
  }
}

class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: InstrumentPalette.surface,
      shape: const CircleBorder(
        side: BorderSide(color: InstrumentPalette.line),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.my_location,
            color: InstrumentPalette.accent,
            size: 22,
          ),
        ),
      ),
    );
  }
}
