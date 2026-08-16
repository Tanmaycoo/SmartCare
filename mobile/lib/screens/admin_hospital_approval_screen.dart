import 'package:flutter/material.dart';
import 'package:smartcare/core/hospital_service.dart';

/// Admin Hospital Approval Screen — design.md §15
/// System Admin can review pending hospitals, approve or reject with reason.
class AdminHospitalApprovalScreen extends StatefulWidget {
  const AdminHospitalApprovalScreen({super.key});

  @override
  State<AdminHospitalApprovalScreen> createState() =>
      _AdminHospitalApprovalScreenState();
}

class _AdminHospitalApprovalScreenState
    extends State<AdminHospitalApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pendingHospitals = [];
  List<dynamic> _allHospitals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final pending = await HospitalService.getPendingHospitals();
    final all = await HospitalService.getAllHospitalsAdmin();

    if (!mounted) return;

    if (pending['success'] == true && all['success'] == true) {
      setState(() {
        _pendingHospitals =
            List<dynamic>.from(pending['data'] as List? ?? []);
        _allHospitals = List<dynamic>.from(all['data'] as List? ?? []);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = pending['error'] ?? all['error'] ?? 'Failed to load hospitals';
        _isLoading = false;
      });
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _approveHospital(Map<String, dynamic> hospital) async {
    final confirmed = await _showConfirmDialog(
      title: 'Approve Hospital',
      message:
          'Approve "${hospital['name']}"?\nIt will become visible to patients.',
      confirmText: 'Approve',
      confirmColor: const Color(0xFF00C48C),
    );
    if (!confirmed || !mounted) return;

    _showLoadingSnackBar('Approving hospital…');
    final result =
        await HospitalService.approveHospital(hospital['id'] as int);
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${hospital['name']} approved successfully.'),
          backgroundColor: const Color(0xFF00C48C),
        ),
      );
      _loadData();
    } else {
      _showErrorSnackBar(result['error'] ?? 'Approval failed');
    }
  }

  Future<void> _rejectHospital(Map<String, dynamic> hospital) async {
    final reason = await _showRejectDialog(hospital['name'] as String);
    if (reason == null || !mounted) return;

    _showLoadingSnackBar('Rejecting hospital…');
    final result = await HospitalService.rejectHospital(
      hospital['id'] as int,
      reason: reason.isNotEmpty ? reason : null,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hospital rejected.'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      _loadData();
    } else {
      _showErrorSnackBar(result['error'] ?? 'Rejection failed');
    }
  }

  Future<void> _activateHospital(int id) async {
    _showLoadingSnackBar('Activating…');
    final result = await HospitalService.activateHospital(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (result['success'] == true) {
      _loadData();
    } else {
      _showErrorSnackBar(result['error'] ?? 'Failed to activate');
    }
  }

  Future<void> _deactivateHospital(int id) async {
    _showLoadingSnackBar('Deactivating…');
    final result = await HospitalService.deactivateHospital(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (result['success'] == true) {
      _loadData();
    } else {
      _showErrorSnackBar(result['error'] ?? 'Failed to deactivate');
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmText,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<String?> _showRejectDialog(String hospitalName) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Hospital'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject "$hospitalName"?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (optional)',
                hintText: 'e.g. Incomplete documentation',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935)),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Confirm Rejection',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLoadingSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)),
          const SizedBox(width: 12),
          Text(msg),
        ]),
        duration: const Duration(seconds: 30),
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFE53935),
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Hospital Verification',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFF00C48C),
          tabs: [
            Tab(
              text: 'Pending (${_pendingHospitals.length})',
              icon: const Icon(Icons.pending_actions),
            ),
            Tab(
              text: 'All (${_allHospitals.length})',
              icon: const Icon(Icons.local_hospital),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A237E)))
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _loadData)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _PendingTab(
                      hospitals: _pendingHospitals,
                      onApprove: _approveHospital,
                      onReject: _rejectHospital,
                    ),
                    _AllHospitalsTab(
                      hospitals: _allHospitals,
                      onActivate: _activateHospital,
                      onDeactivate: _deactivateHospital,
                    ),
                  ],
                ),
    );
  }
}

// ── Pending Tab ────────────────────────────────────────────────────────────────

