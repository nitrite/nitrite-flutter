import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitrite_demo/main.dart';
import 'package:nitrite_demo/providers/providers.dart';
import 'package:nitrite_demo/screens/widgets/stats_card.dart';

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
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stats Card
            const StatsCard(),

            Padding(
              padding: const EdgeInsets.all(30.0),
              child: AnimSearchBar(
                width: MediaQuery.of(context).size.width * 0.9,
                rtl: true,
                textController: textController,
                onSuffixTap: () {
                  setState(() {
                    textController.clear();
                  });
                },
                onSubmitted: (String data) {
                  // ref.read(titleTodosStatusProvider.notifier).change(data);
                },
              ),
            ),

            // TODOS TITLE FILTER
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 10, top: 10),
              child: Text(
                'All tasks',
                style: TextStyle(
                  color: Color(0xff8C8C8C),
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            //  TODOS LISTVIEW
            const Expanded(
              child: TodoList(),
            ),
          ],
        ),
      )
    );
  }
}
