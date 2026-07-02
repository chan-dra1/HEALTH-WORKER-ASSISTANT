import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/observation.dart';
import '../models/facility.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'healthworker.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  Future<void> _upgradeTables(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createFacilitiesTable(db);
    }
  }

  Future<void> _createFacilitiesTable(Database db) async {
    await db.execute('''
      CREATE TABLE facilities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        phone TEXT NOT NULL,
        village TEXT NOT NULL,
        directions TEXT,
        services TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        dateOfBirth TEXT NOT NULL,
        gender TEXT NOT NULL,
        phone TEXT NOT NULL,
        village TEXT NOT NULL,
        facilityName TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        syncedAt TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE observations (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        recordedAt TEXT NOT NULL,
        recordedBy TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (patientId) REFERENCES patients(id)
      )
    ''');

    await _createFacilitiesTable(db);
  }

  // PATIENT OPERATIONS

  Future<void> insertPatient(Patient patient) async {
    final db = await database;
    await db.insert(
      'patients',
      patient.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Patient>> getAllPatients() async {
    final db = await database;
    final maps = await db.query('patients', orderBy: 'createdAt DESC');
    return maps.map(Patient.fromJson).toList();
  }

  Future<Patient?> getPatient(String id) async {
    final db = await database;
    final maps = await db.query(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Patient.fromJson(maps.first);
  }

  Future<void> updatePatient(Patient patient) async {
    final db = await database;
    await db.update(
      'patients',
      patient.toJson(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<void> deletePatient(String id) async {
    final db = await database;
    await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  // OBSERVATION OPERATIONS

  Future<void> insertObservation(Observation obs) async {
    final db = await database;
    await db.insert(
      'observations',
      obs.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Observation>> getPatientObservations(String patientId) async {
    final db = await database;
    final maps = await db.query(
      'observations',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'recordedAt DESC',
    );
    return maps.map(Observation.fromJson).toList();
  }

  // FACILITY OPERATIONS

  Future<void> insertFacility(Facility facility) async {
    final db = await database;
    await db.insert(
      'facilities',
      facility.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Facility>> getAllFacilities() async {
    final db = await database;
    final maps = await db.query('facilities', orderBy: 'name ASC');
    return maps.map(Facility.fromJson).toList();
  }

  Future<void> deleteFacility(String id) async {
    final db = await database;
    await db.delete('facilities', where: 'id = ?', whereArgs: [id]);
  }

  // Drop the on-disk database file (used by tests / dev reset flows).
  // Named `dropDatabase` to avoid shadowing sqflite's top-level
  // `deleteDatabase` function — the quickstart version recursed infinitely.
  Future<void> dropDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'healthworker.db');
    await _database?.close();
    _database = null;
    await deleteDatabase(path);
  }
}
