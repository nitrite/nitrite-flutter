import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitrite_demo/providers/providers.dart';
import 'package:nitrite_demo/screens/home_screen.dart';

import 'models/models.dart';

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
      data: (todoStream) => StreamBuilder(
          stream: todoStream,
          initialData: const <Todo>[],
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            var todoList = snapshot.data as List<Todo>;

            return ListView.builder(
              itemCount: todoList.length,
              itemBuilder: (context, index) {
                Todo todo = todoList[index];

                return ListTile(
                  title: Text(todo.title),
                  trailing: IconButton(
                    icon: Icon(todo.completed
                        ? Icons.check_box
                        : Icons.check_box_outlined),
                    onPressed: () =>
                        ref.read(todosProvider.notifier).toggle(todo.id),
                  ),
                );
              },
            );
          }),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Text('Error: $err'),
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

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
      body: const Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          children: <Widget>[
            TodoList(),
            SizedBox(
              height: 20,
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
