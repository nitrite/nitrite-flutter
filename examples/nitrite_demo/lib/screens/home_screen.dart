import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_demo/models/models.dart';
import 'package:nitrite_demo/providers/providers.dart';
import 'package:nitrite_demo/screens/widgets/new_todo_dialog.dart';
import 'package:nitrite_demo/screens/widgets/stats_card.dart';
import 'package:nitrite_demo/screens/widgets/todo_list.dart';
import 'package:uuid/uuid.dart';

var _uuid = const Uuid();
bool get isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 30,
            ),
            // Stats Card
            const StatsCard(),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SearchBar(
                controller: textController,
                constraints: const BoxConstraints(
                  maxHeight: 50,
                ),
                elevation: MaterialStateProperty.all(1),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                leading: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.search,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
                trailing: [
                  IconButton(
                    onPressed: () {
                      textController.clear();
                      ref.read(filterProvider.notifier).update((state) => all);
                    },
                    icon: const Icon(Icons.clear),
                  ),
                ],
                onChanged: (String data) {
                  if (data.isNotEmpty) {
                    ref
                        .read(filterProvider.notifier)
                        .update((state) => where('title').text('*$data*'));
                  } else {
                    ref.read(filterProvider.notifier).update((state) => all);
                  }
                },
              ),
            ),

            // Title Filter
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 10, top: 10),
              child: Text(
                'Tasks',
                style: TextStyle(
                  color: Color(0xff8C8C8C),
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Expanded(
              child: TodoList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return NewTodoDialog(
                onPressed: () {
                  final todoText = ref.read(todoTextProvider);
                  if (todoText.isNotEmpty) {
                    var todo = Todo(
                      id: _uuid.v4(),
                      title: todoText,
                      completed: false,
                    );
                    ref.read(todosProvider.notifier).addTodo(todo);
                  }
                  Navigator.of(context).pop();
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
