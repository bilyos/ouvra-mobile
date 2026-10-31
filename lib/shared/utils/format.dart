import 'package:intl/intl.dart';

final _amount = NumberFormat.decimalPattern('fr');

/// « 15 000 FCFA » avec espaces insécables (le montant ne se coupe jamais).
String formatFcfa(num value) =>
    '${_amount.format(value).replaceAll(RegExp(r'\s'), ' ')} FCFA';

/// Distance lisible : « 800 m », « 3,4 km ».
String formatDistance(double km) {
  if (km <= 0) return '';
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(km < 10 ? 1 : 0).replaceAll('.', ',')} km';
}

/// Heure ou jour relatif d'un événement passé, pour les listes.
String formatListTime(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return DateFormat.Hm('fr').format(t);
  if (diff == 1) return 'Hier';
  if (diff < 7) return _cap(DateFormat.EEEE('fr').format(t));
  return DateFormat('d MMM', 'fr').format(t);
}

/// « Mardi 12 novembre à 14:00 ».
String formatLongDateTime(DateTime t) =>
    _cap('${DateFormat('EEEE d MMMM', 'fr').format(t)} à ${DateFormat.Hm('fr').format(t)}');

/// « Mar. 12 nov. ».
String formatShortDate(DateTime t) =>
    _cap(DateFormat('EEE d MMM', 'fr').format(t));

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
