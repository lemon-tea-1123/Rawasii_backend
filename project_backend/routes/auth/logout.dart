import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    await supabase.auth.signOut();

    return Response.json(
      statusCode: 200,
      body: {'message': 'Logged out successfully'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': 'Logout failed'},
    );
  }
}
