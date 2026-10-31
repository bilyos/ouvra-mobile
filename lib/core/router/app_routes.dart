/// Chemins de navigation centralisés.
abstract final class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const roleSelection = '/role';
  static const becomeProvider = '/become-provider';
  static const myProviderProfile = '/my-provider-profile';

  // Onglets
  static const home = '/home';
  static const search = '/search';
  static const bookings = '/bookings';
  static const chats = '/chats';
  static const profile = '/profile';

  static const map = '/map';
  static const settings = '/settings';
  static const allCategories = '/categories';
  static const notifications = '/notifications';

  /// Fil de demandes : le client décrit son problème (photo, vocal, texte).
  static const newRequest = '/requests/new';

  /// Les demandes publiées par le client.
  static const myRequests = '/requests';

  /// Fil de demandes côté prestataire : les demandes autour de lui.
  static const requestFeed = '/requests/feed';

  /// Les devis envoyés par le prestataire.
  static const myQuotes = '/quotes';

  /// Détail d'une demande — `/requests/:id` (vue client ou prestataire).
  static String request(String id) => '/requests/$id';

  /// Détail prestataire — `/provider/:id`.
  static String providerDetail(String id) => '/provider/$id';

  /// Réserver un prestataire — `/provider/:id/book`.
  static String bookProvider(String id) => '/provider/$id/book';

  /// Détail d'une réservation — `/booking/:id`.
  static String booking(String id) => '/booking/$id';

  /// Conversation — `/chat/:id`.
  static String chat(String id) => '/chat/$id';
}
