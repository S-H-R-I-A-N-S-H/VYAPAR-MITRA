import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logbook_controller.dart';

class LogbookPage extends ConsumerWidget {
  const LogbookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(logbookControllerProvider);
    final controller = ref.read(logbookControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade200, Colors.deepPurple.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + 20),
            ElevatedButton.icon(
              onPressed: () => controller.startVoiceCapture(context),
              icon: const Icon(Icons.mic),
              label: const Text('Record Transaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white70,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final e = entries[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('\${e.amountRupees} – ${e.itemDescription}'),
                      subtitle: Text('${e.quantity} ${e.unit} • ${e.category ?? "Uncated"}'),
                      trailing: e.synced
                          ? const Icon(Icons.cloud_done, color: Colors.green)
                          : const Icon(Icons.cloud_off, color: Colors.redAccent),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logbook_controller.dart';

class LogbookPage extends ConsumerWidget {
  const LogbookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(logbookControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade200, Colors.deepPurple.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + 20),
            ElevatedButton.icon(
              onPressed: () => controller.startVoiceCapture(context),
              icon: const Icon(Icons.mic),
              label: const Text('Record Transaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white70,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: controller.entries.length,
                itemBuilder: (context, index) {
                  final e = controller.entries[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('\${e.amountRupees} – ${e.itemDescription}'),
                      subtitle: Text('${e.quantity} ${e.unit} • ${e.category ?? "Uncated"}'),
                      trailing: e.synced
                          ? const Icon(Icons.cloud_done, color: Colors.green)
                          : const Icon(Icons.cloud_off, color: Colors.redAccent),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
