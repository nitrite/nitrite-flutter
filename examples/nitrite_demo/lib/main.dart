import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitrite_demo/providers.dart';

void main() {
  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

class TodoList extends ConsumerWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the todos from the provider.
    var todos = ref.watch(todosProvider);

    return todos.when(
      data: (todos) => ListView(
        children: [
          await for (final todo in todos)
            CheckboxListTile(
              value: todo.completed,
              // When tapping on the todo, change its completed status
              onChanged: (value) =>
                  ref.read(asyncTodosProvider.notifier).toggle(todo.id),
              title: Text(todo.description),
            ),
        ],
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Text('Error: $err'),
    );

    return ListView.builder(
      itemCount: todos..length,
      itemBuilder: (context, index) {
        TodoModel todo = todos[index];

        return ListTile(
          title: Text(todo.title),
          trailing: IconButton(
            icon: Icon(
                todo.completed ? Icons.check_box : Icons.check_box_outlined),
            onPressed: () => todo.toggleCompleted(),
          ),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Provider<List<TodoModel>>(
          create: (_) => [
            TodoModel(title: 'Buy milk'),
            TodoModel(title: 'Do laundry'),
            TodoModel(title: 'Clean the house'),
          ],
          child: const TodoList(),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
