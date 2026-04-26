import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FullSignUpScreen extends StatefulWidget {
  const FullSignUpScreen({super.key});

  @override
  State<FullSignUpScreen> createState() => _FullSignUpScreenState();
}

class _FullSignUpScreenState extends State<FullSignUpScreen> {
  final supabase = Supabase.instance.client;

  // Controllers
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Profile Data
  String gender = 'Male';
  int age = 25;
  String occupation = 'Software Engineer';
  String bmiCategory = 'Normal'; // Default value
  double sleepDuration = 7.0;
  int activityLevel = 30;
  int stressLevel = 3;

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final occupations = [
    'Software Engineer',
    'Product Manager',
    'Data Scientist',
    'Marketing Manager',
    'Sales Director',
    'Financial Analyst',
    'Human Resources',
    'Operations Manager',
    'Legal Counsel',
    'Medical Professional',
    'Educator',
    'Consultant',
    'Entrepreneur',
    'Other'
  ];

  final bmiOptions = [
    'Normal',
    'Overweight',
    'Obese'
  ];

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.user != null) {
        await supabase.from('profiles').insert({
          'id': response.user!.id,
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'gender': gender.toLowerCase(),
          'age': age,
          'occupation': occupation,
          'bmi_category': bmiCategory,
          'sleep_duration': sleepDuration,
          'physical_activity_level': activityLevel,
          'stress_level': stressLevel,
          'created_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception:', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                const SizedBox(height: 8),
                
                // Glass morphism header
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please complete your profile information',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.95),
                          letterSpacing: -0.2,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.1),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Glass morphism sections
                _buildGlassSection(
                  title: 'Account Information',
                  children: [
                    TextFormField(
                      controller: usernameController,
                      style: const TextStyle(color: Color(0xFF1F2937)),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _buildGlassInputDecoration(
                        label: 'Username',
                        icon: Icons.person_outline,
                        hint: 'johndoe',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username is required';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                          return 'Use only letters, numbers, and underscores';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      style: const TextStyle(color: Color(0xFF1F2937)),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _buildGlassInputDecoration(
                        label: 'Email address',
                        icon: Icons.email_outlined,
                        hint: 'name@company.com',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: const TextStyle(color: Color(0xFF1F2937)),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _buildGlassInputDecoration(
                        label: 'Password',
                        icon: Icons.lock_outline,
                        hint: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                            color: const Color(0xFF6B7280),
                          ),
                          onPressed: () => setState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      style: const TextStyle(color: Color(0xFF1F2937)),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _buildGlassInputDecoration(
                        label: 'Confirm password',
                        icon: Icons.lock_outline,
                        hint: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                            color: const Color(0xFF6B7280),
                          ),
                          onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                _buildGlassSection(
                  title: 'Personal Information',
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gender',
                          style: _glassFieldLabelStyle(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildGlassGenderOption('Male'),
                            const SizedBox(width: 12),
                            _buildGlassGenderOption('Female'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Age', style: _glassFieldLabelStyle()),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                age.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: age.toDouble(),
                          min: 18,
                          max: 100,
                          divisions: 82,
                          activeColor: const Color(0xFF3B82F6),
                          inactiveColor: Colors.white.withOpacity(0.3),
                          onChanged: (value) => setState(() => age = value.round()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Occupation', style: _glassFieldLabelStyle()),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: occupation,
                              isExpanded: true,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              hint: const Text('Select occupation'),
                              icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF6B7280)),
                              items: occupations.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => occupation = value!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                _buildGlassSection(
                  title: 'BMI Category',
                  subtitle: 'Select your body mass index category',
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: bmiOptions.map((option) {
                            final isSelected = bmiCategory == option;
                            Color optionColor;
                            switch (option) {
                              case 'Normal':
                                optionColor = const Color(0xFF10B981);
                                break;
                              case 'Overweight':
                                optionColor = const Color(0xFFF59E0B);
                                break;
                              case 'Obese':
                                optionColor = const Color(0xFFEF4444);
                                break;
                              default:
                                optionColor = const Color(0xFF3B82F6);
                            }
                            
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => bmiCategory = option),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected 
                                          ? optionColor 
                                          : Colors.white.withOpacity(0.5),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: isSelected 
                                        ? optionColor.withOpacity(0.15)
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        _getBMIcon(option),
                                        size: 24,
                                        color: isSelected ? optionColor : Colors.grey.shade600,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        option,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          color: isSelected ? optionColor : const Color(0xFF374151),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                _buildGlassSection(
                  title: 'Wellness Metrics',
                  subtitle: 'These help us personalize your experience',
                  children: [
                    _buildGlassSliderField(
                      label: 'Sleep duration',
                      value: sleepDuration,
                      min: 4,
                      max: 12,
                      unit: 'hours',
                      decimal: true,
                      onChanged: (value) => setState(() => sleepDuration = value),
                    ),
                    _buildGlassSliderField(
                      label: 'Daily physical activity',
                      value: activityLevel.toDouble(),
                      min: 0,
                      max: 180,
                      unit: 'minutes',
                      decimal: false,
                      onChanged: (value) => setState(() => activityLevel = value.round()),
                    ),
                    _buildGlassSliderField(
                      label: 'Stress level',
                      value: stressLevel.toDouble(),
                      min: 1,
                      max: 10,
                      unit: 'scale (1-10)',
                      decimal: false,
                      onChanged: (value) => setState(() => stressLevel = value.round()),
                    ),
                  ],
                ),
                
                const SizedBox(height: 28),

                // Glass morphism button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.9),
                        const Color(0xFF2563EB).withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.white.withOpacity(0.3),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),

                // Glass morphism sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        'Sign in',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getBMIcon(String category) {
    switch (category) {
      case 'Normal':
        return Icons.favorite;
      case 'Overweight':
        return Icons.trending_up;
      case 'Obese':
        return Icons.warning;
      default:
        return Icons.fitness_center;
    }
  }

  Widget _buildGlassSection({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGlassSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required bool decimal,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: _glassFieldLabelStyle()),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: Text(
                decimal 
                    ? '${value.toStringAsFixed(1)} $unit'
                    : '${value.toInt()} $unit',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: decimal ? null : (max - min).toInt(),
          activeColor: const Color(0xFF3B82F6),
          inactiveColor: Colors.white.withOpacity(0.3),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildGlassGenderOption(String option) {
    final isSelected = gender == option;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => gender = option),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF3B82F6) 
                  : Colors.white.withOpacity(0.5),
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected 
                ? const Color(0xFF3B82F6).withOpacity(0.15)
                : Colors.white.withOpacity(0.5),
          ),
          child: Center(
            child: Text(
              option,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                    ? const Color(0xFF3B82F6) 
                    : const Color(0xFF374151),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildGlassInputDecoration({
    required String label,
    required IconData icon,
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
    );
  }

  TextStyle _glassFieldLabelStyle() {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Color(0xFF374151),
      letterSpacing: -0.2,
    );
  }
}