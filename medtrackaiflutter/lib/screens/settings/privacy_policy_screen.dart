import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

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
        centerTitle: true,
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Section(
                L: L,
                title: 'Data Collection',
                content: 'We only collect data that is essential for your health tracking: medication names, dosages, and compliance history. All data is processed securely.',
              ),
              _Section(
                L: L,
                title: 'AI Analysis',
                content: 'Your health data is analyzed by advanced AI to provide insights. This analysis is private and only visible to you and your authorized caregivers.',
              ),
              _Section(
                L: L,
                title: 'Third-Party Services',
                content: 'We use encrypted cloud services for data storage. We do not sell or share your personal health data with third-party advertisers.',
              ),
              _Section(
                L: L,
                title: 'Your Rights',
                content: 'You share full control over your data. You can export or delete your entire health history at any time from the settings menu.',
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
              const SizedBox(height: 120),
            ],
          ),
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
