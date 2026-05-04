// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routefixer/services/report_service.dart';
import 'package:routefixer/widgets/app_inputfield.dart';

class AddDetailsPage extends StatefulWidget {
  final File imageFile;
  final String gps;
  final String time;
  final String firebaseUid;

  const AddDetailsPage({
    super.key,
    required this.imageFile,
    required this.gps,
    required this.time,
    required this.firebaseUid,
  });

  @override
  State<AddDetailsPage> createState() => _AddDetailsPageState();
}

class _AddDetailsPageState extends State<AddDetailsPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ReportService _reportService = ReportService();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /* -------------------- STATUS BANNER -------------------- */

  void _showStatusBanner({required String message, required Color color}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /* -------------------- FAILURE (DJANGO UNREACHABLE) -------------------- */

  Future<void> _handleNetworkFailure() async {
    if (!mounted) return;

    _showStatusBanner(message: 'Report submission failed', color: Colors.red);

    await Future.delayed(const Duration(seconds: 2));
    context.pop({'status': 'network_error'});
    context.pop();
  }

  /* -------------------- SUBMIT LOGIC -------------------- */

  Future<void> _saveDetails() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      // If this line returns ANY response → Django RECEIVED the report
      await _reportService
          .sendReport(
            firebaseUid: widget.firebaseUid,
            imageFile: widget.imageFile,
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            gps: widget.gps,
            time: widget.time,
          )
          .timeout(const Duration(seconds: 15));

      // ✅ Django reached → SUCCESS
      if (!mounted) return;

      _showStatusBanner(
        message: 'Report submitted successfully',
        color: Colors.green,
      );

      await Future.delayed(const Duration(seconds: 2));
      context.pop({'status': 'success'});
      context.pop();
    } on TimeoutException {
      // ❌ Server unreachable
      await _handleNetworkFailure();
    } on SocketException {
      // ❌ No internet / connection refused
      await _handleNetworkFailure();
    } catch (_) {
      // ❌ Any transport-level failure
      await _handleNetworkFailure();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /* -------------------- UI -------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Details')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  widget.imageFile,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Text('Time: ${widget.time}'),
              Text('GPS: ${widget.gps}'),
              const SizedBox(height: 20),
              AppInputField(
                controller: _titleController,
                label: 'Title',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              AppInputField(
                controller: _descController,
                label: 'Description',
                maxlines: 3,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter a description'
                    : null,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _saveDetails,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isSubmitting ? 'Uploading...' : 'Submit Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
