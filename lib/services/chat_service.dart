import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eugenio_advmobprog/models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // get all users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        user['uid'] ??= doc.id;
        return user;
      }).toList();
    });
  }

  // send message
  Future<void> sendMessage(String receiverId, String message) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) throw StateError('No authenticated user.');

    final String currentUserId = currentUser.uid;
    final String? currentUserEmail = currentUser.email;
    final Timestamp timestamp = Timestamp.now();
    MessageModel newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? "",
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      status: 'sent',
    );

    // construct chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [currentUserId, receiverId];
    ids.sort(); // sort the ids (this ensure the chatroomID is the same for any 2 people)
    String chatRoomID = ids.join('_');
    // add new message to database
    final messageRef = _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc();
    await messageRef.set(newMessage.toMap());
    await messageRef.update({'status': 'delivered'});
  }

  // get message
  Stream<QuerySnapshot> getMessage(String userID, otherUserID) {
    // construct chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [userID, otherUserID];
    ids.sort(); // sort the ids (this ensure the chatroomID is the same for any 2 people) String chatRoomID = ids.join('_');
    String chatRoomID = ids.join("_");
    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markMessagesSeen(
    String currentUserId,
    String otherUserId,
  ) async {
    final ids = [currentUserId, otherUserId]..sort();
    final roomId = ids.join('_');
    final snapshot = await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .get();
    final batch = _firestore.batch();
    var hasUpdates = false;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['receiverId'] == currentUserId && data['status'] != 'seen') {
        batch.update(doc.reference, {'status': 'seen'});
        hasUpdates = true;
      }
    }
    if (hasUpdates) await batch.commit();
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    // Ensure your Users doc actually stores the Firebase Auth UID in a field uid'
    return (q.docs.first.data()['uid'] ?? '').toString();
  }
}
