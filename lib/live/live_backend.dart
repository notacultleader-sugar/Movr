import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:latlong2/latlong.dart';

import '../data/mock_data.dart';
import '../models/move.dart';
import 'live_config.dart';

/// Where a real booking is up to. Stored as the enum name.
enum JobStatus {
  requested('Looking for a driver'),
  accepted('Driver on the way'),
  atPickup('Loading'),
  loaded('In transit'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const JobStatus(this.label);
  final String label;

  static JobStatus parse(Object? v) => JobStatus.values.firstWhere(
    (s) => s.name == v,
    orElse: () => JobStatus.requested,
  );
}

/// The driver's public details, from drivers/{uid}.
class DriverProfile {
  const DriverProfile({
    required this.uid,
    required this.name,
    required this.vehicle,
    required this.plate,
    required this.phone,
    this.rating = 5.0,
  });

  final String uid;
  final String name;
  final String vehicle;
  final String plate;
  final String phone;
  final double rating;

  factory DriverProfile.fromMap(String uid, Map<String, dynamic> m) =>
      DriverProfile(
        uid: uid,
        name: m['name'] as String? ?? 'Driver',
        vehicle: m['vehicle'] as String? ?? '',
        plate: m['plate'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
      );

  Driver toDriver() => Driver(
    name: name,
    rating: rating,
    vehicle: vehicle,
    plate: plate,
    phone: phone,
  );
}

/// One real booking, from jobs/{id}.
class LiveJob {
  const LiveJob({
    required this.id,
    required this.status,
    required this.pickup,
    required this.dropoff,
    required this.quote,
    required this.contactName,
    required this.contactPhone,
    this.notes = '',
    this.driver,
    this.driverPos,
    this.createdAt,
  });

  final String id;
  final JobStatus status;
  final Place pickup;
  final Place dropoff;
  final Quote quote;
  final String contactName;
  final String contactPhone;
  final String notes;
  final DriverProfile? driver;
  final LatLng? driverPos;
  final DateTime? createdAt;

  bool get isOpen => status == JobStatus.requested;
  bool get isActive =>
      status == JobStatus.accepted ||
      status == JobStatus.atPickup ||
      status == JobStatus.loaded;

  factory LiveJob.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    final driverUid = m['driverUid'] as String?;
    final pos = m['driverPos'] as Map<String, dynamic>?;
    return LiveJob(
      id: doc.id,
      status: JobStatus.parse(m['status']),
      pickup: placeFromMap(m['pickup']),
      dropoff: placeFromMap(m['dropoff']),
      quote: Quote(
        vehicle: VehicleTier.values.firstWhere(
          (t) => t.name == m['tier'],
          orElse: () => VehicleTier.haul,
        ),
        items: [
          for (final i in (m['items'] as List? ?? const []))
            itemFromMap(i as Map<String, dynamic>),
        ],
        miles: (m['miles'] as num?)?.toDouble() ?? 0,
        helpers: (m['helpers'] as num?)?.toInt() ?? 1,
        hours: (m['hours'] as num?)?.toInt() ?? 1,
      ),
      contactName: m['contactName'] as String? ?? '',
      contactPhone: m['contactPhone'] as String? ?? '',
      notes: m['notes'] as String? ?? '',
      driver: driverUid == null
          ? null
          : DriverProfile.fromMap(
              driverUid,
              (m['driver'] as Map?)?.cast<String, dynamic>() ?? const {},
            ),
      driverPos: pos == null
          ? null
          : LatLng(
              (pos['lat'] as num).toDouble(),
              (pos['lng'] as num).toDouble(),
            ),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// For the shared completion screen.
  MoveOrder toOrder() => MoveOrder(
    pickup: pickup,
    dropoff: dropoff,
    quote: quote,
    driver: (driver ?? fallbackDriver).toDriver(),
    driverStart: driverPos ?? pickup.pos,
  );

  static const fallbackDriver = DriverProfile(
    uid: '',
    name: 'Your driver',
    vehicle: '',
    plate: '',
    phone: '',
  );
}

Map<String, dynamic> placeToMap(Place p) => {
  'name': p.name,
  'address': p.address,
  'lat': p.pos.latitude,
  'lng': p.pos.longitude,
};

Place placeFromMap(Object? v) {
  final m = (v as Map?)?.cast<String, dynamic>() ?? const {};
  return Place(
    m['name'] as String? ?? '',
    m['address'] as String? ?? '',
    LatLng(
      (m['lat'] as num?)?.toDouble() ?? duncanCentre.latitude,
      (m['lng'] as num?)?.toDouble() ?? duncanCentre.longitude,
    ),
  );
}

Map<String, dynamic> itemToMap(MoveItem i) => {
  'name': i.name,
  'weight': i.weightClass.name,
};

MoveItem itemFromMap(Map<String, dynamic> m) {
  final name = m['name'] as String? ?? 'Item';
  final known = scannableItems.where((i) => i.name == name);
  if (known.isNotEmpty) return known.first;
  return MoveItem(
    name,
    WeightClass.values.firstWhere(
      (w) => w.name == m['weight'],
      orElse: () => WeightClass.medium,
    ),
    Icons.inventory_2,
  );
}

/// Real accounts, bookings and driver location, in Firebase.
///
/// Customers sign in anonymously (no password; the booking carries their
/// name and phone). Drivers sign in with an email and password that Ian
/// creates in the Firebase console, and must also have a drivers/{uid}
/// profile there; the security rules only let those accounts see open
/// jobs and update them.
class LiveBackend {
  LiveBackend._();
  static final instance = LiveBackend._();

