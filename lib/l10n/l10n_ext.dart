import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localizes an API day name ("monday"…"sunday").
String localizedDay(BuildContext context, String day) => switch (day) {
      'tuesday' => context.l10n.dayTuesday,
      'wednesday' => context.l10n.dayWednesday,
      'thursday' => context.l10n.dayThursday,
      'friday' => context.l10n.dayFriday,
      'saturday' => context.l10n.daySaturday,
      'sunday' => context.l10n.daySunday,
      _ => context.l10n.dayMonday,
    };
