import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/core/provider/theme_provider.dart';
import 'package:flutter_openai_stream/pages/chat/chat_page.dart';
import 'package:flutter_openai_stream/core/theme/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'pages/home/home_page.dart';
import 'package:web/web.dart' as web;

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

  // Helper để lấy query parameters
  Map<String, String> _getQueryParams() {
    return Uri.parse(web.window.location.href).queryParameters;
  }

  // Helper để xác định theme mode từ URL
  ThemeMode _getThemeMode() {
    final queryParams = _getQueryParams();
    switch (queryParams['theme']) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final queryParams = _getQueryParams();
          final isIframe = queryParams['iframe'] == 'true';
          
          if (isIframe) {
            // Nếu là iframe, hiển thị ChatPage với layout compact
            return _buildIframeChatPage();
          } else {
            // Kiểm tra nếu có chatId hoặc muốn vào chat trực tiếp
            if (queryParams.containsKey('chatId') || queryParams['page'] == 'chat') {
              return const ChatPage();
            }
            // Mặc định hiển thị HomePage
            return const HomePage();
          }
        },
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final queryParams = _getQueryParams();
          final isIframe = queryParams['iframe'] == 'true';
          
          if (isIframe) {
            return _buildIframeChatPage();
          }
          return const ChatPage();
        },
      ),
      // THÊM ROUTE NÀY ĐỂ XỬ LÝ /chat/:chatId
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final queryParams = _getQueryParams();
          final isIframe = queryParams['iframe'] == 'true';
          
          // Có thể log chatId để debug
          print('Chat ID from URL: $chatId');
          
          if (isIframe) {
            return _buildIframeChatPage();
          }
          return const ChatPage();
        },
      ),
    ],
  );

  // Widget ChatPage tối ưu cho iframe
  Widget _buildIframeChatPage() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const ChatPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final urlThemeMode = _getThemeMode();

    return MaterialApp.router(
      title: 'AI Chat Assistant',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode == ThemeMode.system
          ? urlThemeMode
          : themeProvider.themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}


