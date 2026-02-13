import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class OlympicColors {
  static const bgCharcoal = Color(0xFF1C1C1E);
  static const bgCard = Color(0xFF2C2C2E);
  static const bgElevated = Color(0xFF3A3A3C);

  static const redOlympic = Color(0xFFE63946);
  static const blueOlympic = Color(0xFF1D3557);

  static const goldMedal = Color(0xFFF4C430);
  static const silverMedal = Color(0xFFADB5BD);
  static const bronzeMedal = Color(0xFFCD7F32);

  static const white = Color(0xFFFFFFFF);
  static const gray100 = Color(0xFFF8F9FA);
  static const gray300 = Color(0xFFDEE2E6);
  static const gray500 = Color(0xFFADB5BD);
  static const gray700 = Color(0xFF495057);
  static const gray900 = Color(0xFF212529);

  static const laneColors = [
    Color(0xFFE63946),
    Color(0xFF457B9D),
    Color(0xFF2A9D8F),
    Color(0xFFE9C46A),
    Color(0xFF7209B7),
    Color(0xFFF77F00),
    Color(0xFF06D6A0),
    Color(0xFFEF476F),
    Color(0xFF118AB2),
  ];

  static const statusRowing = Color(0xFF3B82F6);
  static const statusRowingLight = Color(0xFF60A5FA);
  static const statusFinished = Color(0xFF22C55E);
  static const statusFinishedLight = Color(0xFF4ADE80);
}

abstract class OlympicTextStyles {
  static TextStyle headline({double fontSize = 52, Color? color}) =>
      GoogleFonts.bebasNeue(
        fontSize: fontSize,
        color: color ?? OlympicColors.white,
        letterSpacing: 4,
      );

  static TextStyle bigNumber({double fontSize = 36, Color? color}) =>
      GoogleFonts.bebasNeue(
        fontSize: fontSize,
        color: color ?? OlympicColors.white,
        letterSpacing: 2,
      );

  static TextStyle label({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double letterSpacing = 3,
  }) =>
      GoogleFonts.barlowCondensed(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? OlympicColors.gray500,
        letterSpacing: letterSpacing,
      );

  static TextStyle participantName({double fontSize = 20, Color? color}) =>
      GoogleFonts.barlowCondensed(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color ?? OlympicColors.white,
        letterSpacing: 0.5,
      );

  static TextStyle mono({
    double fontSize = 17,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? OlympicColors.white,
      );

  static TextStyle body({double fontSize = 14, Color? color}) =>
      GoogleFonts.barlow(
        fontSize: fontSize,
        color: color ?? OlympicColors.white,
      );
}

abstract class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: OlympicColors.bgCharcoal,
        colorScheme: const ColorScheme.dark(
          primary: OlympicColors.redOlympic,
          secondary: OlympicColors.blueOlympic,
          surface: OlympicColors.bgCard,
          onPrimary: OlympicColors.white,
          onSecondary: OlympicColors.white,
          onSurface: OlympicColors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: OlympicColors.bgCharcoal,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.barlowCondensed(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: OlympicColors.white,
            letterSpacing: 2,
          ),
          iconTheme: const IconThemeData(color: OlympicColors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: OlympicColors.redOlympic,
            foregroundColor: OlympicColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: GoogleFonts.bebasNeue(
              fontSize: 22,
              letterSpacing: 4,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: OlympicColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: OlympicColors.bgElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: OlympicColors.gray500),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: OlympicColors.bgCard,
          contentTextStyle: TextStyle(color: OlympicColors.white),
        ),
        dividerColor: OlympicColors.bgElevated,
      );

  static String rankSuffix(int rank) {
    switch (rank) {
      case 1:
        return 'rank_1st'.tr();
      case 2:
        return 'rank_2nd'.tr();
      case 3:
        return 'rank_3rd'.tr();
      default:
        return 'rank_nth'.tr();
    }
  }

  static Color rankColor(int rank) {
    switch (rank) {
      case 1:
        return OlympicColors.goldMedal;
      case 2:
        return OlympicColors.silverMedal;
      case 3:
        return OlympicColors.bronzeMedal;
      default:
        return OlympicColors.gray500;
    }
  }

  static Color laneColor(int index) =>
      OlympicColors.laneColors[index % OlympicColors.laneColors.length];

  static LinearGradient trackBarGradient(Color color) => LinearGradient(
        colors: [color.withValues(alpha: 0.15), color],
      );
}

class AngleRightClipper extends CustomClipper<Path> {
  final double angle;
  AngleRightClipper({this.angle = 20});

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(size.width - angle, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class ParallelogramClipper extends CustomClipper<Path> {
  final double angle;
  ParallelogramClipper({this.angle = 20});

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(angle, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - angle, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class AngleLeftClipper extends CustomClipper<Path> {
  final double angle;
  AngleLeftClipper({this.angle = 20});

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(angle, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OlympicColors.redOlympic.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    const stripeWidth = 20.0;
    final diagonal = size.width + size.height;

    for (double i = 0; i < diagonal; i += stripeWidth * 2) {
      final path = Path()
        ..moveTo(i, 0)
        ..lineTo(i + stripeWidth, 0)
        ..lineTo(i + stripeWidth - size.height, size.height)
        ..lineTo(i - size.height, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
