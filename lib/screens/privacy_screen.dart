import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';

/// Equivalent of the web app's "delete cookie" page plus API base URL
/// configuration.
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final _urlController = TextEditingController(text: ApiClient.baseUrl);

  Future<void> _clearData() async {
    final prefs = await SharedPreferences.getInstance();
    final keepUrl = prefs.getString('api_base_url');
    final keepTheme = prefs.getString('theme_mode');
    await prefs.clear();
    if (keepUrl != null) await prefs.setString('api_base_url', keepUrl);
    if (keepTheme != null) await prefs.setString('theme_mode', keepTheme);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dati locali eliminati')),
      );
    }
  }

  Future<void> _saveUrl() async {
    await ApiClient.setBaseUrl(_urlController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server API aggiornato')),
      );
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: AppHeader(
              showBack: true,
              title: 'Privacy e dati',
              subtitle: 'Gestione dei dati memorizzati',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Dati locali'),
                      Text(
                        'L\'app memorizza sul dispositivo: fermate preferite, '
                        'tema, storico ritardi e impostazioni.',
                        style: TextStyle(color: context.muted),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _clearData,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Elimina tutti i dati'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red,
                            side: const BorderSide(color: AppColors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Server API'),
                      Text(
                        'Indirizzo del server che fornisce i dati ACTV.',
                        style: TextStyle(color: context.muted),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL base',
                          hintText: 'https://actv-live.test',
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saveUrl,
                          child: const Text('Salva'),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
