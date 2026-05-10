import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nindra/config.dart';

class SleepPredictionFormScreen extends StatefulWidget {
  const SleepPredictionFormScreen({super.key});

  @override
  State<SleepPredictionFormScreen> createState() =>
      _SleepPredictionFormScreenState();
}

class _SleepPredictionFormScreenState extends State<SleepPredictionFormScreen> {
  // ─── Form Controllers ───────────────────────────────
  late TextEditingController heartRateController;
  late TextEditingController dailyStepsController;
  late TextEditingController systolicController;
  late TextEditingController diastolicController;

  // ─── State ─────────────────────────────────────────
  bool _isLoading = false;
  bool _isProfileLoaded = false;
  String? selectedSleepDisorder;
  Map<String, dynamic>? _profile;

  final List<String> sleepDisorders = [
    'None',
    'Insomnia',
    'Sleep Apnea',
    'Restless Leg Syndrome',
    'Narcolepsy',
  ];

  @override
  void initState() {
    super.initState();
    heartRateController = TextEditingController();
    dailyStepsController = TextEditingController();
    systolicController = TextEditingController();
    diastolicController = TextEditingController();
    selectedSleepDisorder = sleepDisorders[0];
    _loadProfile();
  }

  @override
  void dispose() {
    heartRateController.dispose();
    dailyStepsController.dispose();
    systolicController.dispose();
    diastolicController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _isProfileLoaded = false;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Please log in first.');
      }

      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select(
            'gender, age, occupation, bmi_category, sleep_duration, physical_activity_level, stress_level',
          )
          .eq('user_id', userId)
          .single();

      final profile = Map<String, dynamic>.from(profileResponse as Map);
      if (profile.isEmpty) {
        throw Exception('Please complete your profile first.');
      }

      setState(() {
        _profile = profile;
        _isProfileLoaded = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile load error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ─── Form Submission Handler ────────────────────────
  Future<void> _submitForm() async {
    setState(() => _isLoading = true);

    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        throw Exception('Please log in before submitting the prediction form.');
      }

      if (!_isProfileLoaded || _profile == null) {
        throw Exception('Unable to load profile. Please try again.');
      }

      final sleepDuration = (_profile!['sleep_duration'] as num?)?.toDouble();
      final physicalActivity = (_profile!['physical_activity_level'] as num?)
          ?.toInt();
      final stressLevel = (_profile!['stress_level'] as num?)?.toInt();

      if (sleepDuration == null ||
          physicalActivity == null ||
          stressLevel == null) {
        throw Exception(
          'Health metrics are missing from your profile. Update your account settings first.',
        );
      }

      final body = {
        'gender': _profile!['gender'] as String,
        'age': _profile!['age'] as int,
        'occupation': _profile!['occupation'] as String,
        'bmi_category': _profile!['bmi_category'] as String,
        'sleep_duration': sleepDuration,
        'physical_activity_level': physicalActivity,
        'stress_level': stressLevel,
        'systolic': int.parse(systolicController.text.trim()),
        'diastolic': int.parse(diastolicController.text.trim()),
      };

      // Step 4: POST to FastAPI /predict
      final baseUrl = Config.apiBaseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      // Step 5: Handle the response
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;

        // Push latest prediction fields to Supabase profile as well.
        await _updateProfilePredictionFields(result);

        if (mounted) {
          Navigator.pushNamed(context, '/result', arguments: result);
        }
      } else {
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Prediction failed. Please try again. (${response.statusCode})',
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Step 6: Catch and show errors
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      // Always hide loading
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Widget Builders ───────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Sleep Prediction',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFFB06EF3),
            size: 20,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB06EF3)),
              ),
            )
          : !_isProfileLoaded
          ? const Center(
              child: Text(
                'Loading your saved profile...',
                style: TextStyle(color: Colors.white),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252535),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFB06EF3)),
                    ),
                    child: const Text(
                      'We use your saved account health profile for sleep duration, activity, and stress level. Only enter the metrics not stored in your account.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildFormField(
                    label: 'Heart Rate (bpm)',
                    controller: heartRateController,
                    hintText: 'e.g., 77',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: 'Daily Steps',
                    controller: dailyStepsController,
                    hintText: 'e.g., 4200',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildSleepDisorderDropdown(),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: 'Systolic Blood Pressure',
                    controller: systolicController,
                    hintText: 'e.g., 126',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: 'Diastolic Blood Pressure',
                    controller: diastolicController,
                    hintText: 'e.g., 83',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB06EF3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Get Sleep Prediction',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: const Color(0xFF252535),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFB06EF3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFB06EF3)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateProfilePredictionFields(
    Map<String, dynamic> result,
  ) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final updateData = {
        'latest_score': result['sleep_score'],
        'score_band': result['score_band'],
        'sleep_quality': result['sleep_quality'],
        'deep_sleep_pct': result['deep_sleep_pct'],
        'rem_sleep_pct': result['rem_sleep_pct'],
        'sleep_percent': result['sleep_percent'],
        'systolic': int.tryParse(systolicController.text.trim()),
        'diastolic': int.tryParse(diastolicController.text.trim()),
        'updated_at': DateTime.now().toIso8601String(),
      };

      updateData.removeWhere((key, value) => value == null);

      final updateResponse = await Supabase.instance.client
          .from('profiles')
          .update(updateData)
          .eq('user_id', userId)
          .select();

      if (updateResponse is List && updateResponse.isNotEmpty) {
        print('Supabase profile updated with latest prediction');
      } else {
        print('Supabase profile update returned no rows.');
      }
    } catch (e) {
      print('Error updating profile prediction fields: $e');
    }
  }

  Widget _buildSleepDisorderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sleep Disorder',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF252535),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButton<String>(
            value: selectedSleepDisorder,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF252535),
            items: sleepDisorders.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => selectedSleepDisorder = newValue);
              }
            },
          ),
        ),
      ],
    );
  }
}
