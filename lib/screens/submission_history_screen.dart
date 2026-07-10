import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/submission.dart';
import '../services/api_service.dart';

class SubmissionHistoryScreen extends StatefulWidget {
  const SubmissionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SubmissionHistoryScreen> createState() => _SubmissionHistoryScreenState();
}

class _SubmissionHistoryScreenState extends State<SubmissionHistoryScreen> {
  List<HcpProfileSubmission> _submissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final allSubmissions = await apiService.fetchSubmissions();
      // Filter by the current MedRep's email
      final myEmail = apiService.loggedInEmail;
      setState(() {
        _submissions = myEmail != null
            ? allSubmissions.where((s) => s.medrepEmail == myEmail).toList()
            : allSubmissions;
        // Sort by name descending (newest first)
        _submissions.sort((a, b) => (b.name ?? '').compareTo(a.name ?? ''));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading submissions: $e')),
      );
    }
  }

  String _statusLabel(int docstatus) {
    switch (docstatus) {
      case 0:
        return 'Draft';
      case 1:
        return 'Submitted';
      case 2:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color _statusColor(int docstatus) {
    switch (docstatus) {
      case 0:
        return const Color(0xFFFF9F0A); // Orange — Draft
      case 1:
        return const Color(0xFF30D158); // Green — Submitted
      case 2:
        return const Color(0xFFFF453A); // Red — Cancelled
      default:
        return const Color(0xFF8E8E93);
    }
  }

  IconData _statusIcon(int docstatus) {
    switch (docstatus) {
      case 0:
        return Icons.edit_note;
      case 1:
        return Icons.check_circle;
      case 2:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  void _showSubmissionDetail(HcpProfileSubmission submission) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_statusIcon(submission.docstatus),
                color: _statusColor(submission.docstatus), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                submission.hcpFullName ?? submission.hcpName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Submission ID', submission.name ?? 'N/A'),
              _detailRow('Status', _statusLabel(submission.docstatus),
                  color: _statusColor(submission.docstatus)),
              _detailRow('Doctor (HCP)', submission.hcpName),
              _detailRow('Date', submission.submissionDate ?? 'N/A'),
              _detailRow('MedRep', submission.medrepEmail ?? 'N/A'),
              _detailRow(
                  'Consent Given',
                  submission.consentPrivacyUnderstood
                      ? 'Yes \u2713'
                      : 'No \u2717',
                  color: submission.consentPrivacyUnderstood
                      ? Colors.green
                      : Colors.red),
              if (submission.surveyTemplateTitle != null)
                _detailRow('Survey Template', submission.surveyTemplateTitle!),
              if (submission.regionName != null)
                _detailRow('Region', submission.regionName!),
              if (submission.institution != null)
                _detailRow('Institution', submission.institution!),
              const Divider(color: Color(0xFF2C2C2E), height: 24),
              const Text('Specialties',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              if (submission.specialties.isEmpty)
                const Text('None recorded.',
                    style: TextStyle(color: Colors.white30, fontSize: 13))
              else
                ...submission.specialties.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 3.0),
                      child: Text(
                          '\u2022 ${s.hcpSpecialty}${s.subSpecialty != null ? " (${s.subSpecialty})" : ""}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    )),
              const Divider(color: Color(0xFF2C2C2E), height: 24),
              const Text('Survey Answers',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              if (submission.answers.isEmpty)
                const Text('No survey answers.',
                    style: TextStyle(color: Colors.white30, fontSize: 13))
              else
                ...submission.answers.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                          '\u2022 ${a.question}: ${a.answer.isNotEmpty ? a.answer : "N/A"}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style: TextStyle(color: Color(0xFF8E8E93))),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: color ?? Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      appBar: AppBar(
        title: const Text('Submission History'),
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubmissions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5856D6)),
              ),
            )
          : _submissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 64, color: Colors.white.withOpacity(0.15)),
                      const SizedBox(height: 16),
                      const Text(
                        'No submissions found.',
                        style: TextStyle(color: Colors.white38, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Profile a doctor from the Masterlist to create submissions.',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSubmissions,
                  color: const Color(0xFF5856D6),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _submissions.length,
                    itemBuilder: (ctx, index) {
                      final sub = _submissions[index];
                      return Card(
                        color: const Color(0xFF1C1C1E),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _statusColor(sub.docstatus)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _statusIcon(sub.docstatus),
                              color: _statusColor(sub.docstatus),
                              size: 22,
                            ),
                          ),
                          title: Text(
                            sub.hcpFullName ?? sub.hcpName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          subtitle: Text(
                            '${_statusLabel(sub.docstatus)} \u2022 ${sub.submissionDate ?? "No date"}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Color(0xFF8E8E93)),
                          onTap: () => _showSubmissionDetail(sub),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
