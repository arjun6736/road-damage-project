import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/segment_details.dart';
import '../services/segment_details_service.dart';

class SegmentDetailsSheet extends StatefulWidget {
  final int segmentId;

  const SegmentDetailsSheet({super.key, required this.segmentId});

  @override
  State<SegmentDetailsSheet> createState() => _SegmentDetailsSheetState();
}

class _SegmentDetailsSheetState extends State<SegmentDetailsSheet> {
  final SegmentDetailsService _service = SegmentDetailsService();

  SegmentDetails? details;

  bool loading = true;
  bool error = false;

  // -------------------------
  // INIT
  // -------------------------
  @override
  void initState() {
    super.initState();

    debugPrint("SegmentDetailsSheet INIT - Segment ID: ${widget.segmentId}");

    _load();
  }

  // -------------------------
  // LOAD DETAILS
  // -------------------------
  Future<void> _load() async {
    debugPrint("Starting API fetch for segment ${widget.segmentId}");

    try {
      final result = await _service.fetchDetails(widget.segmentId);

      debugPrint("API fetch SUCCESS for segment ${widget.segmentId}");

      debugPrint(
        "Details received:"
        "\nID: ${result.id}"
        "\nTotal Reports: ${result.totalReports}"
        "\nMax Severity: ${result.maxSeverity}"
        "\nAvg Score: ${result.avgSeverityScore}"
        "\nLast Report: ${result.lastReportDate}",
      );

      if (!mounted) return;

      setState(() {
        details = result;
        loading = false;
        error = false;
      });
    } catch (e, stackTrace) {
      debugPrint("API fetch ERROR for segment ${widget.segmentId}");
      debugPrint("Error: $e");
      debugPrint("StackTrace: $stackTrace");

      if (!mounted) return;

      setState(() {
        error = true;
        loading = false;
      });
    }
  }

  // -------------------------
  // NAVIGATE TO REPORT PAGE (GoRouter)
  // -------------------------
  void _openReportPage() async {
    final segmentId = widget.segmentId;

    Navigator.of(context, rootNavigator: true).pop();

    await Future.delayed(const Duration(milliseconds: 150));

    GoRouter.of(context).push('/report', extra: segmentId);
  }

  // -------------------------
  // SEVERITY COLOR
  // -------------------------
  Color severityColor(String severity) {
    debugPrint("Severity color requested: $severity");

    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;

      case 'medium':
        return Colors.orange;

      case 'low':
        return Colors.yellow;

      default:
        return Colors.grey;
    }
  }

  // -------------------------
  // BUILD UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    debugPrint("SegmentDetailsSheet BUILD loading=$loading error=$error");

    return Container(
      padding: const EdgeInsets.all(16),
      height: 340, // increased height for button

      child: loading
          // -------------------------
          // LOADING STATE
          // -------------------------
          ? const Center(child: CircularProgressIndicator())
          // -------------------------
          // ERROR STATE
          // -------------------------
          : error
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 40),

                const SizedBox(height: 10),

                const Text(
                  "Failed to load segment details",
                  style: TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 10),

                Text(
                  "Segment ID: ${widget.segmentId}",
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _openReportPage,
                  icon: const Icon(Icons.report),
                  label: const Text("Report Damage"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            )
          // -------------------------
          // SUCCESS STATE
          // -------------------------
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Severity
                Row(
                  children: [
                    const Text(
                      "Max Severity: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      color: severityColor(details!.maxSeverity),
                      child: Text(
                        details!.maxSeverity.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  "Total Reports: ${details!.totalReports}",
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 8),

                Text(
                  "Average Severity Score: "
                  "${details!.avgSeverityScore.toStringAsFixed(2)}",
                ),

                const SizedBox(height: 8),

                Text("Last Report: ${details!.lastReportDate}"),

                const SizedBox(height: 16),

                const Divider(),

                const Text(
                  "Road condition based on recent reports.",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // -------------------------
                // REPORT BUTTON
                // -------------------------
                ElevatedButton.icon(
                  onPressed: _openReportPage,
                  icon: const Icon(Icons.report),
                  label: const Text("Damage Reports"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
    );
  }
}
