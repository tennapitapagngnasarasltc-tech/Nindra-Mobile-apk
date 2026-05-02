import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FullSignUpScreen extends StatefulWidget {
  const FullSignUpScreen({super.key});

  @override
  State<FullSignUpScreen> createState() => _FullSignUpScreenState();
}

class _FullSignUpScreenState extends State<FullSignUpScreen> {
  final supabase = Supabase.instance.client;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controllers
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Profile Data
  String gender = 'Male';
  int age = 25;
  String occupation = 'Software Engineer';
  String bmiCategory = 'Normal';
  double sleepDuration = 7.0;
  int activityLevel = 30;
  int stressLevel = 3;

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final _page1FormKey = GlobalKey<FormState>();
  final _page2FormKey = GlobalKey<FormState>();

  final occupations = [
    'Software Engineer', 'Product Manager', 'Data Scientist',
    'Marketing Manager', 'Sales Director', 'Financial Analyst',
    'Human Resources', 'Operations Manager', 'Legal Counsel',
    'Medical Professional', 'Educator', 'Consultant', 'Entrepreneur', 'Other'
  ];

  final bmiOptions = ['Normal', 'Overweight', 'Obese'];

  @override
  void dispose() {
    _pageController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentPage = page);
  }

  void _handleNext() {
    if (_page1FormKey.currentState!.validate()) {
      if (passwordController.text != confirmPasswordController.text) {
        _showError('Passwords do not match');
        return;
      }
      _goToPage(1);
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.user != null) {
        final String userId = response.user!.id;
        final String userEmail = response.user!.email ?? emailController.text.trim();

        await supabase.from('profiles').insert({
          'user_id': userId,
          'user_email': userEmail,
          'username': usernameController.text.trim(),
          'gender': gender.toLowerCase(),
          'age': age,
          'occupation': occupation,
          'bmi_category': bmiCategory,
          'sleep_duration': sleepDuration,
          'physical_activity_level': activityLevel,
          'stress_level': stressLevel,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
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
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStepDots(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPage1(),
                    _buildPage2(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final titles = ['Create Account', 'Health Profile'];
    final subtitles = ['Set up your login details', 'Personalize your experience'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Row(
          key: ValueKey(_currentPage),
          children: [
            if (_currentPage > 0)
              GestureDetector(
                onTap: () => _goToPage(0),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              )
            else
              const SizedBox(width: 18),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[_currentPage],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  subtitles[_currentPage],
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Step Dots ────────────────────────────────────────────────────────────────

  Widget _buildStepDots() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(2, (i) {
          final isActive = i == _currentPage;
          final isDone = i < _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: isActive ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : isDone
                      ? Colors.white.withOpacity(0.7)
                      : Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }),
      ),
    );
  }

  // ── Page 1: Account + Personal ───────────────────────────────────────────────

  Widget _buildPage1() {
    return Form(
      key: _page1FormKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildGlassSection(
            title: 'Account Information',
            icon: Icons.lock_person_outlined,
            children: [
              _buildTextField(
                controller: usernameController,
                label: 'Username',
                icon: Icons.person_outline,
                hint: 'johndoe',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Username is required';
                  if (v.length < 3) return 'At least 3 characters';
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) return 'Letters, numbers and _ only';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: emailController,
                label: 'Email address',
                icon: Icons.email_outlined,
                hint: 'name@company.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                hint: '••••••••',
                obscure: obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility,
                      size: 20, color: const Color(0xFF6B7280)),
                  onPressed: () => setState(() => obscurePassword = !obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 8) return 'At least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: confirmPasswordController,
                label: 'Confirm password',
                icon: Icons.lock_outline,
                hint: '••••••••',
                obscure: obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      size: 20, color: const Color(0xFF6B7280)),
                  onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your password';
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGlassSection(
            title: 'Personal Information',
            icon: Icons.badge_outlined,
            children: [
              _buildFieldLabel('Gender'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildGenderOption('Male'),
                  const SizedBox(width: 12),
                  _buildGenderOption('Female'),
                ],
              ),
              const SizedBox(height: 18),
              _buildSliderRow(
                label: 'Age',
                displayText: '$age yrs',
                value: age.toDouble(),
                min: 18,
                max: 100,
                divisions: 82,
                onChanged: (v) => setState(() => age = v.round()),
              ),
              const SizedBox(height: 10),
              _buildFieldLabel('Occupation'),
              const SizedBox(height: 8),
              _buildDropdown(),
            ],
          ),
          const SizedBox(height: 20),
          _buildPrimaryButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: _handleNext,
          ),
          _buildSignInLink(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Page 2: BMI + Wellness ───────────────────────────────────────────────────

  Widget _buildPage2() {
    return Form(
      key: _page2FormKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildGlassSection(
            title: 'BMI Category',
            icon: Icons.monitor_weight_outlined,
            subtitle: 'Select your body mass index',
            children: [
              const SizedBox(height: 4),
              Row(
                children: bmiOptions.map((option) {
                  final isSelected = bmiCategory == option;
                  final color = _bmiColor(option);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => bmiCategory = option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? color : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: isSelected ? color.withOpacity(0.12) : Colors.white.withOpacity(0.6),
                        ),
                        child: Column(
                          children: [
                            Icon(_bmiIcon(option), size: 26, color: isSelected ? color : Colors.grey.shade500),
                            const SizedBox(height: 6),
                            Text(
                              option,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                color: isSelected ? color : const Color(0xFF374151),
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
          const SizedBox(height: 16),
          _buildGlassSection(
            title: 'Wellness Metrics',
            icon: Icons.favorite_border_rounded,
            subtitle: 'Helps us personalize your insights',
            children: [
              _buildSliderRow(
                label: 'Sleep duration',
                displayText: '${sleepDuration.toStringAsFixed(1)} hrs',
                value: sleepDuration,
                min: 4,
                max: 12,
                onChanged: (v) => setState(() => sleepDuration = double.parse(v.toStringAsFixed(1))),
              ),
              const SizedBox(height: 12),
              _buildSliderRow(
                label: 'Physical activity',
                displayText: '$activityLevel min',
                value: activityLevel.toDouble(),
                min: 0,
                max: 180,
                divisions: 180,
                onChanged: (v) => setState(() => activityLevel = v.round()),
              ),
              const SizedBox(height: 12),
              _buildStressRow(),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSecondaryButton(
                label: 'Back',
                icon: Icons.arrow_back_rounded,
                onPressed: () => _goToPage(0),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildPrimaryButton(
                  label: 'Create Account',
                  onPressed: isLoading ? null : _handleSubmit,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
          _buildSignInLink(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Stress level selector ────────────────────────────────────────────────────

  Widget _buildStressRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFieldLabel('Stress level'),
            _buildValueBadge(_stressLabel(stressLevel), _stressColor(stressLevel)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(10, (i) {
            final level = i + 1;
            final isSelected = level == stressLevel;
            final color = _stressColor(level);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => stressLevel = level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Relaxed', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              Text('Critical', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Reusable widgets ─────────────────────────────────────────────────────────

  Widget _buildGlassSection({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937), letterSpacing: -0.2)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 24, thickness: 0.5),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String displayText,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFieldLabel(label),
            _buildValueBadge(displayText, const Color(0xFF3B82F6)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: const Color(0xFF3B82F6),
            inactiveColor: const Color(0xFFE5E7EB),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String option) {
    final isSelected = gender == option;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => gender = option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
            color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.08) : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                option == 'Male' ? Icons.male : Icons.female,
                size: 18,
                color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
              Text(
                option,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: occupation,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
          items: occupations.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => occupation = v!),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.9),
            const Color(0xFF2563EB).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.35),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: Colors.white.withOpacity(0.3),
        ),
        child: isLoading
            ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                  if (icon != null) ...[
                    const SizedBox(width: 6),
                    Icon(icon, size: 18),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.white.withOpacity(0.6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account?',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
          child: const Text('Sign in',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: Color(0xFF374151), letterSpacing: -0.1));
  }

  Widget _buildValueBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Color _bmiColor(String category) {
    switch (category) {
      case 'Normal': return const Color(0xFF10B981);
      case 'Overweight': return const Color(0xFFF59E0B);
      case 'Obese': return const Color(0xFFEF4444);
      default: return const Color(0xFF3B82F6);
    }
  }

  IconData _bmiIcon(String category) {
    switch (category) {
      case 'Normal': return Icons.favorite_rounded;
      case 'Overweight': return Icons.trending_up_rounded;
      case 'Obese': return Icons.warning_amber_rounded;
      default: return Icons.fitness_center;
    }
  }

  Color _stressColor(int level) {
    if (level <= 3) return const Color(0xFF10B981);
    if (level <= 6) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _stressLabel(int level) {
    if (level <= 3) return 'Low';
    if (level <= 6) return 'Moderate';
    return 'High';
  }
}