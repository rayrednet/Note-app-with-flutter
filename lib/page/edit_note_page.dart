import 'dart:io';
import 'package:flutter/material.dart';
import '../db/notes_database.dart';
import '../model/note.dart';
import '../widget/note_form_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class AddEditNotePage extends StatefulWidget {
  final Note? note;

  const AddEditNotePage({
    Key? key,
    this.note,
  }) : super(key: key);

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  final _formKey = GlobalKey<FormState>();
  late bool isImportant;
  late int number;
  late String title;
  late String description;
  String? imagePath;
  double rating = 0.0;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    isImportant = widget.note?.isImportant ?? false;
    number = widget.note?.number ?? 0;
    title = widget.note?.title ?? '';
    description = widget.note?.description ?? '';
    imagePath = widget.note?.imagePath;
    rating = widget.note?.rating ?? 0.0;
  }

  Future<void> pickMedia() async {
    final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ));

    if (source != null) {
      try {
        final pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 88,
          preferredCameraDevice: CameraDevice.rear,
        );

        if (pickedFile != null) {
          setState(() {
            imagePath = pickedFile.path;
          });
        }
      } catch (e) {
        print('Failed to pick image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [buildButton()],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (imagePath != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(File(imagePath!)),
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: pickMedia,
                child: const Text('Pick Image'),
              ),
              RatingBar.builder(
                initialRating: rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) =>
                    Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (newRating) {
                  setState(() {
                    rating = newRating;
                  });
                },
              ),
              NoteFormWidget(
                isImportant: isImportant,
                number: number,
                title: title,
                description: description,
                onChangedImportant: (isImportant) =>
                    setState(() => this.isImportant = isImportant),
                onChangedNumber: (number) =>
                    setState(() => this.number = number),
                onChangedTitle: (title) => setState(() => this.title = title),
                onChangedDescription: (description) =>
                    setState(() => this.description = description),
              ),
            ],
          ),
        ),
      );

  Widget buildButton() {
    final isFormValid = title.isNotEmpty && description.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white,
        ),
        onPressed: addOrUpdateNote,
        child: const Text('Save', style: TextStyle(color: Colors.deepPurple)),
      ),
    );
  }

  void addOrUpdateNote() async {
    print(
        "Title: $title, Description: $description, ImagePath: $imagePath, Rating: $rating");
    final isValid = _formKey.currentState!.validate();
    print("Form validation result: $isValid");

    if (isValid) {
      final isUpdating = widget.note != null;
      print("Updating existing note: $isUpdating");

      try {
        if (isUpdating) {
          await updateNote();
          print("Note updated successfully");
        } else {
          await addNote();
          print("Note added successfully");
        }
        Navigator.of(context).pop();
      } catch (e) {
        print("Failed to add or update note: $e");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Failed to save note')));
      }
    } else {
      print("Form is not valid, not proceeding to save");
    }
  }

  Future updateNote() async {
    final note = widget.note!.copy(
      isImportant: isImportant,
      number: number,
      title: title,
      description: description,
      imagePath: imagePath,
      rating: rating,
    );

    await NotesDatabase.instance.update(note);
  }

  Future addNote() async {
    final note = Note(
      title: title,
      isImportant: isImportant,
      number: number,
      description: description,
      createdTime: DateTime.now(),
      imagePath: imagePath,
      rating: rating,
    );

    await NotesDatabase.instance.create(note);
  }
}
