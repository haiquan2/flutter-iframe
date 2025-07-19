import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/core/constants/app_sizes.dart';
import 'package:flutter_openai_stream/core/utils/helper.dart';
import 'package:go_router/go_router.dart';

class SideBar extends StatefulWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  const SideBar({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (!widget.isCollapsed) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(SideBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCollapsed != oldWidget.isCollapsed) {
      if (widget.isCollapsed) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: widget.isCollapsed ? AppSizes.kSidebarCollapseWidth : AppSizes.kSidebarExpandWidth,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with toggle button
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Toggle/Menu Button

                if (!widget.isCollapsed) ...[
                  const SizedBox(width: 12),
                  // App Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FadeTransition(
                      opacity: _animation,
                      child: Text(
                        'AI Assistant',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                IconButton(
                  onPressed: widget.onToggle,
                  icon: Icon(
                    widget.isCollapsed ? Icons.menu : Icons.chevron_left,
                    size: 20,
                  ),
                  tooltip:
                      widget.isCollapsed ? 'Open sidebar' : 'Close sidebar',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                ),
              ],
            ),
          ),

          // New Chat Button
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 12 : 16,
              vertical: 8,
            ),
            child: widget.isCollapsed
                ? IconButton(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'New Chat',
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Chat'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 8),

          // Chat History
          Expanded(
            child: widget.isCollapsed
                ? Column(
                    children: [
                      const SizedBox(height: 8),
                      // Chat icon for collapsed state
                      IconButton(
                        onPressed: () {
                          // Handle chat history
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 20),
                        tooltip: 'Chat History',
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                      ),
                    ],
                  )
                : FadeTransition(
                    opacity: _animation,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Text(
                          'Recent Chats',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Account Section (bottom)
          Container(
            padding: EdgeInsets.all(widget.isCollapsed ? 8 : 16),
            child: widget.isCollapsed
                ? IconButton(
                    onPressed: () {
                      // Handle account/profile
                      showToast(context: context, message: "Not implemented yet",
                          icon: Icons.info, iconColor: Colors.red);
                    },
                    icon: const Icon(Icons.account_circle, size: 24),
                    tooltip: 'Account',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(40, 40),
                    ),
                  )
                : FadeTransition(
                    opacity: _animation,
                    child: ListTile(
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey,
                        child: Icon(
                          Icons.login,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      title: const Text(
                        'Login',
                        style: TextStyle(fontSize: 14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () {
                        showToast(context: context, message: "Not implemented yet",
                            icon: Icons.info, iconColor: Colors.red);
                        // Handle account/profile
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
