import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routefixer/services/cameraservice.dart';
import 'package:routefixer/services/report_service.dart';

class Repoartscreen extends StatefulWidget {
  final int? segmentId;

  const Repoartscreen({super.key, this.segmentId});

  @override
  State<Repoartscreen> createState() => _RepoartscreenState();
}

class _RepoartscreenState extends State<Repoartscreen> {
  List<dynamic> reports = [];
  bool loading = true;
  String? firebaseUid;
  String selectedStatus = "All";

  // CHANGE THIS TO YOUR ACTUAL DOMAIN
  final String imageBaseUrl = "https://routefixer.dpdns.org";

  final List<String> statusFilters = [
    "All",
    "Pending",
    "Verified",
    "In Process",
    "Rejected",
    "Resolved",
  ];

  final ReportService reportService = ReportService();

  @override
  void initState() {
    super.initState();
    if (widget.segmentId != null) {
      fetchSegmentReports(widget.segmentId!);
    } else {
      loadUser();
    }
  }

  Future<void> loadUser() async {
    firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid == null) {
      setState(() => loading = false);
      return;
    }
    await fetchUserReports();
  }

  Future<void> fetchUserReports() async {
    try {
      final data = await reportService.getReports(firebaseUid!);
      if (mounted) {
        setState(() {
          reports = data;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user reports: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> fetchSegmentReports(int segmentId) async {
    try {
      final data = await reportService.getReportsBySegment(segmentId);
      if (mounted) {
        setState(() {
          reports = data;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching segment reports: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _onRefresh() async {
    setState(() => loading = true);
    if (widget.segmentId != null) {
      await fetchSegmentReports(widget.segmentId!);
    } else {
      await fetchUserReports();
    }
  }

  List<dynamic> get filteredReports {
    if (selectedStatus == "All") return reports;
    return reports
        .where(
          (r) =>
              r["status"]?.toString().toLowerCase() ==
              selectedStatus.toLowerCase(),
        )
        .toList();
  }

  // --- STATUS COLORS (Blue/Indigo Theme) ---
  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "verified":
        return Colors.blue;
      case "in process":
      case "in-process":
        return Colors.indigo; // Deep Blue
      case "rejected":
        return Colors.red;
      case "resolved":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "N/A";
    try {
      final DateTime dt = DateTime.parse(isoString);
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  // =====================================================
  // DETAILS DIALOG (Shows ALL Data)
  // =====================================================
  void _showReportDetails(BuildContext context, dynamic report) {
    String? imageUrl = report["image_url"];
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        !imageUrl.startsWith("http")) {
      imageUrl = "$imageBaseUrl$imageUrl";
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- IMAGE HEADER ---
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),

            // --- DATA BODY ---
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Title + Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            report["damage_type"] ?? "Report Details",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              report["status"],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _statusColor(report["status"]),
                            ),
                          ),
                          child: Text(
                            report["status"] ?? "Unknown",
                            style: TextStyle(
                              color: _statusColor(report["status"]),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),
                    Text(
                      "ID: ${report["id"]} • Segment: ${report["segment_id"] ?? "N/A"}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const Divider(height: 25),

                    // Description
                    const Text(
                      "Description",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      report["description"] != null &&
                              report["description"].toString().isNotEmpty
                          ? report["description"]
                          : "No description provided.",
                    ),

                    const SizedBox(height: 20),

                    // --- ANALYSIS SECTION ---
                    _buildSectionHeader("Analysis"),
                    _buildDetailRow("Severity", report["severity"] ?? "Low"),
                    _buildDetailRow(
                      "AI Detected",
                      report["ml_prediction"] ?? "Pending",
                    ),
                    _buildDetailRow(
                      "Confidence",
                      report["ml_confidence"] != null
                          ? "${report["ml_confidence"]}%"
                          : "N/A",
                    ),

                    const SizedBox(height: 15),

                    // --- LOCATION SECTION ---
                    _buildSectionHeader("Location"),
                    if (report["road_name"] != null)
                      _buildDetailRow("Road", report["road_name"]),
                    if (report["locality"] != null)
                      _buildDetailRow("Locality", report["locality"]),
                    if (report["city"] != null)
                      _buildDetailRow("City", report["city"]),
                    _buildDetailRow(
                      "GPS",
                      "${report["latitude"] ?? "?"}, ${report["longitude"] ?? "?"}",
                    ),

                    const SizedBox(height: 15),

                    // --- TIMESTAMPS SECTION ---
                    _buildSectionHeader("Timeline"),
                    _buildDetailRow(
                      "Reported On",
                      _formatDate(report["timestamp"]),
                    ),
                    _buildDetailRow(
                      "Last Updated",
                      _formatDate(report["updated_at"]),
                    ),
                  ],
                ),
              ),
            ),

            // --- CLOSE BUTTON ---
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Close"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.segmentId != null ? "Segment Reports" : "My Reports",
        ),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // STATUS FILTER CHIPS
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: statusFilters.map((status) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: selectedStatus == status,
                          onSelected: (_) =>
                              setState(() => selectedStatus = status),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // REPORT LIST
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: filteredReports.isEmpty
                        ? const Center(child: Text("No Reports Found"))
                        : ListView.builder(
                            itemCount: filteredReports.length,
                            itemBuilder: (context, index) {
                              final report = filteredReports[index];
                              return Card(
                                elevation: 1,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),

                                  // NO LEADING ICON
                                  leading: null,

                                  title: Text(
                                    report["damage_type"] ?? "Unknown",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),

                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      report["description"] ?? "",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),

                                  // STATUS AT THE END
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(
                                        report["status"],
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _statusColor(
                                          report["status"],
                                        ).withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      report["status"] ?? "Unknown",
                                      style: TextStyle(
                                        color: _statusColor(report["status"]),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                  onTap: () =>
                                      _showReportDetails(context, report),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: "reportFAB",
        onPressed: () {
          final cams = CameraService().cameras;
          if (cams.isNotEmpty) {
            context.pushNamed("capture", extra: cams.first);
          } else {
            availableCameras().then((cams) {
              CameraService().setCameras(cams);
              if (cams.isNotEmpty) {
                context.pushNamed("capture", extra: cams.first);
              }
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
