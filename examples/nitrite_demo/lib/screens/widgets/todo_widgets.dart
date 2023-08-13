import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:nitrite_demo/models/models.dart';
import 'package:nitrite_demo/providers/providers.dart';

class TodoWidget extends ConsumerWidget {
  final Todo todo;

  const TodoWidget({super.key, required this.todo});

  bool _isDesktop() =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isDesktop()) {
      return Card(
        color: Theme.of(context).colorScheme.surface,
        child: ListTile(
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.completed ? TextDecoration.lineThrough : null,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () =>
                    ref.read(todosProvider.notifier).toggle(todo.id),
                icon: Icon(
                  todo.completed ? Icons.task_alt : Icons.check_box_outlined,
                  color: todo.completed ? Colors.green : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: () =>
                    ref.read(todosProvider.notifier).removeTodo(todo.id),
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Slidable(
        key: ValueKey(todo.id),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              borderRadius: BorderRadius.circular(5),
              spacing: 10,
              onPressed: (context) =>
                  ref.read(todosProvider.notifier).toggle(todo.id),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: todo.completed ? Icons.task_alt : Icons.check_box_outlined,
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              borderRadius: BorderRadius.circular(5),
              spacing: 10,
              onPressed: (context) =>
                  ref.read(todosProvider.notifier).removeTodo(todo.id),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
            ),
          ],
        ),
        child: ListTile(
          leading: const Icon(Icons.adjust, color: Colors.black26),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.completed ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      );
    }
  }
}
