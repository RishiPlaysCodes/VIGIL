import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets/section_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.history});

  final List<AlertRecord> history;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Alert History',
        child: history.isEmpty
            ? const Text('No alerts yet.')
            : Column(
                children: history
                    .map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          item.status == 'Alert sent'
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          color: item.status == 'Alert sent'
                              ? Colors.red
                              : Colors.green,
                        ),
                        title: Text(item.reason),
                        subtitle: Text(_format(item.time)),
                        trailing: Text(item.status),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }

  String _format(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
