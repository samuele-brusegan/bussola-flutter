// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Bussolà';

  @override
  String get navHome => 'Home';

  @override
  String get navStops => 'Stops';

  @override
  String get navRoutes => 'Routes';

  @override
  String get navMore => 'More';

  @override
  String get moreLinesMap => 'Lines map';

  @override
  String get moreLineSchedules => 'Line schedules';

  @override
  String get moreLiveVehicles => 'Vehicles in service';

  @override
  String get moreDelayStats => 'Delay statistics';

  @override
  String get moreFeedback => 'Send feedback';

  @override
  String get moreLanguage => 'Language';

  @override
  String get morePrivacy => 'Privacy and data';

  @override
  String get moreCredits => 'Credits';

  @override
  String get moreAltHome => 'Alternative home';

  @override
  String get languageTitle => 'App language';

  @override
  String get languageSystem => 'System default';

  @override
  String get errorLoadData => 'Unable to load data';

  @override
  String get retry => 'Retry';

  @override
  String get qrOpenOnWeb => 'Open this page on the web';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get copyLink => 'Copy link';

  @override
  String get cookieBannerText =>
      'We use local data and server cookies to improve your experience. ';

  @override
  String get cookieLearnMore => 'Learn more';

  @override
  String get cookieAccept => 'Accept';

  @override
  String get youAreOffline => 'You are offline';

  @override
  String get strikeTitle => 'Strike';

  @override
  String get strikePossible => 'Possible strike in progress';

  @override
  String strikeBody(int count) {
    return 'The real-time service is not responding on $count checked stops: a strike or service disruption is likely. Scheduled times may not be respected.';
  }

  @override
  String get strikeEmptyStops => 'Stops with no detected departures:';

  @override
  String stopDefaultName(String id) {
    return 'Stop $id';
  }

  @override
  String get gotIt => 'Got it';

  @override
  String get mapStationLabel => 'Station: ';

  @override
  String mapDistance(String km) {
    return 'Distance: $km km';
  }

  @override
  String get mapSeePassages => 'See departures ›';

  @override
  String get stopsMapTitle => 'Stops map';

  @override
  String get journeySection => 'Your last journey';

  @override
  String get journeyResume => 'Resume journey';

  @override
  String get modify => 'Edit';

  @override
  String get coachSkip => 'Skip';

  @override
  String get coachDone => 'Done';

  @override
  String get coachNext => 'Next';

  @override
  String get footerCredits => 'Credits and licenses';

  @override
  String get footerAppBy => 'MIT License (2025–2026) · App by ';

  @override
  String get footerAnd => ' and ';

  @override
  String get footerDevBy => 'App developed by ';

  @override
  String get footerDesignBy => 'Graphics and design by ';

  @override
  String get footerUnofficial =>
      'Unofficial project, not affiliated with ACTV S.p.A. — map data © OpenStreetMap contributors';

  @override
  String get footerUnofficialMultiline =>
      'Unofficial project, not affiliated with ACTV S.p.A.\nMap data © OpenStreetMap contributors';

  @override
  String get geoWaiting => 'Waiting for geolocation…';

  @override
  String get geoFound => 'Location found. Here are the nearest stops.';

  @override
  String get geoUnavailable => 'Geolocation unavailable';

  @override
  String get noNearbyStops => 'No stops found nearby.';

  @override
  String get homeTitle => 'Your journey,\nin real time.';

  @override
  String get homeSubtitle => 'ACTV times, stops and routes in Venice';

  @override
  String get actvService => 'ACTV service';

  @override
  String get whereBus => 'Where does your bus stop?';

  @override
  String get searchStop => 'Find a stop';

  @override
  String get searchStopSub => 'Real-time departures for every stop';

  @override
  String get searchTrip => 'Find a trip';

  @override
  String get yourStops => 'Your stops';

  @override
  String get favBadge => '★ Favorite';

  @override
  String get nearbyStops => 'Nearby stops';

  @override
  String get mapTitle => 'Map';

  @override
  String get welcome => 'Welcome';

  @override
  String get tourQ => 'Want a quick tour?';

  @override
  String get tourIntroBody =>
      'I\'ll show you in a few seconds where the stops, map, favorites and all the other app features are.';

  @override
  String get startTour => 'Start the tour';

  @override
  String get tourNearbyTitle => 'Nearby stops';

  @override
  String get tourNearbyBody =>
      'With geolocation enabled, the stops closest to you appear here.';

  @override
  String get tourFavsTitle => 'Your stops';

  @override
  String get tourFavsBody =>
      'The stops you save with the star always show up here.';

  @override
  String get tourMapTitle => 'The map';

  @override
  String get tourMapBody =>
      'Each dot is a stop: tap it to see real-time departures.';

  @override
  String get tourMoreTitle => 'Everything else';

  @override
  String get tourMoreBody =>
      'From here: routes with transfers, line schedules, delay statistics and trip search. The other features are in the \"More\" menu below.';

  @override
  String get tourCtaTitle => 'Find a stop';

  @override
  String get tourCtaBody =>
      'Everything starts here: tap the button to open the stop list.';

  @override
  String get homeTitleAlt => 'Your journey, in real time.';

  @override
  String get tourActionsTitle => 'The features';

  @override
  String get tourActionsBody =>
      'Routes with transfers, live vehicle map, schedules, trip search, statistics and the line network.';

  @override
  String get actRoutesSub => 'How to get there';

  @override
  String get actLiveMap => 'Live map';

  @override
  String get actLiveMapSub => 'Vehicles on the move';

  @override
  String get actSchedules => 'Line schedules';

  @override
  String get actSchedulesSub => 'Timetable';

  @override
  String get actTripSearch => 'Find trip';

  @override
  String get actTripSearchSub => 'By line or tripId';

  @override
  String get actDelays => 'Delays';

  @override
  String get actDelaysSub => 'Service statistics';

  @override
  String get actNetwork => 'Network';

  @override
  String get actNetworkSub => 'All lines';

  @override
  String get stopsAllTitle => 'All\nStops';

  @override
  String get viewList => 'List';

  @override
  String get viewZones => 'By zone';

  @override
  String get searchStopHint => 'Search stop...';

  @override
  String get noStationFound => 'No stop found.';

  @override
  String get stopsListTitle => 'Stop List';

  @override
  String get navStopsTitle => 'Navigation Stops';

  @override
  String zoneTitle(String zone) {
    return 'Zone · $zone';
  }

  @override
  String get zonesTitle => 'Zones';

  @override
  String get notRealtime => 'Not a real-time service (ACTV Server Down)';

  @override
  String get navLine => 'Line: ⛴ Navigation';

  @override
  String get noLinesAvailable => 'No lines available';

  @override
  String get linesLabel => 'Lines:';

  @override
  String get originTitle => 'Where are you leaving from?';

  @override
  String get destinationTitle => 'Where do you want to go?';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get searchStopOrAddress => 'Search stop or address...';

  @override
  String get recentStops => 'Recent';

  @override
  String get favStops => 'Favorites';

  @override
  String get addresses => 'Addresses';

  @override
  String get allStops => 'All stops';

  @override
  String get notifDenied => 'Notification permission denied';

  @override
  String get shareStop => 'Share this stop';

  @override
  String get widgetLinkCopied => 'Widget link copied';

  @override
  String get copyWidgetUrl => 'Copy widget URL';

  @override
  String get embedCopied => 'Embed code copied';

  @override
  String get copyIframe => 'Copy iframe';

  @override
  String get tripUnidentified => 'Unable to identify this trip with certainty.';

  @override
  String get nextPassages => 'Upcoming Departures';

  @override
  String get loadError => 'Error loading data.';

  @override
  String get loadingPassages => 'Loading departures...';

  @override
  String get noPassagesStrike =>
      'No real-time departures (possible strike). See the noticeboard.';

  @override
  String get noPassagesScheduled => 'No scheduled departures.';

  @override
  String get navigationSection => '⛴ Navigation';

  @override
  String get refresh => 'Refresh';

  @override
  String get boardStrikeHtml =>
      '<strong>Possible strike or unmonitored service.</strong><br>Real-time departures are not available: the times shown are <em>scheduled</em> and buses may not run.';

  @override
  String get board => 'Noticeboard';

  @override
  String get now => 'Now';

  @override
  String get vehiclePassed => 'The vehicle has already passed this stop';

  @override
  String stopsToBoarding(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# stops',
      one: '# stop',
    );
    return ' · $_temp0';
  }

  @override
  String get unknownDestination => 'Unknown destination';

  @override
  String get navigationLabel => 'Navigation';

  @override
  String atStop(String stop) {
    return 'At $stop';
  }

  @override
  String get notifDelays => 'Delay Notifications';

  @override
  String get notifThreshold => 'Notify for delays over:';

  @override
  String get notifExplain =>
      'You will receive a notification when a line passing through this stop has a delay greater than the set threshold.';

  @override
  String get selectOriginDest => 'Select departure and destination';

  @override
  String get findRouteTitle => 'Find\nRoute';

  @override
  String get favRoutes => 'Favorite routes';

  @override
  String get departure => 'Departure';

  @override
  String get selectDeparture => 'Select departure';

  @override
  String get destination => 'Destination';

  @override
  String get selectDestination => 'Select destination';

  @override
  String get departureReturnOptions => 'Departure and return options';

  @override
  String get selectDepartureDateTime => 'Select departure date and time';

  @override
  String get optimizeFor => 'Optimize for';

  @override
  String get optTime => 'time';

  @override
  String get optTransfers => 'transfers';

  @override
  String get optWalking => 'walking';

  @override
  String get returnTrip => 'Return';

  @override
  String get searchSolutions => 'Search routes';

  @override
  String get travelSolutions => 'Travel options';

  @override
  String get outbound => 'Outbound';

  @override
  String get returnTab => 'Return';

  @override
  String get searchingRoutes => 'Searching routes…';

  @override
  String get noRouteFound => 'No route found for the specified parameters';

  @override
  String get back => 'Back';

  @override
  String get compareRoutes => 'Compare routes';

  @override
  String get compare => 'Compare';

  @override
  String solutionN(int n) {
    return 'Option $n';
  }

  @override
  String minFromNow(int n) {
    return '($n min from now)';
  }

  @override
  String get walk => 'Walk';

  @override
  String walkFor(String distance) {
    return 'for $distance m';
  }

  @override
  String stopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# stops',
      one: '# stop',
    );
    return ' · $_temp0';
  }

  @override
  String transfersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# transfers',
      one: '# transfer',
      zero: 'Direct',
    );
    return '$_temp0';
  }

  @override
  String get details => 'Details';

  @override
  String get selectArrow => 'Select →';

  @override
  String get routeSaved => 'Route saved';

  @override
  String get routeRemoved => 'Route removed from favorites';

  @override
  String get nearOriginHint =>
      'You\'re near the departure point: start from here.';

  @override
  String get saved => 'Saved';

  @override
  String get saveRoute => 'Save route';

  @override
  String get viewOnMap => 'View on map';

  @override
  String get yourRoute => 'Your route';

  @override
  String get liveBusesTitle => 'Buses in service';

  @override
  String liveMapSubtitle(int count, int rt) {
    return '$count buses on the map · $rt realtime';
  }

  @override
  String liveMapDataAt(String time) {
    return ' · data $time';
  }

  @override
  String get searchVehicleHint => 'Search: 5E, 21, …';

  @override
  String get autobus => 'Buses';

  @override
  String get vaporetti => 'Water buses';

  @override
  String get vehicle => 'Vehicle';

  @override
  String lineN(String line) {
    return 'Line $line';
  }

  @override
  String get realtimeLabel => 'real time';

  @override
  String get scheduledLabel => 'scheduled';

  @override
  String get trip => 'Trip';

  @override
  String pathsOnMap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# paths on the map',
      one: '# path on the map',
    );
    return '$_temp0';
  }

  @override
  String get showStops => 'Show stops';

  @override
  String get allChip => 'All';

  @override
  String get chooseLine => 'Choose a line';

  @override
  String lineDay(String line, String day) {
    return 'Line $line · $day';
  }

  @override
  String get linesChip => 'Lines';

  @override
  String get noLinesForDate => 'No lines for this date.';

  @override
  String get searchLineHint => 'Search by number or destination…';

  @override
  String tripsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# trips',
      one: '# trip',
    );
    return '$_temp0';
  }

  @override
  String get noActiveVariants => 'No active variants.';

  @override
  String variantInfo(String origin, String terminus, int stops, int trips) {
    return '$origin → $terminus · $stops stops · $trips trips';
  }

  @override
  String get noScheduleAvailable => 'No schedule available.';

  @override
  String get stopColumn => 'Stop';

  @override
  String get dayMonday => 'Monday';

  @override
  String get dayTuesday => 'Tuesday';

  @override
  String get dayWednesday => 'Wednesday';

  @override
  String get dayThursday => 'Thursday';

  @override
  String get dayFriday => 'Friday';

  @override
  String get daySaturday => 'Saturday';

  @override
  String get daySunday => 'Sunday';

  @override
  String get tripFinderSubtitle => 'Find a trip by line and section';

  @override
  String get variantsAvailable => 'directions available';

  @override
  String get changeLine => 'Change line';

  @override
  String get allVehiclesShown => 'Identified and unidentified buses';

  @override
  String get identifiedVehiclesOnly => 'Only buses with a known line';

  @override
  String scheduleSummary(int stops, int runs) {
    return '$stops stops · $runs trips';
  }

  @override
  String get lineLabel => 'Line';

  @override
  String get lineHint => 'e.g. 5E';

  @override
  String get search => 'Search';

  @override
  String get noTripsFound => 'No trips found for this section.';

  @override
  String get movingPerSchedule => 'Moving per schedule';

  @override
  String get tripDetail => 'Trip details';

  @override
  String directionTo(String headsign) {
    return 'TO $headsign';
  }

  @override
  String stopsTitleCount(int count) {
    return 'Stops ($count)';
  }

  @override
  String delayLate(int min) {
    return '· delay +$min min';
  }

  @override
  String delayEarly(int min) {
    return '· early $min min';
  }

  @override
  String get onTime => '· on time';

  @override
  String nextStopIn(String name, int min) {
    return 'Next stop: $name in $min min';
  }

  @override
  String nextStopNow(String name) {
    return 'Next stop: $name now';
  }

  @override
  String get realtimeActive => 'Real-time position active';

  @override
  String get passed => 'PASSED';

  @override
  String get delayStatsSubtitle => 'Delays observed on this device';

  @override
  String get noDelaysRecorded =>
      'No delays recorded.\nData is collected while you use the bus map.';

  @override
  String get observations => 'Observations';

  @override
  String get avgDelay => 'Average delay';

  @override
  String get maxDelay => 'Max delay';

  @override
  String get delaysByHour => 'Delays by hour';

  @override
  String get perLine => 'By line';

  @override
  String avgDelayMin(String value) {
    return 'Avg $value min';
  }

  @override
  String get clearHistory => 'Clear history';

  @override
  String get clearHistoryConfirm => 'Delete all recorded delays?';

  @override
  String get delete => 'Delete';

  @override
  String get worstLine => 'Worst line';

  @override
  String feedbackFailed(String error) {
    return 'Sending failed: $error';
  }

  @override
  String get feedbackSubtitle => 'Help us make Bussolà more useful.';

  @override
  String get feedbackThanks => 'Thank you, your feedback has been sent.';

  @override
  String get feedbackIntro =>
      'Report a problem, suggest a feature or tell us about your experience. You don\'t need to leave personal data.';

  @override
  String get feedbackType => 'Feedback type *';

  @override
  String get fbFeature => 'New feature';

  @override
  String get fbBug => 'Bug or problem';

  @override
  String get fbImprovement => 'Improvement';

  @override
  String get fbQuestion => 'Question';

  @override
  String get fbOther => 'Other';

  @override
  String get selectCategory => 'Select a category';

  @override
  String get priority => 'Perceived priority';

  @override
  String get prioLow => 'Low';

  @override
  String get prioNormal => 'Normal';

  @override
  String get prioHigh => 'High';

  @override
  String get subjectLabel => 'Subject';

  @override
  String get subjectHint => 'Briefly, what is it about?';

  @override
  String get messageLabel => 'Message *';

  @override
  String get messageHint =>
      'Describe what happened or what you\'d like to improve...';

  @override
  String get minChars => 'Write at least 10 characters';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get emailHint => 'For a possible reply';

  @override
  String get send => 'Send';

  @override
  String get localDataCleared => 'Local data deleted';

  @override
  String get apiServerUpdated => 'API server updated';

  @override
  String get privacySubtitle => 'Manage stored data';

  @override
  String get localData => 'Local data';

  @override
  String get localDataDesc =>
      'The app stores on the device: theme (theme), cookie consent (cookie_consent_accepted), favorite stops (favorite_stops), recent stops (recent_stops), routes (favorite_routes, route_*), delay history (delay_history), monitored stops (monitored_stops) and settings.';

  @override
  String get cookieConsentRevoked => 'Cookie consent revoked';

  @override
  String get revokeCookieConsent => 'Revoke cookie consent';

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get thirdParties => 'Third parties';

  @override
  String get thirdPartiesDesc =>
      'Maps and geocoding: OpenStreetMap and Nominatim.\nTransit data: ACTV backend (oraritemporeale.actv.it) and GTFS/GTFS-RT feeds.\nSubmitted feedback goes to the configured API server (no personal data required).';

  @override
  String get apiServerDesc => 'Address of the server providing ACTV data.';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get save => 'Save';

  @override
  String get creditsSubtitle => 'Attributions and licenses';

  @override
  String get mapsCredit => 'Maps';

  @override
  String get mapDataOdbL => 'map data © ODbL';

  @override
  String get geocodingNote => 'address geocoding';

  @override
  String get transitData => 'Transit data';

  @override
  String get transitDataNote => 'vehicle times and positions';

  @override
  String get unofficialProject =>
      'Unofficial project, not affiliated with ACTV S.p.A.';

  @override
  String get openSourceLibs => 'Open source libraries';

  @override
  String get project => 'Project';

  @override
  String get creditsReleasedBy =>
      'Released under the MIT license.\n\nDeveloped by ';

  @override
  String get creditsDesignBy => '\nGraphics and design by ';

  @override
  String get openOnActvLive => 'Open in ACTV Live →';

  @override
  String get positionDetected => 'Position detected';

  @override
  String get atPreposition => 'at';

  @override
  String get feedbackTileSub => 'Report a problem';

  @override
  String get lmFilters => 'Filters';

  @override
  String get lmAllLines => 'All lines';

  @override
  String get lmSearchBy => 'Search by';

  @override
  String get lmByLine => 'Line';

  @override
  String get lmByTrip => 'Trip';

  @override
  String get lmLinesLabel => 'Lines';

  @override
  String get lmTripsLabel => 'Trip IDs';

  @override
  String get lmQueryHelp =>
      'Separate multiple lines with a comma. Leave empty to show them all.';

  @override
  String get lmTripHelp =>
      'Separate multiple trip IDs with a comma. Leave empty to show all lines.';

  @override
  String get lmReset => 'Reset';

  @override
  String get lmApply => 'Apply';

  @override
  String get lmStopsSuffix => 'Stops';

  @override
  String lmLineTripsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# trips',
      one: '# trip',
    );
    return '$_temp0';
  }

  @override
  String get myPosition => 'My position';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get mapSettings => 'Map settings';

  @override
  String get searchFields => 'Search fields';

  @override
  String get searchFieldLine => 'Line';

  @override
  String get searchFieldDest => 'Destination';

  @override
  String get searchFieldTrip => 'Trip (tripId)';

  @override
  String get noLineShown => 'Vehicles without line';

  @override
  String get noLineShownSub => 'also show unidentified vehicles';

  @override
  String updatedAt(String time) {
    return 'updated $time';
  }

  @override
  String get lsSearchLabel => 'Search line';

  @override
  String get loading => 'Loading…';

  @override
  String get busService => 'Bus service';

  @override
  String get findTrip => 'Find trip';

  @override
  String get dateLabel => 'Date';

  @override
  String get pickLineFirst => 'Pick a line first';

  @override
  String get pickOriginFirst => 'Pick the origin first';

  @override
  String get selectLeg => 'Select a section';

  @override
  String get tripsEmptyState =>
      'Fill in the fields above to see the available trips.';

  @override
  String get goToPage => 'Go to page';

  @override
  String get goToTime => 'Go to time';

  @override
  String get go => 'Go';

  @override
  String get orWord => 'or';

  @override
  String get openTrip => 'Open trip';

  @override
  String get lineHelp => 'Select the line to inspect';

  @override
  String get tripsResults => 'Results';

  @override
  String pageOf(int page, int total) {
    return 'Page $page of $total';
  }
}
