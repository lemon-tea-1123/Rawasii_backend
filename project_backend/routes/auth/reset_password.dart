import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final accessToken = body['access_token'] as String?;
  final newPassword = body['new_password'] as String?;

  if (accessToken == null || newPassword == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Access token and new password are required'},
    );
  }

  try {
    // Extraire le user ID du JWT token
    final parts = accessToken.split('.');
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final map = json.decode(decoded) as Map<String, dynamic>;
    final userId = map['sub'] as String;

    // Update password via admin (service role)
    await supabase.auth.admin.updateUserById(
      userId,
      attributes: AdminUserAttributes(
        password: newPassword,
      ),
    );

    return Response.json(
      statusCode: 200,
      body: {'message': 'Password updated successfully!'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
