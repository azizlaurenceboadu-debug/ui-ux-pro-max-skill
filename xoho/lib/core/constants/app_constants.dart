class AppConstants {
  AppConstants._();

  // App
  static const String appName = 'Xoho';
  static const String appTagline = 'Connecter les besoins et les envois';

  // Unlock fee
  static const int unlockFeeXof = 100;
  static const double commissionRate = 0.10;
  static const int insuranceBasicXof = 200;
  static const int insurancePremiumXof = 500;

  // Cities (Bénin)
  static const List<String> beninCities = [
    'Cotonou',
    'Porto-Novo',
    'Parakou',
    'Abomey-Calavi',
    'Bohicon',
    'Natitingou',
    'Kandi',
    'Djougou',
    'Ouidah',
    'Lokossa',
    'Savè',
    'Abomey',
    'Malanville',
    'Tchaourou',
    'Nikki',
  ];

  // Map defaults – center of Cotonou
  static const double defaultLat = 6.3654;
  static const double defaultLng = 2.4183;
  static const double defaultZoom = 13.5;

  // Shipment status labels
  static const Map<String, String> statusLabels = {
    'pending': 'En attente',
    'accepted': 'Accepté',
    'picked_up': 'Pris en charge',
    'in_transit': 'En route',
    'delivered': 'Livré',
    'cancelled': 'Annulé',
    'disputed': 'Litige',
  };

  // Pricing
  static const double pricePerKmUrban = 50.0;
  static const double pricePerKmInterurban = 35.0;
  static const double minDeliveryPrice = 500.0;

  // Timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration locationTimeout = Duration(seconds: 10);

  // Pagination
  static const int pageSize = 20;

  // Rating system "Gbê"
  static const int minRatingForBadge = 4;
  static const int maxCancellationsBeforePenalty = 3;
  static const double minDriverRating = 3.0;
}
