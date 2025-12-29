import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/news_article.dart';
import '../screens/home_screen.dart';
import '../screens/article_detail_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/settings_screen.dart';

/// Router globale per gestire deep links e navigazione
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/article/:articleId',
      name: 'article',
      builder: (context, state) {
        final extra = state.extra as NewsArticle?;
        
        if (extra != null) {
          return ArticleDetailScreen(article: extra);
        }
        
        // Fallback: ritorna alla home se non hai i dati
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/bookmarks',
      name: 'bookmarks',
      builder: (context, state) => const BookmarksScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
  // Error handler per rotte non trovate
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Pagina non trovata'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Torna alla Home'),
          ),
        ],
      ),
    ),
  ),
);
