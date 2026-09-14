import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logbook_entry.dart';

final logbookControllerProvider =
    StateNotifierProvider<LogbookController, List<LogbookEntry>>(
        (ref) => LogbookController(ref));

class LogbookController extends StateNotifier<List<LogbookEntry>> {
  final Ref ref;

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  LogbookController(this.ref) : super([]) {
    _loadLocalEntries();
    _setupOnlineListener();
  }

  // Load entries saved locally (unsynced) on startup
  Future<void> _loadLocalEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('logbook_pending') ?? '[]';
      final List<dynamic> list = json.decode(jsonStr);
      state = list
          .map((e) => LogbookEntry(
                id: e['id'],
                itemDescription: e['itemDescription'],
                quantity: (e['quantity'] as num).toDouble(),
                unit: e['unit'],
                amountRupees: (e['amountRupees'] as num).toDouble(),
                category: e['category'],
                tags: (e['tags'] as List<dynamic>?)?.cast<String>(),
                createdAt: DateTime.parse(e['createdAt']),
                synced: e['synced'] ?? false,
              ))
          .toList();
    } catch (_) {}
  }

  // Save pending entries to SharedPreferences
  Future<void> _persistPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = state.where((e) => !e.synced).toList();
      final jsonStr = json.encode(pending
          .map((e) => {
                'id': e.id,
                'itemDescription': e.itemDescription,
                'quantity': e.quantity,
                'unit': e.unit,
                'amountRupees': e.amountRupees,
                'category': e.category,
                'tags': e.tags,
                'createdAt': e.createdAt.toIso8601String(),
                'synced': e.synced,
              })
          .toList());
      await prefs.setString('logbook_pending', jsonStr);
    } catch (_) {}
  }

  // Called when user taps the mic button
  Future<void> startVoiceCapture(BuildContext context) async {
    final transcript = await _showManualInputDialog(context);
    if (transcript == null || transcript.trim().isEmpty) return;
    final entry = _parseTranscript(transcript);
    if (entry != null) {
      await addEntry(entry);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not parse the voice input.')),
        );
      }
    }
  }

  // Simple manual fallback dialog
  Future<String?> _showManualInputDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Enter transaction text'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. i sold 4 litres milk for 500',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(c).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Naive parser – expects pattern "(i sold|bought) <qty> <unit> <item> for <price>"
  LogbookEntry? _parseTranscript(String text) {
    final regex = RegExp(
      r'(?:i\s+sold|bought)\s+(\d+(?:\.\d+)?)\s+(\w+)\s+(\w+)\s+for\s+(\d+(?:\.\d+)?)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match == null) return null;
    final qty = double.parse(match.group(1)!);
    final unit = match.group(2)!;
    final item = match.group(3)!;
    final price = double.parse(match.group(4)!);
    return LogbookEntry(
      itemDescription: item,
      quantity: qty,
      unit: unit,
      amountRupees: price,
    );
  }

  Future<void> addEntry(LogbookEntry entry) async {
    state = [...state, entry];
    await _persistPending();
    if (await _isOnline()) {
      await syncPending();
    }
  }

  Future<bool> _isOnline() async {
    final client = _supabase;
    if (client == null) return false;
    return client.auth.currentSession != null;
  }

  // Sync unsynced entries to Supabase
  Future<void> syncPending() async {
    final client = _supabase;
    if (client == null) return;
    final unsynced = state.where((e) => !e.synced).toList();
    if (unsynced.isEmpty) return;

    try {
      final List<Map<String, dynamic>> payload = unsynced
          .map((e) => {
                'user_id': client.auth.currentUser?.id,
                'item_description': e.itemDescription,
                'quantity': e.quantity,
                'unit': e.unit,
                'amount_rupees': e.amountRupees,
                'category': e.category,
                'tags': e.tags,
              })
          .toList();

      await client.schema('logbook').from('transactions').insert(payload);

      for (final e in unsynced) {
        e.synced = true;
      }
      state = [...state];
      await _persistPending();
    } catch (_) {
      // Offline fallback: keep unsynced
    }
  }

  void _setupOnlineListener() {
    final client = _supabase;
    if (client == null) return;
    try {
      client
          .channel('public:logbook_sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'logbook',
            table: 'transactions',
            callback: (payload) async {
              await syncPending();
            },
          )
          .subscribe();
    } catch (_) {}
  }
}
