import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.radius = 20,
  });

  final String displayName;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty
        ? displayName.characters.first.toUpperCase()
        : '?';
    final url = photoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
        child: url.isEmpty ? Text(initial) : null,
      );
    }
    return CircleAvatar(
      radius: radius,
      child: Text(initial),
    );
  }
}
