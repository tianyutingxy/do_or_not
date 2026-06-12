import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/decision_record_service.dart';
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
      ),
      body: JournalPanel(service: service),
    );
  }
}