  /// True when the app was built with Firebase settings (or for the
  /// emulator), so screens should use real bookings.
  static bool get enabled => useEmulator || firebaseOptions != null;

  bool _ready = false;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  CollectionReference<Map<String, dynamic>> get _jobs => _db.collection('jobs');

  Future<void> init() async {
    if (_ready || !enabled) return;
    await Firebase.initializeApp(
      options: useEmulator ? emulatorOptions : firebaseOptions,
    );
    if (useEmulator) {
      _db.useFirestoreEmulator('localhost', 8080);
      await _auth.useAuthEmulator('localhost', 9099);
    }
    _ready = true;
  }

  String? get uid => _auth.currentUser?.uid;

  /// Customers: a silent account so bookings belong to this phone.
  Future<void> ensureCustomer() async {
    await init();
    if (_auth.currentUser == null) await _auth.signInAnonymously();
  }

  /// Drivers: email and password. Returns the profile, or throws
  /// [DriverSignInError] with a message to show.
  Future<DriverProfile> signInDriver(String email, String password) async {
    await init();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final doc = await _db.collection('drivers').doc(cred.user!.uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        throw const DriverSignInError(
          'This account isn\'t set up as a driver yet. Ask the movr team to '
          'add your driver profile.',
        );
      }
      return DriverProfile.fromMap(doc.id, doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw DriverSignInError(switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'That email and password don\'t match.',
        'too-many-requests' => 'Too many tries. Wait a minute and try again.',
        'network-request-failed' => 'No connection. Check your signal.',
        'operation-not-allowed' =>
          'Driver sign-in isn\'t switched on in Firebase yet '
              '(Authentication > Sign-in method > Email/Password).',
        _ => 'Couldn\'t sign in (${e.code}).',
      });
    }
  }

  /// The signed-in driver's profile, if the last session is still valid.
  Future<DriverProfile?> currentDriver() async {
    await init();
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    final doc = await _db.collection('drivers').doc(user.uid).get();
    return doc.exists ? DriverProfile.fromMap(doc.id, doc.data()!) : null;
  }

  Future<void> signOut() => _auth.signOut();

  /// Books a move. Returns the job id.
  Future<String> createJob({
    required Place pickup,
    required Place dropoff,
    required Quote quote,
    required String contactName,
    required String contactPhone,
    String notes = '',
  }) async {
    await ensureCustomer();
    final doc = await _jobs.add({
      'status': JobStatus.requested.name,
      'customerUid': uid,
      'contactName': contactName.trim(),
      'contactPhone': contactPhone.trim(),
      'notes': notes.trim(),
      'pickup': placeToMap(pickup),
      'dropoff': placeToMap(dropoff),
      'tier': quote.vehicle.name,
      'items': [for (final i in quote.items) itemToMap(i)],
      'helpers': quote.helpers,
      'hours': quote.hours,
      'miles': quote.miles,
      'total': quote.total,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<LiveJob?> watchJob(String id) => _jobs
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? LiveJob.fromDoc(d) : null);

  /// Jobs waiting for a driver, oldest first. Drivers only.
  Stream<List<LiveJob>> watchOpenJobs() => _jobs
      .where('status', isEqualTo: JobStatus.requested.name)
      .snapshots()
      .map((q) {
        final jobs = q.docs.map(LiveJob.fromDoc).toList()
          ..sort(
            (a, b) => (a.createdAt ?? DateTime(3000)).compareTo(
              b.createdAt ?? DateTime(3000),
            ),
          );
        return jobs;
      });

  /// The job this driver is in the middle of, if any (e.g. after a reload).
  Future<LiveJob?> activeJobFor(String driverUid) async {
    final q = await _jobs.where('driverUid', isEqualTo: driverUid).get();
    final active = q.docs.map(LiveJob.fromDoc).where((j) => j.isActive);
    return active.isEmpty ? null : active.first;
  }

  /// Claims a job. Fails (returns false) if another driver got it first.
  Future<bool> acceptJob(String id, DriverProfile me, LatLng? at) {
    return _db.runTransaction((tx) async {
      final ref = _jobs.doc(id);
      final snap = await tx.get(ref);
      if (snap.data()?['status'] != JobStatus.requested.name) return false;
      tx.update(ref, {
        'status': JobStatus.accepted.name,
        'driverUid': me.uid,
        'driver': {
          'name': me.name,
          'vehicle': me.vehicle,
          'plate': me.plate,
          'phone': me.phone,
          'rating': me.rating,
        },
        if (at != null) 'driverPos': _pos(at),
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  Future<void> setStatus(String id, JobStatus status) => _jobs.doc(id).update({
    'status': status.name,
    '${status.name}At': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateDriverPos(String id, LatLng at) =>
      _jobs.doc(id).update({'driverPos': _pos(at)});

  /// Customers can cancel until a driver accepts.
  Future<void> cancelJob(String id) => setStatus(id, JobStatus.cancelled);

  static Map<String, dynamic> _pos(LatLng at) => {
    'lat': at.latitude,
    'lng': at.longitude,
    'at': FieldValue.serverTimestamp(),
  };
}

class DriverSignInError implements Exception {
  const DriverSignInError(this.message);
  final String message;
  @override
  String toString() => message;
}
