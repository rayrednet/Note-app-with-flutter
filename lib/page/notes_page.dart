import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../db/notes_database.dart';
import '../model/note.dart';
import '../page/edit_note_page.dart';
import '../page/note_detail_page.dart';
import '../widget/note_card_widget.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class NotesSearch extends SearchDelegate<Note?> {
  final List<Note> notes;

  NotesSearch(this.notes);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<Note> matchQuery = [];

    for (var note in notes) {
      if (note.title.toLowerCase().contains(query.toLowerCase()) ||
          note.description.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(note);
      }
    }

    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context, index) {
        var result = matchQuery[index];
        return ListTile(
          title: Text(
            result.title,
            style: const TextStyle(
              color: Colors
                  .white, // Choose a color that contrasts well with the background
              fontWeight: FontWeight.bold, // Make it bold
            ),
          ),
          subtitle: Text(
            result.description,
            style: const TextStyle(
              color: Colors.white70, // Again, ensure good contrast
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          onTap: () {
            // Push the note detail page onto the navigation stack
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => NoteDetailPage(noteId: result.id!),
            ));
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Note> matchQuery = [];

    for (var note in notes) {
      if (note.title.toLowerCase().contains(query.toLowerCase()) ||
          note.description.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(note);
      }
    }

    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context, index) {
        var result = matchQuery[index];
        return ListTile(
          title: Text(result.title),
          subtitle: Text(result.description),
          onTap: () {
            close(context, result);
          },
        );
      },
    );
  }
}

class _NotesPageState extends State<NotesPage> {
  late List<Note> notes;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    refreshNotes();
  }

  @override
  void dispose() {
    NotesDatabase.instance.close();

    super.dispose();
  }

  Future refreshNotes() async {
    setState(() => isLoading = true);

    notes = await NotesDatabase.instance.readAllNotes();

    if (showingFavorites) {
      notes = notes.where((note) => note.isImportant).toList();
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Notes',
              style: TextStyle(fontSize: 24, color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.white),
              onPressed: () {
                showFavorites();
              },
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: NotesSearch(notes),
                );
              },
            ),
            const SizedBox(width: 12)
          ],
        ),
        body: isLoading
            ? const CircularProgressIndicator()
            : notes.isEmpty
                ? const Center(
                    child: Text(
                      'No Notes',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  )
                : buildNotes(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddEditNotePage()),
            );

            refreshNotes();
          },
        ),
      );

  Widget buildNotes() => StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: List.generate(
        notes.length,
        (index) {
          final note = notes[index];

          return StaggeredGridTile.fit(
            crossAxisCellCount: 1,
            child: GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => NoteDetailPage(noteId: note.id!),
                ));

                refreshNotes();
              },
              child: NoteCardWidget(note: note, index: index),
            ),
          );
        },
      ));

  bool showingFavorites = false;

  void showFavorites() {
    setState(() {
      showingFavorites = !showingFavorites;
      if (showingFavorites) {
        notes = notes.where((note) => note.isImportant).toList();
      } else {
        refreshNotes();
      }
    });
  }
}
