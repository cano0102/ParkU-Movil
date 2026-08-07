import 'package:flutter/material.dart';

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();

    // Comenzamos un poco más abajo
    path.lineTo(0, size.height - 45);

    // Primera parte de la ola
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height + 5,
      size.width * 0.50,
      size.height - 20,
    );

    // Segunda parte de la ola
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 55,
      size.width,
      size.height - 45,
    );

    // Subimos por el lado derecho
    path.lineTo(size.width, 0);

    // Cerramos
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}