import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod; // kent erreur hna
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final email = body['email'] as String?;
  final token = body['token'] as String?;

  if (email == null || token == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Email and token are required'},
    );
  }

  try {
    final response = await supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );

    return Response.json(
      statusCode: 200,
      body: {
        'message': 'Code verified!',
        'access_token': response.session?.accessToken,
        'refresh_token': response.session?.refreshToken,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Invalid or expired code'},
    );
  }
}
