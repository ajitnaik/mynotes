import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/crud/notes_service.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({Key? key}) : super(key: key);

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  DatabaseNote? _note;
  late final NotesService _notesService;
  late final TextEditingController _textEditingController;

  Future<DatabaseNote> createNewNote() async {
    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final currentUser = AuthService.firebase().currentUser!;
    log(currentUser.email!);
    log(_notesService.getUser(email: currentUser.email!).toString());
    return await _notesService.createNote(
        owner: await _notesService.getUser(email: currentUser.email!));
  }

  void _textControllerListener() async {
    _saveNote();
  }

  void _setupTextControllerListener() async {
    _textEditingController.removeListener(_textControllerListener);
    _textEditingController.addListener(_textControllerListener);
  }

  void _deleteNoteIfTextIsEmpty() async {
    final note = _note;
    if (_textEditingController.text.isEmpty && note != null) {
      await _notesService.deleteNote(id: note.id);
    }
  }

  void _saveNote() async {
    final note = _note;
    if (_textEditingController.text.isNotEmpty && note != null) {
      await _notesService.updateNote(
        note: note,
        text: _textEditingController.text,
      );
    }
  }

  @override
  void initState() {
    _notesService = NotesService.instance;
    _textEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNote();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
      ),
      body: FutureBuilder(
        future: createNewNote(),
        builder: ((context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _note = snapshot.data as DatabaseNote;
              _setupTextControllerListener();
              return TextField(
                controller: _textEditingController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(hintText: 'Start typing...'),
              );
            default:
              return const CircularProgressIndicator();
          }
        }),
      ),
    );
  }
}
