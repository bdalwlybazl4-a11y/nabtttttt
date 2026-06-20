import 'package:digl/features/admin/models/admin_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// خدمة إنشاء تقارير PDF للإدارة.
class AdminReportService {
  AdminReportService._();

  static Future<void> printDashboardReport({
    required AdminUser admin,
    required AdminStats stats,
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.notoNaskhArabicRegular();
    final boldFont = await PdfGoogleFonts.notoNaskhArabicBold();
    final theme = pw.ThemeData.withFont(base: font, bold: boldFont);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(28),
        ),
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('تقرير لوحة إدارة نبض', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.Text('المسؤول: ${admin.fullName}'),
          pw.Text('تاريخ التقرير: ${DateTime.now()}'),
          pw.SizedBox(height: 16),
          _section('الإحصائيات العامة'),
          _table([
            ['المرضى', stats.totalPatients.toString()],
            ['الأطباء', stats.totalDoctors.toString()],
            ['الاستشارات', stats.totalConsultations.toString()],
            ['الحجوزات', stats.totalAppointments.toString()],
            ['نتائج التقييم الصحي', stats.totalHealthAssessments.toString()],
            ['متوسط تقييم الأطباء', stats.averageDoctorRating.toStringAsFixed(1)],
          ]),
          pw.SizedBox(height: 14),
          _section('التخصصات الأكثر طلباً'),
          _table(stats.topSpecialties.entries.map((e) => [e.key, e.value.toString()]).toList()),
          pw.SizedBox(height: 14),
          _section('الأطباء الأكثر استخداماً'),
          _table(stats.topDoctors.entries.map((e) => [e.key, e.value.toString()]).toList()),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  static pw.Widget _section(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
      );

  static pw.Widget _table(List<List<String>> rows) {
    if (rows.isEmpty) return pw.Text('لا توجد بيانات متاحة حالياً');
    return pw.TableHelper.fromTextArray(
      headers: ['البند', 'القيمة'],
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      cellAlignment: pw.Alignment.centerRight,
      border: pw.TableBorder.all(color: PdfColors.grey300),
    );
  }
}
