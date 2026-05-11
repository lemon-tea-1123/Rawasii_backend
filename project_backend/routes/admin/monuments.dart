import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getMonuments();
    case HttpMethod.delete:
      return _deleteMonument(context);
    case HttpMethod.put:
      return _updateStatus(context);
    default:
      return Response.json(
        statusCode: 405,
        body: {'error': 'Method not allowed'},
      );
  }
}

Future<Response> _getMonuments() async {
  try {
    final monuments = await supabase.from('monument_in_danger').select('''
          monument_in_danger_id,
          monument_name,
          region,
          description,
          status,
          danger_type,
          urgence_level,
          views_count,
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
      body: {
        'success': true,
        'count': monuments.length,
        'monuments': monuments,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _deleteMonument(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final monumentId = body['monument_id'] as int?;

    if (monumentId == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'monument_id is required'},
      );
    }

    final monument = await supabase
        .from('monument_in_danger')
        .select('monument_in_danger_id')
        .eq('monument_in_danger_id', monumentId)
        .maybeSingle();

    if (monument == null) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Monument not found'},
      );
    }

    await supabase
        .from('mobilization_actions')
        .delete()
        .eq('monument_in_danger_id', monumentId);
    await supabase
        .from('image')
        .delete()
        .eq('monument_in_danger_id', monumentId);
    await supabase
        .from('monument_in_danger')
        .delete()
        .eq('monument_in_danger_id', monumentId);

    return Response.json(
      statusCode: 200,
      body: {'message': 'Monument deleted successfully'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _updateStatus(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final monumentId = body['monument_id'] as int?;
    final status = body['status'] as String?;

    if (monumentId == null || status == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'monument_id and status are required'},
      );
    }

    const validStatuses = ['reported', 'under intervention', 'saved', 'lost'];
    if (!validStatuses.contains(status.toLowerCase())) {
      return Response.json(
        statusCode: 400,
        body: {
          'error':
              'Invalid status. Accepted values: reported, under intervention, saved, lost'
        },
      );
    }

    await supabase.from('monument_in_danger').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('monument_in_danger_id', monumentId);

    return Response.json(
      statusCode: 200,
      body: {'message': 'Status updated successfully to $status'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
