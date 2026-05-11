import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }

  final followingUserId = context.request.uri.queryParameters['following_user_id'];
  final followedUserId  = context.request.uri.queryParameters['followed_user_id'];

  if (followingUserId == null || followedUserId == null) {
    return Response.json(statusCode: 400, body: {'error': 'Missing params'});
  }

  final supabase = context.read<SupabaseClient>();

  try {
    final result = await supabase
        .from('follow')
        .select()
        .eq('following_user_id', int.parse(followingUserId))
        .eq('followed_user_id',  int.parse(followedUserId))
        .maybeSingle();

    return Response.json(body: {'is_following': result != null});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}