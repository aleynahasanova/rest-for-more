import 'package:flutter/material.dart';

import '../../dev/dev_user.dart';
import '../../models/onboarding_profile.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/id_generator.dart';
import 'onboarding_header.dart';
import 'onboarding_question_page.dart';
import 'onboarding_questions.dart';

/// The onboarding flow.
///
/// Step 0 is the intro, steps 1..n are the questions, and the last step is
/// the "all set" screen. After every answer and every step change the profile
/// is saved, so closing the app never loses answers, and opening the screen
/// again continues at the saved step.
///
/// The back arrow (and the phone's back button) goes to the previous step.
/// On the intro it leaves the flow. Answers stay saved.
class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key, this.userId});

  /// The id of the logged in user. When the login is connected, pass it here.
  /// While it is null, a temporary development user is used (see DevUser).
  final String? userId;

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final OnboardingService _onboardingService = OnboardingService();

  OnboardingProfile? _profile;
  bool _loadFailed = false;

  // False until the profile row has been created in the database.
  bool _existsInDatabase = false;

  int _step = 0;

  // Saves wait for each other, so quick taps can never try to create the same
  // profile twice.
  Future<void> _saveQueue = Future<void>.value();

  int get _lastStep => onboardingQuestions.length + 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = widget.userId ?? await DevUser.ensure();
      final existing =
          await _onboardingService.getOnboardingProfileByUserId(userId);

      if (!mounted) return;

      setState(() {
        if (existing != null) {
          _profile = existing;
          _existsInDatabase = true;

          if (existing.isComplete) {
            // Finished before: start at the first question with the saved
            // answers filled in, so they can be changed.
            _step = 1;
          } else {
            _step = existing.onboardingStep;
            if (_step > _lastStep) _step = _lastStep;
            if (_step < 0) _step = 0;
          }
        } else {
          _profile = OnboardingProfile(
            onboardingProfileId: IdGenerator.newId(),
            userId: userId,
            createdAt: DateTime.now(),
          );
        }
      });
    } catch (error) {
      debugPrint('Could not load onboarding profile: $error');

      if (!mounted) return;

      setState(() {
        _loadFailed = true;
      });
    }
  }

  void _selectAnswer(OnboardingQuestion question, String value) {
    setState(() {
      _profile = question
          .writeAnswer(_profile!, value)
          .copyWith(updatedAt: DateTime.now());
    });

    _persist();
  }

  void _goToStep(int step) {
    setState(() {
      _step = step;
      _profile = _profile!.copyWith(
        onboardingStep: step,
        updatedAt: DateTime.now(),
      );
    });

    _persist();
  }

  void _finish() {
    final now = DateTime.now();

    setState(() {
      _profile = _profile!.copyWith(completedAt: now, updatedAt: now);
    });

    _persist();

    Navigator.of(context).pop(true);
  }

  void _persist() {
    final snapshot = _profile!;

    _saveQueue = _saveQueue.then((_) => _write(snapshot));
  }

  Future<void> _write(OnboardingProfile profile) async {
    try {
      if (_existsInDatabase) {
        await _onboardingService.updateOnboardingProfile(profile);
      } else {
        await _onboardingService.createOnboardingProfile(profile);
        _existsInDatabase = true;
      }
    } catch (error) {
      debugPrint('Could not save onboarding profile: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your answer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Something went wrong.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _loadFailed = false;
                  });
                  _load();
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isIntro = _step == 0;
    final isDone = _step == _lastStep;
    final question = (isIntro || isDone) ? null : onboardingQuestions[_step - 1];
    final selectedValue = question?.readAnswer(profile);

    final String nextLabel;
    final VoidCallback? onNext;

    if (isIntro) {
      nextLabel = 'Start';
      onNext = () => _goToStep(_step + 1);
    } else if (isDone) {
      nextLabel = 'Finish';
      onNext = _finish;
    } else {
      nextLabel = 'Next';
      // Next is only possible after choosing. Skip is for no answer.
      onNext = selectedValue == null ? null : () => _goToStep(_step + 1);
    }

    return PopScope(
      // On the intro the back arrow leaves the flow. On every other step it
      // goes to the previous step instead.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goToStep(_step - 1);
      },
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Column(
            children: [
              LinearProgressIndicator(
                value: _step / _lastStep,
                backgroundColor: AppColors.surfaceMuted,
                color: AppColors.brand,
              ),
              Expanded(
                child: _buildPage(
                  question: question,
                  selectedValue: selectedValue,
                  isIntro: isIntro,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  children: [
                    FilledButton(
                      onPressed: onNext,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(nextLabel),
                    ),
                    if (question != null) ...[
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => _goToStep(_step + 1),
                        child: const Text('Skip'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required OnboardingQuestion? question,
    required String? selectedValue,
    required bool isIntro,
  }) {
    if (question != null) {
      return OnboardingQuestionPage(
        // A new key per step makes the list start at the top for each question.
        key: ValueKey(_step),
        question: question,
        eyebrow: 'Question $_step of ${onboardingQuestions.length}',
        selectedValue: selectedValue,
        onSelected: (value) => _selectAnswer(question, value),
      );
    }

    if (isIntro) {
      return const _MessagePage(
        eyebrow: 'Welcome',
        title: 'Rest For More',
        paragraphs: [
          'Rest For More helps you put your phone away and rest better, '
              'one small step at a time.',
          'A RestNest is optional. You can use the app without one.',
          'A few quick questions help us make a plan that fits you. '
              'You can skip any question and change your answers later.',
        ],
      );
    }

    return const _MessagePage(
      eyebrow: 'All set',
      title: 'Thank you!',
      paragraphs: [
        'Your answers are saved.',
        'Next, we use them to make your 14-day plan.',
      ],
    );
  }
}

class _MessagePage extends StatelessWidget {
  const _MessagePage({
    required this.eyebrow,
    required this.title,
    required this.paragraphs,
  });

  final String eyebrow;
  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        OnboardingHeader(eyebrow: eyebrow, title: title),
        const SizedBox(height: 16),
        for (final paragraph in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(paragraph, style: textTheme.bodyLarge),
          ),
      ],
    );
  }
}
