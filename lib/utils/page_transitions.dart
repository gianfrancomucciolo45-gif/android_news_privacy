import 'package:flutter/material.dart';

class PageTransitions {
  // Slide from right transition (Material Design standard)
  static Route<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubicEmphasized;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  // Fade transition
  static Route<T> fade<T>(Widget page) {
    return PageRouteBuilder<T>(
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

  // Slide and fade combined (elegant)
  static Route<T> slideAndFade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubicEmphasized;

        var slideTween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  // Scale and fade (elegant for dialogs and small screens)
  static Route<T> scaleAndFade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubicEmphasized;

        var scaleTween = Tween<double>(begin: 0.95, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  // Shared axis transition (Material Design 3)
  static Route<T> sharedAxis<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubicEmphasized;

        var primarySlide = Tween<Offset>(
          begin: const Offset(0.05, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: curve));

        var secondarySlide = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.05, 0.0),
        ).chain(CurveTween(curve: curve));

        var primaryFade = Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: curve));

        var secondaryFade = Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: curve));

        return Stack(
          children: [
            SlideTransition(
              position: secondaryAnimation.drive(secondarySlide),
              child: FadeTransition(
                opacity: secondaryAnimation.drive(secondaryFade),
                child: Container(),
              ),
            ),
            SlideTransition(
              position: animation.drive(primarySlide),
              child: FadeTransition(
                opacity: animation.drive(primaryFade),
                child: child,
              ),
            ),
          ],
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
    );
  }
}
