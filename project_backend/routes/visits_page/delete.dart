import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.delete) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  // user_id vient du token automatiquement
  final user = context.read<Map<String, dynamic>>();
  final userId = user['id_users'] as int;

  final body = await context.request.json() as Map<String, dynamic>;
  final visitId = body['visit_id'] as int?;

  if (visitId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'visit_id is required'},
    );
  }

  try {
    // Vérifier que c'est bien la visite de cet utilisateur
    final check = await supabase
        .from('visit')
        .select('user_id')
        .eq('id_visit', visitId)
        .maybeSingle();

    if (check == null) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Visit not found'},
      );
    }

    if (check['user_id'] != userId) {
      return Response.json(
        statusCode: 403,
        body: {'error': 'Not authorized'},
      );
    }

    // Supprimer les images liées d'abord
    await supabase.from('image').delete().eq('visit_id', visitId);

    // Supprimer la visite
    await supabase.from('visit').delete().eq('id_visit', visitId);

    return Response.json(
      statusCode: 200,
      body: {'message': 'Visit deleted successfully!'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
