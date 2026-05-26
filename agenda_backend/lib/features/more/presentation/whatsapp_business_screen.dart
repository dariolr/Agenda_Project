import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '/core/l10n/l10_extension.dart';
import '/core/services/whatsapp_embedded_signup_launcher.dart';
import '/core/widgets/app_buttons.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/agenda/providers/business_providers.dart';
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
  int? _lastLoadedBusinessId;
  Map<String, bool>? _lastGoLiveChecks;

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
    final check = result.goLiveCheck;
    setState(() {
      _lastGoLiveChecks = check == null
          ? null
          : {
              'phone': check.phoneNumberActive,
              'webhook': check.webhookVerified,
              'template': check.templateApproved,
              'optin': check.optInActive,
            };
    });

    final autoMapped = result.autoMappedLocationIds;
    final nextSteps = result.nextSteps.join(', ');
    await FeedbackDialog.showSuccess(
      context,
      title: l10n.whatsappEmbeddedSignupSuccessTitle,
      message: autoMapped.isEmpty
          ? l10n.whatsappEmbeddedSignupSuccessMessage(nextSteps)
          : l10n.whatsappEmbeddedSignupSuccessWithMapping(
              autoMapped.join(', '),
              nextSteps,
            ),
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
      final isUserCancelled = message.contains('popup chiuso');
      if (!isUserCancelled) {
        await FeedbackDialog.showError(
          context,
          title: l10n.errorTitle,
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompletingEmbeddedSignup = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final businessId = ref.watch(currentBusinessIdProvider);
    final state = ref.watch(whatsappIntegrationProvider);
    final settings = state.settings;
    final firstConfig = state.configs.isNotEmpty ? state.configs.first : null;
    final hasConfig = firstConfig != null;

    if (businessId > 0 && _lastLoadedBusinessId != businessId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadData(businessId);
      });
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

    if (!hasConfig) {
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
                        child: const GuidaAttivazioneWhatsApp(),
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
                if (settings != null && !settings.activationAllowed) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.whatsappActivationNotAllowed,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.moreWhatsappBusinessTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.moreWhatsappBusinessDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.whatsappPanelTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${l10n.whatsappFieldPhoneNumberId}: ${firstConfig.phoneNumberId}',
                ),
                if (_lastGoLiveChecks != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${l10n.whatsappGoLiveCheck}: '
                    '${(_lastGoLiveChecks!['phone'] == true && _lastGoLiveChecks!['webhook'] == true && _lastGoLiveChecks!['template'] == true && _lastGoLiveChecks!['optin'] == true) ? l10n.whatsappGoLiveReady : l10n.whatsappGoLiveNotReady}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
