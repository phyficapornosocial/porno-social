import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:porno_social/features/search/search_screen.dart'
    as feature_search;
import 'package:porno_social/screens/feed_screen.dart';
import 'package:porno_social/models/user.dart';
import 'package:porno_social/providers/auth_providers.dart';
import 'package:porno_social/providers/user_providers.dart';
import 'package:porno_social/features/groups/groups_screen.dart';
import 'package:porno_social/features/events/events_screen.dart';
import 'package:porno_social/features/shorts/shorts_screen.dart';
import 'package:porno_social/features/live/live_stream_screen.dart';
import 'package:porno_social/features/live/live_list_screen.dart';
import 'package:porno_social/features/subscriptions/subscribe_screen.dart';
import 'package:porno_social/features/messaging/inbox_screen.dart';
import 'package:porno_social/features/dashboard/creator_dashboard.dart';
import 'package:porno_social/features/auth/age_verification_screen.dart';
import 'package:porno_social/features/create_post/create_post_screen.dart';
import 'package:porno_social/features/notifications/notifications_screen.dart';
import 'package:porno_social/features/admin/admin_screen.dart';
import 'package:porno_social/services/follow_service.dart';

final followServiceProvider = Provider<FollowService>((ref) {
  return FollowService();
});

final isFollowingProvider = StreamProvider.family<bool, String>((
  ref,
  targetUid,
) {
  final followService = ref.watch(followServiceProvider);
  return followService.isFollowing(targetUid);
});

class PornoSocialApp extends ConsumerWidget {
  const PornoSocialApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp.router(
      title: 'PornoSocial',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080808),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFe8000a)),
      ),
      routerConfig: _createRouter(
        authState.hasValue ? authState.value != null : false,
      ),
    );
  }

  GoRouter _createRouter(bool isAuthenticated) {
    return GoRouter(
      initialLocation: isAuthenticated ? '/' : '/login',
      redirect: (context, state) async {
        final path = state.uri.path;
        final isAuthRoute =
            path == '/login' ||
            path == '/signup' ||
            path == '/register' ||
            path == '/forgot-password';

        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }

        if (isAuthenticated && isAuthRoute) {
          return '/';
        }

        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          return isAuthRoute ? null : '/login';
        }

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final userData = userDoc.data() ?? <String, dynamic>{};

        final isBanned = userData['isBanned'] == true;
        if (isBanned && path != '/banned') {
          return '/banned';
        }

        if (!isBanned && path == '/banned') {
          return '/';
        }

        final isVerified = userData['isVerified'] == true;
        if (!isVerified && path != '/age-verification') {
          return '/age-verification';
        }

        if (path.startsWith('/admin')) {
          final adminDoc = await FirebaseFirestore.instance
              .collection('admins')
              .doc(uid)
              .get();
          if (!adminDoc.exists) {
            return '/';
          }
        }

        return null;
      },
      routes: [
        // Auth routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Main shell routes
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (context, state) => const FeedScreen()),
            GoRoute(
              path: '/shorts',
              builder: (context, state) => const ShortsScreen(),
            ),
            GoRoute(
              path: '/live',
              builder: (context, state) => const LiveListScreen(),
            ),
            GoRoute(
              path: '/search',
              builder: (context, state) => const feature_search.SearchScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const CurrentUserProfileScreen(),
            ),
            GoRoute(
              path: '/groups',
              builder: (context, state) => const GroupsScreen(),
            ),
            GoRoute(
              path: '/events',
              builder: (context, state) => const EventsScreen(),
            ),
          ],
        ),

        GoRoute(path: '/home', redirect: (context, state) => '/'),
        GoRoute(
          path: '/profile/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId'];
            return ProfileScreen(userId: userId ?? '');
          },
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/live/:channelName',
          builder: (context, state) {
            final channelName = state.pathParameters['channelName'] ?? '';
            final isHostParam = state.uri.queryParameters['isHost']
                ?.toLowerCase();
            final isHost = isHostParam == '1' || isHostParam == 'true';

            return LiveStreamScreen(isHost: isHost, channelName: channelName);
          },
        ),
        GoRoute(
          path: '/subscribe/:creatorId/:price',
          builder: (context, state) {
            final creatorId = state.pathParameters['creatorId'] ?? '';
            final priceRaw = state.pathParameters['price'] ?? '0';
            final price = double.tryParse(priceRaw) ?? 0;

            return SubscribeScreen(creatorId: creatorId, price: price);
          },
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) => const InboxScreen(),
        ),
        GoRoute(
          path: '/dashboard/creator',
          builder: (context, state) => const CreatorDashboard(),
        ),
        GoRoute(
          path: '/age-verification',
          builder: (context, state) => const AgeVerificationScreen(),
        ),
        GoRoute(
          path: '/create-post',
          builder: (context, state) => const CreatePostScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminScreen(),
        ),
        GoRoute(
          path: '/banned',
          builder: (context, state) => const BannedScreen(),
        ),
      ],
    );
  }
}

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const List<String> _paths = [
    '/',
    '/shorts',
    '/live',
    '/search',
    '/profile',
  ];

  int _indexFromLocation(String location) {
    if (location == '/shorts') return 1;
    if (location == '/live') return 2;
    if (location == '/search') return 3;
    if (location == '/profile') return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(_paths[index]),
        backgroundColor: const Color(0xFF0F0F0F),
        indicatorColor: const Color(0xFFe8000a),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'Shorts',
          ),
          NavigationDestination(
            icon: Icon(Icons.live_tv_outlined),
            selectedIcon: Icon(Icons.live_tv),
            label: 'Live',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class CurrentUserProfileScreen extends ConsumerWidget {
  const CurrentUserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('No profile found')));
    }

    return ProfileScreen(userId: userId);
  }
}

