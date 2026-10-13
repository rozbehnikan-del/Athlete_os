import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.brandBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/images/onboarding_hero.jpg'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: .24)),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xDD071119),
                  AppColors.brandBlack,
                ],
                stops: [0.35, 0.72, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _AthleteLogoMark(),
                      const SizedBox(width: 14),
                      Text(
                        l.app,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    l.heroTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      height: .96,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l.heroSubtitle,
                    style: const TextStyle(
                      color: Color(0xFFC3CAD0),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: _OnboardingButton(
                      label: l.getStarted,
                      onPressed: onGetStarted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        '${l.signinPrompt} ${l.signIn}',
                        style: const TextStyle(
                          color: Color(0xFFC3CAD0),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AthleteLogoMark extends StatelessWidget {
  const _AthleteLogoMark();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 48,
    height: 32,
    child: CustomPaint(painter: _LogoPainter()),
  );
}

class _OnboardingButton extends StatelessWidget {
  const _OnboardingButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandBlack,
        minimumSize: const Size(0, 50),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(2, size.height - 3)
      ..lineTo(size.width * .26, 4)
      ..lineTo(size.width * .48, size.height - 3)
      ..lineTo(size.width * .64, 8)
      ..lineTo(size.width - 2, size.height - 3);
    canvas.drawPath(path, p);
    canvas.drawLine(
      Offset(size.width * .20, size.height - 3),
      Offset(size.width * .39, size.height * .42),
      p,
    );
    canvas.drawLine(
      Offset(size.width * .36, size.height - 3),
      Offset(size.width * .54, size.height * .42),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
