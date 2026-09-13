import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logbook_entry.dart';

final logbookControllerProvider = StateNotifierProvider<LogbookController, List<LogbookEntry>>((ref) => LogbookController(ref));

class LogbookController extends StateNotifier<List<LogbookEntry>> {
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;
  LogbookController(this.ref) : super([]) {
    _loadLocalEntries();
    _setupOnlineListener();
  }

  // Load entries saved locally (unsynced) on startup
  Future<void> _loadLocalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('logbook_pending') ?? '[]';
    final List<dynamic> list = json.decode(jsonStr);
    state = list.map((e) => LogbookEntry(
      id: e['id'],
      itemDescription: e['itemDescription'],
      quantity: e['quantity'],
      unit: e['unit'],
      amountRupees: e['amountRupees'],
      category: e['category'],
      tags: (e['tags'] as List<dynamic>?)?.cast<String>(),
      createdAt: DateTime.parse(e['createdAt']),
      synced: e['synced'] ?? false,
    )).toList();
  }

  // Save pending entries to SharedPreferences
  Future<void> _persistPending() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = state.where((e) => !e.synced).toList();
    final jsonStr = json.encode(pending.map((e) => {
      'id': e.id,
      'itemDescription': e.itemDescription,
      'quantity': e.quantity,
      'unit': e.unit,
      'amountRupees': e.amountRupees,
      'category': e.category,
      'tags': e.tags,
      'createdAt': e.createdAt.toIso8601String(),
      'synced': e.synced,
    }).toList());
    await prefs.setString('logbook_pending', jsonStr);
  }

  // Called when user taps the mic button
  Future<void> startVoiceCapture(BuildContext context) async {
    // TODO: integrate bhashini_plugin – capture audio, send to API, receive transcript
    // For now we use a placeholder dialog to enter text manually.
    final transcript = await _showManualInputDialog(context);
    if (transcript == null) return;
    final entry = _parseTranscript(transcript);
    if (entry != null) {
      await addEntry(entry);
    } else {
      // Show error toast
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not parse the voice input.')));
    }
  }

  // Simple manual fallback dialog
  Future<String?> _showManualInputDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Enter transaction text'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'e.g. i sold 4 litres milk for 500')),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(c).pop(controller.text), child: const Text('OK')),
        ],
      ),
    );
  }

  // Very naive parser – expects pattern "i sold <qty> <unit> <item> for <price>"
  LogbookEntry? _parseTranscript(String text) {
    final regex = RegExp(r"(?:i\s+sold|bought)\s+(\d+(?:\.\d+)?)\s+(\w+)\s+(\w+)\s+for\s+(\d+(?:\.\d+)?)", caseSensitive: false);
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
    // Add to state immediately (optimistic UI)
    state = [...state, entry];
    await _persistPending();
    // Attempt immediate sync if online
    if (await _isOnline()) {
      await syncPending();
    }
  }

  Future<bool> _isOnline() async => await Supabase.instance.client.auth.session() != null && (await Supabase.instance.client.from('logbook.transactions').select('id').limit(1).execute()).statusCode == 200;

  // Sync unsynced entries to Supabase
  Future<void> syncPending() async {
    final unsynced = state.where((e) => !e.synced).toList();
    if (unsynced.isEmpty) return;
    final List<Map<String, dynamic>> payload = unsynced.map((e) => {
      'user_id': _supabase.auth.currentUser?.id,
      'item_description': e.itemDescription,
      'quantity': e.quantity,
      'unit': e.unit,
      'amount_rupees': e.amountRupees,
      'category': e.category,
      'tags': e.tags,
    }).toList();
    final response = await _supabase.from('logbook.transactions').insert(payload).execute();
    if (response.error == null) {
      // Mark as synced
      final syncedIds = response.data as List<dynamic>;
      for (int i = 0; i < unsynced.length; i++) {
        unsynced[i].synced = true; // ignore const; we recreate list
      }
      // Refresh state with synced flag
      state = state.map((e) => e.synced ? e : e..synced = true).toList();
      await _persistPending();
    }
  }

  void _setupOnlineListener() {
    // Listen to connectivity changes (web / mobile) – simplified using Supabase realtime on .connected
    Supabase.instance.client.realtime.channel('public:logbook_sync').on('postgres_changes', '*', (payload) async {
      await syncPending();
    }).subscribe();
  }
}

