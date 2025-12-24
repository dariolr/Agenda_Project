import 'package:intl/intl.dart';

/// Localization helpers per le stringhe di seed e duplicazione usate dalla feature Services.
class ServiceSeedTexts {
  const ServiceSeedTexts._();

  static String get categoryBodyName => Intl.message(
        'Trattamenti Corpo',
        name: 'serviceSeedCategoryBodyName',
        desc: 'Nome della categoria di default dedicata ai trattamenti corpo.',
      );

  static String get categoryBodyDescription => Intl.message(
        'Servizi dedicati al benessere del corpo',
        name: 'serviceSeedCategoryBodyDescription',
        desc: 'Descrizione della categoria di default dedicata ai trattamenti corpo.',
      );

  static String get categorySportsName => Intl.message(
        'Trattamenti Sportivi',
        name: 'serviceSeedCategorySportsName',
        desc: 'Nome della categoria di default dedicata ai trattamenti sportivi.',
      );

  static String get categorySportsDescription => Intl.message(
        'Percorsi pensati per atleti e persone attive',
        name: 'serviceSeedCategorySportsDescription',
        desc: 'Descrizione della categoria di default dedicata ai trattamenti sportivi.',
      );

  static String get categoryFaceName => Intl.message(
        'Trattamenti Viso',
        name: 'serviceSeedCategoryFaceName',
        desc: 'Nome della categoria di default dedicata ai trattamenti viso.',
      );

  static String get categoryFaceDescription => Intl.message(
        'Cura estetica e rigenerante per il viso',
        name: 'serviceSeedCategoryFaceDescription',
        desc: 'Descrizione della categoria di default dedicata ai trattamenti viso.',
      );

  static String get serviceRelaxName => Intl.message(
        'Massaggio Relax',
        name: 'serviceSeedServiceRelaxName',
        desc: 'Nome del servizio di massaggio relax iniziale.',
      );

  static String get serviceRelaxDescription => Intl.message(
        'Trattamento rilassante da 30 minuti',
        name: 'serviceSeedServiceRelaxDescription',
        desc: 'Descrizione del servizio di massaggio relax iniziale.',
      );

  static String get serviceSportName => Intl.message(
        'Massaggio Sportivo',
        name: 'serviceSeedServiceSportName',
        desc: 'Nome del servizio di massaggio sportivo iniziale.',
      );

  static String get serviceSportDescription => Intl.message(
        'Trattamento decontratturante intensivo',
        name: 'serviceSeedServiceSportDescription',
        desc: 'Descrizione del servizio di massaggio sportivo iniziale.',
      );

  static String get serviceFaceName => Intl.message(
        'Trattamento Viso',
        name: 'serviceSeedServiceFaceName',
        desc: 'Nome del servizio per il viso iniziale.',
      );

  static String get serviceFaceDescription => Intl.message(
        'Pulizia e trattamento illuminante',
        name: 'serviceSeedServiceFaceDescription',
        desc: 'Descrizione del servizio per il viso iniziale.',
      );

  static String get duplicateCopyWord => Intl.message(
        'Copia',
        name: 'serviceDuplicateCopyWord',
        desc:
            'Parola usata per nominare servizi duplicati (es. "Servizio Copia" o "Servizio Copia 2").',
      );
}
