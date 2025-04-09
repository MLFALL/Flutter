import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../../config/themes.dart';
import '../../config/constants.dart';
import 'project_status_badge.dart';
import '../user/user_avatar.dart';

/// A card widget for displaying project information in lists
class ProjectCard extends StatelessWidget {
  /// Project data to display
  final ProjectModel project;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Callback when menu button is tapped
  final void Function(BuildContext, ProjectModel)? onMenuPressed;

  /// Show or hide the options menu
  final bool showOptions;

  /// Show team members avatars
  final bool showMembers;

  /// Show progress indicator
  final bool showProgress;

  /// Elevation of the card
  final double elevation;

  /// Border radius of the card
  final double borderRadius;

  /// Padding inside the card
  final EdgeInsets padding;

  /// Constructor for ProjectCard
  const ProjectCard({
    Key? key,
    required this.project,
    this.onTap,
    this.onMenuPressed,
    this.showOptions = true,
    this.showMembers = true,
    this.showProgress = true,
    this.elevation = 2.0,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(16.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Calculate days remaining until deadline
    final now = DateTime.now();
    final daysRemaining = project.endDate.difference(now).inDays;

    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and options menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showOptions && onMenuPressed != null)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => onMenuPressed!(context, project),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Status badge and priority
              Row(
                children: [
                  ProjectStatusBadge(status: project.status.name),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: AppThemes.getPriorityColor(project.priority.name),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    project.priority.name,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),

              if (project.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  project.description,
                  style: textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Date information
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(project.startDate)} - ${_formatDate(project.endDate)}',
                    style: textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (daysRemaining > 0) ...[
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: daysRemaining < 3
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$daysRemaining jour${daysRemaining > 1 ? "s" : ""}',
                      style: textTheme.bodySmall?.copyWith(
                        color: daysRemaining < 3
                            ? theme.colorScheme.error
                            : null,
                      ),
                    ),
                  ] else if (daysRemaining < 0 &&
                      project.status != AppConstants.statusCompleted &&
                      project.status != AppConstants.statusCancelled) ...[
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'En retard',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),

              // Progress bar
              if (showProgress) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: project.completionPercentage / 100,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progression',
                      style: textTheme.bodySmall,
                    ),
                    Text(
                      '${project.completionPercentage.toInt()}%',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],

              // Team members
              if (showMembers && project.teamMembers.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Équipe',
                      style: textTheme.bodySmall,
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 32,
                      child: Stack(
                        children: _buildMemberAvatars(project.teamMembers),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a row of overlapping member avatars
  List<Widget> _buildMemberAvatars(List<UserModel> members) {
    final displayLimit = 3; // Maximum number of avatars to show
    final memberCount = members.length;
    final displayCount = memberCount > displayLimit ? displayLimit : memberCount;

    List<Widget> avatars = [];

    for (int i = 0; i < displayCount; i++) {
      avatars.add(
        Positioned(
          left: i * 20.0,
          child: UserAvatar(
            user: members[i],
            size: 32,
            showBorder: true,
          ),
        ),
      );
    }

    // Add a "+X more" indicator if there are more members than the display limit
    if (memberCount > displayLimit) {
      avatars.add(
        Positioned(
          left: displayLimit * 20.0,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '+${memberCount - displayLimit}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return avatars;
  }

  /// Format date to display format
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}