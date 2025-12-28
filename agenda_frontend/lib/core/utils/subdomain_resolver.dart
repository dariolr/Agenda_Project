/// Utility per risolvere il business slug dall'URL corrente.
///
/// Pattern supportati (in ordine di priorità):
/// 1. Sottodominio: {slug}.prenota.tuodominio.it → "slug"
/// 2. Path-based: prenota.tuodominio.it/{slug} → "slug"
/// 3. Query param: prenota.tuodominio.it?business={slug} → "slug"
///
/// Esempio: salonemario.prenota.romeolab.it → "salonemario"
/// Esempio: prenota.romeolab.it/salonemario → "salonemario"
class SubdomainResolver {
  /// Pattern regex per estrarre lo slug dal sottodominio.
  /// Supporta: {slug}.prenota.{domain} o {slug}.{domain}
  static final RegExp _subdomainPattern = RegExp(
    r'^([a-z0-9][a-z0-9-]*[a-z0-9]|[a-z0-9])\.(?:prenota\.)?',
    caseSensitive: false,
  );

  /// Pattern per validare lo slug (alfanumerico con trattini)
  static final RegExp _slugPattern = RegExp(
    r'^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$',
  );

  /// Domini da escludere (non sono slug di business)
  static const _excludedSubdomains = {
    'www',
    'api',
    'admin',
    'gestionale',
    'app',
    'staging',
    'dev',
    'test',
    'localhost',
    'prenota',
  };

  /// Path segments da escludere (non sono slug)
  static const _excludedPaths = {
    '',
    'index.html',
    'booking',
    'login',
    'register',
    'privacy',
    'terms',
  };

  /// Estrae lo slug del business dall'URL corrente.
  ///
  /// Prova in ordine:
  /// 1. Sottodominio: salonemario.prenota.romeolab.it
  /// 2. Path: prenota.romeolab.it/salonemario
  /// 3. Query: prenota.romeolab.it?business=salonemario
  ///
  /// Returns: slug del business o null se non trovato
  static String? getBusinessSlug() {
    try {
      // 1. Prova sottodominio
      final subdomainSlug = _getSlugFromSubdomain();
      if (subdomainSlug != null) {
        return subdomainSlug;
      }

      // 2. Prova path-based (primo segmento del path)
      final pathSlug = _getSlugFromPath();
      if (pathSlug != null) {
        return pathSlug;
      }

      // 3. Prova query parameter
      final querySlug = _getSlugFromQuery();
      if (querySlug != null) {
        return querySlug;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Estrae slug dal sottodominio
  static String? _getSlugFromSubdomain() {
    final host = Uri.base.host.toLowerCase();

    // Localhost non ha sottodomini
    if (host.startsWith('localhost') || host.startsWith('127.0.0.1')) {
      return null;
    }

    final match = _subdomainPattern.firstMatch(host);
    if (match == null) {
      return null;
    }

    final slug = match.group(1);
    if (slug == null || _excludedSubdomains.contains(slug)) {
      return null;
    }

    return slug;
  }

  /// Estrae slug dal primo segmento del path
  /// Es: prenota.romeolab.it/salonemario → "salonemario"
  static String? _getSlugFromPath() {
    final pathSegments = Uri.base.pathSegments;
    if (pathSegments.isEmpty) {
      return null;
    }

    final firstSegment = pathSegments.first.toLowerCase();

    // Verifica che sia un slug valido
    if (_excludedPaths.contains(firstSegment)) {
      return null;
    }

    if (!_slugPattern.hasMatch(firstSegment)) {
      return null;
    }

    return firstSegment;
  }

  /// Estrae slug dal query parameter "business" o "b"
  /// Es: prenota.romeolab.it?business=salonemario → "salonemario"
  static String? _getSlugFromQuery() {
    final params = Uri.base.queryParameters;
    final slug = params['business'] ?? params['b'];

    if (slug == null || slug.isEmpty) {
      return null;
    }

    final normalizedSlug = slug.toLowerCase();
    if (!_slugPattern.hasMatch(normalizedSlug)) {
      return null;
    }

    return normalizedSlug;
  }

  /// Verifica se l'URL corrente contiene un business slug.
  static bool isBusinessSubdomain() {
    return getBusinessSlug() != null;
  }

  /// Costruisce l'URL per un business dato il suo slug.
  ///
  /// Usa il formato path-based per compatibilità con hosting standard.
  /// Esempio: buildBusinessUrl("salonemario") → "https://prenota.romeolab.it/salonemario"
  static String buildBusinessUrl(
    String slug, {
    String baseDomain = 'prenota.romeolab.it',
    bool usePathBased = true,
  }) {
    if (usePathBased) {
      return 'https://$baseDomain/$slug';
    }
    // Formato sottodominio (richiede wildcard SSL)
    return 'https://$slug.$baseDomain';
  }

  /// Ritorna la modalità di risoluzione usata per lo slug corrente.
  /// Utile per debug.
  static String? getResolutionMode() {
    if (_getSlugFromSubdomain() != null) return 'subdomain';
    if (_getSlugFromPath() != null) return 'path';
    if (_getSlugFromQuery() != null) return 'query';
    return null;
  }
}
