import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/project.dart';
import '../models/car_model.dart';
import '../models/measurement.dart';
import 'measurement_statistics_service.dart';

/// Сервис для генерации отчетов
class ReportGenerationService {
  /// Генерирует PDF отчет по проекту
  static Future<Uint8List> generatePdfReport({
    required Project project,
    required CarModel carModel,
    required List<Measurement> measurements,
  }) async {
    final pdf = pw.Document();
    final statistics = MeasurementStatisticsService.calculateDeviationStatistics(measurements);
    final criticalMeasurements = MeasurementStatisticsService.getMostCriticalMeasurements(measurements);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(project, carModel),
          pw.SizedBox(height: 20),
          _buildProjectInfo(project, carModel),
          pw.SizedBox(height: 20),
          _buildStatisticsSummary(statistics),
          pw.SizedBox(height: 20),
          _buildCriticalMeasurements(criticalMeasurements, carModel),
          pw.SizedBox(height: 20),
          _buildAllMeasurements(measurements, carModel),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(Project project, CarModel carModel) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ОТЧЕТ ПО ДИАГНОСТИКЕ КУЗОВА',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          '${carModel.displayName} - ${project.plateNumber ?? ""}',
          style: const pw.TextStyle(fontSize: 18),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Дата: ${_formatDate(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _buildProjectInfo(Project project, CarModel carModel) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Информация о проекте', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildInfoRow('Проект:', project.name),
          _buildInfoRow('Клиент:', project.customerName ?? '-'),
          _buildInfoRow('Гос. номер:', project.plateNumber ?? '-'),
          _buildInfoRow('Автомобиль:', carModel.displayName),
          _buildInfoRow('Описание:', project.description ?? '-'),
          _buildInfoRow('Прогресс:', '${(project.completionProgress * 100).toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  static pw.Widget _buildStatisticsSummary(Map<String, int> statistics) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Сводка по измерениям', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Всего', statistics['total']!, PdfColors.blue),
              _buildStatCard('Норма', statistics['normal']!, PdfColors.green),
              _buildStatCard('Внимание', statistics['warning']!, PdfColors.orange),
              _buildStatCard('Критично', statistics['critical']!, PdfColors.deepOrange),
              _buildStatCard('Серьезно', statistics['severe']!, PdfColors.red),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatCard(String label, int value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        children: [
          pw.Container(
            width: 40,
            height: 40,
            decoration: pw.BoxDecoration(
              color: color.shade(0.2),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                value.toString(),
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildCriticalMeasurements(List<Measurement> criticalMeasurements, CarModel carModel) {
    if (criticalMeasurements.isEmpty) {
      return pw.Container();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Критические отклонения',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableHeader('Точки'),
                _buildTableHeader('Заводской'),
                _buildTableHeader('Фактический'),
                _buildTableHeader('Отклонение'),
                _buildTableHeader('Статус'),
              ],
            ),
            ...criticalMeasurements.map((m) => _buildMeasurementRow(m, carModel)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildAllMeasurements(List<Measurement> measurements, CarModel carModel) {
    final groupedMeasurements = MeasurementStatisticsService.groupByType(measurements);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Все измерения',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ...groupedMeasurements.entries.map((entry) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _getMeasurementTypeLabel(entry.key),
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableHeader('Точки'),
                    _buildTableHeader('Заводской'),
                    _buildTableHeader('Фактический'),
                    _buildTableHeader('Отклонение'),
                    _buildTableHeader('Статус'),
                  ],
                ),
                ...entry.value.map((m) => _buildMeasurementRow(m, carModel)),
              ],
            ),
            pw.SizedBox(height: 15),
          ],
        )),
      ],
    );
  }

  static pw.TableRow _buildMeasurementRow(Measurement measurement, CarModel carModel) {
    final fromPoint = carModel.controlPoints.firstWhere((p) => p.id == measurement.fromPointId);
    final toPoint = carModel.controlPoints.firstWhere((p) => p.id == measurement.toPointId);
    
    return pw.TableRow(
      children: [
        _buildTableCell('${fromPoint.code} - ${toPoint.code}'),
        _buildTableCell('${measurement.factoryValue.toStringAsFixed(1)} мм'),
        _buildTableCell(measurement.actualValue != null 
          ? '${measurement.actualValue!.toStringAsFixed(1)} мм' 
          : '-'),
        _buildTableCell(measurement.actualValue != null 
          ? '${measurement.deviation.toStringAsFixed(1)} мм (${measurement.deviationPercent.toStringAsFixed(1)}%)' 
          : '-'),
        _buildTableCell(
          measurement.actualValue != null 
            ? _getSeverityLabel(measurement.severity) 
            : 'Не измерено',
          color: measurement.actualValue != null 
            ? _getSeverityColor(measurement.severity) 
            : PdfColors.grey,
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _buildTableCell(String text, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(color: color)),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  static String _getMeasurementTypeLabel(MeasurementType type) {
    switch (type) {
      case MeasurementType.linear:
        return 'Линейные измерения';
      case MeasurementType.diagonal:
        return 'Диагональные измерения';
      case MeasurementType.width:
        return 'Измерения ширины';
      case MeasurementType.length:
        return 'Измерения длины';
      case MeasurementType.height:
        return 'Измерения высоты';
      case MeasurementType.reference:
        return 'Референсные измерения';
    }
  }

  static String _getSeverityLabel(DeviationSeverity severity) {
    switch (severity) {
      case DeviationSeverity.normal:
        return 'Норма';
      case DeviationSeverity.warning:
        return 'Внимание';
      case DeviationSeverity.critical:
        return 'Критично';
      case DeviationSeverity.severe:
        return 'Серьезно';
    }
  }

  static PdfColor _getSeverityColor(DeviationSeverity severity) {
    switch (severity) {
      case DeviationSeverity.normal:
        return PdfColors.green;
      case DeviationSeverity.warning:
        return PdfColors.orange;
      case DeviationSeverity.critical:
        return PdfColors.deepOrange;
      case DeviationSeverity.severe:
        return PdfColors.red;
    }
  }
}