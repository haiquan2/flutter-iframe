import 'package:flutter/material.dart';

class SuggestionCards extends StatelessWidget {
  const SuggestionCards({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final suggestions = [
      {
        'title': 'Medical Advice',
        'subtitle': 'Ask about symptoms or treatments',
        'icon': Icons.medical_services,
      },
      {
        'title': 'Health Tips',
        'subtitle': 'Get wellness recommendations',
        'icon': Icons.health_and_safety,
      },
      {
        'title': 'Drug Information',
        'subtitle': 'Learn about medications',
        'icon': Icons.medication,
      },
      {
        'title': 'General Questions',
        'subtitle': 'Ask anything else',
        'icon': Icons.help_outline,
      },
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return Card(
            elevation: 0,
            color: isDark ? const Color(0xFF334155) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Handle suggestion tap
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      suggestion['icon'] as IconData,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            suggestion['title'] as String,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            suggestion['subtitle'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}