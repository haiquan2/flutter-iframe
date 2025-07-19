import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/core/provider/theme_provider.dart';
import 'package:flutter_openai_stream/pages/chat/chat_page.dart';
import 'package:flutter_openai_stream/core/theme/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'pages/home/home_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatPage(chatId: chatId);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'AI Chat Assistant',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode, 
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
