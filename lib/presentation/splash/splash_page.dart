import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

  import '../../core/services/permission_service.dart';
import '../../di/service_locator.dart';

/// A beautiful animated splash screen with background image and logo
/// 
/// Features:
/// - Full-screen background image with blur overlay
/// - Animated logo with scale, fade, and glow effects
/// - Pulsing loading indicator
/// - Smooth entrance animations
/// - Responsive design for all screen sizes
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Pulse animation controller for loading indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Shimmer animation for the glow effect
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Logo scale animation - bouncy entrance
    _logoScaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Logo fade animation
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Pulse animation
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Shimmer animation for glow
    _shimmerAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Start the logo animation
    _logoController.forward();
    
    // Request permissions after a short delay
    _requestPermissions();
  }
  
  Future<void> _requestPermissions() async {
    // Wait for the splash animation to be visible
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Request all required permissions
    final permissionService = getIt<PermissionService>();
    await permissionService.requestAllPermissions();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Responsive logo size
    final logoSize = isTablet
        ? 180.w.clamp(150.0, 220.0)
        : (screenHeight < 700 ? 120.w : 150.w).clamp(100.0, 180.0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          _buildBackground(),

          // Gradient Overlay
          _buildGradientOverlay(),

          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Animated Logo
                _buildAnimatedLogo(logoSize),

                SizedBox(height: 24.h),

                // App Title
                _buildAppTitle(),

                const Spacer(flex: 2),

                // Loading Indicator
                _buildLoadingIndicator(),

                SizedBox(height: 16.h),

                // Loading Text
                _buildLoadingText(),

                const Spacer(),

                // Version Info
                _buildVersionInfo(),

                SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Image.asset(
      'lib/assets/images/login-bgg.jpg',
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        // Fallback gradient if image doesn't load
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F3460),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.6),
            Colors.black.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildAnimatedLogo(double logoSize) {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _shimmerController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Opacity(
            opacity: _logoFadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(
                      alpha: _shimmerAnimation.value * 0.3,
                    ),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: const Color(0xFF006778).withValues(
                      alpha: _shimmerAnimation.value * 0.5,
                    ),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        width: logoSize,
        height: logoSize,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Image.asset(
          'lib/assets/images/YDC-HD.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            // Fallback icon if image doesn't load
            return Icon(
              Icons.timelapse_rounded,
              size: logoSize * 0.5,
              color: Colors.white,
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppTitle() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final delay = Curves.easeOut.transform(
          (_logoController.value - 0.3).clamp(0.0, 1.0) / 0.7,
        );
        return Opacity(
          opacity: delay,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - delay)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Text(
            'Leave Management',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'System',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(
              Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingText() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (_pulseController.value * 0.5),
          child: child,
        );
      },
      child: Text(
        'Loading...',
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.white.withValues(alpha: 0.7),
          letterSpacing: 2,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Column(
      children: [
        Text(
          'YDC',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Version 1.0.0',
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
