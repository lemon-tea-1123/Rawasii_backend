import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
//import 'package:project_backend/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  // 1. Restrict to PUT or PATCH
  if (context.request.method != HttpMethod.put &&
      context.request.method != HttpMethod.patch) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    // 2. Extract Token
    final authHeader = context.request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
          statusCode: 401, body: {'error': 'Missing or malformed token'});
    }
    final token = authHeader.substring(7);
    final supabase = context.read<SupabaseClient>();

    // 3. SECURELY validate the token using Supabase
    // This verifies the signature and checks if the user still exists/is valid
    final userResponse = await supabase.auth.getUser(token);
    final userId = userResponse.user?.id;

    if (userId == null) {
      return Response.json(
          statusCode: 401, body: {'error': 'Invalid or expired token'});
    }

    // 4. Parse Body
    final body = await context.request.json() as Map<String, dynamic>;
    final name = body['full_name'] as String?;
    final bio = body['biography'] as String?;
    final job = body['expertise'] as String?;
    final interest = body['specialties'] as String?;
    final profilepic = body['profile_image_url'] as String?;
    final city = body['city'] as String?;

    // 5. Validate that at least one field is being updated
    if (name == null &&
        bio == null &&
        job == null &&
        interest == null &&
        profilepic == null) {
      return Response.json(
          statusCode: 400,
          body: {'error': 'No valid fields provided to update'});
    }

    // 6. Build the updates map dynamically
    final updates = <String, dynamic>{
      if (name != null) 'full_name': name,
      if (bio != null) 'biography': bio,
      if (job != null) 'expertise': job,
      if (interest != null) 'specialties': interest,
      if (profilepic != null) 'profile_image_url': profilepic,
      if (city != null) 'city': city,
      // Optional: Add an updated_at timestamp if your DB doesn't do it automatically
      // 'updated_at': DateTime.now().toIso8601String(),
    };

    // 7. Execute Database Update
    // .select() at the end is crucial: it returns the updated row instead of an empty count
    final authUser = await supabase.auth.getUser(token);
    final userEmail = authUser.user?.email;

// find integer id using email
    final userRow = await supabase
        .from('user')
        .select('id_users')
        .eq('email', userEmail!) // ← match by email instead
        .single();

    final intId = userRow['id_users'] as int;

// now update with correct integer id
    final response = await supabase
        .from('user_profile')
        .update(updates)
        .eq('user_id', intId)
        .select();
    // 8. Handle Response
    if (response.isEmpty) {
      return Response.json(
          statusCode: 404,
          body: {'error': 'User profile not found in database'});
    }

    // 9. Return the newly updated profile data to the frontend
    return Response.json(
      statusCode: 200,
      body: {
        'message': 'Profile updated successfully',
        'profile': response.first, // Send the updated data back
      },
    );
  } catch (e) {
    // Log the actual error on your server for debugging
    print('Error updating profile: $e');

    return Response.json(
      statusCode: 500,
      body: {'error': 'An unexpected server error occurred'},
    );
  }
}
