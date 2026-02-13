import 'package:renizo/core/constants/api_control/global_api.dart';

/// Chat API endpoints – GET threads, read, messages; POST messages.
/// Auth: Bearer token required on all requests.
/// {{thread_Id}} = thread's _id from GET /chat/threads response (e.g. "698cea6a38b40661d78a6003").
class ChatApi {
  static String get _base => '$api/chat';
  static String get threads => '$_base/threads';
  /// POST body: { "bookingId": "..." } – get or create thread, returns thread with _id.
  static String get createThread => '$_base/threads';
  static String threadRead(String threadId) => '$_base/threads/$threadId/read';
  static String threadMessages(String threadId) =>
      '$_base/threads/$threadId/messages';
}
