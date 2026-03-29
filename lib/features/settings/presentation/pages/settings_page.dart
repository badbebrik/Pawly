import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/providers/session_state_reset.dart';
import '../../../../app/providers/theme_mode_controller.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/models/profile_models.dart';
import '../../../../design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/utils/auth_error_message.dart';
import '../../../auth/presentation/utils/auth_validators.dart';
import '../../../chat/presentation/widgets/chat_app_bar_action.dart';
import '../providers/settings_profile_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _supportedLocales = <String>['ru', 'en'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(settingsProfileControllerProvider);
    final profile = profileState.whenOrNull(data: (state) => state.profile);
    final themeMode = ref.watch(themeModeControllerProvider).asData?.value ??
        ThemeMode.system;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        actions: const <Widget>[
          ChatAppBarAction(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        children: <Widget>[
          profileState.when(
            data: (state) => _ProfileHeader(
              profile: state.profile,
              isUploadingPhoto: state.isUploadingPhoto,
              onAvatarTap: () => _showPhotoActionsSheet(context, ref),
            ),
            loading: _ProfileHeader.loading,
            error: (_, __) => _ProfileHeader.error(
              onRetry: () =>
                  ref.read(settingsProfileControllerProvider.notifier).reload(),
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
          PawlyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Настройки профиля',
                  subtitle: profile == null
                      ? 'Имя и фамилия'
                      : _profileSettingsSubtitle(profile),
                  onTap: profile == null
                      ? () {}
                      : () => _showProfileSettingsSheet(
                            context,
                            profile,
                          ),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: 'Язык приложения',
                  subtitle: _localeLabel(profile?.locale),
                  onTap: profile == null
                      ? () {}
                      : () => _showLanguageSheet(
                            context,
                            profile.locale,
                          ),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Тема приложения',
                  subtitle: _themeModeLabel(themeMode),
                  onTap: () async {
                    final selectedMode = await _showThemeModeSheet(
                      context: context,
                      currentMode: themeMode,
                    );
                    if (selectedMode == null) {
                      return;
                    }

                    await ref
                        .read(themeModeControllerProvider.notifier)
                        .setThemeMode(selectedMode);
                  },
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Безопасность',
                  subtitle: 'Смена пароля',
                  onTap: () => _showSecuritySheet(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
          PawlyButton(
            label: 'Выйти из аккаунта',
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              resetSessionState(ref);
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            variant: PawlyButtonVariant.secondary,
            icon: Icons.logout_rounded,
          ),
        ],
      ),
    );
  }

  static Future<ThemeMode?> _showThemeModeSheet({
    required BuildContext context,
    required ThemeMode currentMode,
  }) {
    return showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: PawlySpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PawlySpacing.lg,
                    PawlySpacing.xs,
                    PawlySpacing.lg,
                    PawlySpacing.sm,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Тема приложения',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                _ThemeModeOption(
                  icon: Icons.brightness_auto_rounded,
                  title: 'Как в системе',
                  mode: ThemeMode.system,
                  currentMode: currentMode,
                ),
                _ThemeModeOption(
                  icon: Icons.light_mode_outlined,
                  title: 'Светлая',
                  mode: ThemeMode.light,
                  currentMode: currentMode,
                ),
                _ThemeModeOption(
                  icon: Icons.dark_mode_outlined,
                  title: 'Темная',
                  mode: ThemeMode.dark,
                  currentMode: currentMode,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'Как в системе',
      ThemeMode.light => 'Светлая',
      ThemeMode.dark => 'Темная',
    };
  }

  static String _profileSettingsSubtitle(ProfileResponse profile) {
    return _ProfileHeader._fullName(
      profile.firstName,
      profile.lastName,
    );
  }

  static String _localeLabel(String? locale) {
    return switch (locale) {
      'en' => 'English',
      _ => 'Русский',
    };
  }

  static Future<void> _showProfileSettingsSheet(
    BuildContext context,
    ProfileResponse profile,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ProfileSettingsSheet(profile: profile),
    );
  }

  static Future<void> _showLanguageSheet(
    BuildContext context,
    String currentLocale,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _LanguageSettingsSheet(
        currentLocale: currentLocale,
        supportedLocales: _supportedLocales,
      ),
    );
  }

  static Future<void> _showPhotoActionsSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(PawlyRadius.xl)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              PawlySpacing.md,
              PawlySpacing.md,
              PawlySpacing.md,
              PawlySpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Выбрать из галереи'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _uploadProfilePhoto(
                        context, ref, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded),
                  title: const Text('Сделать фото'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _uploadProfilePhoto(context, ref, ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _uploadProfilePhoto(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      await ref.read(settingsProfileControllerProvider.notifier).uploadPhoto(
            source,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message.toString()
                  : 'Не удалось установить фото профиля.',
            ),
          ),
        );
      }
    }
  }

  static Future<void> _showSecuritySheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _SecuritySettingsSheet(),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.isUploadingPhoto,
    required this.onAvatarTap,
  })  : title = null,
        subtitle = null,
        trailing = null;

  factory _ProfileHeader.loading() {
    return _ProfileHeader._placeholder(
      title: 'Загрузка профиля',
      subtitle: 'Получаем данные из профиля',
      trailing: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  factory _ProfileHeader.error({required VoidCallback onRetry}) {
    return _ProfileHeader._placeholder(
      title: 'Профиль недоступен',
      subtitle: 'Не удалось загрузить данные пользователя',
      trailing: TextButton(onPressed: onRetry, child: const Text('Повторить')),
    );
  }

  const _ProfileHeader._placeholder({
    required this.title,
    required this.subtitle,
    this.trailing,
  })  : profile = null,
        isUploadingPhoto = false,
        onAvatarTap = null;

  final ProfileResponse? profile;
  final bool isUploadingPhoto;
  final VoidCallback? onAvatarTap;
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  static String _fullName(String? firstName, String? lastName) {
    final parts = <String>[
      if (firstName != null && firstName.trim().isNotEmpty) firstName.trim(),
      if (lastName != null && lastName.trim().isNotEmpty) lastName.trim(),
    ];

    return parts.isEmpty ? 'Профиль Pawly' : parts.join(' ');
  }

  static String _initials(String? firstName, String? lastName) {
    final buffer = StringBuffer();
    if (firstName != null && firstName.trim().isNotEmpty) {
      buffer.write(firstName.trim().characters.first.toUpperCase());
    }
    if (lastName != null && lastName.trim().isNotEmpty) {
      buffer.write(lastName.trim().characters.first.toUpperCase());
    }

    return buffer.isEmpty ? 'P' : buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedProfile = profile;
    final resolvedTitle = resolvedProfile == null
        ? title ?? 'Профиль Pawly'
        : _fullName(resolvedProfile.firstName, resolvedProfile.lastName);
    final resolvedSubtitle = subtitle;
    final initials = resolvedProfile == null
        ? 'P'
        : _initials(resolvedProfile.firstName, resolvedProfile.lastName);

    return PawlyCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              GestureDetector(
                onTap: onAvatarTap,
                child: _ProfileAvatar(
                  photoUrl: resolvedProfile?.avatarDownloadUrl,
                  initials: initials,
                ),
              ),
              if (resolvedProfile != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              if (isUploadingPhoto)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: PawlySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(resolvedTitle, style: theme.textTheme.titleLarge),
                if (resolvedSubtitle != null &&
                    resolvedSubtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: PawlySpacing.xxxs),
                  Text(
                    resolvedSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: PawlySpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.photoUrl,
    required this.initials,
  }) : size = 76;

  final String? photoUrl;
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final resolvedPhotoUrl = hasPhoto ? _normalizeStorageUrl(photoUrl!) : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.onSurface, width: 2),
        color: colorScheme.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? CachedNetworkImage(
              imageUrl: resolvedPhotoUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _ProfileAvatarFallback(
                initials: initials,
              ),
            )
          : _ProfileAvatarFallback(initials: initials),
    );
  }

  String _normalizeStorageUrl(String url) {
    final uri = Uri.tryParse(url);
    final apiUri = Uri.tryParse(ApiConstants.baseUrl);
    if (uri == null || apiUri == null || uri.host != 'minio') {
      return url;
    }

    return uri.replace(host: apiUri.host).toString();
  }
}