class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, color: Color(0xFFe8000a), size: 56),
              const SizedBox(height: 12),
              Text(
                'Account Restricted',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account is currently unavailable due to a moderation action. Contact support if you believe this is an error.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ LOGIN SCREEN ============
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                'Welcome to Porno Social',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Email is required';
                  if (!value!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Password is required';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, child) {
                  final signInAsync = ref.watch(
                    signInProvider(
                      SignInParams(
                        email: _emailController.text,
                        password: _passwordController.text,
                      ),
                    ),
                  );

                  return signInAsync.when(
                    loading: () => const ElevatedButton(
                      onPressed: null,
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, stack) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$error')));
                        ref.invalidate(
                          signInProvider(
                            SignInParams(
                              email: _emailController.text,
                              password: _passwordController.text,
                            ),
                          ),
                        );
                      });
                      return ElevatedButton(
                        onPressed: _handleSignIn,
                        child: const Text('Sign In'),
                      );
                    },
                    data: (_) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        context.go('/home');
                      });
                      return ElevatedButton(
                        onPressed: null,
                        child: const Text('Signing In...'),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text('Forgot Password?'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(
        signInProvider(
          SignInParams(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        ),
      );
    }
  }
}

// ============ SIGN UP SCREEN ============
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDOB;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Create Your Account',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Email is required';
                  if (!value!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Username is required';
                  }
                  if (value!.length < 3) {
                    return 'Username must be 3+ characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Display name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Password is required';
                  }
                  if (value!.length < 6) {
                    return 'Password must be 6+ characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _selectDOB,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _selectedDOB == null
                      ? 'Select Date of Birth'
                      : DateFormat('MMM dd, yyyy').format(_selectedDOB!),
                ),
              ),
              if (_selectedDOB != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '(You are ${_calculateAge()} years old)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _agreeToTerms,
                onChanged: (value) {
                  setState(() => _agreeToTerms = value ?? false);
                },
                title: const Text('I am 18+ years old and agree to Terms'),
                subtitle: const Text('You must be at least 18 to use this app'),
              ),
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, child) {
                  final signUpAsync = ref.watch(
                    signUpProvider(
                      SignUpParams(
                        email: _emailController.text,
                        password: _passwordController.text,
                      ),
                    ),
                  );

                  return signUpAsync.when(
                    loading: () => const ElevatedButton(
                      onPressed: null,
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, stack) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$error')));
                        ref.invalidate(
                          signUpProvider(
                            SignUpParams(
                              email: _emailController.text,
                              password: _passwordController.text,
                            ),
                          ),
                        );
                      });
                      return ElevatedButton(
                        onPressed: _handleSignUp,
                        child: const Text('Create Account'),
                      );
                    },
                    data: (_) {
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        _completeSignUp();
                      });
                      return ElevatedButton(
                        onPressed: null,
                        child: const Text('Creating Account...'),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDOB() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: initialDate,
    );

    if (selected != null) {
      setState(() => _selectedDOB = selected);
    }
  }

  int _calculateAge() {
    final now = DateTime.now();
    var age = now.year - _selectedDOB!.year;
    if (now.month < _selectedDOB!.month ||
        (now.month == _selectedDOB!.month && now.day < _selectedDOB!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to the terms')),
        );
        return;
      }
      if (_selectedDOB == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your date of birth')),
        );
        return;
      }
      if (_calculateAge() < 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be at least 18 years old')),
        );
        return;
      }

      ref.read(
        signUpProvider(
          SignUpParams(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        ),
      );
    }
  }

  Future<void> _completeSignUp() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final userRepository = ref.read(userRepositoryProvider);
      await userRepository.createUser(
        uid: userId,
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        email: _emailController.text.trim(),
        dateOfBirth: _selectedDOB!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// ============ FORGOT PASSWORD SCREEN ============
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                'Reset Your Password',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                enabled: !_emailSent,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Email is required';
                  if (!value!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (!_emailSent)
                Consumer(
                  builder: (context, ref, child) {
                    final resetAsync = ref.watch(
                      passwordResetProvider(_emailController.text),
                    );

                    return resetAsync.when(
                      loading: () => const ElevatedButton(
                        onPressed: null,
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (error, stack) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$error')));
                          ref.invalidate(
                            passwordResetProvider(_emailController.text),
                          );
                        });
                        return ElevatedButton(
                          onPressed: _handleReset,
                          child: const Text('Send Reset Link'),
                        );
                      },
                      data: (_) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() => _emailSent = true);
                        });
                        return const ElevatedButton(
                          onPressed: null,
                          child: Text('Sending...'),
                        );
                      },
                    );
                  },
                )
              else
                Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Email Sent!',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check your email for instructions to reset your password.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleReset() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(passwordResetProvider(_emailController.text.trim()));
    }
  }
}

