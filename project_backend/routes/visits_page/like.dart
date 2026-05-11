import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
        statusCode: 405, body: {'error': 'Method not allowed'});
  }

  final user = context.read<Map<String, dynamic>>();
  final userId = user['id_users'] as int;

  final body = await context.request.json() as Map<String, dynamic>;
  final visitId = body['visit_id'] as int?;

  if (visitId == null) {
    return Response.json(statusCode: 400, body: {'error': 'visit_id required'});
  }

  try {
    // 1. Récupérer le owner te3 visit
    final visit = await supabase
        .from('visit')
        .select('user_id')
        .eq('id_visit', visitId)
        .maybeSingle();

    if (visit == null) {
      return Response.json(statusCode: 404, body: {'error': 'Visit not found'});
    }

    final visitOwnerId = visit['user_id'] as int;

    print('DEBUG visitOwnerId: $visitOwnerId');
    print('DEBUG userId (liker): $userId');
    print('DEBUG same user: ${visitOwnerId == userId}');

    // 2. Chekkek ila déjà liké
    final existing = await supabase
        .from('visit_reaction')
        .select('id')
        .eq('visit_id', visitId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      // ── UNLIKE ──
      await supabase
          .from('visit_reaction')
          .delete()
          .eq('visit_id', visitId)
          .eq('user_id', userId);

      await supabase.rpc('increment_reaction', params: {
        'visit_id_param': visitId,
        'increment_by': -1,
      });

      print('DEBUG unliked visit $visitId');

      return Response.json(
          statusCode: 200, body: {'message': 'unliked', 'liked': false});
    } else {
      // ── LIKE ──
      await supabase.from('visit_reaction').insert({
        'visit_id': visitId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      await supabase.rpc('increment_reaction', params: {
        'visit_id_param': visitId,
        'increment_by': 1,
      });

      print('DEBUG liked visit $visitId');

      // 3. Notification
      if (visitOwnerId != userId) {
        print('DEBUG inserting notification...');
        await supabase.from('notification').insert({
          'user_id': visitOwnerId,
          'sender_id': userId,
          'type': 'reaction_visit',
          'visit_id': visitId,
          'post_id': null,
          'comment_id': null,
          'comment_visit_id': null,
          'is_read': false,
        });
        print('DEBUG notification inserted ✓');
      } else {
        print('DEBUG same user — no notification sent');
      }

      return Response.json(
          statusCode: 200, body: {'message': 'liked', 'liked': true});
    }
  } catch (e) {
    print('DEBUG ERROR: $e');
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
