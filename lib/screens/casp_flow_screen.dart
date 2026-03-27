import 'package:flutter/material.dart';
import '../theme.dart';

/// CASP Flow Screen — Crypto Asset Service Provider regulatory onboarding.
///
/// This screen handles the regulatory compliance flow for users who want to
/// engage in cryptocurrency asset services. CASP status requires specific
/// KYC/KYB documentation and compliance verification.
///
/// Flow:
///   1. Intro: Explain CASP requirements
///   2. Compliance check: Verify jurisdiction eligibility
///   3. Documentation: Collect required documents (ID, proof of address, etc.)
///   4. Review: Submit for compliance review
///   5. Status: Monitor approval status
class CASPFlowScreen extends StatefulWidget {
  const CASPFlowScreen({super.key});

  @override
  State<CASPFlowScreen> createState() => _CASPFlowScreenState();
}

enum CASPStep { intro, eligibility, documentation, review, status }

class _CASPFlowScreenState extends State<CASPFlowScreen> {
  CASPStep _currentStep = CASPStep.intro;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CASP Onboarding'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _buildStepContent(),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case CASPStep.intro:
        return _buildIntroStep();
      case CASPStep.eligibility:
        return _buildEligibilityStep();
      case CASPStep.documentation:
        return _buildDocumentationStep();
      case CASPStep.review:
        return _buildReviewStep();
      case CASPStep.status:
        return _buildStatusStep();
    }
  }

  Widget _buildIntroStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon header
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: NomadsColors.primaryLight,
                borderRadius: BorderRadius.circular(NomadsRadius.lg),
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 40,
                color: NomadsColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Crypto Asset Service Provider',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NomadsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          const Text(
            'Enable regulated cryptocurrency and digital asset services on your account.',
            style: TextStyle(
              fontSize: 15,
              color: NomadsColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // Requirements section
          const Text(
            'What you need:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: NomadsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _requirementItem(
            Icons.person_outline,
            'Valid Government ID',
            'Passport, driver license, or national ID',
          ),
          const SizedBox(height: 12),

          _requirementItem(
            Icons.location_on_outlined,
            'Proof of Address',
            'Recent utility bill or bank statement (< 3 months)',
          ),
          const SizedBox(height: 12),

          _requirementItem(
            Icons.verified_user_outlined,
            'KYC Verification',
            'Photo verification and jurisdiction check',
          ),
          const SizedBox(height: 12),

          _requirementItem(
            Icons.assignment_outlined,
            'Compliance Agreement',
            'Review and accept CASP terms and regulations',
          ),
          const SizedBox(height: 40),

          // Start button
          PrimaryButton(
            label: 'Start CASP Setup',
            loading: _loading,
            onTap: () => setState(() => _currentStep = CASPStep.eligibility),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NomadsColors.errorLight,
                borderRadius: BorderRadius.circular(NomadsRadius.md),
              ),
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 13, color: NomadsColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEligibilityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(2, 5),
          const SizedBox(height: 24),

          const Text(
            'Jurisdiction Eligibility',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NomadsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'We need to verify your location for regulatory compliance.',
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
                  'Where are you based?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NomadsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: NomadsColors.border),
                    borderRadius: BorderRadius.circular(NomadsRadius.md),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Select country'),
                      Icon(Icons.arrow_drop_down, color: NomadsColors.textMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = CASPStep.intro),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Continue',
                  onTap: () => setState(() => _currentStep = CASPStep.documentation),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(3, 5),
          const SizedBox(height: 24),

          const Text(
            'Upload Documents',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NomadsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Please provide clear, recent copies of your documents.',
            style: TextStyle(
              fontSize: 15,
              color: NomadsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          _documentUploadItem('Government ID', Icons.badge_outlined),
          const SizedBox(height: 16),

          _documentUploadItem('Proof of Address', Icons.home_outlined),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = CASPStep.eligibility),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Review',
                  onTap: () => setState(() => _currentStep = CASPStep.review),
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
          _stepIndicator(4, 5),
          const SizedBox(height: 24),

          const Text(
            'Review & Confirm',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NomadsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Please review your information before submitting.',
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
                const DetailRow(
                  label: 'Status',
                  value: 'Ready for submission',
                ),
                const Divider(height: 16),
                const DetailRow(
                  label: 'Documents',
                  value: '2 files uploaded',
                ),
                const Divider(height: 16),
                const DetailRow(
                  label: 'Processing time',
                  value: '3-5 business days',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = CASPStep.documentation),
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
                      _currentStep = CASPStep.status;
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

  Widget _buildStatusStep() {
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
            'Application Submitted',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NomadsColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          const Text(
            'Your CASP application has been submitted for review. We\'ll notify you within 3-5 business days.',
            style: TextStyle(
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
                Text(
                  '1. We review your documents\n2. Compliance verification\n3. Final approval\n4. CASP features enabled',
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
            label: 'Back to Home',
            onTap: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  Widget _requirementItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: NomadsColors.primaryLight,
            borderRadius: BorderRadius.circular(NomadsRadius.md),
          ),
          child: Icon(icon, size: 20, color: NomadsColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: NomadsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: NomadsColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _documentUploadItem(String title, IconData icon) {
    return NCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: NomadsColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NomadsColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              border: Border.all(
                color: NomadsColors.border,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(NomadsRadius.md),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 32,
                    color: NomadsColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to upload',
                    style: TextStyle(
                      fontSize: 13,
                      color: NomadsColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
