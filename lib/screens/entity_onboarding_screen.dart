import 'dart:math';

import 'package:flutter/material.dart';
import '../theme.dart';

/// Entity Onboarding Screen — KYB (Know Your Business) workflow.
///
/// This screen guides businesses through compliance onboarding for institutional
/// accounts. Supports multiple institution types (e.g., CurrencyClear, AML/CFT).
///
/// Flow:
///   1. Entity verification: Business registration, legal structure
///   2. Director/UBO info: Beneficial owners and directors
///   3. Banking details: Institution-specific account setup
///   4. Risk assessment: Compliance questionnaire
///   5. Review & submit: Final approval
class EntityOnboardingScreen extends StatefulWidget {
  final String institutionType;
  final String entityName;

  const EntityOnboardingScreen({
    super.key,
    required this.institutionType,
    required this.entityName,
  });

  @override
  State<EntityOnboardingScreen> createState() => _EntityOnboardingScreenState();
}

enum OnboardingStep {
  entityInfo,
  businessType,
  directors,
  banking,
  review,
  complete,
}

class _EntityOnboardingScreenState extends State<EntityOnboardingScreen> {
  OnboardingStep _currentStep = OnboardingStep.entityInfo;
  bool _loading = false;

  // Form state
  final _registrationNumberCtrl = TextEditingController();
  final _registrationDateCtrl = TextEditingController();
  final _directorNameCtrl = TextEditingController();
  final _directorEmailCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();

