import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    // ✅ Ramène monuments + images
    final monuments = await supabase.from('monument_in_danger').select('''
      *,
      image (
        id_image,
        image_path
      ),
      user (
        username
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
