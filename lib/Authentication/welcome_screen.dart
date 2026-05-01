import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'login_screen.dart';
import 'signup.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _videoReady = false;

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _topSlide;
  late Animation<Offset> _midSlide;
  late Animation<Offset> _btnSlide;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // ── Video: place your MP4 at assets/videos/background.mp4 ──
    _videoController = VideoPlayerController.asset(
      'assets/bgg.mp4',
    )..initialize().then((_) {
        _videoController
          ..setLooping(true)
          ..setVolume(0)
          ..play();
        setState(() => _videoReady = true);
      });

    // ── Animations ──
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _topSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _midSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideCtrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _btnSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideCtrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. MP4 background ──
          if (_videoReady)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [
                    Color(0xFF1A1035),
                    Color(0xFF0D0820),
                    Color(0xFF050310),
                    Color(0xFF000000),
                  ],
                ),
              ),
            ),

          // ── 2. Dark gradient overlay ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.25),
                  Colors.black.withOpacity(0.50),
                  Colors.black.withOpacity(0.78),
                  Colors.black.withOpacity(0.92),
                ],
                stops: const [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),

          // ── 3. UI ──
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // App name
                  SlideTransition(
                    position: _topSlide,
                    child: ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [
                          Color(0xFFE8DEFF),
                          Color(0xFFC9B8FF),
                          Color(0xFF9B87D8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(b),
                      child: const Text(
                        'Nidra',
                        style: TextStyle(
                          fontSize: 70,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 12,
                          color: Colors.white,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  SlideTransition(
                    position: _midSlide,
                    child: Text(
                      'personal sleeping assistant',
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 4,
                        color: Colors.white.withOpacity(0.50),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Thin divider rule
                  SlideTransition(
                    position: _midSlide,
                    child: Container(
                      width: 55,
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          const Color(0xFFC9B8FF).withOpacity(0.55),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Buttons
                  SlideTransition(
                    position: _btnSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                           _NidraButton(
                             label: 'Log In',
                             filled: true,
                             onTap: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(builder: (_) => const SignInScreen()),
                               );
                             },
                           ),
                          const SizedBox(height: 14),
                           _NidraButton(
                             label: 'Create Account',
                             filled: false,
                             onTap: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(builder: (_) => const FullSignUpScreen()),
                               );
                             },
                           ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 44),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Button widget
// ─────────────────────────────────────────────

class _NidraButton extends StatefulWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _NidraButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_NidraButton> createState() => _NidraButtonState();
}

class _NidraButtonState extends State<_NidraButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    lowerBound: 0.95,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.filled
                ? const LinearGradient(
                    colors: [Color(0xFF7B67D8), Color(0xFF9B87D8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.filled ? null : Colors.white.withOpacity(0.08),
            border: Border.all(
              color: widget.filled
                  ? const Color(0xFF9B87D8).withOpacity(0.4)
                  : Colors.white.withOpacity(0.18),
            ),
            boxShadow: widget.filled
                ? [
                    BoxShadow(
                      color: const Color(0xFF7B67D8).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.5,
              color: widget.filled
                  ? Colors.white
                  : Colors.white.withOpacity(0.78),
            ),
          ),
        ),
      ),
    );
  }
}