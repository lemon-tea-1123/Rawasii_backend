import 'package:dart_frog/dart_frog.dart';
import '../../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getUsers();
    case HttpMethod.put:
      return _updateUserStatus(context);
    default:
      return Response.json(
        statusCode: 405,
        body: {'error': 'Method not allowed'},
      );
  }
}

Future<Response> _getUsers() async {
  try {
    final users = await supabase
        .from('user')
        .select('id_users, username, email, validation, status, created_at');

    return Response.json(
      statusCode: 200,
      body: {'success': true, 'count': users.length, 'users': users},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _updateUserStatus(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final userId = body['user_id'] as int?;
    final action = body['action'] as String?;

    if (userId == null || action == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'user_id and action are required'},
      );
    }

    if (action != 'suspend' && action != 'ban' && action != 'activate') {
      return Response.json(
        statusCode: 400,
        body: {'error': 'action must be: suspend, ban, or activate'},
      );
    }

    final status = action == 'suspend'
        ? 'suspended'
        : action == 'ban'
            ? 'banned'
            : 'active';

    await supabase.from('user').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id_users', userId);

    return Response.json(
      statusCode: 200,
      body: {'message': 'User $status successfully'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
