import 'package:flutter/widgets.dart';

class MyCustomLogo extends StatelessWidget {
  const MyCustomLogo({
    super.key,
    this.size,
    this.duration = const Duration(milliseconds: 750),
    this.curve = Curves.fastOutSlowIn,
  });

  final double? size;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final IconThemeData iconTheme = IconTheme.of(context);
    final double? iconSize = size ?? iconTheme.size;
    return AnimatedContainer(
      width: iconSize,
      height: iconSize,
      duration: duration,
      curve: curve,
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(iconSize! / 2),
        ),
        child: Image.asset(
          // color: Color.fromARGB(255, 255, 255, 255),
          'assets/logo.png', // Replace with your image asset path
          width: iconSize,
          height: iconSize,
        ),
      )
    );
  }
}