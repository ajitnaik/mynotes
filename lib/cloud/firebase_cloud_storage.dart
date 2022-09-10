import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotes/cloud/cloud_exceptions.dart';
import 'package:mynotes/cloud/cloud_note.dart';
import 'package:mynotes/cloud/cloud_storage_constants.dart';

class FirebaseCloudStorage {
  FirebaseCloudStorage._();

  static final instance = FirebaseCloudStorage._();

  final notes = FirebaseFirestore.instance.collection('notes');

  Future<CloudNote> createNewNote({required String ownerUserId}) async {
    try {
      final document = await notes.add({
        ownerUserIdFieldName: ownerUserId,
        textFieldName: '',
      });
      final fetchedNote = await document.get();
      return CloudNote(
        documentId: fetchedNote.id,
        ownerUserId: ownerUserId,
        text: '',
      );
    } on Exception catch (e) {
      throw CouldNotCreateNoteException();
    }
  }

  Future<Iterable<CloudNote>> getNotes({required ownerUserId}) async {
    return await notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .get()
        .then((value) => value.docs.map((e) => CloudNote.fromSnapshot(e)));
  }

  Stream<Iterable<CloudNote>> allNotes({required ownerUserId}) =>
      notes.snapshots().map((event) => event.docs
          .map((e) => CloudNote.fromSnapshot(e))
          .where((note) => note.ownerUserId == ownerUserId));

  Future<void> updateNote({
    required String documentId,
    required String text,
  }) async {
    try {
      await notes.doc(documentId).update({textFieldName: text});
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }

  Future<void> deleteNote({
    required String documentId,
  }) async {
    try {
      await notes.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteNoteException();
    }
  }
}
