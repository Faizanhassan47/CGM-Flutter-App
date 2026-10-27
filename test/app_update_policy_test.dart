import 'package:flutter_test/flutter_test.dart';
import 'package:aima_cgm/services/app_update_service.dart';

void main() {
  AppUpdatePolicy policy({
    required int installed,
    required int minimum,
    required int latest,
    bool enabled = true,
  }) => AppUpdateService.evaluateForTesting(
    enabled: enabled,
    installedBuild: installed,
    minimumBuild: minimum,
    latestBuild: latest,
    installedVersion: '4.0.0',
    latestVersion: '4.0.1',
    releaseNotes: '',
    storeUrl: '',
    forceMessage: 'Required',
    optionalMessage: 'Available',
  );

  test('requires update below minimum build', () {
    expect(
      policy(installed: 1, minimum: 2, latest: 2).state,
      UpdateState.mandatoryUpdate,
    );
  });

  test('offers optional update between minimum and latest', () {
    expect(
      policy(installed: 1, minimum: 1, latest: 2).state,
      UpdateState.optionalUpdate,
    );
  });

  test('is current at latest build', () {
    expect(
      policy(installed: 2, minimum: 1, latest: 2).state,
      UpdateState.upToDate,
    );
  });

  test('disabled updates are safe', () {
    expect(
      policy(installed: 1, minimum: 2, latest: 3, enabled: false).state,
      UpdateState.upToDate,
    );
  });

  test('invalid remote policy fails safe', () {
    expect(
      policy(installed: 1, minimum: 5, latest: 2).state,
      UpdateState.upToDate,
    );
    expect(
      policy(installed: 1, minimum: 0, latest: 0).state,
      UpdateState.upToDate,
    );
  });
}
