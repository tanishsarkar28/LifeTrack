import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../services/supabase_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

final syncLoadingProvider = NotifierProvider<SyncLoadingNotifier, bool>(() {
  return SyncLoadingNotifier();
});

class SyncLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool loading) {
    state = loading;
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncLoading = ref.watch(syncLoadingProvider);
    final profile = ref.watch(userProfileProvider);
    final authState = ref.watch(authStateProvider);

    if (profile == null) return const Center(child: CircularProgressIndicator());

    final streak = ref.watch(streakProvider);
    final heightInMeters = profile.height / 100;
    final bmi = profile.weight / (heightInMeters * heightInMeters);
    String category = '';
    Color categoryColor = Colors.white;
    if (bmi < 18.5) {
      category = 'Underweight';
      categoryColor = Colors.blueAccent;
    } else if (bmi < 24.9) {
      category = 'Normal weight';
      categoryColor = Colors.green;
    } else if (bmi < 29.9) {
      category = 'Overweight';
      categoryColor = Colors.orange;
    } else {
      category = 'Obese';
      categoryColor = Colors.red;
    }

    final user = authState.value?.session?.user;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final fullName = user?.userMetadata?['full_name'] as String? ?? user?.userMetadata?['name'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context, ref, profile),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.5)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 10)),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(fullName ?? profile.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('$streak Day Streak', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            // Stats
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  _buildStatRow('Current Weight', '${profile.weight} kg'),
                  const Divider(color: Colors.white10),
                  _buildStatRow('Target Weight', '${profile.targetWeight} kg'),
                  const Divider(color: Colors.white10),
                  _buildStatRow('Height', '${profile.height} cm'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings buttons
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('App Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAppSettingsDialog(context, ref),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  const Text('BMI Calculator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Your Body Mass Index is:', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  Text(
                    bmi.toStringAsFixed(1),
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: categoryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category,
                    style: TextStyle(fontSize: 20, color: categoryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildCloudSyncCard(context, ref, authState.value?.session?.user, isSyncLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCloudSyncCard(BuildContext context, WidgetRef ref, User? user, bool isSyncLoading) {
    final bool isLoggedIn = user != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_sync, color: Colors.blueAccent),
              const SizedBox(width: 10),
              const Text('Cloud Backup & Sync', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (!isLoggedIn) ...[
            const Text('Sign in with Google to securely backup your data so you never lose it.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            if (isSyncLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    ref.read(syncLoadingProvider.notifier).setLoading(true);
                    try {
                      final response = await SupabaseSyncService.instance.signInWithGoogle();
                      if (response != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged in successfully! Downloading data...')));
                        await SupabaseSyncService.instance.restoreDataFromSupabase();
                        if (context.mounted) {
                          ref.invalidate(taskProvider);
                          ref.invalidate(workoutProvider);
                          ref.invalidate(userProfileProvider);
                          ref.invalidate(themeProvider);
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Sign in failed: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ));
                      }
                    } finally {
                      if (context.mounted) {
                        ref.read(syncLoadingProvider.notifier).setLoading(false);
                      }
                    }
                  },
                ),
              ),
          ] else ...[
            Text('Signed in as:\n${user.email}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            if (isSyncLoading) ...[
              const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
              const SizedBox(height: 8),
              const Center(child: Text('Downloading data...', style: TextStyle(color: Colors.blueAccent))),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                     Icon(Icons.check_circle, color: Colors.blueAccent, size: 20),
                     SizedBox(width: 8),
                     Expanded(
                       child: Text(
                         'Your data is automatically synced to the cloud.',
                         style: TextStyle(color: Colors.blueAccent),
                       ),
                     ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => SupabaseSyncService.instance.signOut(),
                child: const Text('Sign out', style: TextStyle(color: Colors.redAccent)),
              )
            ]
          ]
        ],
      ),
    );
  }

  // BMI logic moved inline

  void _showAppSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('App Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: const Text('About LifeTrack'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('About'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'LifeTrack\nVersion 1.0.1\nDeveloped to help you track your fitness and daily tasks.\n',
                            textAlign: TextAlign.center,
                          ),
                          const Text('Developer: Tanish Sarkar', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.linkedin, color: Colors.blueAccent, size: 36),
                                onPressed: () {
                                  launchUrl(Uri.parse('https://www.linkedin.com/in/tanish-sarkar28/'), mode: LaunchMode.externalApplication);
                                },
                              ),
                              const SizedBox(width: 24),
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.github, size: 36),
                                onPressed: () {
                                  launchUrl(Uri.parse('https://github.com/tanishsarkar28'), mode: LaunchMode.externalApplication);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette, color: Colors.purple),
                title: const Text('Change Theme'),
                onTap: () {
                  Navigator.pop(context);
                  _showThemePicker(context, ref);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppThemeType.values.map((type) {
              String label;
              switch (type) {
                case AppThemeType.midnightBlack: label = 'Midnight Black'; break;
                case AppThemeType.forestGreen: label = 'Forest Green'; break;
                case AppThemeType.neonCyberpunk: label = 'Neon Cyberpunk'; break;
                case AppThemeType.darkBlue:
                default: label = 'Dark Blue'; break;
              }
              return ListTile(
                title: Text(label),
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(type);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, dynamic profile) {
    final weightCtrl = TextEditingController(text: profile.weight.toString());
    final targetWeightCtrl = TextEditingController(text: profile.targetWeight.toString());
    final heightCtrl = TextEditingController(text: profile.height.toString());
    DateTime selectedDate = profile.startDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: weightCtrl, decoration: const InputDecoration(labelText: 'Current Weight (kg)'), keyboardType: TextInputType.number),
                    TextField(controller: targetWeightCtrl, decoration: const InputDecoration(labelText: 'Target Weight (kg)'), keyboardType: TextInputType.number),
                    TextField(controller: heightCtrl, decoration: const InputDecoration(labelText: 'Height (cm)'), keyboardType: TextInputType.number),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    ref.read(userProfileProvider.notifier).saveProfile(
                      name: profile.name,
                      height: double.tryParse(heightCtrl.text) ?? profile.height,
                      weight: double.tryParse(weightCtrl.text) ?? profile.weight,
                      targetWeight: double.tryParse(targetWeightCtrl.text) ?? profile.targetWeight,
                      startDate: selectedDate,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                )
              ],
            );
          }
        );
      },
    );
  }
}
