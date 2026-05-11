import 'package:dart_frog/dart_frog.dart';
//import 'package:project_backend/supabase_client.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;
  if (method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }
  final supabase = context.read<SupabaseClient>();
  final body = await context.request.json() as Map<String, dynamic>;
  //li ydir follow
  final followingUserId = body['following_user_id'] as int?;
  //li ytab3oh
  final followedUserId = body['followed_user_id'] as int?;

  if (followingUserId == null || followedUserId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Missing required fields'},
    );
  }

  if (followedUserId == followingUserId) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'You cannot follow yourself'},
    );
  }

  final existingFollow = await supabase
      .from('follow')
      .select()
      .eq('followed_user_id', followedUserId)
      .eq('following_user_id', followingUserId)
      .maybeSingle();

// Unfollow
  if (existingFollow != null) {
    await supabase
        .from('follow')
        .delete()
        .eq('followed_user_id', followedUserId)
        .eq('following_user_id', followingUserId);

    final currentFollowingCount = await supabase
        .from('user')
        .select('following_count')
        .eq('id_users', followingUserId)
        .single();

    await supabase.from('user').update({
      'following_count': (currentFollowingCount['following_count'] as int) - 1,
    }).eq('id_users', followingUserId);

    //
    final currentFollowersCount = await supabase
        .from('user')
        .select('followers_count')
        .eq('id_users', followedUserId)
        .single();

    await supabase.from('user').update({
      'followers_count': (currentFollowersCount['followers_count'] as int) - 1,
    }).eq('id_users', followedUserId);

    return Response.json(
      body: {'message': 'Unfollowed successfully'},
    );
  }
  //follow
  await supabase.from('follow').insert({
    'following_user_id': followingUserId,
    'followed_user_id': followedUserId,
  });

  final currentFollowingCount = await supabase
      .from('user')
      .select('following_count')
      .eq('id_users', followingUserId)
      .single();

  await supabase.from('user').update({
    'following_count': (currentFollowingCount['following_count'] as int) + 1,
  }).eq('id_users', followingUserId);

  //
  final currentFollowersCount = await supabase
      .from('user')
      .select('followers_count')
      .eq('id_users', followedUserId)
      .single();

  await supabase.from('user').update({
    'followers_count': (currentFollowersCount['followers_count'] as int) + 1,
  }).eq('id_users', followedUserId);

  await supabase.from('notification').insert({
    'user_id': followedUserId,
    'type': 'follow',
    'sender_id': followingUserId,
    'post_id': null,
    'comment_id': null,
    'is_read': false,
  });

  return Response.json(
    body: {'message': 'Followed successfully'},
  );
}
