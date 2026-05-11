import 'package:dart_frog/dart_frog.dart';
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

  if (email == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Email is required'},
    );
  }

  try {
    await supabase.auth.resetPasswordForEmail(
      email,

      // Envoie un code OTP au lieu d'un lien
      //// await supabase.auth.signInWithOtp(
      //// email: email,
      // shouldCreateUser: false,
    );

    return Response.json(
      statusCode: 200,
      body: {'message': 'Verification code sent to your email!'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
