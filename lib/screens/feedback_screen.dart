import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController(); // honeypot
  String _category = '';
  String _priority = 'normal';
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final res = await ApiClient.post('/api/feedback', {
        'category': _category,
        'priority': _priority,
        'subject': _subject.text.trim(),
        'message': _message.text.trim(),
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'website': _website.text,
      });
      if (!mounted) return;
      if (res is Map && res['success'] == true) {
        setState(() => _sent = true);
      } else {
        throw ApiException('${res is Map ? res['error'] : 'Errore'}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invio non riuscito: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: AppHeader(
              showBack: true,
              compact: true,
              title: 'Invia feedback',
              subtitle: 'Aiutaci a rendere Bussolà più utile.',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            sliver: SliverToBoxAdapter(
              child: _sent ? _success() : _form(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _success() {
    return AppCard(
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, color: context.green, size: 48),
          const SizedBox(height: 12),
          Text(
            'Grazie, il tuo feedback è stato inviato.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.ink,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Segnalaci un problema, proponi una funzione o raccontaci la '
              'tua esperienza. Non è necessario lasciare dati personali.',
              style: TextStyle(color: context.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category.isEmpty ? null : _category,
              decoration:
                  const InputDecoration(labelText: 'Tipo di feedback *'),
              items: const [
                DropdownMenuItem(
                    value: 'feature', child: Text('Nuova funzionalità')),
                DropdownMenuItem(
                    value: 'bug', child: Text('Bug o problema')),
                DropdownMenuItem(
                    value: 'improvement', child: Text('Miglioramento')),
                DropdownMenuItem(
                    value: 'question', child: Text('Domanda')),
                DropdownMenuItem(value: 'other', child: Text('Altro')),
              ],
              onChanged: (v) => _category = v ?? '',
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Seleziona una categoria' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration:
                  const InputDecoration(labelText: 'Priorità percepita'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Bassa')),
                DropdownMenuItem(value: 'normal', child: Text('Normale')),
                DropdownMenuItem(value: 'high', child: Text('Alta')),
              ],
              onChanged: (v) => _priority = v ?? 'normal',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subject,
              maxLength: 180,
              decoration: const InputDecoration(
                labelText: 'Titolo',
                hintText: 'In breve, di cosa si tratta?',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _message,
              minLines: 5,
              maxLines: 10,
              maxLength: 5000,
              decoration: const InputDecoration(
                labelText: 'Messaggio *',
                hintText:
                    'Descrivi cosa è successo o cosa vorresti migliorare...',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().length < 10)
                  ? 'Scrivi almeno 10 caratteri'
                  : null,
            ),
            // Honeypot invisibile (stesso campo `website` della web app)
            Offstage(
              offstage: true,
              child: TextFormField(
                controller: _website,
                decoration:
                    const InputDecoration(labelText: 'Website'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              maxLength: 120,
              decoration:
                  const InputDecoration(labelText: 'Nome (facoltativo)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              maxLength: 190,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (facoltativa)',
                hintText: 'Per eventuale risposta',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Invia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
