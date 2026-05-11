import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
//import '../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'error': 'Method not allowed'},
    );
  }
  final supabase = context.read<SupabaseClient>();

  try {
    final body = await request.json() as Map<String, dynamic>;

    final senderId = body['sender_id'] as int?;
    final groupId = body['group_id'] as int?;
    final content = body['content'] as String?;

    if (senderId == null || groupId == null || content == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'error': 'sender_id, group_id, and content are required'
        },
      );
    }

    final now = DateTime.now().toIso8601String();

    final message = await supabase
        .from('message_group')
        .insert({
          'user_id': senderId,
          'group_id': groupId,
          'content': content,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    return Response.json(
      body: {'success': true, 'message': message},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'error': e.toString()},
    );
  }
}
