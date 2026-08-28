import re

with open('lib/src/features/auth/presentation/login_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add enums and state variables
enum_code = '''
enum LoginStep { phone, password, register }

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  LoginStep _currentStep = LoginStep.phone;
  PhoneLookupResult? _lookupResult;
  bool _isLoading = false;
  
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupNameController = TextEditingController();
'''
content = re.sub(
    r'class _LoginScreenState extends ConsumerState<LoginScreen>\s*with SingleTickerProviderStateMixin \{.*?(?=  bool _obscurePassword = true;)', 
    enum_code, 
    content, 
    flags=re.DOTALL
)

# Update handlers
handlers_code = '''
  void _handleNext() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _mobileController.text.trim();
    if (phone.isEmpty) return;
    
    setState(() => _isLoading = true);
    final result = await ref.read(supabaseAuthNotifierProvider).checkPhoneNumber(phone);
    setState(() => _isLoading = false);

    if (result.isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duplicate phone number found. Please contact branch admin.')));
      return;
    }
    if (!result.isFound) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Number not found in the system. Please contact branch admin.')));
      return;
    }

    setState(() {
      _lookupResult = result;
      _currentStep = result.hasAuthAccount ? LoginStep.password : LoginStep.register;
    });
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    if (_lookupResult == null || _lookupResult!.email == null) return;
    
    ref.read(supabaseAuthNotifierProvider).signIn(
      email: _lookupResult!.email!,
      password: _passwordController.text,
    );
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;
    if (_signupPasswordController.text != _signupConfirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    ref.read(supabaseAuthNotifierProvider).registerWithPhone(
      phone: _mobileController.text.trim(),
      email: _signupEmailController.text.trim(),
      password: _signupPasswordController.text,
    );
  }
'''
content = re.sub(
    r'  void _handleLogin\(\) \{.*?(?=  Future<void> _callCentre\(\))',
    handlers_code,
    content,
    flags=re.DOTALL
)

# Now update the UI builder to show steps
# We will just replace the "loginForm" Widget entirely!
# It's defined as `final loginForm = Center(...)` inside the `build` method.
new_form = '''
    final authState = ref.watch(supabaseAuthNotifierProvider).state;
    final isAuthLoading = authState is AuthLoading;
    final isLoading = _isLoading || isAuthLoading;

    final loginForm = Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.inkNavy900.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider10, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.goldCta.withOpacity(0.1),
                      border: Border.all(color: AppColors.goldCta.withOpacity(0.2), width: 1),
                    ),
                    child: const Icon(Icons.lock_person_rounded, size: 36, color: AppColors.goldCta),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _currentStep == LoginStep.phone ? 'Secure Sign In' :
                    _currentStep == LoginStep.password ? 'Welcome Back!' : 'Complete Details',
                    style: AppTypography.headingMd,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStep == LoginStep.phone ? 'Enter your registered mobile number' :
                    _currentStep == LoginStep.password ? 'Please enter your password' : 'Set your email and password',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Step 1: Phone
                  if (_currentStep == LoginStep.phone) ...[
                    TextFormField(
                      controller: _mobileController,
                      style: AppTypography.bodyLg,
                      keyboardType: TextInputType.phone,
                      decoration: _buildGlassInputDecoration(
                        labelText: 'Mobile Number',
                        hintText: 'Enter 10-digit mobile number',
                        prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.goldCta),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Mobile number is required';
                        if (v.length < 10) return 'Enter a valid mobile number';
                        return null;
                      },
                    ),
                  ],

                  // Step 2: Password
                  if (_currentStep == LoginStep.password) ...[
                    TextFormField(
                      controller: _passwordController,
                      style: AppTypography.bodyLg,
                      obscureText: _obscurePassword,
                      decoration: _buildGlassInputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.goldCta),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                    ),
                  ],

                  // Step 3: Register
                  if (_currentStep == LoginStep.register) ...[
                    TextFormField(
                      controller: _signupEmailController,
                      style: AppTypography.bodyLg,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildGlassInputDecoration(
                        labelText: 'Email Address',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.goldCta),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _signupPasswordController,
                      style: AppTypography.bodyLg,
                      obscureText: _obscurePassword,
                      decoration: _buildGlassInputDecoration(
                        labelText: 'Create Password',
                        hintText: 'Enter new password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.goldCta),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _signupConfirmPasswordController,
                      style: AppTypography.bodyLg,
                      obscureText: _obscurePassword,
                      decoration: _buildGlassInputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.goldCta),
                      ),
                      validator: (v) => v != _signupPasswordController.text ? 'Passwords do not match' : null,
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () {
                        if (_currentStep == LoginStep.phone) _handleNext();
                        else if (_currentStep == LoginStep.password) _handleLogin();
                        else _handleRegister();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldCta,
                        foregroundColor: AppColors.inkNavy900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.inkNavy900))
                          : Text(
                              _currentStep == LoginStep.phone ? 'NEXT' :
                              _currentStep == LoginStep.password ? 'LOGIN' : 'CREATE ACCOUNT',
                              style: AppTypography.labelLg.copyWith(color: AppColors.inkNavy900, fontSize: 16, letterSpacing: 1.2),
                            ),
                    ),
                  ),
                  if (_currentStep != LoginStep.phone) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _currentStep = LoginStep.phone),
                      child: Text('Change Phone Number', style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _callCentre,
                    icon: const Icon(Icons.phone_outlined, size: 16, color: AppColors.textMuted),
                    label: Text('Call Center Support', style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
'''

# Find the start of loginForm and end of the build method
# Let's replace the whole `build` method up to `return Scaffold`
content = re.sub(
    r'    final authState = ref\.watch\(supabaseAuthNotifierProvider\)\.state;.*?return Scaffold\(',
    new_form + '\n    return Scaffold(',
    content,
    flags=re.DOTALL
)

with open('lib/src/features/auth/presentation/login_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated login_screen.dart")
