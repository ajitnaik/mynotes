import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:mynotes/extensions/list/filter.dart';
import 'package:mynotes/services/crud/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

const dbName = "notes.db";
const noteTable = "notes";
const userTable = "user";
const idColumn = "id";
const emailColumn = "email";
const userIdColumn = "user_id";
const textColumn = "text";
const isSyncedWithCloudColumn = "is_synced_with_cloud";

const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
        "id"	INTEGER NOT NULL,
        "email"	TEXT NOT NULL UNIQUE,
        PRIMARY KEY("id" AUTOINCREMENT)
      );
      ''';

const createNotesTable = '''CREATE TABLE IF NOT EXISTS "notes" (
        "id"	INTEGER NOT NULL,
        "user_id"	INTEGER NOT NULL,
        "text"	TEXT,
        "is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY("user_id") REFERENCES "user"("id"),
        PRIMARY KEY("id" AUTOINCREMENT)
      );
      ''';

class NotesService {

  NotesService._() {
    _notesStreamController =  StreamController<List<DatabaseNote>>.broadcast(onListen: (() {
      _notesStreamController.sink.add(_notes);
    }));
  }

  static final instance = NotesService._();

  Database? _db;

  List<DatabaseNote> _notes = [];

  DatabaseUser? _user;

  late final  StreamController<List<DatabaseNote>> _notesStreamController;
  
  get allNotes => _notesStreamController.stream.filter(((note) {
    final currentUser = _user;

    if (currentUser != null) {
      return note.userId == currentUser.id;
    } else {
      throw UserShouldBeSetException();
    }
  }));

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Database _getDatabaseOrThrow() {
    open();
    final db = _db;
    if (db == null || !db.isOpen) {
      throw DatabaseNotOpenException();
    } else {
      return db;
    }
  }

  Future<void> deleteUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
  }

  Future<DatabaseUser> createUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    final userExists = await db.query(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (userExists.isNotEmpty) {
      throw UserAlreadyExistsException();
    } else {
  final int userId = await db.insert(
    userTable,
    {emailColumn: email.toLowerCase()},
  );
  return DatabaseUser(
    id: userId,
    email: email,
  );
    }
  }

  Future<DatabaseUser> getUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    final userExists = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    log(userExists.toString());
    if (userExists.isEmpty) {
      throw UserDoesNotExistException();
    } else {
      return DatabaseUser.fromRow(userExists.first);
    }
  }

  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    try {
      final user = await getUser(email: email);
      _user = user;
      return user;
    } on UserDoesNotExistException catch (e) {
      final createdUser = await createUser(email: email);
      _user = createdUser;
      return createdUser;
    }

  }

  Future<void> close() async {
    _getDatabaseOrThrow().close();
  }

  Future<void> open() async {
    if (_db != null && _db!.isOpen) {
      
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      await db.execute(createUserTable);
      await db.execute(createNotesTable);
      await _cacheNotes();
    } on MissingPlatformDirectoryException catch (e) {
      throw UnableToGetDocumentsDirectoryException();
    }
  }

  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    final db = _getDatabaseOrThrow();
    final dbUser = await getUser(email: owner.email);

    if (dbUser != owner) {
      throw UserDoesNotExistException();
    }

    const text = '';

    final int noteId = await db.insert(
      noteTable,
      {userIdColumn: owner.id, textColumn: text, isSyncedWithCloudColumn: 1},
    );

    final DatabaseNote note = DatabaseNote(
      id: noteId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );

    _notes.add(note);
    _notesStreamController.add(_notes);
    
    return note;
  }

  Future<void> deleteNote({required int id}) async {
    final db = _getDatabaseOrThrow();
    await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    _notes.removeWhere((note) => note.id == id);
    _notesStreamController.add(_notes);
  }

  Future<void> deleteAllNotes({required int id}) async {
    final db = _getDatabaseOrThrow();
    await db.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);
  }

  Future<DatabaseNote> getNote({required int id}) async {
    final db = _getDatabaseOrThrow();
    final noteExists = await db.query(
      noteTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (noteExists.isEmpty) {
      throw NoteDoesNotExistException();
    } else {
      final newNote = DatabaseNote.fromRow(noteExists.first);
      _notes.removeWhere((note) => note.id == newNote.id);
      _notes.add(newNote);
      _notesStreamController.add(_notes);
      return newNote;
    }
  }

  Future<Iterable<DatabaseNote>> getAllNotes() async {
    final db = _getDatabaseOrThrow();
    final noteExists = await db.query(noteTable);
    if (noteExists.isEmpty) {
      throw NoteDoesNotExistException();
    } else {
      return noteExists.map((e) => DatabaseNote.fromRow(e));
    }
  }

  Future<DatabaseNote> updateNote(
      {required DatabaseNote note, required String text}) async {
    final db = _getDatabaseOrThrow();
    await getNote(id: note.id);

    db.update(noteTable, {textColumn: text},
        where: 'id = ?', whereArgs: [note.id]);

    final updatedNote = await getNote(id: note.id);
    _notes.removeWhere((note) => note.id == updatedNote.id);
    _notes.add(updatedNote);
    _notesStreamController.add(_notes);
    return updatedNote;
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({
    required this.id,
    required this.email,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Note, ID = $id, userId = $userId, isSyncedWithCloud = $isSyncedWithCloud';

  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}
