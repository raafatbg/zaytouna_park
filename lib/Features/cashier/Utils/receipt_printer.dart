import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

// 👇 IMPORT the models from your orders file instead of duplicating them!
import 'package:zaytouna_park/Features/cashier/Widgets/Orders/orders.dart';

class ReceiptPrinter {
  /// Generates and prints a receipt specifically formatted for an 80mm roll printer.
  static Future<void> printReceipt(OrderModel order) async {
    final pdf = pw.Document();

    // Standard 80mm thermal receipt paper width is roughly 3.14 inches.
    // 3.14 inches * 72 points per inch ≈ 226 points wide.
    const roll80mm = PdfPageFormat(226, double.infinity, marginAll: 5);

    // Load a font that supports standard characters well on small scales
    final font = await PdfGoogleFonts.robotoMonoRegular();
    final fontBold = await PdfGoogleFonts.robotoMonoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: roll80mm,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'ZAYTOUNA PARK',
                      style: pw.TextStyle(font: fontBold, fontSize: 18),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Receipt of Transaction',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),
              _buildDivider(),
              pw.SizedBox(height: 10),

              // --- ORDER INFO ---
              pw.Text(
                'Order #     : ${order.id}',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.Text(
                'Date        : ${DateFormat('yyyy-MM-dd HH:mm').format(order.timestamp)}',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.Text(
                'Location    : ${order.tableNumber}',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.Text(
                'Customer    : ${order.customerName}',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.Text(
                'Status      : ${order.paymentStatus.toUpperCase()}',
                style: pw.TextStyle(font: fontBold, fontSize: 10),
              ),

              pw.SizedBox(height: 10),
              _buildDivider(),
              pw.SizedBox(height: 10),

              // --- ITEMS HEADER ---
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'QTY',
                      style: pw.TextStyle(font: fontBold, fontSize: 10),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'ITEM',
                      style: pw.TextStyle(font: fontBold, fontSize: 10),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'TOTAL',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: fontBold, fontSize: 10),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 4),
              _buildDivider(style: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              // --- ITEMS LIST ---
              ...order.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '${item.quantity}x',
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          item.name,
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          '\$${item.total.toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 6),
              _buildDivider(),
              pw.SizedBox(height: 6),

              // --- FINANCIALS ---
              _buildSummaryRow(
                'Subtotal:',
                '\$${order.subtotal.toStringAsFixed(2)}',
                font,
              ),
              if (order.discountAmount > 0)
                _buildSummaryRow(
                  'Discount:',
                  '-\$${order.discountAmount.toStringAsFixed(2)}',
                  font,
                ),
              if (order.taxAmount > 0)
                _buildSummaryRow(
                  'Tax:',
                  '+\$${order.taxAmount.toStringAsFixed(2)}',
                  font,
                ),

              pw.SizedBox(height: 4),
              _buildDivider(style: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              _buildSummaryRow(
                'TOTAL USD:',
                '\$${order.totalAmount.toStringAsFixed(2)}',
                fontBold,
                size: 14,
              ),
              pw.SizedBox(height: 4),
              _buildSummaryRow(
                'TOTAL LBP:',
                '${_roundTo5000(order.totalAmount * 90000)} LBP',
                fontBold,
                size: 12,
              ),

              pw.SizedBox(height: 15),
              _buildDivider(),
              pw.SizedBox(height: 10),

              // --- FOOTER ---
              pw.Center(
                child: pw.Text(
                  'Thank you for visiting Zaytouna Park!',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_Order_${order.id}',
    );
  }

  static pw.Widget _buildDivider({
    pw.BorderStyle style = pw.BorderStyle.solid,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 1, style: style),
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value,
    pw.Font font, {
    double size = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: size),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: font, fontSize: size),
          ),
        ],
      ),
    );
  }

  static int _roundTo5000(num amount) {
    return ((amount / 5000).round() * 5000);
  }
}
