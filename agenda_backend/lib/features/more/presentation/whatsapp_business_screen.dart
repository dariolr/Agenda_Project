import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '/core/environment/app_environment_config.dart';
import '/core/l10n/l10_extension.dart';
import '/core/models/location.dart';
import '/core/network/api_client.dart';
import '/core/services/whatsapp_embedded_signup_launcher.dart';
import '/core/widgets/app_buttons.dart';
import '/core/widgets/app_switch.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/agenda/providers/business_providers.dart';
import '/features/agenda/providers/location_providers.dart';
import '/features/auth/providers/auth_provider.dart';
import '/features/booking_notifications/providers/whatsapp_integration_provider.dart';
import '/features/more/presentation/widgets/guida_attivazione_whatsapp.dart';

class WhatsappBusinessScreen extends ConsumerStatefulWidget {
  const WhatsappBusinessScreen({super.key});

  @override
  ConsumerState<WhatsappBusinessScreen> createState() =>
      _WhatsappBusinessScreenState();
}

class _WhatsappBusinessScreenState
    extends ConsumerState<WhatsappBusinessScreen> {
  final _embeddedSignupLauncher = WhatsappEmbeddedSignupLauncher();
  final ScrollController _guideScrollController = ScrollController();
  bool _isCompletingEmbeddedSignup = false;
  bool _isUpdatingBusinessMessages = false;
  bool _isForgettingLocalConfig = false;
  int? _lastLoadedBusinessId;
  static final Uri _metaBusinessUri = Uri.parse(
    'https://business.facebook.com/settings',
  );

  @override
  void dispose() {
    _guideScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData(int businessId) async {
    if (businessId <= 0 || _lastLoadedBusinessId == businessId) {
      return;
    }
    _lastLoadedBusinessId = businessId;
    await ref
        .read(whatsappIntegrationProvider.notifier)
        .loadBusinessWhatsappData(businessId);
  }

  Future<void> _completeEmbeddedSignup({
    required int businessId,
    required String code,
    required String state,
    int? sessionInfoVersion,
    String? wabaId,
    String? phoneNumberId,
    String? displayPhoneNumber,
  }) async {
    final l10n = context.l10n;
    final result = await ref
        .read(whatsappIntegrationProvider.notifier)
        .completeEmbeddedSignup(
          businessId: businessId,
          code: code,
          state: state,
          sessionInfoVersion: sessionInfoVersion,
          wabaId: wabaId,
          phoneNumberId: phoneNumberId,
          displayPhoneNumber: displayPhoneNumber,
        );

    if (!mounted) return;
    final hasAutoMappedSingleLocation = result.autoMappedLocationIds.isNotEmpty;
    await FeedbackDialog.showSuccess(
      context,
      title: l10n.whatsappEmbeddedSignupSuccessTitle,
      message: hasAutoMappedSingleLocation
          ? l10n.whatsappEmbeddedSignupSuccessWithMapping
          : l10n.whatsappEmbeddedSignupSuccessMessage,
    );
  }

  Future<void> _startEmbeddedSignupAutomatic() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;
    final l10n = context.l10n;

    try {
      setState(() => _isCompletingEmbeddedSignup = true);
      final state = await ref
          .read(whatsappIntegrationProvider.notifier)
          .createEmbeddedSignupState(businessId);
      if (state.isEmpty) {
        throw StateError(l10n.whatsappEmbeddedSignupStateInvalid);
      }
      final launchResult = await _embeddedSignupLauncher.launch(
        expectedState: state,
      );

      await _completeEmbeddedSignup(
        businessId: businessId,
        code: launchResult.code,
        state: launchResult.state,
        sessionInfoVersion: launchResult.sessionInfoVersion ?? 3,
        wabaId: launchResult.wabaId,
        phoneNumberId: launchResult.phoneNumberId,
        displayPhoneNumber: launchResult.displayPhoneNumber,
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().toLowerCase();
      final isUserCancelled =
          message.contains('popup chiuso') || message.contains('access_denied');
      if (!isUserCancelled) {
        await FeedbackDialog.showError(
          context,
          title: l10n.errorTitle,
          message: _formatEmbeddedSignupError(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompletingEmbeddedSignup = false);
      }
    }
  }

  String _formatEmbeddedSignupError(Object error) {
    if (error is! ApiException) {
      return error.toString();
    }

    final reason = error.reason;
    if (reason == null || reason.trim().isEmpty) {
      return error.message;
    }

    final detail = switch (reason) {
      'meta_app_not_configured' => 'app Meta non configurata sul server',
      'meta_token_not_obtained' => 'token Meta non ottenuto',
      'meta_phone_or_waba_not_accessible' =>
        'account WhatsApp o numero non accessibile con i permessi concessi',
      _ => reason,
    };

    if (error.message.contains(detail)) {
      return error.message;
    }
    return '${error.message}\n\nDettaglio tecnico: $detail';
  }

  String? _buildPublicBookingUrl({
    required String? businessSlug,
    required List<Location> locations,
  }) {
    final slug = businessSlug?.trim();
    if (slug == null || slug.isEmpty) {
      return null;
    }

    final bookableLocations = locations
        .where((location) => location.isActive && location.onlineBookingEnabled)
        .toList();
    if (bookableLocations.isEmpty) {
      return null;
    }

    final baseUri = Uri.parse(_publicBookingBaseUrl());

    return baseUri.replace(pathSegments: <String>[slug, 'booking']).toString();
  }

  String _publicBookingBaseUrl() {
    final webBaseUrl = _configuredWebBaseUrl();
    if (webBaseUrl == null) {
      return 'https://prenota.romeolab.it';
    }

    final webBaseUri = Uri.parse(webBaseUrl);
    final host = webBaseUri.host;

    if (host == 'gestionale.romeolab.it') {
      return 'https://prenota.romeolab.it';
    }
    if (host == 'demo-gestionale.romeolab.it') {
      return 'https://demo-prenota.romeolab.it';
    }
    if (host == 'staging-gestionale.romeolab.it') {
      return 'https://staging-prenota.romeolab.it';
    }

    return 'https://prenota.romeolab.it';
  }

  String? _configuredWebBaseUrl() {
    try {
      return AppEnvironmentConfig.current.webBaseUrl;
    } catch (_) {
      return null;
    }
  }

  Future<void> _setBusinessMessagesEnabled(bool enabled) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;

    final l10n = context.l10n;
    setState(() => _isUpdatingBusinessMessages = true);
    try {
      await ref
          .read(whatsappIntegrationProvider.notifier)
          .updateBusinessMessageSending(
            businessId: businessId,
            enabled: enabled,
          );
    } catch (e) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingBusinessMessages = false);
      }
    }
  }

  Future<void> _forgetLocalConfig(int configId) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0 || configId <= 0) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.whatsappForgetLocalConfigTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.whatsappForgetLocalConfigMessage),
            const SizedBox(height: 16),
            _MetaBusinessDialogLink(uri: _metaBusinessUri),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isForgettingLocalConfig = true);
    try {
      await ref
          .read(whatsappIntegrationProvider.notifier)
          .deleteBusinessWhatsappConfig(
            businessId: businessId,
            configId: configId,
          );
    } catch (e) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isForgettingLocalConfig = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final businessId = ref.watch(currentBusinessIdProvider);
    final business = ref.watch(currentBusinessProvider);
    final locations = ref.watch(locationsProvider);
    final isSuperadmin = ref.watch(
      authProvider.select((state) => state.user?.isSuperadmin ?? false),
    );
    final state = ref.watch(whatsappIntegrationProvider);
    final settings = state.settings;
    final firstConfig = state.configs.isNotEmpty ? state.configs.first : null;
    final displayPhoneNumber = firstConfig?.displayPhoneNumber?.trim();
    final showBusinessMessagesSwitch =
        isSuperadmin || (settings?.messagesEnabled ?? false);

    if (businessId <= 0) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasResolvedBusinessData =
        state.loadedBusinessId == businessId &&
        !state.isLoading &&
        (state.settings != null || state.error != null);

    if (_lastLoadedBusinessId != businessId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadData(businessId);
      });
    }

    if (!hasResolvedBusinessData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 40,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.errorTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () {
                        _lastLoadedBusinessId = null;
                        _loadData(businessId);
                      },
                      child: Text(l10n.actionRetry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (settings != null && !settings.whatsappEnabled) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/whatsapp.svg',
                      width: 42,
                      height: 42,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF25D366),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.whatsappNotEnabledForBusiness,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.whatsappSuperadminMustEnable,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (firstConfig == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              children: [
                Text(
                  l10n.moreWhatsappBusinessTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.moreWhatsappBusinessDescription,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Scrollbar(
                      controller: _guideScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _guideScrollController,
                        padding: const EdgeInsets.all(20),
                        child: GuidaAttivazioneWhatsApp(
                          publicBookingUrl: _buildPublicBookingUrl(
                            businessSlug: business.slug,
                            locations: locations,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 280,
                  child: AppAsyncFilledButton(
                    onPressed: settings?.canOnboard == true
                        ? _startEmbeddedSignupAutomatic
                        : null,
                    isLoading: _isCompletingEmbeddedSignup,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/meta.svg',
                          width: 18,
                          height: 18,
                          colorFilter: ColorFilter.mode(
                            theme.colorScheme.onPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.whatsappConnectMeta),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (firstConfig.isConnectionInvalid || firstConfig.phoneNumberId.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/whatsapp.svg',
                      width: 42,
                      height: 42,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.error,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.whatsappConnectionInvalidTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.whatsappConnectionInvalidMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isSuperadmin &&
                        (firstConfig.lastErrorMessage?.isNotEmpty ??
                            false)) ...[
                      const SizedBox(height: 12),
                      _WhatsappConfigField(
                        label: l10n.whatsappStatusError,
                        value: firstConfig.lastErrorMessage!,
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 280,
                      child: AppAsyncFilledButton(
                        onPressed: settings?.canOnboard == true
                            ? _startEmbeddedSignupAutomatic
                            : null,
                        isLoading: _isCompletingEmbeddedSignup,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        child: Text(l10n.whatsappReconnectMeta),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/whatsapp.svg',
                    width: 42,
                    height: 42,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF25D366),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.whatsappMessagingActiveTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.whatsappMessagingActiveMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (isSuperadmin) ...[
                    if (displayPhoneNumber != null &&
                        displayPhoneNumber.isNotEmpty) ...[
                      _WhatsappConfigField(
                        label: l10n.whatsappFieldDisplayPhoneNumber,
                        value: displayPhoneNumber,
                      ),
                      const SizedBox(height: 8),
                    ],
                    _WhatsappConfigField(
                      label: l10n.whatsappFieldPhoneNumberId,
                      value: firstConfig.phoneNumberId,
                    ),
                    const SizedBox(height: 8),
                    _WhatsappConfigField(
                      label: l10n.whatsappFieldWabaId,
                      value: firstConfig.wabaId,
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (showBusinessMessagesSwitch)
                    _WhatsappBusinessMessagesSwitch(
                      value: settings?.businessMessagesEnabled ?? true,
                      enabled:
                          (settings?.whatsappEnabled ?? false) &&
                          (settings?.messagesEnabled ?? false) &&
                          !_isUpdatingBusinessMessages,
                      isUpdating: _isUpdatingBusinessMessages,
                      onChanged: _setBusinessMessagesEnabled,
                    ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 280,
                    child: AppAsyncFilledButton(
                      onPressed: () => _forgetLocalConfig(firstConfig.id),
                      isLoading: _isForgettingLocalConfig,
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/meta.svg',
                            width: 18,
                            height: 18,
                            colorFilter: ColorFilter.mode(
                              theme.colorScheme.onError,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(l10n.whatsappForgetLocalConfigAction),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WhatsappBusinessMessagesSwitch extends StatelessWidget {
  const _WhatsappBusinessMessagesSwitch({
    required this.value,
    required this.enabled,
    required this.isUpdating,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.mark_chat_read_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.whatsappBusinessMessagesToggleTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value
                      ? l10n.whatsappBusinessMessagesSuperadminEnabled
                      : l10n.whatsappBusinessMessagesSuperadminDisabled,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppSwitch(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}

class _MetaBusinessDialogLink extends StatelessWidget {
  const _MetaBusinessDialogLink({required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final url = uri.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                launchUrl(
                  uri,
                  mode: LaunchMode.platformDefault,
                  webOnlyWindowName: '_blank',
                );
              },
              child: Text(
                url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: l10n.whatsappCopyTechnicalValueTooltip,
            child: IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
              },
              icon: const Icon(Icons.copy_outlined, size: 18),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsappConfigField extends StatelessWidget {
  const _WhatsappConfigField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Tooltip(
                message: l10n.whatsappCopyTechnicalValueTooltip,
                child: IconButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                  },
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