// ============ HOME SCREEN ============
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Porno Social'), elevation: 0),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildFeedTab(),
          const SearchScreen(),
          _buildAccountTab(currentUser),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.video_library,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text('Feed Coming Soon'),
                    const SizedBox(height: 8),
                    const Text(
                      'Check back soon for creator content',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.push('/shorts'),
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Shorts'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/groups'),
                          icon: const Icon(Icons.groups_2_outlined),
                          label: const Text('Groups'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/events'),
                          icon: const Icon(Icons.event_outlined),
                          label: const Text('Events'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTab(AsyncValue<User?> currentUser) {
    return currentUser.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (user) {
        if (user == null) {
          return Center(child: Text('No profile found'));
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: user.avatarUrl.isNotEmpty
                          ? NetworkImage(user.avatarUrl)
                          : null,
                      child: user.avatarUrl.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '@${user.username}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${user.subscriberCount}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const Text('Subscribers'),
                          ],
                        ),
                        if (user.isCreator)
                          Column(
                            children: [
                              Text(
                                '\$${user.subscriptionPrice.toStringAsFixed(2)}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const Text('Per Month'),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/edit-profile'),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ),
              Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _showSignOutDialog(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(signOutProvider);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ============ PROFILE SCREEN ============
class ProfileScreen extends ConsumerWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider(userId));
    // ignore: unused_local_variable
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userProfile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text('User not found'),
                ],
              ),
            );
          }

          final isOwnProfile = userId == currentUserId;

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: user.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
                            : null,
                        child: user.avatarUrl.isEmpty
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      if (user.isVerified)
                        const Chip(
                          label: Text('Age Verified'),
                          avatar: Icon(Icons.verified),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '@${user.username}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.bio,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${user.subscriberCount}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const Text('Subscribers'),
                            ],
                          ),
                          if (user.isCreator)
                            Column(
                              children: [
                                Text(
                                  '\$${user.subscriptionPrice.toStringAsFixed(2)}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const Text('Per Month'),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isOwnProfile)
                        ElevatedButton.icon(
                          onPressed: () => context.push('/edit-profile'),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _FollowButton(targetUid: userId),
                            if (user.isCreator)
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.add),
                                label: const Text('Subscribe'),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                Divider(),
                if (user.interests.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Interests',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: user.interests
                              .map((interest) => Chip(label: Text(interest)))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  final String targetUid;

  const _FollowButton({required this.targetUid});

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _isSubmitting = false;

  Future<void> _toggleFollow(bool isCurrentlyFollowing) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final followService = ref.read(followServiceProvider);

    try {
      if (isCurrentlyFollowing) {
        await followService.unfollow(widget.targetUid);
      } else {
        await followService.follow(widget.targetUid);
      }

      ref.invalidate(userProfileProvider(widget.targetUid));
      ref.invalidate(currentUserProfileProvider);
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to update follow status: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    if (currentUserId == null || currentUserId == widget.targetUid) {
      return const SizedBox.shrink();
    }

    final isFollowingAsync = ref.watch(isFollowingProvider(widget.targetUid));

    return isFollowingAsync.when(
      loading: () => ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('Follow'),
      ),
      error: (_, stackTrace) => ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.person_add_disabled),
        label: const Text('Follow'),
      ),
      data: (isFollowing) => ElevatedButton.icon(
        onPressed: _isSubmitting ? null : () => _toggleFollow(isFollowing),
        icon: _isSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(isFollowing ? Icons.person_remove : Icons.person_add),
        label: Text(isFollowing ? 'Following' : 'Follow'),
      ),
    );
  }
}

