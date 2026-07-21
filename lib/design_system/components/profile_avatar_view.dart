import 'package:flutter/material.dart';
import '../../data/models/usuario.dart';

class ProfileAvatarView extends StatelessWidget {
  final Usuario user;
  final double size;

  const ProfileAvatarView({
    super.key,
    required this.user,
    this.size = 36,
  });

  String get initials {
    final firstInitial = user.nombres.isNotEmpty ? user.nombres[0] : "";
    final apellidosArr = user.apellidos.split(" ");
    final lastInitial = apellidosArr.isNotEmpty && apellidosArr[0].isNotEmpty ? apellidosArr[0][0] : "";
    return (firstInitial + lastInitial).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: user.avatarUrl != null
          ? Image.network(
              user.avatarUrl!.toString(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildMonogram(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildMonogram();
              },
            )
          : _buildMonogram(),
    );
  }

  Widget _buildMonogram() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade400, Colors.grey.shade600],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
