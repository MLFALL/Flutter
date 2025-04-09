import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/user_controller.dart';
import '../../config/constants.dart';
import '../../models/user_model.dart';

class UserAvatar extends StatelessWidget {
  final UserModel user;

  final double size;
  final bool showStatus;
  final bool showBorder;
  final VoidCallback? onTap;

  const UserAvatar({
    Key? key,
    required this.user,
    this.size = 40,
    this.showStatus = false,
    this.showBorder = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: showBorder
                  ? Border.all(
                color: Colors.white,
                width: 2,
              )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: user.photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              )
                  : _buildPlaceholder(),
            ),
          ),
          if (showStatus)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size / 4,
                height: size / 4,
                decoration: BoxDecoration(
                  color: user.isActive
                      ? AppConstants.userStatusActiveColor
                      : AppConstants.userStatusInactiveColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade300,
      child: Center(
        child: Icon(
          Icons.person,
          size: size * 0.6,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}