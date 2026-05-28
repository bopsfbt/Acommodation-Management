import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'features/auth/providers/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kdtxgfagwckcecalqlls.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkdHhnZmFnd2NrY2VjYWxxbGxzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5MzE3MTAsImV4cCI6MjA5NTUwNzcxMH0.-Nd2dFurXkBEUjac2MuI7rtpqMJ2SPKR4aC2NVBmTeI',
  );

  runApp(
    const ProviderScope(
      child: _AppWithSessionRestore(),
    ),
  );
}

/// Widget khôi phục session từ bộ nhớ cục bộ trước khi render App
class _AppWithSessionRestore extends ConsumerStatefulWidget {
  const _AppWithSessionRestore();

  @override
  ConsumerState<_AppWithSessionRestore> createState() =>
      _AppWithSessionRestoreState();
}

class _AppWithSessionRestoreState
    extends ConsumerState<_AppWithSessionRestore> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    // Khôi phục session nếu user đã đăng nhập trước đó
    await ref.read(authControllerProvider).restoreSession();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    return const App();
  }
}
