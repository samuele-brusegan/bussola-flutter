// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Bussolà';

  @override
  String get navHome => 'Home';

  @override
  String get navStops => 'Fermate';

  @override
  String get navRoutes => 'Percorsi';

  @override
  String get navMore => 'Altro';

  @override
  String get moreLinesMap => 'Mappa linee';

  @override
  String get moreLineSchedules => 'Orari delle linee';

  @override
  String get moreLiveVehicles => 'Bus in servizio';

  @override
  String get moreDelayStats => 'Statistiche ritardi';

  @override
  String get moreFeedback => 'Invia feedback';

  @override
  String get moreLanguage => 'Lingua';

  @override
  String get morePrivacy => 'Privacy e dati';

  @override
  String get moreCredits => 'Crediti';

  @override
  String get moreAltHome => 'Home alternativa';

  @override
  String get languageTitle => 'Lingua dell\'app';

  @override
  String get languageSystem => 'Predefinita di sistema';

  @override
  String get errorLoadData => 'Impossibile caricare i dati';

  @override
  String get retry => 'Riprova';

  @override
  String get qrOpenOnWeb => 'Apri questa pagina sul web';

  @override
  String get linkCopied => 'Link copiato';

  @override
  String get copyLink => 'Copia link';

  @override
  String get cookieBannerText =>
      'Utilizziamo i dati locali e i cookie del server per migliorare la tua esperienza. ';

  @override
  String get cookieLearnMore => 'Scopri di più';

  @override
  String get cookieAccept => 'Accetta';

  @override
  String get youAreOffline => 'Sei offline';

  @override
  String get strikeTitle => 'Sciopero';

  @override
  String get strikePossible => 'Possibile sciopero in corso';

  @override
  String strikeBody(int count) {
    return 'Il servizio in tempo reale non risponde su $count fermate controllate: è probabile uno sciopero o un\'interruzione del servizio. Gli orari previsti potrebbero non essere rispettati.';
  }

  @override
  String get strikeEmptyStops => 'Fermate senza passaggi rilevati:';

  @override
  String stopDefaultName(String id) {
    return 'Fermata $id';
  }

  @override
  String get gotIt => 'Ho capito';

  @override
  String get mapStationLabel => 'Stazione: ';

  @override
  String mapDistance(String km) {
    return 'Distanza: $km km';
  }

  @override
  String get mapSeePassages => 'Vedi passaggi ›';

  @override
  String get stopsMapTitle => 'Mappa delle fermate';

  @override
  String get journeySection => 'Il tuo ultimo viaggio';

  @override
  String get journeyResume => 'Riprendi viaggio';

  @override
  String get modify => 'Modifica';

  @override
  String get coachSkip => 'Salta';

  @override
  String get coachDone => 'Fine';

  @override
  String get coachNext => 'Avanti';

  @override
  String get footerCredits => 'Crediti e licenze';

  @override
  String get footerAppBy => 'MIT License (2025–2026) · App di ';

  @override
  String get footerAnd => ' e ';

  @override
  String get footerDevBy => 'App sviluppata da ';

  @override
  String get footerDesignBy => 'Grafica e design da ';

  @override
  String get footerUnofficial =>
      'Progetto non ufficiale, non affiliato ad ACTV S.p.A. — dati mappe © OpenStreetMap contributors';

  @override
  String get footerUnofficialMultiline =>
      'Progetto non ufficiale, non affiliato ad ACTV S.p.A.\nDati mappe © OpenStreetMap contributors';

  @override
  String get geoWaiting => 'In attesa di geolocalizzazione…';

  @override
  String get geoFound => 'Posizione trovata. Ecco le stazioni più vicine.';

  @override
  String get geoUnavailable => 'Geolocalizzazione non disponibile';

  @override
  String get noNearbyStops => 'Nessuna fermata trovata nelle vicinanze.';

  @override
  String get homeTitle => 'Il tuo viaggio,\nin tempo reale.';

  @override
  String get homeSubtitle => 'Orari, fermate e percorsi ACTV a Venezia';

  @override
  String get actvService => 'Servizio ACTV';

  @override
  String get whereBus => 'Dove passa il tuo bus?';

  @override
  String get searchStop => 'Cerca una fermata';

  @override
  String get searchStopSub => 'Passaggi in tempo reale per ogni fermata';

  @override
  String get searchTrip => 'Cerca una corsa';

  @override
  String get yourStops => 'Le tue fermate';

  @override
  String get favBadge => '★ Preferita';

  @override
  String get nearbyStops => 'Fermate vicine';

  @override
  String get mapTitle => 'Mappa';

  @override
  String get welcome => 'Benvenuto';

  @override
  String get tourQ => 'Vuoi fare un giro?';

  @override
  String get tourIntroBody =>
      'Ti mostro in pochi secondi dove sono fermate, mappa, preferiti e tutte le altre funzioni dell\'app.';

  @override
  String get startTour => 'Inizia il tour';

  @override
  String get tourNearbyTitle => 'Fermate vicine';

  @override
  String get tourNearbyBody =>
      'Con la geolocalizzazione attiva, qui compaiono le fermate più vicine a te.';

  @override
  String get tourFavsTitle => 'Le tue fermate';

  @override
  String get tourFavsBody =>
      'Le fermate che salvi con la stella le ritrovi sempre qui.';

  @override
  String get tourMapTitle => 'La mappa';

  @override
  String get tourMapBody =>
      'Ogni pallino è una fermata: toccalo per aprire i passaggi in tempo reale.';

  @override
  String get tourMoreTitle => 'Tutto il resto';

  @override
  String get tourMoreBody =>
      'Da qui: percorsi con cambio, orari delle linee, statistiche sui ritardi e ricerca di una corsa. Le altre funzioni sono nel menu \"Altro\" in basso.';

  @override
  String get tourCtaTitle => 'Cerca una fermata';

  @override
  String get tourCtaBody =>
      'Tutto parte da qui: tocca il pulsante per aprire l\'elenco delle fermate.';

  @override
  String get homeTitleAlt => 'Il tuo viaggio, in tempo reale.';

  @override
  String get tourActionsTitle => 'Le funzioni';

  @override
  String get tourActionsBody =>
      'Percorsi con cambio, mappa live dei mezzi, orari, ricerca corsa, statistiche e rete di linee.';

  @override
  String get actRoutesSub => 'Come arrivare';

  @override
  String get actLiveMap => 'Mappa live';

  @override
  String get actLiveMapSub => 'Mezzi in movimento';

  @override
  String get actSchedules => 'Orari linee';

  @override
  String get actSchedulesSub => 'Tabella oraria';

  @override
  String get actTripSearch => 'Cerca corsa';

  @override
  String get actTripSearchSub => 'Per linea o tripId';

  @override
  String get actDelays => 'Ritardi';

  @override
  String get actDelaysSub => 'Statistiche servizio';

  @override
  String get actNetwork => 'Rete';

  @override
  String get actNetworkSub => 'Tutte le linee';

  @override
  String get stopsAllTitle => 'Tutte le\nStazioni';

  @override
  String get viewList => 'Elenco';

  @override
  String get viewZones => 'Per zona';

  @override
  String get searchStopHint => 'Cerca stazione...';

  @override
  String get noStationFound => 'Nessuna stazione trovata.';

  @override
  String get stopsListTitle => 'Elenco Stazioni';

  @override
  String get navStopsTitle => 'Fermate Navigazione';

  @override
  String zoneTitle(String zone) {
    return 'Zone · $zone';
  }

  @override
  String get zonesTitle => 'Zone';

  @override
  String get notRealtime => 'Servizio non in tempo reale (Server ACTV Down)';

  @override
  String get navLine => 'Linea: ⛴ Navigazione';

  @override
  String get noLinesAvailable => 'Nessuna linea disponibile';

  @override
  String get linesLabel => 'Linee:';

  @override
  String get originTitle => 'Da dove parti?';

  @override
  String get destinationTitle => 'Dove vuoi andare?';

  @override
  String get cancel => 'Annulla';

  @override
  String get done => 'Fatto';

  @override
  String get searchStopOrAddress => 'Cerca stazione o indirizzo...';

  @override
  String get recentStops => 'Recenti';

  @override
  String get favStops => 'Preferite';

  @override
  String get addresses => 'Indirizzi';

  @override
  String get allStops => 'Tutte le fermate';

  @override
  String get notifDenied => 'Permesso notifiche negato';

  @override
  String get shareStop => 'Condividi questa fermata';

  @override
  String get widgetLinkCopied => 'Link widget copiato';

  @override
  String get copyWidgetUrl => 'Copia URL widget';

  @override
  String get embedCopied => 'Codice embed copiato';

  @override
  String get copyIframe => 'Copia iframe';

  @override
  String get tripUnidentified =>
      'Impossibile identificare con certezza questa corsa.';

  @override
  String get nextPassages => 'Prossimi Passaggi';

  @override
  String get loadError => 'Errore nel caricamento dei dati.';

  @override
  String get loadingPassages => 'Caricamento passaggi...';

  @override
  String get noPassagesStrike =>
      'Nessun passaggio in tempo reale (possibile sciopero). Vedi la bacheca.';

  @override
  String get noPassagesScheduled => 'Nessun passaggio previsto.';

  @override
  String get navigationSection => '⛴ Navigazione';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get boardStrikeHtml =>
      '<strong>Possibile sciopero o servizio non monitorato.</strong><br>I passaggi in tempo reale non sono disponibili: gli orari mostrati sono quelli <em>previsti</em> e i bus potrebbero non passare.';

  @override
  String get board => 'Bacheca';

  @override
  String get now => 'Ora';

  @override
  String get vehiclePassed => 'Il mezzo ha già superato questa fermata';

  @override
  String stopsToBoarding(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# fermate',
      one: '# fermata',
    );
    return ' · $_temp0';
  }

  @override
  String get unknownDestination => 'Destinazione ignota';

  @override
  String get navigationLabel => 'Navigazione';

  @override
  String atStop(String stop) {
    return 'Presso $stop';
  }

  @override
  String get notifDelays => 'Notifiche Ritardi';

  @override
  String get notifThreshold => 'Avvisa per ritardi superiori a:';

  @override
  String get notifExplain =>
      'Riceverai una notifica quando una linea che passa da questa fermata ha un ritardo superiore alla soglia impostata.';

  @override
  String get selectOriginDest => 'Seleziona partenza e destinazione';

  @override
  String get findRouteTitle => 'Trova\nPercorso';

  @override
  String get favRoutes => 'Tragitti preferiti';

  @override
  String get departure => 'Partenza';

  @override
  String get selectDeparture => 'Seleziona partenza';

  @override
  String get destination => 'Destinazione';

  @override
  String get selectDestination => 'Seleziona destinazione';

  @override
  String get departureReturnOptions => 'Opzioni di partenza e ritorno';

  @override
  String get selectDepartureDateTime => 'Seleziona data e ora partenza';

  @override
  String get optimizeFor => 'Ottimizza per';

  @override
  String get optTime => 'tempo';

  @override
  String get optTransfers => 'cambi';

  @override
  String get optWalking => 'a piedi';

  @override
  String get returnTrip => 'Ritorno';

  @override
  String get searchSolutions => 'Ricerca soluzioni';

  @override
  String get travelSolutions => 'Soluzioni di viaggio';

  @override
  String get outbound => 'Andata';

  @override
  String get returnTab => 'Ritorno';

  @override
  String get searchingRoutes => 'Ricerca percorsi in corso…';

  @override
  String get noRouteFound =>
      'Nessun percorso trovato per i parametri specificati';

  @override
  String get back => 'Indietro';

  @override
  String get compareRoutes => 'Confronta percorsi';

  @override
  String get compare => 'Confronta';

  @override
  String solutionN(int n) {
    return 'Soluzione $n';
  }

  @override
  String minFromNow(int n) {
    return '($n min da ora)';
  }

  @override
  String get walk => 'Cammina';

  @override
  String walkFor(String distance) {
    return 'per $distance m';
  }

  @override
  String stopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# fermate',
      one: '# fermata',
    );
    return ' · $_temp0';
  }

  @override
  String transfersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# cambi',
      one: '# cambio',
      zero: 'Diretto',
    );
    return '$_temp0';
  }

  @override
  String get details => 'Dettagli';

  @override
  String get selectArrow => 'Seleziona →';

  @override
  String get routeSaved => 'Tragitto salvato';

  @override
  String get routeRemoved => 'Tragitto rimosso dai preferiti';

  @override
  String get nearOriginHint => 'Sei vicino al punto di partenza: parti da qui.';

  @override
  String get saved => 'Salvato';

  @override
  String get saveRoute => 'Salva tragitto';

  @override
  String get viewOnMap => 'Visualizza sulla mappa';

  @override
  String get yourRoute => 'Il tuo percorso';

  @override
  String get liveBusesTitle => 'Bus in servizio';

  @override
  String liveMapSubtitle(int count, int rt) {
    return '$count bus sulla mappa · $rt realtime';
  }

  @override
  String liveMapDataAt(String time) {
    return ' · dati $time';
  }

  @override
  String get searchVehicleHint => 'Cerca: 5E, 21, …';

  @override
  String get autobus => 'Autobus';

  @override
  String get vaporetti => 'Vaporetti';

  @override
  String get vehicle => 'Veicolo';

  @override
  String lineN(String line) {
    return 'Linea $line';
  }

  @override
  String get realtimeLabel => 'tempo reale';

  @override
  String get scheduledLabel => 'programmato';

  @override
  String get trip => 'Corsa';

  @override
  String pathsOnMap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# percorsi sulla mappa',
      one: '# percorso sulla mappa',
    );
    return '$_temp0';
  }

  @override
  String get showStops => 'Mostra le fermate';

  @override
  String get allChip => 'Tutte';

  @override
  String get chooseLine => 'Scegli una linea';

  @override
  String lineDay(String line, String day) {
    return 'Linea $line · $day';
  }

  @override
  String get linesChip => 'Linee';

  @override
  String get noLinesForDate => 'Nessuna linea per questa data.';

  @override
  String get searchLineHint => 'Cerca per numero o destinazione…';

  @override
  String tripsCount(int count) {
    return '$count corse';
  }

  @override
  String get noActiveVariants => 'Nessuna variante attiva.';

  @override
  String variantInfo(String origin, String terminus, int stops, int trips) {
    return '$origin → $terminus · $stops fermate · $trips corse';
  }

  @override
  String get noScheduleAvailable => 'Nessun orario disponibile.';

  @override
  String get stopColumn => 'Fermata';

  @override
  String get dayMonday => 'lunedì';

  @override
  String get dayTuesday => 'martedì';

  @override
  String get dayWednesday => 'mercoledì';

  @override
  String get dayThursday => 'giovedì';

  @override
  String get dayFriday => 'venerdì';

  @override
  String get daySaturday => 'sabato';

  @override
  String get daySunday => 'domenica';

  @override
  String get tripFinderSubtitle => 'Trova una corsa per linea e tratta';

  @override
  String get variantsAvailable => 'direzioni disponibili';

  @override
  String get changeLine => 'Cambia linea';

  @override
  String get allVehiclesShown => 'Bus identificati e non identificati';

  @override
  String get identifiedVehiclesOnly => 'Solo bus con linea riconosciuta';

  @override
  String scheduleSummary(int stops, int runs) {
    return '$stops fermate · $runs corse';
  }

  @override
  String get lineLabel => 'Linea';

  @override
  String get lineHint => 'es. 5E';

  @override
  String get search => 'Cerca';

  @override
  String get noTripsFound => 'Nessuna corsa trovata per questa tratta.';

  @override
  String get movingPerSchedule => 'In movimento secondo orario';

  @override
  String get tripDetail => 'Dettaglio corsa';

  @override
  String directionTo(String headsign) {
    return 'DIREZIONE $headsign';
  }

  @override
  String stopsTitleCount(int count) {
    return 'Fermate ($count)';
  }

  @override
  String delayLate(int min) {
    return '· ritardo +$min min';
  }

  @override
  String delayEarly(int min) {
    return '· anticipo $min min';
  }

  @override
  String get onTime => '· in orario';

  @override
  String nextStopIn(String name, int min) {
    return 'Prossima fermata: $name tra $min min';
  }

  @override
  String nextStopNow(String name) {
    return 'Prossima fermata: $name ora';
  }

  @override
  String get realtimeActive => 'Posizione in tempo reale attiva';

  @override
  String get passed => 'TRASCORSO';

  @override
  String get delayStatsSubtitle => 'Ritardi osservati su questo dispositivo';

  @override
  String get noDelaysRecorded =>
      'Nessun ritardo registrato.\nI dati vengono raccolti mentre usi la mappa dei bus.';

  @override
  String get observations => 'Rilevamenti';

  @override
  String get avgDelay => 'Ritardo medio';

  @override
  String get maxDelay => 'Ritardo max';

  @override
  String get delaysByHour => 'Ritardi per ora';

  @override
  String get perLine => 'Per linea';

  @override
  String avgDelayMin(String value) {
    return 'Media $value min';
  }

  @override
  String get clearHistory => 'Cancella storico';

  @override
  String get clearHistoryConfirm => 'Eliminare tutti i ritardi registrati?';

  @override
  String get delete => 'Elimina';

  @override
  String get worstLine => 'Linea peggiore';

  @override
  String feedbackFailed(String error) {
    return 'Invio non riuscito: $error';
  }

  @override
  String get feedbackSubtitle => 'Aiutaci a rendere Bussolà più utile.';

  @override
  String get feedbackThanks => 'Grazie, il tuo feedback è stato inviato.';

  @override
  String get feedbackIntro =>
      'Segnalaci un problema, proponi una funzione o raccontaci la tua esperienza. Non è necessario lasciare dati personali.';

  @override
  String get feedbackType => 'Tipo di feedback *';

  @override
  String get fbFeature => 'Nuova funzionalità';

  @override
  String get fbBug => 'Bug o problema';

  @override
  String get fbImprovement => 'Miglioramento';

  @override
  String get fbQuestion => 'Domanda';

  @override
  String get fbOther => 'Altro';

  @override
  String get selectCategory => 'Seleziona una categoria';

  @override
  String get priority => 'Priorità percepita';

  @override
  String get prioLow => 'Bassa';

  @override
  String get prioNormal => 'Normale';

  @override
  String get prioHigh => 'Alta';

  @override
  String get subjectLabel => 'Titolo';

  @override
  String get subjectHint => 'In breve, di cosa si tratta?';

  @override
  String get messageLabel => 'Messaggio *';

  @override
  String get messageHint =>
      'Descrivi cosa è successo o cosa vorresti migliorare...';

  @override
  String get minChars => 'Scrivi almeno 10 caratteri';

  @override
  String get nameOptional => 'Nome (facoltativo)';

  @override
  String get emailOptional => 'Email (facoltativa)';

  @override
  String get emailHint => 'Per eventuale risposta';

  @override
  String get send => 'Invia';

  @override
  String get localDataCleared => 'Dati locali eliminati';

  @override
  String get apiServerUpdated => 'Server API aggiornato';

  @override
  String get privacySubtitle => 'Gestione dei dati memorizzati';

  @override
  String get localData => 'Dati locali';

  @override
  String get localDataDesc =>
      'L\'app memorizza sul dispositivo: tema (theme), consenso cookie (cookie_consent_accepted), fermate preferite (favorite_stops), fermate recenti (recent_stops), tragitti (favorite_routes, route_*), storico ritardi (delay_history), fermate monitorate (monitored_stops) e impostazioni.';

  @override
  String get cookieConsentRevoked => 'Consenso cookie revocato';

  @override
  String get revokeCookieConsent => 'Revoca consenso cookie';

  @override
  String get deleteAllData => 'Elimina tutti i dati';

  @override
  String get thirdParties => 'Terze parti';

  @override
  String get thirdPartiesDesc =>
      'Mappe e geocoding: OpenStreetMap e Nominatim.\nDati trasporto: backend ACTV (oraritemporeale.actv.it) e feed GTFS/GTFS-RT.\nI feedback inviati arrivano al server API configurato (nessun dato personale obbligatorio).';

  @override
  String get apiServerDesc => 'Indirizzo del server che fornisce i dati ACTV.';

  @override
  String get baseUrl => 'URL base';

  @override
  String get save => 'Salva';

  @override
  String get creditsSubtitle => 'Attribuzioni e licenze';

  @override
  String get mapsCredit => 'Mappe';

  @override
  String get mapDataOdbL => 'dati mappe © ODbL';

  @override
  String get geocodingNote => 'geocoding indirizzi';

  @override
  String get transitData => 'Dati trasporto';

  @override
  String get transitDataNote => 'orari e posizioni dei mezzi';

  @override
  String get unofficialProject =>
      'Progetto non ufficiale, non affiliato ad ACTV S.p.A.';

  @override
  String get openSourceLibs => 'Librerie open source';

  @override
  String get project => 'Progetto';

  @override
  String get creditsReleasedBy =>
      'Rilasciato con licenza MIT.\n\nSviluppato da ';

  @override
  String get creditsDesignBy => '\nGrafica e design da ';

  @override
  String get openOnActvLive => 'Apri su ACTV Live →';

  @override
  String get positionDetected => 'Posizione rilevata';

  @override
  String get atPreposition => 'a';

  @override
  String get feedbackTileSub => 'Segnala un problema';

  @override
  String get lmFilters => 'Filtri';

  @override
  String get lmAllLines => 'Tutte le linee';

  @override
  String get lmSearchBy => 'Cerca per';

  @override
  String get lmByLine => 'Linea';

  @override
  String get lmByTrip => 'Corsa';

  @override
  String get lmLinesLabel => 'Linee';

  @override
  String get lmTripsLabel => 'ID corse';

  @override
  String get lmQueryHelp =>
      'Separa più linee con una virgola. Lascia vuoto per mostrarle tutte.';

  @override
  String get lmTripHelp =>
      'Separa più ID corsa con una virgola. Lascia vuoto per mostrare tutte le linee.';

  @override
  String get lmReset => 'Reset';

  @override
  String get lmApply => 'Applica';

  @override
  String get lmStopsSuffix => 'Fermate';

  @override
  String lmLineTripsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# corse',
      one: '# corsa',
    );
    return '$_temp0';
  }

  @override
  String get myPosition => 'La mia posizione';

  @override
  String get refreshTooltip => 'Aggiorna';

  @override
  String get mapSettings => 'Impostazioni mappa';

  @override
  String get searchFields => 'Campi di ricerca';

  @override
  String get searchFieldLine => 'Linea';

  @override
  String get searchFieldDest => 'Destinazione';

  @override
  String get searchFieldTrip => 'Corsa (tripId)';

  @override
  String get noLineShown => 'Veicoli senza linea';

  @override
  String get noLineShownSub => 'mostra anche i mezzi non identificati';

  @override
  String updatedAt(String time) {
    return 'aggiornato $time';
  }

  @override
  String get lsSearchLabel => 'Cerca linea';

  @override
  String get loading => 'Caricamento…';

  @override
  String get busService => 'Servizio bus';

  @override
  String get findTrip => 'Trova corsa';

  @override
  String get dateLabel => 'Data';

  @override
  String get pickLineFirst => 'Scegli prima una linea';

  @override
  String get pickOriginFirst => 'Scegli prima la partenza';

  @override
  String get selectLeg => 'Seleziona una tratta';

  @override
  String get tripsEmptyState =>
      'Compila i campi qui sopra per vedere le corse disponibili.';

  @override
  String get goToPage => 'Vai a pagina';

  @override
  String get goToTime => 'Vai all\'orario';

  @override
  String get go => 'Vai';

  @override
  String get orWord => 'oppure';

  @override
  String get openTrip => 'Apri corsa';

  @override
  String get lineHelp => 'Seleziona la linea da ispezionare';

  @override
  String get tripsResults => 'Risultati';

  @override
  String pageOf(int page, int total) {
    return 'Pagina $page di $total';
  }
}