// ============ EDIT PROFILE SCREEN ============
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _interestController;
  List<String> _interests = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _interestController = TextEditingController();

    // Load current user data
    Future.microtask(() {
      final currentUser = ref.read(currentUserProfileProvider).value;
      if (currentUser != null) {
        _displayNameController.text = currentUser.displayName;
        _bioController.text = currentUser.bio;
        _interests = currentUser.interests.toList();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  hintText: 'Tell us about yourself',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Interests (Kinks/Tags)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _interestController,
                      decoration: const InputDecoration(
                        labelText: 'Add interest',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_interestController.text.isNotEmpty) {
                        setState(() {
                          _interests.add(_interestController.text);
                          _interestController.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _interests
                    .map(
                      (interest) => Chip(
                        label: Text(interest),
                        onDeleted: () {
                          setState(() => _interests.remove(interest));
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _handleSave,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final userId = ref.read(currentUserIdProvider);
        if (userId == null) return;

        await ref.read(
          updateUserProfileProvider(
            UpdateUserProfileParams(
              uid: userId,
              displayName: _displayNameController.text.trim(),
              bio: _bioController.text.trim(),
              interests: _interests,
            ),
          ).future,
        );

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

// ============ SEARCH SCREEN ============
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchMode = 'username'; // 'username' or 'interest'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = _searchMode == 'username'
        ? ref.watch(searchUsersByUsernameProvider(_searchQuery))
        : ref.watch(searchCreatorsByInterestProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: _searchMode == 'username'
                        ? 'Search by username'
                        : 'Search by interest',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'username',
                            label: Text('Username'),
                          ),
                          ButtonSegment(
                            value: 'interest',
                            label: Text('Interest'),
                          ),
                        ],
                        selected: {_searchMode},
                        onSelectionChanged: (selected) {
                          setState(() {
                            _searchMode = selected.first;
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _searchQuery.isEmpty
                ? Center(
                    child: Text(
                      _searchMode == 'username'
                          ? 'Search for creators by username'
                          : 'Search for creators by interest',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : searchResults.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                    data: (users) {
                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            'No creators found',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.avatarUrl.isNotEmpty
                                  ? NetworkImage(user.avatarUrl)
                                  : null,
                              child: user.avatarUrl.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(user.displayName),
                            subtitle: Text('@${user.username}'),
                            trailing: user.isCreator
                                ? Chip(
                                    label: Text(
                                      '\$${user.subscriptionPrice.toStringAsFixed(2)}',
                                    ),
                                  )
                                : null,
                            onTap: () => context.push('/profile/${user.uid}'),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