class _ProfileAvatarFallback extends StatelessWidget {
  const _ProfileAvatarFallback({
    required this.initials,
  });

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: PawlySpacing.md,
        vertical: PawlySpacing.xxs,
      ),
      leading: Icon(icon),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.icon,
    required this.title,
    required this.mode,
    required this.currentMode,
  });

  final IconData icon;
  final String title;
  final ThemeMode mode;
  final ThemeMode currentMode;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: currentMode == mode
          ? Icon(
              Icons.check_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () => Navigator.of(context).pop(mode),
    );
  }
}

class _ProfileSettingsSheet extends ConsumerStatefulWidget {
  const _ProfileSettingsSheet({
    required this.profile,
  });

  final ProfileResponse profile;

  @override
  ConsumerState<_ProfileSettingsSheet> createState() =>
      _ProfileSettingsSheetState();
}

class _ProfileSettingsSheetState extends ConsumerState<_ProfileSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.profile.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.profile.lastName ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          PawlySpacing.lg,
          PawlySpacing.sm,
          PawlySpacing.lg,
          PawlySpacing.lg + viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Профиль',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyTextField(
                  controller: _firstNameController,
                  label: 'Имя',
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyTextField(
                  controller: _lastNameController,
                  label: 'Фамилия',
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: PawlySpacing.lg),
                PawlyButton(
                  label: _isSaving ? 'Сохраняем...' : 'Сохранить',
                  onPressed: _isSaving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    final isNameChanged =
        firstName != (widget.profile.firstName ?? '').trim() ||
            lastName != (widget.profile.lastName ?? '').trim();

    if (!isNameChanged) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final controller = ref.read(settingsProfileControllerProvider.notifier);
      await controller.updateName(
        firstName: firstName,
        lastName: lastName,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить настройки профиля.'),
        ),
      );
    }
  }
}

