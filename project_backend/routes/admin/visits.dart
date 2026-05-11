import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getVisits();
    case HttpMethod.delete:
      return _deleteVisit(context);
    default:
      return Response.json(
        statusCode: 405,
        body: {'error': 'Method not allowed'},
      );
  }
}

Future<Response> _getVisits() async {
  try {
    final visits = await supabase.from('visit').select('''
          id_visit,
          monument_name,
          localisation,
          description,
          reaction_count,
          created_at,
          user:user_id (
            id_users,
            username,
            email
          ),
          image (
            id_image,
            image_path
          )
        ''').order('created_at', ascending: false);

    return Response.json(
      statusCode: 200,
      body: {'success': true, 'count': visits.length, 'visits': visits},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _deleteVisit(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final visitId = body['visit_id'] as int?;

    if (visitId == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'visit_id is required'},
      );
    }

    final visit = await supabase
        .from('visit')
        .select('id_visit')
        .eq('id_visit', visitId)
        .maybeSingle();

    if (visit == null) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Visit not found'},
      );
    }

    await supabase.from('image').delete().eq('visit_id', visitId);
    await supabase.from('visit').delete().eq('id_visit', visitId);

    return Response.json(
      statusCode: 200,
      body: {'message': 'Visit deleted successfully'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
