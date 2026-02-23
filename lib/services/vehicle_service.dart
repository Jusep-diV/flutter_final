import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addVehicle({
    required String plate,
    required String brand,
    required String model,
    required String fuelType,
    DateTime? lastRevision,
    DateTime? nextItv,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    await _db.collection('users').doc(user.uid).collection('vehicles').add({
      'plate': plate.trim(),
      'brand': brand.trim(),
      'model': model.trim(),
      'fuelType': fuelType.trim(),
      'lastRevision': lastRevision == null ? null : Timestamp.fromDate(lastRevision),
      'nextItv': nextItv == null ? null : Timestamp.fromDate(nextItv),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateVehicle({
    required String vehicleId,
    required String plate,
    required String brand,
    required String model,
    required String fuelType,
    DateTime? lastRevision,
    DateTime? nextItv,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('vehicles')
        .doc(vehicleId)
        .update({
      'plate': plate.trim(),
      'brand': brand.trim(),
      'model': model.trim(),
      'fuelType': fuelType.trim(),
      'lastRevision': lastRevision == null ? null : Timestamp.fromDate(lastRevision),
      'nextItv': nextItv == null ? null : Timestamp.fromDate(nextItv),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteVehicle({required String vehicleId}) async {
  final user = _auth.currentUser;
  if (user == null) throw Exception('Usuario no autenticado');

  await _db
      .collection('users')
      .doc(user.uid)
      .collection('vehicles')
      .doc(vehicleId)
      .delete();
}
}