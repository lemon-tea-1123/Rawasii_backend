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
  final password = body['password'] as String?;

  if (email == null || password == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Email and password are required'},
    );
  }

  try {
    // 1. Supabase checks password automatically
    final authResponse = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final session = authResponse.session;
    if (session == null) {
      return Response.json(
        statusCode: 401,
        body: {'error': 'Invalid email or password'},
      );
    }

    // 2. Get user data from "user" table including status
    final userData = await supabase
        .from('user')
        .select(
            'id_users, username, email, validation, status') // ← AJOUTE status
        .eq('email', email)
        .maybeSingle();

    if (userData == null) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'User not found in database'},
      );
    }

    // 3. Check if account is validated
    if (authResponse.user?.emailConfirmedAt == null) {
      return Response.json(
        statusCode: 403,
        body: {'error': 'Account not verified. Please check your email.'},
      );
    }

    // 4. ← ZID HEDHA - CHECK STATUS (suspended/banned)
    final status = userData['status'] as String? ?? 'active';

    if (status == 'suspended') {
      return Response.json(
        statusCode: 403,
        body: {'Account suspended.'}, // ← Français
      );
    }

    if (status == 'banned') {
      return Response.json(
        statusCode: 403,
        body: {'error': 'Account permanently banned..'}, // ← Français
      );
    }

    return Response.json(
      statusCode: 200,
      body: {
        'access_token': session.accessToken,
        'refresh_token': session.refreshToken,
        'user': {
          'id': userData['id_users'],
          'username': userData['username'],
          'email': userData['email'],
        },
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 401,
      body: {'error': e.toString()},
    );
  }
}
