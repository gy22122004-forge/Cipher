import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/splash_screen.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/dashboard/dashboard_screen.dart';
import 'presentation/projects/projects_screen.dart';
import 'presentation/projects/project_detail_screen.dart';
import 'presentation/profile/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CipherApp()));
}

class CipherApp extends ConsumerWidget {
  const CipherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Cipher — Task Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        if (name.startsWith('/projects/')) {
          final id = name.replaceFirst('/projects/', '');
          return MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: id));
        }
        switch (name) {
          case '/': return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/login': return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register': return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/dashboard': return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case '/projects': return MaterialPageRoute(builder: (_) => const ProjectsScreen());
          case '/profile': return MaterialPageRoute(builder: (_) => const ProfileScreen());
          default: return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
