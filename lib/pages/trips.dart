import 'dart:typed_data';
import 'package:fleet_management/pages/LiveTracking.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

import '../../services/create_trip_page.dart';

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    void showExpenseDialog(BuildContext context, Map<String, dynamic> data) {
      final fuel = data['fuelCost'] ?? 0;
      final service = data['serviceCost'] ?? 0;
      final toll = data['tollCost'] ?? 0;
      final total = data['totalCost'] ?? (fuel + service + toll);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              "Trip Expenses",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Fuel Cost: ₹$fuel"),
                Text("Service Cost: ₹$service"),
                Text("Toll Cost: ₹$toll"),
                const Divider(),
                Text(
                  "Total Cost: ₹$total",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("Close"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: const Text("Trip Management"),
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('trips').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final trips = snapshot.data!.docs;

          if (trips.isEmpty) {
            return const Center(
              child: Text(
                "No trips available",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                columns: const [
                  DataColumn(
                      label: Text("Trip ID",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text("Route",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text("Driver",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text("Vehicle",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text("Status",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text("Actions",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: trips.asMap().entries.map((entry) {
                  final index = entry.key;
                  final trip = entry.value;
                  final data = trip.data() as Map<String, dynamic>;

                  return DataRow(
                    cells: [
                      DataCell(Text("${index + 1}")),
                      DataCell(Text("${data['start']} → ${data['end']}")),
                      DataCell(Text(data['driverName'] ?? "Unassigned")),
                      DataCell(
                        Text(
                          "${data['vehicleCode'] ?? ''} - ${data['vehicleNumber'] ?? 'Unassigned'}",
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: data['status'] == "Ongoing"
                                ? Colors.green[100]
                                : Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            data['status'] ?? "Scheduled",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: data['status'] == "Ongoing"
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            if (data['status'] == "Ongoing")
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          LiveTrackingPage(tripId: trip.id),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Track",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            IconButton(
                              tooltip: "View Expenses",
                              icon: const Icon(
                                Icons.receipt_long,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                showExpenseDialog(context, data);
                              },
                            ),
                            IconButton(
                              tooltip: "Export PDF",
                              icon: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                if (kIsWeb) {
                                  _generatePdfWeb(data);
                                } else {
                                  _generatePdf(context, data);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add),
        label: const Text("New Trip"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateTripPage()),
          );
        },
      ),
    );
  }

  Future<void> _generatePdf(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final pdf = pw.Document();

    final fuel = data['fuelCost'] ?? 0;
    final service = data['serviceCost'] ?? 0;
    final toll = data['tollCost'] ?? 0;
    final total = data['totalCost'] ?? (fuel + service + toll);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Trip Summary",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text("Driver Name: ${data['driverName'] ?? 'N/A'}"),
                pw.Text("Vehicle Type: ${data['vehicleType'] ?? 'N/A'}"),
                pw.Text("Vehicle No: ${data['vehicleNumber'] ?? 'N/A'}"),
                pw.Text("Vehicle Code: ${data['vehicleCode'] ?? 'N/A'}"),
                pw.Text("Route: ${data['start']} → ${data['end']}"),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Expense Type"),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Amount (₹)"),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Fuel"),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("$fuel"),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Service"),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("$service"),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Toll"),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("$toll"),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            "Total",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            "$total",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _generatePdfWeb(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final fuel = data['fuelCost'] ?? 0;
    final service = data['serviceCost'] ?? 0;
    final toll = data['tollCost'] ?? 0;
    final total = data['totalCost'] ?? (fuel + service + toll);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Trip Summary",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text("Driver Name: ${data['driverName'] ?? 'N/A'}"),
                pw.Text("Vehicle Type: ${data['vehicleType'] ?? 'N/A'}"),
                pw.Text("Vehicle No: ${data['vehicleNumber'] ?? 'N/A'}"),
                pw.Text("Vehicle Code: ${data['vehicleCode'] ?? 'N/A'}"),
                pw.Text("Route: ${data['start']} → ${data['end']}"),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Fuel"),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("₹$fuel"),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Service"),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("₹$service"),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Toll"),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("₹$toll"),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            "Total",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            "₹$total",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    Uint8List bytes = await pdf.save();
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "trip_summary.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
