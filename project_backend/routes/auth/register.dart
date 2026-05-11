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
  final username = body['username'] as String?;

  if (email == null || password == null || username == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Email, password and username are required'},
    );
  }

  try {
    // 1. Créer le compte dans Supabase Auth
    final authResponse = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (authResponse.user == null) {
      return Response.json(
        statusCode: 500,
        body: {'error': 'Error creating account'},
      );
    }

    final now = DateTime.now().toIso8601String();

    // 2. INSERT dans table "user"
    final userInsert = await supabase
        .from('user')
        .insert({
          'username': username,
          'email': email,
          'password': 'managed_by_supabase_auth', // ✅ fix
          'validation': false,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    final userId = userInsert['id_users'] as int;

    // 3. INSERT dans table "user_profile"
    await supabase.from('user_profile').insert({
      'user_id': userId,
      'full_name': username,
      'created_at': now,
      'updated_at': now,
    });

    return Response.json(
      statusCode: 201,
      body: {
        'message': 'Account created successfully!',
        'user_id': userId,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
