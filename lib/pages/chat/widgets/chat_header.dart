import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/core/provider/theme_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ChatHeader extends StatelessWidget {
  final String chatId;

  const ChatHeader({super.key, required this.chatId});


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            // ignore: deprecated_member_use
            color: theme.dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Ask me anything',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              // Theme Mode Toggle
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return IconButton(
                    onPressed: () => themeProvider.toggleTheme(),
                    icon: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                    tooltip: themeProvider.isDarkMode
                        ? 'Light Mode'
                        : 'Dark Mode',
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.add),
                tooltip: 'New Chat',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
