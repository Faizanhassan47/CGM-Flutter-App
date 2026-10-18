import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pill_button.dart';

class FamilyCircleScreen extends StatefulWidget {
  const FamilyCircleScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<FamilyCircleScreen> createState() => _FamilyCircleScreenState();
}

class _FamilyCircleScreenState extends State<FamilyCircleScreen> {
  final inviteCodeController = TextEditingController();
  final familyNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.loadUserProfile();
    widget.controller.loadFamily();
  }

  @override
  void dispose() {
    inviteCodeController.dispose();
    familyNameController.dispose();
    super.dispose();
  }

  void _onJoin() async {
    final code = inviteCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an invite code.')),
      );
      return;
    }

    try {
      await widget.controller.joinFamily(code);
      if (mounted) {
        inviteCodeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined family circle successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to join: $e')));
    }
  }

  void _onCreate() async {
    try {
      await widget.controller.createFamily();
      if (mounted) {
        familyNameController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family circle created successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = '$e'.replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create circle: $msg')));
    }
  }

  void _onDeleteFamily() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Family Circle'),
        content: const Text(
          'Are you sure you want to permanently delete this family circle? All members will be disconnected and sharing will be stopped immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text(
              'Delete Circle',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.controller.deleteFamily();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Family circle successfully deleted.'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = '$e'.replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete family: $msg')));
    }
  }

  void _onLeave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Family Circle'),
        content: const Text(
          'Are you sure you want to leave this circle? You will stop sharing glucose data and alerts with members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.controller.leaveFamily();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Left family circle.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to leave: $e')));
    }
  }

  void _onEditThresholds() async {
    final f = widget.controller.family;
    final currentLow =
        (f?['LowGlucoseThreshold'] ?? f?['lowGlucoseThreshold'] ?? 70.0)
            .toString();
    final currentHigh =
        (f?['HighGlucoseThreshold'] ?? f?['highGlucoseThreshold'] ?? 180.0)
            .toString();

    final lowCtrl = TextEditingController(text: currentLow);
    final highCtrl = TextEditingController(text: currentHigh);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.r20),
        title: Row(
          children: const [
            Icon(Icons.tune_rounded, color: AppTheme.primaryPurple),
            SizedBox(width: 10),
            Text(
              'Circle Alert Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkPurple,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set dynamic low and high glucose limits. Circle admins and caregivers will receive alerts when a member goes out of range.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: lowCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Low Alert Threshold (mg/dL)',
                labelStyle: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.dangerRed,
                ),
                prefixIcon: const Icon(
                  Icons.arrow_downward,
                  color: AppTheme.dangerRed,
                  size: 20,
                ),
                filled: true,
                fillColor: AppPalette.hexFFFFF5F5,
                border: OutlineInputBorder(
                  borderRadius: AppRadii.r12,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: highCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'High Alert Threshold (mg/dL)',
                labelStyle: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.warningOrange,
                ),
                prefixIcon: const Icon(
                  Icons.arrow_upward,
                  color: AppTheme.warningOrange,
                  size: 20,
                ),
                filled: true,
                fillColor: AppPalette.hexFFFFF9F0,
                border: OutlineInputBorder(
                  borderRadius: AppRadii.r12,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.r12),
            ),
            child: const Text('Save Alert Range'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final low = double.tryParse(lowCtrl.text.trim());
      final high = double.tryParse(highCtrl.text.trim());
      try {
        await widget.controller.updateFamilyThresholds(
          lowThreshold: low,
          highThreshold: high,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alert thresholds updated successfully!'),
              backgroundColor: AppTheme.primaryPurple,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update thresholds: $e')),
        );
      }
    }
  }

  void _onViewMemberReport(Map<String, dynamic> member) async {
    final memberUserId = member['userId'] ?? member['UserId'];
    if (memberUserId == null) return;
    final name = member['fullName']?.toString() ?? 'Member';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: FutureBuilder<Map<String, dynamic>>(
            future: widget.controller.getFamilyMemberReport(
              int.parse('$memberUserId'),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 250,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return SizedBox(
                  height: 220,
                  child: Center(
                    child: Text(
                      'Could not load report for $name.\n${snapshot.error ?? ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.dangerRed),
                    ),
                  ),
                );
              }

              final rep = snapshot.data!;
              final readingCount = rep['readingCount'] ?? 0;
              final avgGlucose = rep['averageGlucose']?.toString() ?? '--';
              final tir = rep['timeInRangePercentage']?.toString() ?? '--';
              final readings = (rep['readings'] as List?) ?? [];

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$name\'s Glucose Report',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkPurple,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Past 7-day summary & readings',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: AppInsets.all14,
                          decoration: BoxDecoration(
                            color: AppPalette.hexFFF7F4FB,
                            borderRadius: AppRadii.r14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Avg Glucose',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$avgGlucose mg/dL',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: AppInsets.all14,
                          decoration: BoxDecoration(
                            color: AppPalette.hexFFF1FBF4,
                            borderRadius: AppRadii.r14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Time in Range',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$tir%',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: AppInsets.all14,
                          decoration: BoxDecoration(
                            color: AppPalette.hexFFF0F7FF,
                            borderRadius: AppRadii.r14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Readings',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$readingCount',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.hexFF0077B6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Recent Measurement History',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (readings.isEmpty)
                    Container(
                      padding: AppInsets.all20,
                      alignment: Alignment.center,
                      child: const Text(
                        'No recent readings found for this member.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  else
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        itemCount: readings.length > 15 ? 15 : readings.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (c, idx) {
                          final r = readings[readings.length - 1 - idx];
                          final val = r['GlucoseValue'] ?? r['glucoseValue'];
                          final time =
                              (r['MeasurementTime'] ?? r['measurementTime'])
                                  ?.toString()
                                  .split('T')
                                  .last
                                  .split('.')
                                  .first ??
                              '';
                          final date =
                              (r['MeasurementTime'] ?? r['measurementTime'])
                                  ?.toString()
                                  .split('T')
                                  .first ??
                              '';
                          final numVal = double.tryParse('$val') ?? 0;
                          final isHigh = numVal > 180;
                          final isLow = numVal < 70;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$date  $time',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '$val mg/dL',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isHigh
                                            ? AppTheme.warningOrange
                                            : isLow
                                            ? AppTheme.dangerRed
                                            : AppTheme.successGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      isHigh
                                          ? Icons.arrow_upward
                                          : isLow
                                          ? Icons.arrow_downward
                                          : Icons.check_circle_outline,
                                      size: 15,
                                      color: isHigh
                                          ? AppTheme.warningOrange
                                          : isLow
                                          ? AppTheme.dangerRed
                                          : AppTheme.successGreen,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _onToggleMemberAlerts(Map<String, dynamic> member, bool enable) async {
    final memberUserId = member['userId'] ?? member['UserId'];
    if (memberUserId == null) return;
    try {
      await widget.controller.setFamilyMemberAlerts(
        int.parse('$memberUserId'),
        enable,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enable
                  ? 'Enabled notifications for member.'
                  : 'Muted notifications for member.',
            ),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update alert: $e')));
    }
  }

  void _onRemoveMember(Map<String, dynamic> member) async {
    final memberUserId = member['userId'] ?? member['UserId'];
    if (memberUserId == null) return;
    final name = member['fullName']?.toString() ?? 'member';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $name?'),
        content: Text(
          'Are you sure you want to remove $name from your family circle?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text(
              'Remove',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.controller.removeFamilyMember(int.parse('$memberUserId'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name was removed from the family circle.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final hasFamily = widget.controller.family != null;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: Container(
              margin: AppInsets.all8,
              decoration: const BoxDecoration(
                color: AppPalette.hexFFF6F3FA,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.darkPurple,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            title: Column(
              children: const [
                Text(
                  'Family circle',
                  style: TextStyle(
                    color: AppTheme.darkPurple,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'People you trust',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.darkPurple),
                onPressed: widget.controller.loading
                    ? null
                    : widget.controller.loadFamily,
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: hasFamily
                  ? _buildActiveFamilyView()
                  : _buildSetupFamilyView(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveFamilyView() {
    final members = widget.controller.familyMembers;
    final f = widget.controller.family;
    String inviteCode = widget.controller.referralCode.trim();
    if (inviteCode.isEmpty && f != null) {
      inviteCode = (f['referralCode'] ?? f['ReferralCode'] ?? '')
          .toString()
          .trim();
    }
    if (inviteCode.isEmpty) {
      inviteCode =
          'CIRCLE-${widget.controller.userEmail.split('@').first.toUpperCase()}';
    }

    final currentUserEmail = widget.controller.userEmail.trim().toLowerCase();
    final isUserAdminOrOwner =
        members.any((m) {
          if (m is Map<String, dynamic>) {
            final email = (m['email'] ?? '').toString().trim().toLowerCase();
            final role = (m['role'] ?? '').toString().trim().toLowerCase();
            return email == currentUserEmail &&
                (role == 'owner' || role == 'admin');
          }
          return false;
        }) ||
        (f != null && (f['OwnerUserId'] != null || f['ownerUserId'] != null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        // Circle Banner Card
        Container(
          padding: AppInsets.all20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppPalette.hexFF673AB7, AppPalette.hexFF9C27B0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadii.r22,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPurple.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.2),
                      borderRadius: AppRadii.r12,
                    ),
                    child: const Text(
                      'ACTIVE CIRCLE',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.family_restroom,
                    color: AppColors.surface,
                    size: 26,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Private Caregiver Circle',
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${members.length} member${members.length == 1 ? '' : 's'} sharing alerts & readings',
                style: const TextStyle(color: AppColors.white70, fontSize: 13),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Invite Code Card
        Container(
          padding: AppInsets.all18,
          decoration: BoxDecoration(
            color: AppPalette.hexFFFBF9FD,
            borderRadius: AppRadii.r18,
            border: Border.all(color: AppPalette.hexFFECE6F5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invite Code',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        inviteCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.darkPurple,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Invite code "$inviteCode" copied to clipboard!',
                          ),
                          backgroundColor: AppTheme.primaryPurple,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      foregroundColor: AppColors.surface,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: AppRadii.r10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Share this code with caregivers or family members so they can join your circle.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),

        const SizedBox(height: 26),

        // Members Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Circle Members',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkPurple,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightPurpleBg,
                    borderRadius: AppRadii.r10,
                  ),
                  child: Text(
                    '${members.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
            if (isUserAdminOrOwner)
              TextButton.icon(
                onPressed: _onEditThresholds,
                icon: const Icon(
                  Icons.notifications_active_outlined,
                  size: 16,
                  color: AppTheme.primaryPurple,
                ),
                label: const Text(
                  'Set Alerts',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppPalette.hexFFF3EDF9,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: AppRadii.r10),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        if (members.isEmpty)
          Container(
            padding: AppInsets.all24,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.r16,
              border: Border.all(color: AppPalette.hexFFF0ECF8),
            ),
            child: const Center(
              child: Text(
                'No other members in this circle yet.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final m = members[i] as Map<String, dynamic>;
              final name = m['fullName']?.toString() ?? 'Member';
              final email = m['email']?.toString() ?? '';
              final role = m['role']?.toString() ?? 'Member';
              final isOwner = role.toLowerCase() == 'owner';
              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

              // Enriched Telemetry
              final currentGlucose = m['currentGlucose'];
              final sensorExpiresAt = m['sensorExpiresAt']?.toString();
              final batteryPct = m['batteryPercentage'];
              final batteryMv = m['batteryVoltageMv'];
              final receiveAlerts =
                  m['receiveAlerts'] == true || m['receiveAlerts'] == 1;

              String expiryDisplay = 'No active sensor';
              if (sensorExpiresAt != null && sensorExpiresAt.isNotEmpty) {
                try {
                  final expDate = DateTime.parse(sensorExpiresAt).toLocal();
                  final diff = expDate.difference(DateTime.now());
                  if (diff.isNegative) {
                    expiryDisplay = 'Sensor Expired';
                  } else if (diff.inDays > 0) {
                    expiryDisplay = 'Sensor: ${diff.inDays}d left';
                  } else {
                    expiryDisplay = 'Sensor: ${diff.inHours}h left';
                  }
                } catch (_) {
                  expiryDisplay = 'Sensor Active';
                }
              }

              String batteryDisplay = '--';
              if (batteryPct != null) {
                batteryDisplay = '${batteryPct.toString()}%';
              } else if (batteryMv != null) {
                batteryDisplay = '${batteryMv}mV';
              }

              return Container(
                padding: AppInsets.all16,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.r18,
                  border: Border.all(color: AppPalette.hexFFECEAF4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isOwner
                              ? AppTheme.primaryPurple
                              : AppPalette.hexFFE0F7FD,
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: isOwner
                                  ? AppColors.surface
                                  : AppPalette.hexFF00B2E2,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.darkPurple,
                                ),
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOwner
                                ? AppPalette.hexFFF3EDF9
                                : AppPalette.hexFFE8F5E9,
                            borderRadius: AppRadii.r8,
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isOwner
                                  ? AppTheme.primaryPurple
                                  : AppTheme.successGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppPalette.hexFFF1EEF6),
                    const SizedBox(height: 12),

                    // Live Sensor and Glucose Status Grid
                    Row(
                      children: [
                        // Current Reading
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.hexFFFAF8FE,
                              borderRadius: AppRadii.r12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Glucose',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      currentGlucose != null
                                          ? '$currentGlucose'
                                          : '--',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: currentGlucose == null
                                            ? AppTheme.textMuted
                                            : ((currentGlucose as num) > 180
                                                  ? AppTheme.warningOrange
                                                  : ((currentGlucose
                                                                as dynamic) <
                                                            70
                                                        ? AppTheme.dangerRed
                                                        : AppTheme
                                                              .successGreen)),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'mg/dL',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Sensor Expiry
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.hexFFF0FDF4,
                              borderRadius: AppRadii.r12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sensor Lifespan',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      size: 14,
                                      color: AppTheme.successGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        expiryDisplay,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.darkPurple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Battery
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.hexFFF3F7FF,
                              borderRadius: AppRadii.r12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sensor Battery',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.battery_charging_full_rounded,
                                      size: 14,
                                      color: AppPalette.hexFF0077B6,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      batteryDisplay,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.darkPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Actions Row: View Report, Alerts Toggle (Admin), Remove (Admin)
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _onViewMemberReport(m),
                          icon: const Icon(
                            Icons.analytics_outlined,
                            size: 15,
                            color: AppTheme.primaryPurple,
                          ),
                          label: const Text(
                            'View Report',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryPurple,
                            side: const BorderSide(
                              color: AppPalette.hexFFDDD2F0,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadii.r10,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (isUserAdminOrOwner && !isOwner) ...[
                          IconButton(
                            icon: Icon(
                              receiveAlerts
                                  ? Icons.notifications_active
                                  : Icons.notifications_off_outlined,
                              color: receiveAlerts
                                  ? AppTheme.primaryPurple
                                  : AppTheme.textMuted,
                              size: 20,
                            ),
                            tooltip: receiveAlerts
                                ? 'Alerts active (tap to mute)'
                                : 'Alerts muted (tap to enable)',
                            onPressed: () =>
                                _onToggleMemberAlerts(m, !receiveAlerts),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.person_remove_outlined,
                              color: AppTheme.dangerRed,
                              size: 20,
                            ),
                            tooltip: 'Remove member',
                            onPressed: () => _onRemoveMember(m),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

        const SizedBox(height: 36),

        // Owner/Admin can delete family circle; Members can leave
        if (isUserAdminOrOwner) ...[
          OutlinedButton.icon(
            onPressed: widget.controller.loading ? null : _onDeleteFamily,
            icon: const Icon(
              Icons.delete_outline,
              color: AppTheme.dangerRed,
              size: 19,
            ),
            label: const Text(
              'Delete Family Circle',
              style: TextStyle(
                color: AppTheme.dangerRed,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppPalette.hexFFFBD0D0, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: AppRadii.r16),
              backgroundColor: AppPalette.hexFFFFF5F5,
            ),
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: widget.controller.loading ? null : _onLeave,
            icon: const Icon(
              Icons.exit_to_app,
              color: AppTheme.dangerRed,
              size: 18,
            ),
            label: const Text(
              'Leave Family Circle',
              style: TextStyle(
                color: AppTheme.dangerRed,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppPalette.hexFFFBD0D0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: AppRadii.r16),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSetupFamilyView() {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Group icon illustration
        Container(
          width: 74,
          height: 74,
          decoration: const BoxDecoration(
            color: AppPalette.hexFFF3EDF9,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.group_rounded,
            color: AppTheme.primaryPurple,
            size: 38,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Stay connected',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkPurple,
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Create a private circle for your family, or use an invite code to join one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Card 1: Join a circle
        Container(
          padding: AppInsets.all20,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.r22,
            border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: AppInsets.all8,
                    decoration: BoxDecoration(
                      color: AppPalette.hexFFE0F7FD,
                      borderRadius: AppRadii.r12,
                    ),
                    child: const Icon(
                      Icons.handshake_outlined,
                      color: AppPalette.hexFF00B2E2,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Join a circle',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkPurple,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ask the owner for their invite code',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomUnderlineField(
                controller: inviteCodeController,
                label: '',
                hintText: 'Enter invite code',
              ),
              const SizedBox(height: 20),
              PillButton(
                variant: PillButtonVariant.cyan,
                text: 'Join family',
                loading: widget.controller.loading,
                onPressed: _onJoin,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Row(
          children: const [
            Expanded(child: Divider(color: AppPalette.hexFFECEAF4)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'or start your own',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
              ),
            ),
            Expanded(child: Divider(color: AppPalette.hexFFECEAF4)),
          ],
        ),
        const SizedBox(height: 24),

        // Card 2: Create a circle
        Container(
          padding: AppInsets.all20,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.r22,
            border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: AppInsets.all8,
                    decoration: BoxDecoration(
                      color: AppTheme.lightPurpleBg,
                      borderRadius: AppRadii.r12,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppTheme.primaryPurple,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Create a circle',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkPurple,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'You manage members and alert settings',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomUnderlineField(
                controller: familyNameController,
                label: '',
                hintText: 'Family name',
              ),
              const SizedBox(height: 20),
              PillButton(
                variant: PillButtonVariant.purple,
                text: 'Create family',
                loading: widget.controller.loading,
                onPressed: _onCreate,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
