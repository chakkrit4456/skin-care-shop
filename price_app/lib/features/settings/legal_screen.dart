import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/l10n_legal.dart';
import '../../core/widgets.dart';

const _docs = {'terms', 'privacy', 'purchase', 'licenses', 'about'};

class LegalScreen extends StatelessWidget {
  final String doc;
  const LegalScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final known = _docs.contains(doc);
    return Scaffold(
      appBar: AppBar(title: Text(known ? t(context, doc) : doc)),
      body: Constrained(
        maxWidth: 720,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          SelectableText(known ? legal(context, '${doc}_body') : doc),
        ]),
      ),
    );
  }
}
