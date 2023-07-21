import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitrite_demo/providers/providers.dart';

class StatsCard extends ConsumerStatefulWidget {
  const StatsCard({super.key});

  @override
  ConsumerState<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends ConsumerState<StatsCard> {
  @override
  Widget build(BuildContext context) {
    final completedCounter = ref.watch(completedCounterProvider.future);
    final pendingCounter = ref.watch(pendingCounterProvider.future);

    return Center(
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: SizedBox(
          width: 300,
          height: 350,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FutureBuilder(
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        'Completed Task - ${snapshot.data}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                  future: completedCounter,
                ),
                FutureBuilder(
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        'Pending Task - ${snapshot.data}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                  future: pendingCounter,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
