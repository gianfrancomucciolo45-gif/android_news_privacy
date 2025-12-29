import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/rss_service.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const String developerName = 'Android News Team';
  static const String supportEmail = 'gianfrancomucciolo45@gmail.com';
  static const String websiteUrl =
      'https://gianfrancomucciolo45-gif.github.io/android_news_privacy/';
  static const String phoneNumber =
      '+39 000 0000000'; // opzionale, sostituire se disponibile

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {}
  }

  Future<void> _sendEmail() async {
    final uri = Uri.parse('mailto:$supportEmail');
    await launchUrl(uri);
  }

  Future<void> _callPhone() async {
    final uri = Uri.parse('tel:$phoneNumber');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final sources = RssService.sources.values.map((s) => s.name).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Contatti')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Informazioni sull\'app',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Android News è un aggregatore di notizie tecnologiche focalizzato sul mondo Android. Non produciamo contenuti originali, ma raccogliamo e mostriamo titoli e anteprime provenienti da fonti pubbliche RSS, mantenendo i diritti e la paternità ai rispettivi editori.',
          ),
          const SizedBox(height: 24),
          Text(
            'Dati di Contatto',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email di supporto'),
                  subtitle: Text(supportEmail),
                  onTap: _sendEmail,
                ),
                ListTile(
                  leading: const Icon(Icons.web),
                  title: const Text('Sito web'),
                  subtitle: Text(websiteUrl),
                  onTap: () => _openUrl(websiteUrl),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Telefono'),
                  subtitle: Text(phoneNumber),
                  onTap: _callPhone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Trasparenza Editoriale',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Le fonti possono essere abilitate/disabilitate dall\'utente. L\'ordine di priorità è configurabile nella sezione Fonti nelle Impostazioni.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sources.map((name) => Chip(label: Text(name))).toList(),
          ),
          const SizedBox(height: 32),
          Text(
            'Segnalazioni e Richieste',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Per problemi di copyright o richieste di rimozione di contenuti, contattaci via email. Risponderemo entro 72 ore lavorative.',
          ),
          const SizedBox(height: 24),
          Text(
            'Versione',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Text('v0.1.0'), // TODO: sincronizzare con pubspec version
        ],
      ),
    );
  }
}
