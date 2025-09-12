import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendInAppNotification({
    required String userId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    await _db
        .collection('user_notifications')
        .doc(userId)
        .collection('items')
        .add({
          'type': type,
          'data': data,
          'status': 'new',
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}