class _LanguageSettingsSheet extends ConsumerStatefulWidget {
  const _LanguageSettingsSheet({
    required this.currentLocale,
    required this.supportedLocales,
  });

  final String currentLocale;
  final List<String> supportedLocales;

  @override
  ConsumerState<_LanguageSettingsSheet> createState() =>
      _LanguageSettingsSheetState();
}

class _LanguageSettingsSheetState extends ConsumerState<_LanguageSettingsSheet> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: PawlySpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PawlySpacing.lg,
                PawlySpacing.xs,
                PawlySpacing.lg,
                PawlySpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Язык приложения',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            for (final locale in widget.supportedLocales)
              _LanguageOption(
                locale: locale,
                title: SettingsPage._localeLabel(locale),
                currentLocale: widget.currentLocale,
                enabled: !_isSaving,
                onTap: () => _selectLocale(locale),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectLocale(String locale) async {
    if (_isSaving || locale == widget.currentLocale) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(settingsProfileControllerProvider.notifier)
          .updatePreferences(locale: locale);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сменить язык приложения.')),
      );
    }
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.locale,
    required this.title,
    required this.currentLocale,
    required this.enabled,
    required this.onTap,
  });

  final String locale;
  final String title;
  final String currentLocale;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      leading: const Icon(Icons.language_rounded),
      title: Text(title),
      trailing: currentLocale == locale
          ? Icon(
              Icons.check_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _SecuritySettingsSheet extends ConsumerStatefulWidget {
  const _SecuritySettingsSheet();

  @override
  ConsumerState<_SecuritySettingsSheet> createState() =>
      _SecuritySettingsSheetState();
}

class _SecuritySettingsSheetState
    extends ConsumerState<_SecuritySettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          PawlySpacing.lg,
          PawlySpacing.sm,
          PawlySpacing.lg,
          PawlySpacing.lg + viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Безопасность',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: PawlySpacing.xxxs),
                Text(
                  'После смены пароля потребуется войти заново.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyTextField(
                  controller: _oldPasswordController,
                  label: 'Текущий пароль',
                  obscureText: !_oldPasswordVisible,
                  enabled: !_isSubmitting,
                  validator: AuthValidators.password,
                  suffixIcon: IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                              _oldPasswordVisible = !_oldPasswordVisible;
                            }),
                    icon: Icon(
                      _oldPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyTextField(
                  controller: _newPasswordController,
                  label: 'Новый пароль',
                  obscureText: !_newPasswordVisible,
                  enabled: !_isSubmitting,
                  validator: (value) {
                    final base = AuthValidators.password(value);
                    if (base != null) {
                      return base;
                    }
                    if ((value ?? '') == _oldPasswordController.text) {
                      return 'Новый пароль должен отличаться от текущего.';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                              _newPasswordVisible = !_newPasswordVisible;
                            }),
                    icon: Icon(
                      _newPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyTextField(
                  controller: _confirmPasswordController,
                  label: 'Повторите новый пароль',
                  obscureText: !_confirmPasswordVisible,
                  enabled: !_isSubmitting,
                  validator: (value) => AuthValidators.confirmPassword(
                    value,
                    _newPasswordController.text,
                  ),
                  suffixIcon: IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                              _confirmPasswordVisible =
                                  !_confirmPasswordVisible;
                            }),
                    icon: Icon(
                      _confirmPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: PawlySpacing.lg),
                PawlyButton(
                  label: _isSubmitting ? 'Сохраняем...' : 'Сменить пароль',
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(authRepositoryProvider).changePassword(
            oldPassword: _oldPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) {
        return;
      }
      resetSessionState(ref);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пароль изменен. Войдите в аккаунт снова.'),
        ),
      );
      context.go(AppRoutes.login);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
      final message = authErrorMessage(error) ?? 'Не удалось сменить пароль.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
