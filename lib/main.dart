import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import 'amplifyconfiguration.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isSignedIn = false;
  late String? firstName;
  late String? lastName;

  @override
  void initState() {
    super.initState();
    _configureAmplify();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      isSignedIn = await _isUserSignedIn();
      if (isSignedIn) {
        final result = await Amplify.Auth.fetchAuthSession();
        final cognitoUserPoolTokens =
            result.toJson()['userPoolTokens'] as CognitoUserPoolTokens;
        final idToken = cognitoUserPoolTokens.idToken;

        firstName = idToken.givenName;
        lastName = idToken.familyName;
      }
      setState(() {});
    });
  }

  Future<void> _configureAmplify() async {
    try {
      final auth = AmplifyAuthCognito();
      await Amplify.addPlugin(auth);

      await Amplify.configure(amplifyconfig);
    } on Exception catch (e) {
      safePrint('An error occurred configuring Amplify: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await _signInSaml();
                    final isUserSignedIn = await _isUserSignedIn();
                    setState(() {
                      isSignedIn = isUserSignedIn;
                    });
                  },
                  child: const Text('Sign in saml'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final isUserSignedIn = await _isUserSignedIn();
                    setState(() {
                      isSignedIn = isUserSignedIn;
                    });
                  },
                  child: const Text('Current user'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    Amplify.Auth.signOut();
                    final isUserSignedIn = await _isUserSignedIn();
                    setState(() {
                      isSignedIn = isUserSignedIn;
                    });
                  },
                  child: const Text('Sign out'),
                ),
                const SizedBox(height: 24),
                if (isSignedIn)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$lastName $firstName',
                        style: const TextStyle(fontSize: 36),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInSaml() async {
    final result = await Amplify.Auth.signInWithWebUI(
      provider: const AuthProvider.saml('SampleProvider'),
    );
    debugPrint('result=$result');
  }

  Future<bool> _isUserSignedIn() async {
    final result = await Amplify.Auth.fetchAuthSession();
    if (result.isSignedIn) {
      final cognitoUserPoolTokens =
          result.toJson()['userPoolTokens'] as CognitoUserPoolTokens;
      final idToken = cognitoUserPoolTokens.idToken;
      debugPrint('userId=${idToken.userId}');
      debugPrint('name=${idToken.name}');
      debugPrint('familyName=${idToken.familyName}');
      debugPrint('givenName=${idToken.givenName}');

      try {
        final userAttributes = await Amplify.Auth.fetchUserAttributes();
        debugPrint('userAttributes=$userAttributes');
      } catch (e) {
        safePrint(e);
      }
    }

    return result.isSignedIn;
  }
}