  @override
  void dispose() {
    _registrationNumberCtrl.dispose();
    _registrationDateCtrl.dispose();
    _directorNameCtrl.dispose();
    _directorEmailCtrl.dispose();
    _bankAccountCtrl.dispose();
    _bankNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Onboarding'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _buildStepContent(),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case OnboardingStep.entityInfo:
        return _buildEntityInfoStep();
      case OnboardingStep.businessType:
        return _buildBusinessTypeStep();
      case OnboardingStep.directors:
        return _buildDirectorsStep();
      case OnboardingStep.banking:
        return _buildBankingStep();
      case OnboardingStep.review:
        return _buildReviewStep();
      case OnboardingStep.complete:
        return _buildCompleteStep();
    }
  }

  Widget _buildEntityInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(1, 6),
          const SizedBox(height: 24),

          const Text(
            'Business Registration',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NomadsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Provide your business registration details.',
            style: TextStyle(
              fontSize: 15,
              color: NomadsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Entity name display
          NCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Name',
                  style: TextStyle(
                    fontSize: 12,
                    color: NomadsColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.entityName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NomadsColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Registration number
          TextField(
            controller: _registrationNumberCtrl,
            decoration: InputDecoration(
              labelText: 'Registration/Company Number',
              hintText: 'e.g., 12345678',
              prefixIcon: const Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Registration date
          TextField(
            controller: _registrationDateCtrl,
            decoration: InputDecoration(
              labelText: 'Date of Incorporation',
              hintText: 'YYYY-MM-DD',
              prefixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                _registrationDateCtrl.text = date.toString().substring(0, 10);
              }
            },
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Continue',
                  onTap: () => setState(() => _currentStep = OnboardingStep.businessType),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(2, 6),
          const SizedBox(height: 24),

          const Text(
            'Business Structure',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NomadsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Select your legal structure.',
            style: TextStyle(
              fontSize: 15,
              color: NomadsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          _businessTypeOption('Sole Proprietor', Icons.person_outlined),
          const SizedBox(height: 12),

          _businessTypeOption('Partnership', Icons.people_outlined),
          const SizedBox(height: 12),

          _businessTypeOption('Limited Company (Ltd)', Icons.business_outlined),
          const SizedBox(height: 12),

          _businessTypeOption('Non-Profit / Charity', Icons.favorite_outline),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = OnboardingStep.entityInfo),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Continue',
                  onTap: () => setState(() => _currentStep = OnboardingStep.directors),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectorsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(3, 6),
          const SizedBox(height: 24),

          const Text(
            'Directors & Beneficial Owners',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NomadsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Provide details of all directors and beneficial owners.',
            style: TextStyle(
              fontSize: 15,
              color: NomadsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _directorNameCtrl,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _directorEmailCtrl,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          NCard(
            padding: const EdgeInsets.all(12),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: NomadsColors.textMuted),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We\'ll verify this information with company records.',
                    style: TextStyle(fontSize: 12, color: NomadsColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = OnboardingStep.businessType),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Continue',
                  onTap: () => setState(() => _currentStep = OnboardingStep.banking),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(4, 6),
          const SizedBox(height: 24),

          const Text(
            'Banking Details',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NomadsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Link your business bank account for settlement.',
            style: TextStyle(
              fontSize: 15,
              color: NomadsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _bankNameCtrl,
            decoration: InputDecoration(
              labelText: 'Bank Name',
              prefixIcon: const Icon(Icons.account_balance_outlined),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _bankAccountCtrl,
            decoration: InputDecoration(
              labelText: 'Account Number / IBAN',
              prefixIcon: const Icon(Icons.credit_card_outlined),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            decoration: InputDecoration(
              labelText: 'Account Holder Name',
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = OnboardingStep.directors),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Continue',
                  onTap: () => setState(() => _currentStep = OnboardingStep.review),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(5, 6),
          const SizedBox(height: 24),

          const Text(
            'Review Your Information',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NomadsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Please verify all details before submission.',
            style: TextStyle(
              fontSize: 15,
              color: NomadsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          NCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NomadsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                DetailRow(
                  label: 'Business Name',
                  value: widget.entityName,
                  bold: true,
                ),
                const Divider(height: 16),

                DetailRow(
                  label: 'Institution Type',
                  value: widget.institutionType,
                ),
                const Divider(height: 16),

                DetailRow(
                  label: 'Registration Number',
                  value: _registrationNumberCtrl.text.isNotEmpty
                      ? _registrationNumberCtrl.text
                      : 'Not provided',
                ),
                const Divider(height: 16),

                DetailRow(
                  label: 'Bank Account',
                  value: _bankAccountCtrl.text.isNotEmpty
                      ? '••••${_bankAccountCtrl.text.substring(max(0, _bankAccountCtrl.text.length - 4))}'
                      : 'Not provided',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          NCard(
            padding: const EdgeInsets.all(16),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, size: 20, color: NomadsColors.success),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your submission will be reviewed within 2-3 business days.',
                    style: TextStyle(fontSize: 12, color: NomadsColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = OnboardingStep.banking),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Submit',
                  loading: _loading,
                  onTap: () async {
                    setState(() => _loading = true);
                    await Future.delayed(const Duration(milliseconds: 800));
                    setState(() {
                      _loading = false;
                      _currentStep = OnboardingStep.complete;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: NomadsColors.successLight,
                borderRadius: BorderRadius.circular(NomadsRadius.lg),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 40,
                color: NomadsColors.success,
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Onboarding Complete',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NomadsColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Text(
            'Your business "${widget.entityName}" has been submitted for verification.',
            style: const TextStyle(
              fontSize: 15,
              color: NomadsColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          NCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What happens next?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NomadsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Verification of company records\n2. Director identity confirmation\n3. Banking details validation\n4. Compliance approval\n5. Account activation',
                  style: TextStyle(
                    fontSize: 13,
                    color: NomadsColors.textSecondary,
                    height: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          PrimaryButton(
            label: 'Back to Account',
            onTap: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  Widget _businessTypeOption(String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: NomadsColors.border),
        borderRadius: BorderRadius.circular(NomadsRadius.md),
      ),
      child: ListTile(
        leading: Icon(icon, color: NomadsColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }

  Widget _stepIndicator(int current, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $current of $total',
          style: const TextStyle(
            fontSize: 12,
            color: NomadsColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(NomadsRadius.sm),
          child: LinearProgressIndicator(
            value: current / total,
            minHeight: 6,
            backgroundColor: NomadsColors.border,
            valueColor: const AlwaysStoppedAnimation(NomadsColors.primary),
          ),
        ),
      ],
    );
  }
}
