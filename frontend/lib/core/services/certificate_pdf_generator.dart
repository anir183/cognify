import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme/app_theme.dart';

class CertificatePDFGenerator {
  static Future<Uint8List> generateCertificatePDF({
    required String studentName,
    required String courseName,
    required String issuerName,
    required String issueDate,
    required String certificateHash,
    required String academicDNA,
    required int trustScore,
  }) async {
    final pdf = pw.Document();

    // Load logo (optional - using placeholder)
    final logoImage = await imageFromAssetBundle('assets/logo.png')
        .catchError((_) => null);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColor.fromHex('#00D9FF'),
                width: 8,
              ),
            ),
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Header
                pw.Column(
                  children: [
                    if (logoImage != null)
                      pw.Image(logoImage, width: 80, height: 80),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'CERTIFICATE OF COMPLETION',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#00D9FF'),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Container(
                      width: 100,
                      height: 3,
                      color: PdfColor.fromHex('#A855F7'),
                    ),
                  ],
                ),

                // Main Content
                pw.Column(
                  children: [
                    pw.Text(
                      'This is to certify that',
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      studentName,
                      style: pw.TextStyle(
                        fontSize: 40,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'has successfully completed',
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Text(
                      courseName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#A855F7'),
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 30),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        pw.Column(
                          children: [
                            pw.Text(
                              'Issued By',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              issuerName,
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Text(
                              'Issue Date',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              issueDate,
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Footer - Blockchain Verification
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F0F0F0'),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Blockchain Hash',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey700,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                certificateHash,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  font: pw.Font.courier(),
                                ),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Academic DNA',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey700,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                academicDNA.substring(0, 16) + '...',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  font: pw.Font.courier(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Trust Score: ',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            '$trustScore/100',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#00D9FF'),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Verify at: verify.cognify.app',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                 pw.SizedBox(height: 10),

                 // QR Code
                 pw.Container(
                   height: 60,
                   width: 60,
                   child: pw.BarcodeWidget(
                     barcode: pw.Barcode.qrCode(),
                     data: 'https://verify.cognify.app/cert/$certificateHash',
                     drawText: false,
                     color: PdfColor.fromHex('#000000'),
                   ),
                 ),
                 pw.SizedBox(height: 5),
                 pw.Text(
                    "Scan to Verify",
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                 ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> downloadCertificate({
    required BuildContext context,
    required String studentName,
    required String courseName,
    required String issuerName,
    required String issueDate,
    required String certificateHash,
    required String academicDNA,
    required int trustScore,
  }) async {
    try {
      final pdfData = await generateCertificatePDF(
        studentName: studentName,
        courseName: courseName,
        issuerName: issuerName,
        issueDate: issueDate,
        certificateHash: certificateHash,
        academicDNA: academicDNA,
        trustScore: trustScore,
      );

      await Printing.sharePdf(
        bytes: pdfData,
        filename: '${studentName.replaceAll(' ', '_')}_certificate.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  static Future<void> printCertificate({
    required BuildContext context,
    required String studentName,
    required String courseName,
    required String issuerName,
    required String issueDate,
    required String certificateHash,
    required String academicDNA,
    required int trustScore,
  }) async {
    try {
      final pdfData = await generateCertificatePDF(
        studentName: studentName,
        courseName: courseName,
        issuerName: issuerName,
        issueDate: issueDate,
        certificateHash: certificateHash,
        academicDNA: academicDNA,
        trustScore: trustScore,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
