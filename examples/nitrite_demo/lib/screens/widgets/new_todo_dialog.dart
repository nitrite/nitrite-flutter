import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitrite_demo/providers/providers.dart';

class NewTodoDialog extends ConsumerWidget {
  final void Function()? onPressed;
  const NewTodoDialog({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FocusNode focusNode = FocusNode();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: Column(
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: Offset(0, 0),
                  )
                ],
                color: Colors.white,
              ),
              child: Icon(
                Icons.task_alt_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                'New Task',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: TextField(
            focusNode: focusNode,
            maxLines: null,
            // expands: true,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              labelText: 'Whats on your mind?',
              hintText: 'Make Dr appointment',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              ref.read(todoTextProvider.notifier).update((state) => value);
            },
            onTapOutside: (event) {
              focusNode.unfocus();
            },
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              "Create",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
