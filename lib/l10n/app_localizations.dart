import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In it, this message translates to:
  /// **'Bussolà'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In it, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navStops.
  ///
  /// In it, this message translates to:
  /// **'Fermate'**
  String get navStops;

  /// No description provided for @navRoutes.
  ///
  /// In it, this message translates to:
  /// **'Percorsi'**
  String get navRoutes;

  /// No description provided for @navMore.
  ///
  /// In it, this message translates to:
  /// **'Altro'**
  String get navMore;

  /// No description provided for @moreLinesMap.
  ///
  /// In it, this message translates to:
  /// **'Mappa linee'**
  String get moreLinesMap;

  /// No description provided for @moreLineSchedules.
  ///
  /// In it, this message translates to:
  /// **'Orari delle linee'**
  String get moreLineSchedules;

  /// No description provided for @moreLiveVehicles.
  ///
  /// In it, this message translates to:
  /// **'Bus in servizio'**
  String get moreLiveVehicles;

  /// No description provided for @moreDelayStats.
  ///
  /// In it, this message translates to:
  /// **'Statistiche ritardi'**
  String get moreDelayStats;

  /// No description provided for @moreFeedback.
  ///
  /// In it, this message translates to:
  /// **'Invia feedback'**
  String get moreFeedback;

  /// No description provided for @moreLanguage.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get moreLanguage;

  /// No description provided for @morePrivacy.
  ///
  /// In it, this message translates to:
  /// **'Privacy e dati'**
  String get morePrivacy;

  /// No description provided for @moreCredits.
  ///
  /// In it, this message translates to:
  /// **'Crediti'**
  String get moreCredits;

  /// No description provided for @moreAltHome.
  ///
  /// In it, this message translates to:
  /// **'Home alternativa'**
  String get moreAltHome;

  /// No description provided for @languageTitle.
  ///
  /// In it, this message translates to:
  /// **'Lingua dell\'app'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In it, this message translates to:
  /// **'Predefinita di sistema'**
  String get languageSystem;

  /// No description provided for @errorLoadData.
  ///
  /// In it, this message translates to:
  /// **'Impossibile caricare i dati'**
  String get errorLoadData;

  /// No description provided for @retry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get retry;

  /// No description provided for @qrOpenOnWeb.
  ///
  /// In it, this message translates to:
  /// **'Apri questa pagina sul web'**
  String get qrOpenOnWeb;

  /// No description provided for @linkCopied.
  ///
  /// In it, this message translates to:
  /// **'Link copiato'**
  String get linkCopied;

  /// No description provided for @copyLink.
  ///
  /// In it, this message translates to:
  /// **'Copia link'**
  String get copyLink;

  /// No description provided for @cookieBannerText.
  ///
  /// In it, this message translates to:
  /// **'Utilizziamo i dati locali e i cookie del server per migliorare la tua esperienza. '**
  String get cookieBannerText;

  /// No description provided for @cookieLearnMore.
  ///
  /// In it, this message translates to:
  /// **'Scopri di più'**
  String get cookieLearnMore;

  /// No description provided for @cookieAccept.
  ///
  /// In it, this message translates to:
  /// **'Accetta'**
  String get cookieAccept;

  /// No description provided for @youAreOffline.
  ///
  /// In it, this message translates to:
  /// **'Sei offline'**
  String get youAreOffline;

  /// No description provided for @strikeTitle.
  ///
  /// In it, this message translates to:
  /// **'Sciopero'**
  String get strikeTitle;

  /// No description provided for @strikePossible.
  ///
  /// In it, this message translates to:
  /// **'Possibile sciopero in corso'**
  String get strikePossible;

  /// No description provided for @strikeBody.
  ///
  /// In it, this message translates to:
  /// **'Il servizio in tempo reale non risponde su {count} fermate controllate: è probabile uno sciopero o un\'interruzione del servizio. Gli orari previsti potrebbero non essere rispettati.'**
  String strikeBody(int count);

  /// No description provided for @strikeEmptyStops.
  ///
  /// In it, this message translates to:
  /// **'Fermate senza passaggi rilevati:'**
  String get strikeEmptyStops;

  /// No description provided for @stopDefaultName.
  ///
  /// In it, this message translates to:
  /// **'Fermata {id}'**
  String stopDefaultName(String id);

  /// No description provided for @gotIt.
  ///
  /// In it, this message translates to:
  /// **'Ho capito'**
  String get gotIt;

  /// No description provided for @mapStationLabel.
  ///
  /// In it, this message translates to:
  /// **'Stazione: '**
  String get mapStationLabel;

  /// No description provided for @mapDistance.
  ///
  /// In it, this message translates to:
  /// **'Distanza: {km} km'**
  String mapDistance(String km);

  /// No description provided for @mapSeePassages.
  ///
  /// In it, this message translates to:
  /// **'Vedi passaggi ›'**
  String get mapSeePassages;

  /// No description provided for @stopsMapTitle.
  ///
  /// In it, this message translates to:
  /// **'Mappa delle fermate'**
  String get stopsMapTitle;

  /// No description provided for @journeySection.
  ///
  /// In it, this message translates to:
  /// **'Il tuo ultimo viaggio'**
  String get journeySection;

  /// No description provided for @journeyResume.
  ///
  /// In it, this message translates to:
  /// **'Riprendi viaggio'**
  String get journeyResume;

  /// No description provided for @modify.
  ///
  /// In it, this message translates to:
  /// **'Modifica'**
  String get modify;

  /// No description provided for @coachSkip.
  ///
  /// In it, this message translates to:
  /// **'Salta'**
  String get coachSkip;

  /// No description provided for @coachDone.
  ///
  /// In it, this message translates to:
  /// **'Fine'**
  String get coachDone;

  /// No description provided for @coachNext.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get coachNext;

  /// No description provided for @footerCredits.
  ///
  /// In it, this message translates to:
  /// **'Crediti e licenze'**
  String get footerCredits;

  /// No description provided for @footerAppBy.
  ///
  /// In it, this message translates to:
  /// **'MIT License (2025–2026) · App di '**
  String get footerAppBy;

  /// No description provided for @footerAnd.
  ///
  /// In it, this message translates to:
  /// **' e '**
  String get footerAnd;

  /// No description provided for @footerDevBy.
  ///
  /// In it, this message translates to:
  /// **'App sviluppata da '**
  String get footerDevBy;

  /// No description provided for @footerDesignBy.
  ///
  /// In it, this message translates to:
  /// **'Grafica e design da '**
  String get footerDesignBy;

  /// No description provided for @footerUnofficial.
  ///
  /// In it, this message translates to:
  /// **'Progetto non ufficiale, non affiliato ad ACTV S.p.A. — dati mappe © OpenStreetMap contributors'**
  String get footerUnofficial;

  /// No description provided for @footerUnofficialMultiline.
  ///
  /// In it, this message translates to:
  /// **'Progetto non ufficiale, non affiliato ad ACTV S.p.A.\nDati mappe © OpenStreetMap contributors'**
  String get footerUnofficialMultiline;

  /// No description provided for @geoWaiting.
  ///
  /// In it, this message translates to:
  /// **'In attesa di geolocalizzazione…'**
  String get geoWaiting;

  /// No description provided for @geoFound.
  ///
  /// In it, this message translates to:
  /// **'Posizione trovata. Ecco le stazioni più vicine.'**
  String get geoFound;

  /// No description provided for @geoUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Geolocalizzazione non disponibile'**
  String get geoUnavailable;

  /// No description provided for @noNearbyStops.
  ///
  /// In it, this message translates to:
  /// **'Nessuna fermata trovata nelle vicinanze.'**
  String get noNearbyStops;

  /// No description provided for @homeTitle.
  ///
  /// In it, this message translates to:
  /// **'Il tuo viaggio,\nin tempo reale.'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Orari, fermate e percorsi ACTV a Venezia'**
  String get homeSubtitle;

  /// No description provided for @actvService.
  ///
  /// In it, this message translates to:
  /// **'Servizio ACTV'**
  String get actvService;

  /// No description provided for @whereBus.
  ///
  /// In it, this message translates to:
  /// **'Dove passa il tuo bus?'**
  String get whereBus;

  /// No description provided for @searchStop.
  ///
  /// In it, this message translates to:
  /// **'Cerca una fermata'**
  String get searchStop;

  /// No description provided for @searchStopSub.
  ///
  /// In it, this message translates to:
  /// **'Passaggi in tempo reale per ogni fermata'**
  String get searchStopSub;

  /// No description provided for @searchTrip.
  ///
  /// In it, this message translates to:
  /// **'Cerca una corsa'**
  String get searchTrip;

  /// No description provided for @yourStops.
  ///
  /// In it, this message translates to:
  /// **'Le tue fermate'**
  String get yourStops;

  /// No description provided for @favBadge.
  ///
  /// In it, this message translates to:
  /// **'★ Preferita'**
  String get favBadge;

  /// No description provided for @nearbyStops.
  ///
  /// In it, this message translates to:
  /// **'Fermate vicine'**
  String get nearbyStops;

  /// No description provided for @mapTitle.
  ///
  /// In it, this message translates to:
  /// **'Mappa'**
  String get mapTitle;

  /// No description provided for @welcome.
  ///
  /// In it, this message translates to:
  /// **'Benvenuto'**
  String get welcome;

  /// No description provided for @tourQ.
  ///
  /// In it, this message translates to:
  /// **'Vuoi fare un giro?'**
  String get tourQ;

  /// No description provided for @tourIntroBody.
  ///
  /// In it, this message translates to:
  /// **'Ti mostro in pochi secondi dove sono fermate, mappa, preferiti e tutte le altre funzioni dell\'app.'**
  String get tourIntroBody;

  /// No description provided for @startTour.
  ///
  /// In it, this message translates to:
  /// **'Inizia il tour'**
  String get startTour;

  /// No description provided for @tourNearbyTitle.
  ///
  /// In it, this message translates to:
  /// **'Fermate vicine'**
  String get tourNearbyTitle;

  /// No description provided for @tourNearbyBody.
  ///
  /// In it, this message translates to:
  /// **'Con la geolocalizzazione attiva, qui compaiono le fermate più vicine a te.'**
  String get tourNearbyBody;

  /// No description provided for @tourFavsTitle.
  ///
  /// In it, this message translates to:
  /// **'Le tue fermate'**
  String get tourFavsTitle;

  /// No description provided for @tourFavsBody.
  ///
  /// In it, this message translates to:
  /// **'Le fermate che salvi con la stella le ritrovi sempre qui.'**
  String get tourFavsBody;

  /// No description provided for @tourMapTitle.
  ///
  /// In it, this message translates to:
  /// **'La mappa'**
  String get tourMapTitle;

  /// No description provided for @tourMapBody.
  ///
  /// In it, this message translates to:
  /// **'Ogni pallino è una fermata: toccalo per aprire i passaggi in tempo reale.'**
  String get tourMapBody;

  /// No description provided for @tourMoreTitle.
  ///
  /// In it, this message translates to:
  /// **'Tutto il resto'**
  String get tourMoreTitle;

  /// No description provided for @tourMoreBody.
  ///
  /// In it, this message translates to:
  /// **'Da qui: percorsi con cambio, orari delle linee, statistiche sui ritardi e ricerca di una corsa. Le altre funzioni sono nel menu \"Altro\" in basso.'**
  String get tourMoreBody;

  /// No description provided for @tourCtaTitle.
  ///
  /// In it, this message translates to:
  /// **'Cerca una fermata'**
  String get tourCtaTitle;

  /// No description provided for @tourCtaBody.
  ///
  /// In it, this message translates to:
  /// **'Tutto parte da qui: tocca il pulsante per aprire l\'elenco delle fermate.'**
  String get tourCtaBody;

  /// No description provided for @homeTitleAlt.
  ///
  /// In it, this message translates to:
  /// **'Il tuo viaggio, in tempo reale.'**
  String get homeTitleAlt;

  /// No description provided for @tourActionsTitle.
  ///
  /// In it, this message translates to:
  /// **'Le funzioni'**
  String get tourActionsTitle;

  /// No description provided for @tourActionsBody.
  ///
  /// In it, this message translates to:
  /// **'Percorsi con cambio, mappa live dei mezzi, orari, ricerca corsa, statistiche e rete di linee.'**
  String get tourActionsBody;

  /// No description provided for @actRoutesSub.
  ///
  /// In it, this message translates to:
  /// **'Come arrivare'**
  String get actRoutesSub;

  /// No description provided for @actLiveMap.
  ///
  /// In it, this message translates to:
  /// **'Mappa live'**
  String get actLiveMap;

  /// No description provided for @actLiveMapSub.
  ///
  /// In it, this message translates to:
  /// **'Mezzi in movimento'**
  String get actLiveMapSub;

  /// No description provided for @actSchedules.
  ///
  /// In it, this message translates to:
  /// **'Orari linee'**
  String get actSchedules;

  /// No description provided for @actSchedulesSub.
  ///
  /// In it, this message translates to:
  /// **'Tabella oraria'**
  String get actSchedulesSub;

  /// No description provided for @actTripSearch.
  ///
  /// In it, this message translates to:
  /// **'Cerca corsa'**
  String get actTripSearch;

  /// No description provided for @actTripSearchSub.
  ///
  /// In it, this message translates to:
  /// **'Per linea o tripId'**
  String get actTripSearchSub;

  /// No description provided for @actDelays.
  ///
  /// In it, this message translates to:
  /// **'Ritardi'**
  String get actDelays;

  /// No description provided for @actDelaysSub.
  ///
  /// In it, this message translates to:
  /// **'Statistiche servizio'**
  String get actDelaysSub;

  /// No description provided for @actNetwork.
  ///
  /// In it, this message translates to:
  /// **'Rete'**
  String get actNetwork;

  /// No description provided for @actNetworkSub.
  ///
  /// In it, this message translates to:
  /// **'Tutte le linee'**
  String get actNetworkSub;

  /// No description provided for @stopsAllTitle.
  ///
  /// In it, this message translates to:
  /// **'Tutte le\nStazioni'**
  String get stopsAllTitle;

  /// No description provided for @viewList.
  ///
  /// In it, this message translates to:
  /// **'Elenco'**
  String get viewList;

  /// No description provided for @viewZones.
  ///
  /// In it, this message translates to:
  /// **'Per zona'**
  String get viewZones;

  /// No description provided for @searchStopHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca stazione...'**
  String get searchStopHint;

  /// No description provided for @noStationFound.
  ///
  /// In it, this message translates to:
  /// **'Nessuna stazione trovata.'**
  String get noStationFound;

  /// No description provided for @stopsListTitle.
  ///
  /// In it, this message translates to:
  /// **'Elenco Stazioni'**
  String get stopsListTitle;

  /// No description provided for @navStopsTitle.
  ///
  /// In it, this message translates to:
  /// **'Fermate Navigazione'**
  String get navStopsTitle;

  /// No description provided for @zoneTitle.
  ///
  /// In it, this message translates to:
  /// **'Zone · {zone}'**
  String zoneTitle(String zone);

  /// No description provided for @zonesTitle.
  ///
  /// In it, this message translates to:
  /// **'Zone'**
  String get zonesTitle;

  /// No description provided for @notRealtime.
  ///
  /// In it, this message translates to:
  /// **'Servizio non in tempo reale (Server ACTV Down)'**
  String get notRealtime;

  /// No description provided for @navLine.
  ///
  /// In it, this message translates to:
  /// **'Linea: ⛴ Navigazione'**
  String get navLine;

  /// No description provided for @noLinesAvailable.
  ///
  /// In it, this message translates to:
  /// **'Nessuna linea disponibile'**
  String get noLinesAvailable;

  /// No description provided for @linesLabel.
  ///
  /// In it, this message translates to:
  /// **'Linee:'**
  String get linesLabel;

  /// No description provided for @originTitle.
  ///
  /// In it, this message translates to:
  /// **'Da dove parti?'**
  String get originTitle;

  /// No description provided for @destinationTitle.
  ///
  /// In it, this message translates to:
  /// **'Dove vuoi andare?'**
  String get destinationTitle;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In it, this message translates to:
  /// **'Fatto'**
  String get done;

  /// No description provided for @searchStopOrAddress.
  ///
  /// In it, this message translates to:
  /// **'Cerca stazione o indirizzo...'**
  String get searchStopOrAddress;

  /// No description provided for @recentStops.
  ///
  /// In it, this message translates to:
  /// **'Recenti'**
  String get recentStops;

  /// No description provided for @favStops.
  ///
  /// In it, this message translates to:
  /// **'Preferite'**
  String get favStops;

  /// No description provided for @addresses.
  ///
  /// In it, this message translates to:
  /// **'Indirizzi'**
  String get addresses;

  /// No description provided for @allStops.
  ///
  /// In it, this message translates to:
  /// **'Tutte le fermate'**
  String get allStops;

  /// No description provided for @notifDenied.
  ///
  /// In it, this message translates to:
  /// **'Permesso notifiche negato'**
  String get notifDenied;

  /// No description provided for @shareStop.
  ///
  /// In it, this message translates to:
  /// **'Condividi questa fermata'**
  String get shareStop;

  /// No description provided for @widgetLinkCopied.
  ///
  /// In it, this message translates to:
  /// **'Link widget copiato'**
  String get widgetLinkCopied;

  /// No description provided for @copyWidgetUrl.
  ///
  /// In it, this message translates to:
  /// **'Copia URL widget'**
  String get copyWidgetUrl;

  /// No description provided for @embedCopied.
  ///
  /// In it, this message translates to:
  /// **'Codice embed copiato'**
  String get embedCopied;

  /// No description provided for @copyIframe.
  ///
  /// In it, this message translates to:
  /// **'Copia iframe'**
  String get copyIframe;

  /// No description provided for @tripUnidentified.
  ///
  /// In it, this message translates to:
  /// **'Impossibile identificare con certezza questa corsa.'**
  String get tripUnidentified;

  /// No description provided for @nextPassages.
  ///
  /// In it, this message translates to:
  /// **'Prossimi Passaggi'**
  String get nextPassages;

  /// No description provided for @loadError.
  ///
  /// In it, this message translates to:
  /// **'Errore nel caricamento dei dati.'**
  String get loadError;

  /// No description provided for @loadingPassages.
  ///
  /// In it, this message translates to:
  /// **'Caricamento passaggi...'**
  String get loadingPassages;

  /// No description provided for @noPassagesStrike.
  ///
  /// In it, this message translates to:
  /// **'Nessun passaggio in tempo reale (possibile sciopero). Vedi la bacheca.'**
  String get noPassagesStrike;

  /// No description provided for @noPassagesScheduled.
  ///
  /// In it, this message translates to:
  /// **'Nessun passaggio previsto.'**
  String get noPassagesScheduled;

  /// No description provided for @navigationSection.
  ///
  /// In it, this message translates to:
  /// **'⛴ Navigazione'**
  String get navigationSection;

  /// No description provided for @refresh.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna'**
  String get refresh;

  /// No description provided for @boardStrikeHtml.
  ///
  /// In it, this message translates to:
  /// **'<strong>Possibile sciopero o servizio non monitorato.</strong><br>I passaggi in tempo reale non sono disponibili: gli orari mostrati sono quelli <em>previsti</em> e i bus potrebbero non passare.'**
  String get boardStrikeHtml;

  /// No description provided for @board.
  ///
  /// In it, this message translates to:
  /// **'Bacheca'**
  String get board;

  /// No description provided for @now.
  ///
  /// In it, this message translates to:
  /// **'Ora'**
  String get now;

  /// No description provided for @vehiclePassed.
  ///
  /// In it, this message translates to:
  /// **'Il mezzo ha già superato questa fermata'**
  String get vehiclePassed;

  /// No description provided for @stopsToBoarding.
  ///
  /// In it, this message translates to:
  /// **' · {count, plural, =1{# fermata} other{# fermate}}'**
  String stopsToBoarding(int count);

  /// No description provided for @unknownDestination.
  ///
  /// In it, this message translates to:
  /// **'Destinazione ignota'**
  String get unknownDestination;

  /// No description provided for @navigationLabel.
  ///
  /// In it, this message translates to:
  /// **'Navigazione'**
  String get navigationLabel;

  /// No description provided for @atStop.
  ///
  /// In it, this message translates to:
  /// **'Presso {stop}'**
  String atStop(String stop);

  /// No description provided for @notifDelays.
  ///
  /// In it, this message translates to:
  /// **'Notifiche Ritardi'**
  String get notifDelays;

  /// No description provided for @notifThreshold.
  ///
  /// In it, this message translates to:
  /// **'Avvisa per ritardi superiori a:'**
  String get notifThreshold;

  /// No description provided for @notifExplain.
  ///
  /// In it, this message translates to:
  /// **'Riceverai una notifica quando una linea che passa da questa fermata ha un ritardo superiore alla soglia impostata.'**
  String get notifExplain;

  /// No description provided for @selectOriginDest.
  ///
  /// In it, this message translates to:
  /// **'Seleziona partenza e destinazione'**
  String get selectOriginDest;

  /// No description provided for @findRouteTitle.
  ///
  /// In it, this message translates to:
  /// **'Trova\nPercorso'**
  String get findRouteTitle;

  /// No description provided for @favRoutes.
  ///
  /// In it, this message translates to:
  /// **'Tragitti preferiti'**
  String get favRoutes;

  /// No description provided for @departure.
  ///
  /// In it, this message translates to:
  /// **'Partenza'**
  String get departure;

  /// No description provided for @selectDeparture.
  ///
  /// In it, this message translates to:
  /// **'Seleziona partenza'**
  String get selectDeparture;

  /// No description provided for @destination.
  ///
  /// In it, this message translates to:
  /// **'Destinazione'**
  String get destination;

  /// No description provided for @selectDestination.
  ///
  /// In it, this message translates to:
  /// **'Seleziona destinazione'**
  String get selectDestination;

  /// No description provided for @departureReturnOptions.
  ///
  /// In it, this message translates to:
  /// **'Opzioni di partenza e ritorno'**
  String get departureReturnOptions;

  /// No description provided for @selectDepartureDateTime.
  ///
  /// In it, this message translates to:
  /// **'Seleziona data e ora partenza'**
  String get selectDepartureDateTime;

  /// No description provided for @optimizeFor.
  ///
  /// In it, this message translates to:
  /// **'Ottimizza per'**
  String get optimizeFor;

  /// No description provided for @optTime.
  ///
  /// In it, this message translates to:
  /// **'tempo'**
  String get optTime;

  /// No description provided for @optTransfers.
  ///
  /// In it, this message translates to:
  /// **'cambi'**
  String get optTransfers;

  /// No description provided for @optWalking.
  ///
  /// In it, this message translates to:
  /// **'a piedi'**
  String get optWalking;

  /// No description provided for @returnTrip.
  ///
  /// In it, this message translates to:
  /// **'Ritorno'**
  String get returnTrip;

  /// No description provided for @searchSolutions.
  ///
  /// In it, this message translates to:
  /// **'Ricerca soluzioni'**
  String get searchSolutions;

  /// No description provided for @travelSolutions.
  ///
  /// In it, this message translates to:
  /// **'Soluzioni di viaggio'**
  String get travelSolutions;

  /// No description provided for @outbound.
  ///
  /// In it, this message translates to:
  /// **'Andata'**
  String get outbound;

  /// No description provided for @returnTab.
  ///
  /// In it, this message translates to:
  /// **'Ritorno'**
  String get returnTab;

  /// No description provided for @searchingRoutes.
  ///
  /// In it, this message translates to:
  /// **'Ricerca percorsi in corso…'**
  String get searchingRoutes;

  /// No description provided for @noRouteFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun percorso trovato per i parametri specificati'**
  String get noRouteFound;

  /// No description provided for @back.
  ///
  /// In it, this message translates to:
  /// **'Indietro'**
  String get back;

  /// No description provided for @compareRoutes.
  ///
  /// In it, this message translates to:
  /// **'Confronta percorsi'**
  String get compareRoutes;

  /// No description provided for @compare.
  ///
  /// In it, this message translates to:
  /// **'Confronta'**
  String get compare;

  /// No description provided for @solutionN.
  ///
  /// In it, this message translates to:
  /// **'Soluzione {n}'**
  String solutionN(int n);

  /// No description provided for @minFromNow.
  ///
  /// In it, this message translates to:
  /// **'({n} min da ora)'**
  String minFromNow(int n);

  /// No description provided for @walk.
  ///
  /// In it, this message translates to:
  /// **'Cammina'**
  String get walk;

  /// No description provided for @walkFor.
  ///
  /// In it, this message translates to:
  /// **'per {distance} m'**
  String walkFor(String distance);

  /// No description provided for @stopsCount.
  ///
  /// In it, this message translates to:
  /// **' · {count, plural, =1{# fermata} other{# fermate}}'**
  String stopsCount(int count);

  /// No description provided for @transfersCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Diretto} =1{# cambio} other{# cambi}}'**
  String transfersCount(int count);

  /// No description provided for @details.
  ///
  /// In it, this message translates to:
  /// **'Dettagli'**
  String get details;

  /// No description provided for @selectArrow.
  ///
  /// In it, this message translates to:
  /// **'Seleziona →'**
  String get selectArrow;

  /// No description provided for @routeSaved.
  ///
  /// In it, this message translates to:
  /// **'Tragitto salvato'**
  String get routeSaved;

  /// No description provided for @routeRemoved.
  ///
  /// In it, this message translates to:
  /// **'Tragitto rimosso dai preferiti'**
  String get routeRemoved;

  /// No description provided for @nearOriginHint.
  ///
  /// In it, this message translates to:
  /// **'Sei vicino al punto di partenza: parti da qui.'**
  String get nearOriginHint;

  /// No description provided for @saved.
  ///
  /// In it, this message translates to:
  /// **'Salvato'**
  String get saved;

  /// No description provided for @saveRoute.
  ///
  /// In it, this message translates to:
  /// **'Salva tragitto'**
  String get saveRoute;

  /// No description provided for @viewOnMap.
  ///
  /// In it, this message translates to:
  /// **'Visualizza sulla mappa'**
  String get viewOnMap;

  /// No description provided for @yourRoute.
  ///
  /// In it, this message translates to:
  /// **'Il tuo percorso'**
  String get yourRoute;

  /// No description provided for @liveBusesTitle.
  ///
  /// In it, this message translates to:
  /// **'Bus in servizio'**
  String get liveBusesTitle;

  /// No description provided for @liveMapSubtitle.
  ///
  /// In it, this message translates to:
  /// **'{count} bus sulla mappa · {rt} realtime'**
  String liveMapSubtitle(int count, int rt);

  /// No description provided for @liveMapDataAt.
  ///
  /// In it, this message translates to:
  /// **' · dati {time}'**
  String liveMapDataAt(String time);

  /// No description provided for @searchVehicleHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca: 5E, 21, …'**
  String get searchVehicleHint;

  /// No description provided for @autobus.
  ///
  /// In it, this message translates to:
  /// **'Autobus'**
  String get autobus;

  /// No description provided for @vaporetti.
  ///
  /// In it, this message translates to:
  /// **'Vaporetti'**
  String get vaporetti;

  /// No description provided for @vehicle.
  ///
  /// In it, this message translates to:
  /// **'Veicolo'**
  String get vehicle;

  /// No description provided for @lineN.
  ///
  /// In it, this message translates to:
  /// **'Linea {line}'**
  String lineN(String line);

  /// No description provided for @realtimeLabel.
  ///
  /// In it, this message translates to:
  /// **'tempo reale'**
  String get realtimeLabel;

  /// No description provided for @scheduledLabel.
  ///
  /// In it, this message translates to:
  /// **'programmato'**
  String get scheduledLabel;

  /// No description provided for @trip.
  ///
  /// In it, this message translates to:
  /// **'Corsa'**
  String get trip;

  /// No description provided for @pathsOnMap.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{# percorso sulla mappa} other{# percorsi sulla mappa}}'**
  String pathsOnMap(int count);

  /// No description provided for @showStops.
  ///
  /// In it, this message translates to:
  /// **'Mostra le fermate'**
  String get showStops;

  /// No description provided for @allChip.
  ///
  /// In it, this message translates to:
  /// **'Tutte'**
  String get allChip;

  /// No description provided for @chooseLine.
  ///
  /// In it, this message translates to:
  /// **'Scegli una linea'**
  String get chooseLine;

  /// No description provided for @lineDay.
  ///
  /// In it, this message translates to:
  /// **'Linea {line} · {day}'**
  String lineDay(String line, String day);

  /// No description provided for @linesChip.
  ///
  /// In it, this message translates to:
  /// **'Linee'**
  String get linesChip;

  /// No description provided for @noLinesForDate.
  ///
  /// In it, this message translates to:
  /// **'Nessuna linea per questa data.'**
  String get noLinesForDate;

  /// No description provided for @searchLineHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca per numero o destinazione…'**
  String get searchLineHint;

  /// No description provided for @tripsCount.
  ///
  /// In it, this message translates to:
  /// **'{count} corse'**
  String tripsCount(int count);

  /// No description provided for @noActiveVariants.
  ///
  /// In it, this message translates to:
  /// **'Nessuna variante attiva.'**
  String get noActiveVariants;

  /// No description provided for @variantInfo.
  ///
  /// In it, this message translates to:
  /// **'{origin} → {terminus} · {stops} fermate · {trips} corse'**
  String variantInfo(String origin, String terminus, int stops, int trips);

  /// No description provided for @noScheduleAvailable.
  ///
  /// In it, this message translates to:
  /// **'Nessun orario disponibile.'**
  String get noScheduleAvailable;

  /// No description provided for @stopColumn.
  ///
  /// In it, this message translates to:
  /// **'Fermata'**
  String get stopColumn;

  /// No description provided for @dayMonday.
  ///
  /// In it, this message translates to:
  /// **'lunedì'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In it, this message translates to:
  /// **'martedì'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In it, this message translates to:
  /// **'mercoledì'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In it, this message translates to:
  /// **'giovedì'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In it, this message translates to:
  /// **'venerdì'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In it, this message translates to:
  /// **'sabato'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In it, this message translates to:
  /// **'domenica'**
  String get daySunday;

  /// No description provided for @tripFinderSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Trova una corsa per linea e tratta'**
  String get tripFinderSubtitle;

  /// No description provided for @variantsAvailable.
  ///
  /// In it, this message translates to:
  /// **'direzioni disponibili'**
  String get variantsAvailable;

  /// No description provided for @changeLine.
  ///
  /// In it, this message translates to:
  /// **'Cambia linea'**
  String get changeLine;

  /// No description provided for @allVehiclesShown.
  ///
  /// In it, this message translates to:
  /// **'Bus identificati e non identificati'**
  String get allVehiclesShown;

  /// No description provided for @identifiedVehiclesOnly.
  ///
  /// In it, this message translates to:
  /// **'Solo bus con linea riconosciuta'**
  String get identifiedVehiclesOnly;

  /// No description provided for @scheduleSummary.
  ///
  /// In it, this message translates to:
  /// **'{stops} fermate · {runs} corse'**
  String scheduleSummary(int stops, int runs);

  /// No description provided for @lineLabel.
  ///
  /// In it, this message translates to:
  /// **'Linea'**
  String get lineLabel;

  /// No description provided for @lineHint.
  ///
  /// In it, this message translates to:
  /// **'es. 5E'**
  String get lineHint;

  /// No description provided for @search.
  ///
  /// In it, this message translates to:
  /// **'Cerca'**
  String get search;

  /// No description provided for @noTripsFound.
  ///
  /// In it, this message translates to:
  /// **'Nessuna corsa trovata per questa tratta.'**
  String get noTripsFound;

  /// No description provided for @movingPerSchedule.
  ///
  /// In it, this message translates to:
  /// **'In movimento secondo orario'**
  String get movingPerSchedule;

  /// No description provided for @tripDetail.
  ///
  /// In it, this message translates to:
  /// **'Dettaglio corsa'**
  String get tripDetail;

  /// No description provided for @directionTo.
  ///
  /// In it, this message translates to:
  /// **'DIREZIONE {headsign}'**
  String directionTo(String headsign);

  /// No description provided for @stopsTitleCount.
  ///
  /// In it, this message translates to:
  /// **'Fermate ({count})'**
  String stopsTitleCount(int count);

  /// No description provided for @delayLate.
  ///
  /// In it, this message translates to:
  /// **'· ritardo +{min} min'**
  String delayLate(int min);

  /// No description provided for @delayEarly.
  ///
  /// In it, this message translates to:
  /// **'· anticipo {min} min'**
  String delayEarly(int min);

  /// No description provided for @onTime.
  ///
  /// In it, this message translates to:
  /// **'· in orario'**
  String get onTime;

  /// No description provided for @nextStopIn.
  ///
  /// In it, this message translates to:
  /// **'Prossima fermata: {name} tra {min} min'**
  String nextStopIn(String name, int min);

  /// No description provided for @nextStopNow.
  ///
  /// In it, this message translates to:
  /// **'Prossima fermata: {name} ora'**
  String nextStopNow(String name);

  /// No description provided for @realtimeActive.
  ///
  /// In it, this message translates to:
  /// **'Posizione in tempo reale attiva'**
  String get realtimeActive;

  /// No description provided for @passed.
  ///
  /// In it, this message translates to:
  /// **'TRASCORSO'**
  String get passed;

  /// No description provided for @delayStatsSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Ritardi osservati su questo dispositivo'**
  String get delayStatsSubtitle;

  /// No description provided for @noDelaysRecorded.
  ///
  /// In it, this message translates to:
  /// **'Nessun ritardo registrato.\nI dati vengono raccolti mentre usi la mappa dei bus.'**
  String get noDelaysRecorded;

  /// No description provided for @observations.
  ///
  /// In it, this message translates to:
  /// **'Rilevamenti'**
  String get observations;

  /// No description provided for @avgDelay.
  ///
  /// In it, this message translates to:
  /// **'Ritardo medio'**
  String get avgDelay;

  /// No description provided for @maxDelay.
  ///
  /// In it, this message translates to:
  /// **'Ritardo max'**
  String get maxDelay;

  /// No description provided for @delaysByHour.
  ///
  /// In it, this message translates to:
  /// **'Ritardi per ora'**
  String get delaysByHour;

  /// No description provided for @perLine.
  ///
  /// In it, this message translates to:
  /// **'Per linea'**
  String get perLine;

  /// No description provided for @avgDelayMin.
  ///
  /// In it, this message translates to:
  /// **'Media {value} min'**
  String avgDelayMin(String value);

  /// No description provided for @clearHistory.
  ///
  /// In it, this message translates to:
  /// **'Cancella storico'**
  String get clearHistory;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In it, this message translates to:
  /// **'Eliminare tutti i ritardi registrati?'**
  String get clearHistoryConfirm;

  /// No description provided for @delete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get delete;

  /// No description provided for @worstLine.
  ///
  /// In it, this message translates to:
  /// **'Linea peggiore'**
  String get worstLine;

  /// No description provided for @feedbackFailed.
  ///
  /// In it, this message translates to:
  /// **'Invio non riuscito: {error}'**
  String feedbackFailed(String error);

  /// No description provided for @feedbackSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Aiutaci a rendere Bussolà più utile.'**
  String get feedbackSubtitle;

  /// No description provided for @feedbackThanks.
  ///
  /// In it, this message translates to:
  /// **'Grazie, il tuo feedback è stato inviato.'**
  String get feedbackThanks;

  /// No description provided for @feedbackIntro.
  ///
  /// In it, this message translates to:
  /// **'Segnalaci un problema, proponi una funzione o raccontaci la tua esperienza. Non è necessario lasciare dati personali.'**
  String get feedbackIntro;

  /// No description provided for @feedbackType.
  ///
  /// In it, this message translates to:
  /// **'Tipo di feedback *'**
  String get feedbackType;

  /// No description provided for @fbFeature.
  ///
  /// In it, this message translates to:
  /// **'Nuova funzionalità'**
  String get fbFeature;

  /// No description provided for @fbBug.
  ///
  /// In it, this message translates to:
  /// **'Bug o problema'**
  String get fbBug;

  /// No description provided for @fbImprovement.
  ///
  /// In it, this message translates to:
  /// **'Miglioramento'**
  String get fbImprovement;

  /// No description provided for @fbQuestion.
  ///
  /// In it, this message translates to:
  /// **'Domanda'**
  String get fbQuestion;

  /// No description provided for @fbOther.
  ///
  /// In it, this message translates to:
  /// **'Altro'**
  String get fbOther;

  /// No description provided for @selectCategory.
  ///
  /// In it, this message translates to:
  /// **'Seleziona una categoria'**
  String get selectCategory;

  /// No description provided for @priority.
  ///
  /// In it, this message translates to:
  /// **'Priorità percepita'**
  String get priority;

  /// No description provided for @prioLow.
  ///
  /// In it, this message translates to:
  /// **'Bassa'**
  String get prioLow;

  /// No description provided for @prioNormal.
  ///
  /// In it, this message translates to:
  /// **'Normale'**
  String get prioNormal;

  /// No description provided for @prioHigh.
  ///
  /// In it, this message translates to:
  /// **'Alta'**
  String get prioHigh;

  /// No description provided for @subjectLabel.
  ///
  /// In it, this message translates to:
  /// **'Titolo'**
  String get subjectLabel;

  /// No description provided for @subjectHint.
  ///
  /// In it, this message translates to:
  /// **'In breve, di cosa si tratta?'**
  String get subjectHint;

  /// No description provided for @messageLabel.
  ///
  /// In it, this message translates to:
  /// **'Messaggio *'**
  String get messageLabel;

  /// No description provided for @messageHint.
  ///
  /// In it, this message translates to:
  /// **'Descrivi cosa è successo o cosa vorresti migliorare...'**
  String get messageHint;

  /// No description provided for @minChars.
  ///
  /// In it, this message translates to:
  /// **'Scrivi almeno 10 caratteri'**
  String get minChars;

  /// No description provided for @nameOptional.
  ///
  /// In it, this message translates to:
  /// **'Nome (facoltativo)'**
  String get nameOptional;

  /// No description provided for @emailOptional.
  ///
  /// In it, this message translates to:
  /// **'Email (facoltativa)'**
  String get emailOptional;

  /// No description provided for @emailHint.
  ///
  /// In it, this message translates to:
  /// **'Per eventuale risposta'**
  String get emailHint;

  /// No description provided for @send.
  ///
  /// In it, this message translates to:
  /// **'Invia'**
  String get send;

  /// No description provided for @localDataCleared.
  ///
  /// In it, this message translates to:
  /// **'Dati locali eliminati'**
  String get localDataCleared;

  /// No description provided for @apiServerUpdated.
  ///
  /// In it, this message translates to:
  /// **'Server API aggiornato'**
  String get apiServerUpdated;

  /// No description provided for @privacySubtitle.
  ///
  /// In it, this message translates to:
  /// **'Gestione dei dati memorizzati'**
  String get privacySubtitle;

  /// No description provided for @localData.
  ///
  /// In it, this message translates to:
  /// **'Dati locali'**
  String get localData;

  /// No description provided for @localDataDesc.
  ///
  /// In it, this message translates to:
  /// **'L\'app memorizza sul dispositivo: tema (theme), consenso cookie (cookie_consent_accepted), fermate preferite (favorite_stops), fermate recenti (recent_stops), tragitti (favorite_routes, route_*), storico ritardi (delay_history), fermate monitorate (monitored_stops) e impostazioni.'**
  String get localDataDesc;

  /// No description provided for @cookieConsentRevoked.
  ///
  /// In it, this message translates to:
  /// **'Consenso cookie revocato'**
  String get cookieConsentRevoked;

  /// No description provided for @revokeCookieConsent.
  ///
  /// In it, this message translates to:
  /// **'Revoca consenso cookie'**
  String get revokeCookieConsent;

  /// No description provided for @deleteAllData.
  ///
  /// In it, this message translates to:
  /// **'Elimina tutti i dati'**
  String get deleteAllData;

  /// No description provided for @thirdParties.
  ///
  /// In it, this message translates to:
  /// **'Terze parti'**
  String get thirdParties;

  /// No description provided for @thirdPartiesDesc.
  ///
  /// In it, this message translates to:
  /// **'Mappe e geocoding: OpenStreetMap e Nominatim.\nDati trasporto: backend ACTV (oraritemporeale.actv.it) e feed GTFS/GTFS-RT.\nI feedback inviati arrivano al server API configurato (nessun dato personale obbligatorio).'**
  String get thirdPartiesDesc;

  /// No description provided for @apiServerDesc.
  ///
  /// In it, this message translates to:
  /// **'Indirizzo del server che fornisce i dati ACTV.'**
  String get apiServerDesc;

  /// No description provided for @baseUrl.
  ///
  /// In it, this message translates to:
  /// **'URL base'**
  String get baseUrl;

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get save;

  /// No description provided for @creditsSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Attribuzioni e licenze'**
  String get creditsSubtitle;

  /// No description provided for @mapsCredit.
  ///
  /// In it, this message translates to:
  /// **'Mappe'**
  String get mapsCredit;

  /// No description provided for @mapDataOdbL.
  ///
  /// In it, this message translates to:
  /// **'dati mappe © ODbL'**
  String get mapDataOdbL;

  /// No description provided for @geocodingNote.
  ///
  /// In it, this message translates to:
  /// **'geocoding indirizzi'**
  String get geocodingNote;

  /// No description provided for @transitData.
  ///
  /// In it, this message translates to:
  /// **'Dati trasporto'**
  String get transitData;

  /// No description provided for @transitDataNote.
  ///
  /// In it, this message translates to:
  /// **'orari e posizioni dei mezzi'**
  String get transitDataNote;

  /// No description provided for @unofficialProject.
  ///
  /// In it, this message translates to:
  /// **'Progetto non ufficiale, non affiliato ad ACTV S.p.A.'**
  String get unofficialProject;

  /// No description provided for @openSourceLibs.
  ///
  /// In it, this message translates to:
  /// **'Librerie open source'**
  String get openSourceLibs;

  /// No description provided for @project.
  ///
  /// In it, this message translates to:
  /// **'Progetto'**
  String get project;

  /// No description provided for @creditsReleasedBy.
  ///
  /// In it, this message translates to:
  /// **'Rilasciato con licenza MIT.\n\nSviluppato da '**
  String get creditsReleasedBy;

  /// No description provided for @creditsDesignBy.
  ///
  /// In it, this message translates to:
  /// **'\nGrafica e design da '**
  String get creditsDesignBy;

  /// No description provided for @openOnActvLive.
  ///
  /// In it, this message translates to:
  /// **'Apri su ACTV Live →'**
  String get openOnActvLive;

  /// No description provided for @positionDetected.
  ///
  /// In it, this message translates to:
  /// **'Posizione rilevata'**
  String get positionDetected;

  /// No description provided for @atPreposition.
  ///
  /// In it, this message translates to:
  /// **'a'**
  String get atPreposition;

  /// No description provided for @feedbackTileSub.
  ///
  /// In it, this message translates to:
  /// **'Segnala un problema'**
  String get feedbackTileSub;

  /// No description provided for @lmFilters.
  ///
  /// In it, this message translates to:
  /// **'Filtri'**
  String get lmFilters;

  /// No description provided for @lmAllLines.
  ///
  /// In it, this message translates to:
  /// **'Tutte le linee'**
  String get lmAllLines;

  /// No description provided for @lmSearchBy.
  ///
  /// In it, this message translates to:
  /// **'Cerca per'**
  String get lmSearchBy;

  /// No description provided for @lmByLine.
  ///
  /// In it, this message translates to:
  /// **'Linea'**
  String get lmByLine;

  /// No description provided for @lmByTrip.
  ///
  /// In it, this message translates to:
  /// **'Corsa'**
  String get lmByTrip;

  /// No description provided for @lmLinesLabel.
  ///
  /// In it, this message translates to:
  /// **'Linee'**
  String get lmLinesLabel;

  /// No description provided for @lmTripsLabel.
  ///
  /// In it, this message translates to:
  /// **'ID corse'**
  String get lmTripsLabel;

  /// No description provided for @lmQueryHelp.
  ///
  /// In it, this message translates to:
  /// **'Separa più linee con una virgola. Lascia vuoto per mostrarle tutte.'**
  String get lmQueryHelp;

  /// No description provided for @lmTripHelp.
  ///
  /// In it, this message translates to:
  /// **'Separa più ID corsa con una virgola. Lascia vuoto per mostrare tutte le linee.'**
  String get lmTripHelp;

  /// No description provided for @lmReset.
  ///
  /// In it, this message translates to:
  /// **'Reset'**
  String get lmReset;

  /// No description provided for @lmApply.
  ///
  /// In it, this message translates to:
  /// **'Applica'**
  String get lmApply;

  /// No description provided for @lmStopsSuffix.
  ///
  /// In it, this message translates to:
  /// **'Fermate'**
  String get lmStopsSuffix;

  /// No description provided for @lmLineTripsCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{# corsa} other{# corse}}'**
  String lmLineTripsCount(int count);

  /// No description provided for @myPosition.
  ///
  /// In it, this message translates to:
  /// **'La mia posizione'**
  String get myPosition;

  /// No description provided for @refreshTooltip.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna'**
  String get refreshTooltip;

  /// No description provided for @mapSettings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni mappa'**
  String get mapSettings;

  /// No description provided for @searchFields.
  ///
  /// In it, this message translates to:
  /// **'Campi di ricerca'**
  String get searchFields;

  /// No description provided for @searchFieldLine.
  ///
  /// In it, this message translates to:
  /// **'Linea'**
  String get searchFieldLine;

  /// No description provided for @searchFieldDest.
  ///
  /// In it, this message translates to:
  /// **'Destinazione'**
  String get searchFieldDest;

  /// No description provided for @searchFieldTrip.
  ///
  /// In it, this message translates to:
  /// **'Corsa (tripId)'**
  String get searchFieldTrip;

  /// No description provided for @noLineShown.
  ///
  /// In it, this message translates to:
  /// **'Veicoli senza linea'**
  String get noLineShown;

  /// No description provided for @noLineShownSub.
  ///
  /// In it, this message translates to:
  /// **'mostra anche i mezzi non identificati'**
  String get noLineShownSub;

  /// No description provided for @updatedAt.
  ///
  /// In it, this message translates to:
  /// **'aggiornato {time}'**
  String updatedAt(String time);

  /// No description provided for @lsSearchLabel.
  ///
  /// In it, this message translates to:
  /// **'Cerca linea'**
  String get lsSearchLabel;

  /// No description provided for @loading.
  ///
  /// In it, this message translates to:
  /// **'Caricamento…'**
  String get loading;

  /// No description provided for @busService.
  ///
  /// In it, this message translates to:
  /// **'Servizio bus'**
  String get busService;

  /// No description provided for @findTrip.
  ///
  /// In it, this message translates to:
  /// **'Trova corsa'**
  String get findTrip;

  /// No description provided for @dateLabel.
  ///
  /// In it, this message translates to:
  /// **'Data'**
  String get dateLabel;

  /// No description provided for @pickLineFirst.
  ///
  /// In it, this message translates to:
  /// **'Scegli prima una linea'**
  String get pickLineFirst;

  /// No description provided for @pickOriginFirst.
  ///
  /// In it, this message translates to:
  /// **'Scegli prima la partenza'**
  String get pickOriginFirst;

  /// No description provided for @selectLeg.
  ///
  /// In it, this message translates to:
  /// **'Seleziona una tratta'**
  String get selectLeg;

  /// No description provided for @tripsEmptyState.
  ///
  /// In it, this message translates to:
  /// **'Compila i campi qui sopra per vedere le corse disponibili.'**
  String get tripsEmptyState;

  /// No description provided for @goToPage.
  ///
  /// In it, this message translates to:
  /// **'Vai a pagina'**
  String get goToPage;

  /// No description provided for @goToTime.
  ///
  /// In it, this message translates to:
  /// **'Vai all\'orario'**
  String get goToTime;

  /// No description provided for @go.
  ///
  /// In it, this message translates to:
  /// **'Vai'**
  String get go;

  /// No description provided for @orWord.
  ///
  /// In it, this message translates to:
  /// **'oppure'**
  String get orWord;

  /// No description provided for @openTrip.
  ///
  /// In it, this message translates to:
  /// **'Apri corsa'**
  String get openTrip;

  /// No description provided for @lineHelp.
  ///
  /// In it, this message translates to:
  /// **'Seleziona la linea da ispezionare'**
  String get lineHelp;

  /// No description provided for @tripsResults.
  ///
  /// In it, this message translates to:
  /// **'Risultati'**
  String get tripsResults;

  /// No description provided for @pageOf.
  ///
  /// In it, this message translates to:
  /// **'Pagina {page} di {total}'**
  String pageOf(int page, int total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
