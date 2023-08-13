import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitrite_demo/providers/providers.dart';
import 'package:nitrite_demo/screens/home_screen.dart';

class StatsCard extends ConsumerStatefulWidget {
  const StatsCard({super.key});

  @override
  ConsumerState<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends ConsumerState<StatsCard> {
  @override
  Widget build(BuildContext context) {
    final completedCounter = ref.watch(completedCounterProvider);
    final pendingCounter = ref.watch(pendingCounterProvider);

    var width = MediaQuery.of(context).size.width * (isDesktop ? 0.7 : 0.9);

    return Center(
      child: Card(
        elevation: 2,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: SizedBox(
          width: width,
          height: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  'Completed Task: $completedCounter',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  'Pending Task: $pendingCounter',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
