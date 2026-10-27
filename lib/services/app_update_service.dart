import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateState { upToDate, optionalUpdate, mandatoryUpdate, unavailable }

class AppUpdatePolicy {
  const AppUpdatePolicy({
    required this.state,
    required this.installedBuild,
    required this.minimumBuild,
    required this.latestBuild,
    required this.installedVersion,
    required this.latestVersion,
    required this.message,
    required this.releaseNotes,
    required this.storeUrl,
  });
  final UpdateState state;
  final int installedBuild;
  final int minimumBuild;
  final int latestBuild;
  final String installedVersion, latestVersion, message, releaseNotes, storeUrl;
}

class AppUpdateService {
  AppUpdateService._();
  static final instance = AppUpdateService._();
  final _config = FirebaseRemoteConfig.instance;
  bool _optionalShown = false;
  AppUpdatePolicy? _lastPolicy;

  Future<AppUpdatePolicy> check({bool forceFetch = false}) async {
    final info = await PackageInfo.fromPlatform();
    final installed = int.tryParse(info.buildNumber) ?? 0;
    try {
      await _config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: forceFetch
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );
      await _config.setDefaults(const {
        'android_updates_enabled': false,
        'android_min_build': 0,
        'android_latest_build': 0,
        'android_latest_version_name': '',
        'android_force_update_message': '',
        'android_optional_update_message': '',
        'android_store_url': '',
        'android_release_notes': '',
      });
      await _config.fetchAndActivate().timeout(const Duration(seconds: 7));
      debugPrint(
        'Updates enabled: ${_config.getBool('android_updates_enabled')}',
      );
      debugPrint('Minimum build: ${_config.getInt('android_min_build')}');
      debugPrint('Latest build: ${_config.getInt('android_latest_build')}');
      debugPrint(
        'Latest version: ${_config.getString('android_latest_version_name')}',
      );
      debugPrint('Last fetch status: ${_config.lastFetchStatus}');
    } catch (error, stackTrace) {
      debugPrint('Remote Config fetch failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    final enabled = _config.getBool('android_updates_enabled');
    final minimum = _config.getInt('android_min_build');
    final latest = _config.getInt('android_latest_build');
    return _save(
      evaluateForTesting(
        enabled: enabled,
        installedBuild: installed,
        minimumBuild: minimum,
        latestBuild: latest,
        installedVersion: info.version,
        latestVersion: _config.getString('android_latest_version_name'),
        releaseNotes: _config.getString('android_release_notes'),
        storeUrl: _config.getString('android_store_url'),
        forceMessage: _config.getString('android_force_update_message'),
        optionalMessage: _config.getString('android_optional_update_message'),
      ),
    );
  }

  @visibleForTesting
  static AppUpdatePolicy evaluateForTesting({
    required bool enabled,
    required int installedBuild,
    required int minimumBuild,
    required int latestBuild,
    required String installedVersion,
    required String latestVersion,
    required String releaseNotes,
    required String storeUrl,
    required String forceMessage,
    required String optionalMessage,
  }) {
    if (!enabled ||
        minimumBuild < 0 ||
        latestBuild < minimumBuild ||
        latestBuild == 0)
      return AppUpdatePolicy(
        state: UpdateState.upToDate,
        installedBuild: installedBuild,
        minimumBuild: minimumBuild,
        latestBuild: latestBuild,
        installedVersion: installedVersion,
        latestVersion: latestVersion,
        message: '',
        releaseNotes: releaseNotes,
        storeUrl: storeUrl,
      );
    final state = installedBuild < minimumBuild
        ? UpdateState.mandatoryUpdate
        : installedBuild < latestBuild
        ? UpdateState.optionalUpdate
        : UpdateState.upToDate;
    return AppUpdatePolicy(
      state: state,
      installedBuild: installedBuild,
      minimumBuild: minimumBuild,
      latestBuild: latestBuild,
      installedVersion: installedVersion,
      latestVersion: latestVersion,
      message: state == UpdateState.mandatoryUpdate
          ? forceMessage
          : optionalMessage,
      releaseNotes: releaseNotes,
      storeUrl: storeUrl,
    );
  }

  AppUpdatePolicy _save(AppUpdatePolicy value) {
    _lastPolicy = value;
    return value;
  }

  bool get optionalShown => _optionalShown;
  void markOptionalShown() => _optionalShown = true;
  Future<bool> launchUpdate(
    AppUpdatePolicy policy, {
    required bool mandatory,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('In-app update skipped: Android-only Google Play API.');
      return policy.storeUrl.isNotEmpty
          ? launchUrl(
              Uri.parse(policy.storeUrl),
              mode: LaunchMode.externalApplication,
            )
          : false;
    }
    try {
      final availability = await InAppUpdate.checkForUpdate();
      if (availability.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        if (mandatory && availability.immediateUpdateAllowed) {
          final result = await InAppUpdate.performImmediateUpdate();
          return result == AppUpdateResult.success;
        }
        if (!mandatory && availability.flexibleUpdateAllowed) {
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success) {
            await InAppUpdate.completeFlexibleUpdate();
            return true;
          }
          debugPrint('Flexible update did not start successfully: $result');
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Google Play in-app update failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    if (policy.storeUrl.isNotEmpty)
      return launchUrl(
        Uri.parse(policy.storeUrl),
        mode: LaunchMode.externalApplication,
      );
    return false;
  }
}
