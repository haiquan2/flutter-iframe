import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/core/provider/theme_provider.dart';
import 'package:flutter_openai_stream/core/utils/id_generator.dart';
import 'package:flutter_openai_stream/pages/chat/chat_page.dart';
import 'package:flutter_openai_stream/core/theme/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'pages/home/home_page.dart';
import 'package:web/web.dart' as web;

void main() {
  final queryParams = Uri.parse(web.window.location.href).queryParameters;
  final isIframe = queryParams['iframe'] == 'true';

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(isIframe: isIframe),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isIframe;
  MyApp({super.key, required this.isIframe});

  final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final params = Uri.parse(web.window.location.href).queryParameters;
          final chatId = params['chatId'] ?? generateChatId();
          final isIframe = params['iframe'] == 'true';
          return isIframe
              ? ChatPage(chatId: chatId, isIframe: true)
              : const HomePage();
        },
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final params = Uri.parse(web.window.location.href).queryParameters;
          final isIframe = params['iframe'] == 'true';
          return ChatPage(chatId: chatId, isIframe: isIframe);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final params = Uri.parse(web.window.location.href).queryParameters;
    final themeMode =
        params['theme'] == 'dark' ? ThemeMode.dark : ThemeMode.light;

    return MaterialApp.router(
      title: 'AI Chat Assistant',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode == ThemeMode.system
          ? themeMode
          : themeProvider.themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
