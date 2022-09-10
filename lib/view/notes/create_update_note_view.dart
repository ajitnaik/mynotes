import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mynotes/cloud/cloud_note.dart';
import 'package:mynotes/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/generics/get_arguments.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({Key? key}) : super(key: key);

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  CloudNote? _note;
  late final FirebaseCloudStorage _cloudStorage;
  late final TextEditingController _textEditingController;

  Future<CloudNote> createOrGetExistingNote(BuildContext context) async {
    final widgetNote = context.getArgument<CloudNote>();

    if (widgetNote != null) {
      _note = widgetNote;
      _textEditingController.text = widgetNote.text;
    }
    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final currentUser = AuthService.firebase().currentUser!;
    log(currentUser.email);
    final userId = currentUser.id;
    final newNote = await _cloudStorage.createNewNote(
      ownerUserId: userId,
    );
    _note = newNote;
    return newNote;
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
      await _cloudStorage.deleteNote(documentId: note.documentId);
    }
  }

  void _saveNote() async {
    final note = _note;
    if (_textEditingController.text.isNotEmpty && note != null) {
      await _cloudStorage.updateNote(
        documentId: note.documentId,
        text: _textEditingController.text,
      );
    }
  }

  @override
  void initState() {
    _cloudStorage = FirebaseCloudStorage.instance;
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
        future: createOrGetExistingNote(context),
        builder: ((context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
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
