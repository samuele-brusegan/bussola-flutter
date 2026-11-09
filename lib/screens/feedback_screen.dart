import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
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
          SnackBar(content: Text(context.l10n.feedbackFailed('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              showBack: true,
              compact: true,
              title: context.l10n.moreFeedback,
              subtitle: context.l10n.feedbackSubtitle,
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
            context.l10n.feedbackThanks,
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
              context.l10n.feedbackIntro,
              style: TextStyle(color: context.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category.isEmpty ? null : _category,
              decoration:
                  InputDecoration(labelText: context.l10n.feedbackType),
              items: [
                DropdownMenuItem(
                    value: 'feature', child: Text(context.l10n.fbFeature)),
                DropdownMenuItem(
                    value: 'bug', child: Text(context.l10n.fbBug)),
                DropdownMenuItem(
                    value: 'improvement', child: Text(context.l10n.fbImprovement)),
                DropdownMenuItem(
                    value: 'question', child: Text(context.l10n.fbQuestion)),
                DropdownMenuItem(value: 'other', child: Text(context.l10n.fbOther)),
              ],
              onChanged: (v) => _category = v ?? '',
              validator: (v) =>
                  (v == null || v.isEmpty) ? context.l10n.selectCategory : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration:
                  InputDecoration(labelText: context.l10n.priority),
              items: [
                DropdownMenuItem(value: 'low', child: Text(context.l10n.prioLow)),
                DropdownMenuItem(value: 'normal', child: Text(context.l10n.prioNormal)),
                DropdownMenuItem(value: 'high', child: Text(context.l10n.prioHigh)),
              ],
              onChanged: (v) => _priority = v ?? 'normal',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subject,
              maxLength: 180,
              decoration: InputDecoration(
                labelText: context.l10n.subjectLabel,
                hintText: context.l10n.subjectHint,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _message,
              minLines: 5,
              maxLines: 10,
              maxLength: 5000,
              decoration: InputDecoration(
                labelText: context.l10n.messageLabel,
                hintText: context.l10n.messageHint,
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().length < 10)
                  ? context.l10n.minChars
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
                  InputDecoration(labelText: context.l10n.nameOptional),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              maxLength: 190,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: context.l10n.emailOptional,
                hintText: context.l10n.emailHint,
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
                    : Text(context.l10n.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
