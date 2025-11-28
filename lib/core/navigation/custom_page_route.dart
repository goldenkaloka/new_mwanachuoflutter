import 'package:flutter/material.dart';

/// Custom page route with fade transition
/// Provides smooth fade-in effect for page transitions
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  FadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 250),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Fade transition
           return FadeTransition(opacity: animation, child: child);
         },
         transitionDuration: duration,
         reverseTransitionDuration: duration,
       );
}

/// Custom page route with slide transition
/// Provides smooth slide-in effect from right to left
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Offset begin;

  SlidePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.begin = const Offset(1.0, 0.0), // Slide from right
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           const end = Offset.zero;
           const curve = Curves.easeInOutCubic;

           var tween = Tween(
             begin: begin,
             end: end,
           ).chain(CurveTween(curve: curve));

           var offsetAnimation = animation.drive(tween);

           return SlideTransition(position: offsetAnimation, child: child);
         },
         transitionDuration: duration,
         reverseTransitionDuration: duration,
       );
}

/// Custom page route with scale transition
/// Provides smooth scale-up effect for modal-like transitions
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  ScalePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 250),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           const begin = 0.9;
           const end = 1.0;
           const curve = Curves.easeInOut;

           var scaleTween = Tween(
             begin: begin,
             end: end,
           ).chain(CurveTween(curve: curve));

           var fadeTween = Tween(
             begin: 0.0,
             end: 1.0,
           ).chain(CurveTween(curve: curve));

           return FadeTransition(
             opacity: animation.drive(fadeTween),
             child: ScaleTransition(
               scale: animation.drive(scaleTween),
               child: child,
             ),
           );
         },
         transitionDuration: duration,
         reverseTransitionDuration: duration,
       );
}

/// Custom page route combining slide and fade for smooth transitions
/// Best for main navigation between features
class SlideAndFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideAndFadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           const begin = Offset(0.3, 0.0); // Subtle slide from right
           const end = Offset.zero;
           const curve = Curves.easeOutCubic;

           var slideTween = Tween(
             begin: begin,
             end: end,
           ).chain(CurveTween(curve: curve));

           var fadeTween = Tween(
             begin: 0.0,
             end: 1.0,
           ).chain(CurveTween(curve: curve));

           return SlideTransition(
             position: animation.drive(slideTween),
             child: FadeTransition(
               opacity: animation.drive(fadeTween),
               child: child,
             ),
           );
         },
         transitionDuration: duration,
         reverseTransitionDuration: duration,
       );
}
