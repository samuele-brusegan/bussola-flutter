# Bussolà (ex actv-live)

App Flutter multipiattaforma (Android, iOS, Web, Linux, macOS, Windows) che
reimplementa la web app ACTV Live (`~/webserver/sites/actv-live`, repo
`samuele-brusegan/actv-live`) mantenendo lo stesso aspetto grafico.

## Comandi

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d linux        # debug locale
flutter run -d chrome       # attenzione: CORS/cert self-signed bloccano le API

# Android: esistono i flavor "store" e "fdroid" (quest'ultimo esclude
# com.google.android.gms; geolocator usa LocationManager). Va sempre
# specificato --flavor:
flutter run -d android --flavor store --debug
flutter build apk --release --flavor fdroid   # APK per F-Droid
flutter build appbundle --release --flavor store
```

## Architettura

- `lib/api/api_client.dart` — client HTTP verso `/api/*` del server PHP;
  `baseUrl` di default `https://actv-live.test`, modificabile in
  Privacy → Server API (SharedPreferences `api_base_url`). In debug accetta
  certificati self-signed.
- `lib/models/models.dart` — modelli GTFS (Stop, StopLine, Vehicle,
  LineVariant, PlannedRoute, LineShape...). Le API restituiscono tipi misti
  (stringhe/numeri): i parser usano helper tolleranti.
- `lib/services/stops_service.dart` — cache fermate, merge per nome,
  ricerca fuzzy (port di `stopSearchScore`), fermate vicine (geolocator),
  preferiti in SharedPreferences.
- `lib/services/delay_service.dart` — storico ritardi locale (port di
  `delayHistory.js`).
- `lib/l10n/` — localizzazione it/en via `flutter gen-l10n` (ARB
  `app_it.arb` / `app_en.arb`, output in `app_localizations*.dart` generati).
  Uso: `context.l10n.<chiave>` (extension in `l10n_ext.dart`). La lingua si
  cambia da menu Altro → Lingua (SharedPreferences `app_locale`);
  `localizedDay()` traduce i nomi dei giorni dell'API.
- `lib/theme/app_theme.dart` — design tokens da `app-shell.css`
  (verde #008F5B, blu #0759B8, radius 18, Inter), chiaro/scuro.
- `lib/widgets/` — `AppHeader` (gradiente verde con taglio diagonale),
  `AppCard`, `LineBadge`, `StopTile`, bottom nav con menu "Altro".
- `lib/screens/` — home, fermate, dettaglio fermata/passaggi, route finder,
  risultati, dettaglio percorso, live map, mappa linee, orari linee,
  cerca corsa, statistiche ritardi, feedback, privacy.

## Endpoint usati

`/api/stops`, `/api/navigation/stops`, `/api/stop-lines`,
`/api/navigation/passages`, `/api/plan-route`, `/api/realtime/vehicles`,
`/api/lines-shapes`, `/api/line-catalog`, `/api/line-variants`,
`/api/line-schedule`, `/api/line-trips`, `/api/bus-position`,
`POST /api/feedback`. Riferimento: `docs/api.md` nel repo della web app.

## Note

- L'area admin, il widget embeddabile e la PWA non sono stati portati.
- Su Android emulatore usare `https://10.0.2.2` come URL base se il server
  gira sulla macchina host.
