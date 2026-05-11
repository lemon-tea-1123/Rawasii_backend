import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
//import '../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'error': 'Method not allowed'},
    );
  }

   final supabase = context.read<SupabaseClient>();
  final groupId = request.uri.queryParameters['group_id'];

  if (groupId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'error': 'group_id is required'},
    );
  }

  final groupIdInt = int.tryParse(groupId);
  if (groupIdInt == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'error': 'Invalid group_id'},
    );
  }

  try {
    final messages = await supabase
        .from('message_group')
        .select('*, user:user_id(*)')
        .eq('group_id', groupIdInt)
        .order('created_at', ascending:false);

    return Response.json(
      body: {'success': true, 'messages': messages},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'error': e.toString()},
    );
  }
}