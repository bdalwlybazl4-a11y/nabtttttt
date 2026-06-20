import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StaticInfoPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> paragraphs;
  final List<Widget> actions;

  const StaticInfoPage({
    super.key,
    required this.title,
    required this.icon,
    required this.paragraphs,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(colors: [scheme.primaryContainer, scheme.secondaryContainer]),
              ),
              child: Row(children: [
                CircleAvatar(radius: 28, backgroundColor: scheme.primary, child: Icon(icon, color: scheme.onPrimary)),
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
              ]),
            ),
            const SizedBox(height: 18),
            ...paragraphs.map((p) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(p, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55)),
              ),
            )),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _open(Uri uri) async => launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) => StaticInfoPage(
    title: 'الدعم الفني',
    icon: Icons.support_agent_rounded,
    paragraphs: const [
      'فريق الدعم جاهز لمساعدتك في مشاكل الحساب، الحجز، الدفع، التنبيهات أو استخدام التطبيق.',
      'يرجى عدم إرسال معلومات طبية حساسة عبر قنوات الدعم العامة، واستخدم الاستشارة الطبية داخل التطبيق للحالات الصحية.',
    ],
    actions: [
      ElevatedButton.icon(onPressed: () => _open(Uri.parse('mailto:support@digl.com?subject=دعم تطبيق نبض')), icon: const Icon(Icons.email), label: const Text('التواصل عبر البريد الإلكتروني')),
      OutlinedButton.icon(onPressed: () => _open(Uri.parse('https://wa.me/966500000000')), icon: const Icon(Icons.chat), label: const Text('التواصل عبر واتساب')),
    ],
  );
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});
  @override
  Widget build(BuildContext context) => const StaticInfoPage(title: 'سياسة الخصوصية', icon: Icons.privacy_tip_rounded, paragraphs: [
    'نحمي بياناتك الشخصية والطبية ونستخدمها فقط لتقديم خدمات التطبيق مثل الحجز، التذكيرات، الاستشارات وتحسين التجربة.',
    'قد تُحفظ بيانات الحجز والمحادثات والإعدادات في Firebase وفق صلاحيات آمنة مرتبطة بحسابك.',
    'يمكنك طلب تحديث أو حذف بياناتك عبر الدعم الفني وفق الأنظمة المعمول بها.',
  ]);
}

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});
  @override
  Widget build(BuildContext context) => const StaticInfoPage(title: 'شروط الاستخدام', icon: Icons.gavel_rounded, paragraphs: [
    'استخدام التطبيق يعني موافقتك على الالتزام بالتعليمات وعدم إساءة استخدام خدمات الحجز أو الاستشارات.',
    'المساعد الذكي يقدم معلومات إرشادية ولا يغني عن الطبيب أو الطوارئ، ويجب مراجعة مختص عند وجود أعراض شديدة.',
    'الدفع عند المقابلة أو طرق الدفع الإلكترونية تخضع لسياسة الطبيب أو العيادة وتظهر حالة الدفع في تفاصيل الحجز.',
  ]);
}

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});
  @override
  Widget build(BuildContext context) => const StaticInfoPage(title: 'عن التطبيق', icon: Icons.favorite_rounded, paragraphs: [
    'نبض تطبيق صحي يربط المرضى بالأطباء ويوفر الحجز، المتابعة، التذكيرات الطبية، الخرائط والمساعد الذكي.',
    'هدفنا تقديم تجربة حديثة وآمنة تساعد المستخدم على إدارة رحلته الصحية من مكان واحد.',
    'الإصدار: 1.0.0',
  ]);
}
