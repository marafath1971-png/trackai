import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Scaffold(
      backgroundColor: L.bg,
      appBar: AppBar(
        backgroundColor: L.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: L.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Privacy Policy',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: L.text)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy for Med AI',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: L.text,
                    letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Last Updated: March 10, 2026',
                style:
                    TextStyle(fontFamily: 'Inter', fontSize: 13, color: L.sub)),
            const SizedBox(height: 32),
            _Section(
              title: '1. Introduction',
              content:
                  'Med AI is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your health information when you use our medication tracking and health insight application.',
              L: L,
            ),
            _Section(
              title: '2. Information We Collect',
              content:
                  'We collect information to provide you with a better experience:\n\n'
                  '• Health Data: Medication names, dosages, schedules, and adherence history.\n'
                  '• Images: Photos of medication packaging you take for AI scanning.\n'
                  '• Profile Data: Your name and health goals.\n'
                  '• Caregiver Information: Names and contact details of family members you choose to share alerts with.',
              L: L,
            ),
            _Section(
              title: '3. How We Use Data',
              content: 'Your data is used specifically for:\n\n'
                  '• Generating smart medication reminders.\n'
                  '• Providing AI-powered insights on your health and adherence.\n'
                  '• Escalating missed-dose alerts to your designated caregivers.\n'
                  '• Identifying medications via visual AI analysis.',
              L: L,
            ),
            _Section(
              title: '4. AI Services & Third Parties',
              content:
                  'To provide our advanced features, we use third-party AI services:\n\n'
                  '• Google Gemini: Used for processing medication images to identify products.\n'
                  '• Anthropic Claude: Used for analyzing your medication patterns to provide health insights.\n\n'
                  'Data sent to these services is limited to what is necessary for the specific function and is handled according to their respective privacy standards.',
              L: L,
            ),
            _Section(
              title: '5. Data Storage',
              content:
                  'Most of your personal data is stored locally on your device to ensure maximum privacy. Some features, like caregiver alerts, require minimal transmission of data to facilitate notification delivery.',
              L: L,
            ),
            _Section(
              title: '6. Your Rights',
              content:
                  'You have full control over your data. You can delete all your tracked medications and history at any time from within the App Settings.',
              L: L,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text('Med AI · Secure. Private. Simple.',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: L.sub.withValues(alpha: 0.6))),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title, content;
  final AppThemeColors L;
  const _Section({required this.title, required this.content, required this.L});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: L.text)),
          const SizedBox(height: 10),
          Text(content,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: L.sub,
                  height: 1.6,
                  fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }
}
