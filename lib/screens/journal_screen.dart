import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/decision_record_service.dart';
import 'archive_screen.dart';
import '../widgets/journal_panel.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key, DecisionRecordService? service})
      : _service = service;

  final DecisionRecordService? _service;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = _service ?? DecisionRecordService();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.journalTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => ArchiveScreen(service: service),
                ),
              );
            },
            icon: const Icon(Icons.inventory_2_outlined, size: 20),
            label: Text(l10n.journalArchiveTitle),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              l10n.journalPendingSection,
              style: const TextStyle(
                fontSize: 13,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: Colors.white38,
              ),
            ),
          ),
          Expanded(
            child: JournalPanel(service: service),
          ),
        ],
      ),
    );
  }
}
