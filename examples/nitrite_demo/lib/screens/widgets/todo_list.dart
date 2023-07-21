import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitrite_demo/models/models.dart';
import 'package:nitrite_demo/providers/providers.dart';
import 'package:nitrite_demo/screens/widgets/todo_widgets.dart';

class TodoList extends ConsumerWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the todos from the provider.
    var todos = ref.watch(todosProvider);

    return todos.when(
      data: (todoList) => ListView.builder(
        itemCount: todoList.length,
        itemBuilder: (context, index) {
          Todo todo = todoList[index];
          return Padding(
            padding: const EdgeInsets.only(left: 30.0, right: 30.0),
            child: TodoWidget(todo: todo),
          );
        },
      ),
      error: (err, stack) => Text('Error: $err\n$stack'),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
