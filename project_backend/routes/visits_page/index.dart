import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final user = context.read<Map<String, dynamic>>();
  final userId = user['id_users'] as int;

  try {
    final visits = await supabase.from('visit').select('''
          id_visit,
          monument_name,
          localisation,
          description,
          historical_period,
          heritage_type,
          reaction_count,
          created_at,
          updated_at,
          user:user_id (
            id_users,
            username,
            user_profile (
              full_name,
              expertise,
              profile_image_url
            )
          ),
          image (
            id_image,
            image_path
          ),
          visit_reaction (
            user_id
          )
        ''').order('created_at', ascending: false);

    // Ajouter le champ 'liked' pour chaque visit
    final result = visits.map((v) {
      final reactions = v['visit_reaction'] as List<dynamic>? ?? [];
      final liked = reactions.any((r) => r['user_id'] == userId);
      return {
        ...v,
        'liked': liked,
      };
    }).toList();

    return Response.json(
      statusCode: 200,
      body: {
        'success': true,
        'count': result.length,
        'visits': result,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
