import 'package:dart_frog/dart_frog.dart';
import '../lib/supabase_client.dart';

final _init = _setup();
bool _initialized = false;

Future<void> _setup() async {
  initSupabase();
}

Handler middleware(Handler handler) {
  if (!_initialized) {
    try {
      _setup();
      _initialized = true;
    } catch (e) {
      print('Failed to initialize supabase ! $e');
      rethrow;
    }
  }
  return (context) async {
    if (context.request.method == HttpMethod.options) {
      return Response(
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      );
    }
    final response = await handler
        .use(requestLogger())
        .use(provider((context) => supabase))(context);
    return response.copyWith(
      headers: {
        ...response.headers,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    );
  };
}
