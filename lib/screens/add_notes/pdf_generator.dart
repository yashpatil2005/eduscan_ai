import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<File> generatePdfFromImages(List<File> images) async {
  final pdf = pw.Document();

  for (var imageFile in images) {
    final image = pw.MemoryImage(await imageFile.readAsBytes());
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Center(child: pw.Image(image)),
        pageFormat: PdfPageFormat.a4,
      ),
    );
  }

  final outputDir = await getApplicationDocumentsDirectory();
  final filePath = p.join(outputDir.path, 'scanned_notes_${DateTime.now().millisecondsSinceEpoch}.pdf');
  final pdfFile = File(filePath);
  await pdfFile.writeAsBytes(await pdf.save());

  return pdfFile;
}
