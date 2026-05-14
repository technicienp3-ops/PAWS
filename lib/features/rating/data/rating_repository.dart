import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/cleanliness_rating.dart';

class RatingRepository {
  RatingRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<void> submitRating({
    required String locationId,
    required CleanlinessRating rating,
    String? comment,
    Uint8List? imageBytes,
  }) async {
    final locationRef = _firestore.collection('locations').doc(locationId);
    final ratingRef = locationRef.collection('ratings').doc();
    String? photoUrl;

    if (imageBytes != null) {
      final imageRef = _storage.ref(
        'locations/$locationId/${ratingRef.id}.jpg',
      );
      await imageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      photoUrl = await imageRef.getDownloadURL();
    }

    await _firestore.runTransaction((transaction) async {
      final locationSnapshot = await transaction.get(locationRef);
      final data = locationSnapshot.data() ?? <String, dynamic>{};
      final currentAverage = (data['averageRating'] as num?)?.toDouble() ?? 0;
      final currentCount = (data['ratingCount'] as num?)?.toInt() ?? 0;
      final nextCount = currentCount + 1;
      final nextAverage =
          ((currentAverage * currentCount) + rating.score) / nextCount;

      transaction.set(ratingRef, {
        'rating': rating.name,
        'score': rating.score,
        'comment': comment,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(
        locationRef,
        {
          'averageRating': nextAverage,
          'ratingCount': nextCount,
          if (photoUrl != null) 'photoUrl': photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