class _PendingTab extends StatelessWidget {
  final List<dynamic> hospitals;
  final void Function(Map<String, dynamic>) onApprove;
  final void Function(Map<String, dynamic>) onReject;

  const _PendingTab({
    required this.hospitals,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (hospitals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF00C48C)),
            SizedBox(height: 16),
            Text('No pending hospitals.',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text('All hospitals have been reviewed.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hospitals.length,
      itemBuilder: (context, i) {
        final h = hospitals[i] as Map<String, dynamic>;
        return _HospitalApprovalCard(
          hospital: h,
          onApprove: () => onApprove(h),
          onReject: () => onReject(h),
        );
      },
    );
  }
}

// ── All Hospitals Tab ──────────────────────────────────────────────────────────

class _AllHospitalsTab extends StatelessWidget {
  final List<dynamic> hospitals;
  final void Function(int) onActivate;
  final void Function(int) onDeactivate;

  const _AllHospitalsTab({
    required this.hospitals,
    required this.onActivate,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    if (hospitals.isEmpty) {
      return const Center(
        child: Text('No hospitals registered yet.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hospitals.length,
      itemBuilder: (context, i) {
        final h = hospitals[i] as Map<String, dynamic>;
        final verStatus = h['verification_status'] as String? ?? '';
        final hStatus = h['status'] as String? ?? '';
        final isActive =
            verStatus == 'VERIFIED' && hStatus == 'ACTIVE';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h['name'] as String? ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('${h['city'] ?? ''}, ${h['state'] ?? ''}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      _StatusBadge(verStatus: verStatus, hStatus: hStatus),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (!isActive)
                      TextButton.icon(
                        icon: const Icon(Icons.check_circle,
                            color: Color(0xFF00C48C), size: 18),
                        label: const Text('Activate',
                            style: TextStyle(color: Color(0xFF00C48C))),
                        onPressed: () => onActivate(h['id'] as int),
                      ),
                    if (isActive)
                      TextButton.icon(
                        icon: const Icon(Icons.block,
                            color: Color(0xFFE53935), size: 18),
                        label: const Text('Deactivate',
                            style: TextStyle(color: Color(0xFFE53935))),
                        onPressed: () => onDeactivate(h['id'] as int),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Hospital Approval Card — design.md §15 ─────────────────────────────────────

class _HospitalApprovalCard extends StatelessWidget {
  final Map<String, dynamic> hospital;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _HospitalApprovalCard({
    required this.hospital,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              const Icon(Icons.local_hospital,
                  color: Color(0xFF1A237E), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hospital['name'] as String? ?? '',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9C4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('● PENDING',
                    style: TextStyle(
                        color: Color(0xFFF57F17),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ]),
            const Divider(height: 24),

            // Details
            _DetailRow(icon: Icons.location_on, label: 'Address', value: hospital['address'] as String? ?? ''),
            _DetailRow(icon: Icons.location_city, label: 'City / State', value: '${hospital['city'] ?? ''}, ${hospital['state'] ?? ''}'),
            _DetailRow(icon: Icons.phone, label: 'Phone', value: hospital['phone'] as String? ?? ''),
            _DetailRow(icon: Icons.email, label: 'Email', value: hospital['email'] as String? ?? ''),
            _DetailRow(
              icon: Icons.emergency,
              label: 'Emergency',
              value: (hospital['emergency_available'] == true) ? 'Available' : 'Not Available',
            ),
            const SizedBox(height: 20),

            // Action buttons — design.md §15
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('APPROVE',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C48C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onApprove,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text('REJECT',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onReject,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1A237E)),
          const SizedBox(width: 8),
          SizedBox(
              width: 90,
              child: Text('$label:',
                  style: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(
              child:
                  Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String verStatus;
  final String hStatus;

  const _StatusBadge({required this.verStatus, required this.hStatus});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    if (verStatus == 'VERIFIED' && hStatus == 'ACTIVE') {
      color = const Color(0xFF00C48C);
      label = '● APPROVED';
    } else if (verStatus == 'REJECTED') {
      color = const Color(0xFFE53935);
      label = '● REJECTED';
    } else if (verStatus == 'PENDING') {
      color = const Color(0xFFF57F17);
      label = '● PENDING';
    } else {
      color = Colors.grey;
      label = '● INACTIVE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFE53935)),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
