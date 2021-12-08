import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:task_sqflite/model/notes_model.dart';

class NoteDatabase {
  static final NoteDatabase instance = NoteDatabase._init();

  static Database? _database;
  NoteDatabase._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase('notes.db');
    return _database!;
  }

  Future<Database> _initDatabase(String filePath) async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const boolType = 'BOOLEAN NOT NULL';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
    CREATE TABLE $tableNotes(
          ${NoteFields.id} $idType,
          ${NoteFields.isImportant} $boolType,
          ${NoteFields.number} $integerType,
          ${NoteFields.title} $textType,
          ${NoteFields.description} $textType,
          ${NoteFields.time} $textType
        )
        ''');
  }

  Future<Notes> createNote(Notes note) async {
    final db = await instance.database;
    // final json = note.toJson();
    // final columns = '${NoteFields.title}, ${NoteFields.description}, ${NoteFields.time}';
    // final values =  '"${json[NoteFields.title]}", "${json[NoteFields.description]}", "${json[NoteFields.time]}"';
    // final id = await db.rawInsert('''INSERT INTO $tableNotes ($columns) VALUES ($values)''');
    final id = await db.insert(tableNotes, note.toJson());
    return note.copyWith(id: id);
  }

  Future<Notes> readNote(int id) async {
    final db = await instance.database;
    final note = await db.query(tableNotes,
        columns: NoteFields.values,
        where: '${NoteFields.id} = ?',
        whereArgs: [id]);

    if (note.isNotEmpty) {
      return Notes.fromJson(note.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Notes>> readAllNotes() async {
    final db = await instance.database;
    final orderBy = '${NoteFields.time} ASC';
    final notes = await db.query(tableNotes,
        columns: NoteFields.values, orderBy: orderBy);
    return notes.map((note) => Notes.fromJson(note)).toList();
  }

  Future<int> updateNote(Notes note) async {
    final db = await instance.database;
    return await db.update(tableNotes, note.toJson(),
        where: '${NoteFields.id} = ?', whereArgs: [note.id]);
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db
        .delete(tableNotes, where: '${NoteFields.id} = ?', whereArgs: [id]);
  }

  Future close() async {
    var db = await instance.database;
    return db.close();
  }
}
