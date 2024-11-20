import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickAccessButton extends StatefulWidget {
  final String? label;
  final IconData icon;
  final String route;
  final Color iconColor;

  const QuickAccessButton({
    this.label,
    required this.icon,
    required this.route,
    required this.iconColor,
    super.key,
  });

  @override
  QuickAccessButtonState createState() => QuickAccessButtonState();
}

class QuickAccessButtonState extends State<QuickAccessButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        _isHovered = true;
      }),
      onExit: (_) => setState(() {
        _isHovered = false;
      }),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
          borderRadius: BorderRadius.circular(8),
          gradient: _isHovered
              ? LinearGradient(
            colors: [Colors.blue.withOpacity(0.7), Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            context.go(widget.route);
          },
          icon: Icon(widget.icon, color: widget.iconColor), // Use dynamic color here
          label: Text(widget.label ?? ''), // Handle null case
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _isHovered ? Colors.transparent : Colors.white,
            foregroundColor: _isHovered ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Rounded corners
            ),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}