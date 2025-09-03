import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

import '../../services/create_trip_page.dart'; // make sure path is correct

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trip Management")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('trips').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final trips = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Trip ID")),
                  DataColumn(label: Text("Route")),
                  DataColumn(label: Text("Driver")),
                  DataColumn(label: Text("Vehicle")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Expenses")),
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
                      DataCell(Text(data['status'] ?? "Scheduled")),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_red_eye,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                _showExpenseDialog(context, data);
                              },
                            ),
                            IconButton(
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

      /// 👇 Floating Action Button to create a new trip
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateTripPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showExpenseDialog(BuildContext context, Map<String, dynamic> data) {
    final fuel = data['fuelCost'] ?? 0;
    final service = data['serviceCost'] ?? 0;
    final toll = data['tollCost'] ?? 0;
    final total = data['totalCost'] ?? (fuel + service + toll);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Trip Expenses"),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
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

                // Trip details
                pw.Text("Driver Name: ${data['driverName'] ?? 'N/A'}"),
                pw.Text("Vehicle Type: ${data['vehicleType'] ?? 'N/A'}"),
                pw.Text("Vehicle No: ${data['vehicleNumber'] ?? 'N/A'}"),
                pw.Text(
                  "Vehicle Code: ${data['vehicleCode'] ?? 'N/A'}",
                ), // ✅ Added
                pw.Text("Route: ${data['start']} → ${data['end']}"),

                pw.SizedBox(height: 20),

                // Expense Table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
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
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
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
                pw.Text(
                  "Vehicle Code: ${data['vehicleCode'] ?? 'N/A'}",
                ), // ✅ Added
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
