// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:smartcare/core/hospital_service.dart';
import 'package:smartcare/screens/hospital_registration_screen.dart';
import 'package:smartcare/screens/hospital_profile_screen.dart';

class HospitalDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HospitalDashboardScreen({super.key, required this.userData});

  @override
  State<HospitalDashboardScreen> createState() => _HospitalDashboardScreenState();
}

class _HospitalDashboardScreenState extends State<HospitalDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _hospitals = [];

  @override
  void initState() {
    super.initState();
    _loadHospitalData();
  }

  Future<void> _loadHospitalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await HospitalService.getHospitals();

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _hospitals = result['data'] as List<dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['error'] as String? ?? 'Failed to load hospital';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Dashboard'),
        backgroundColor: const Color(0xFF131B2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHospitalData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHospitalData,
          color: const Color(0xFF00A896),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hospital Portal',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          widget.userData['full_name'] ?? 'Hospital Admin',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HospitalRegistrationScreen()),
                        );
                        if (res == true) _loadHospitalData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A896),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                      label: const Text('New Hospital', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: Color(0xFF00A896)),
                    ),
                  )
                else if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadHospitalData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (_hospitals.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.domain_disabled_rounded, color: Colors.white38, size: 48),
                        const SizedBox(height: 14),
                        const Text(
                          'No Hospital Registered',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Register your hospital to start managing real-time emergency services.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HospitalRegistrationScreen()),
                            );
                            if (res == true) _loadHospitalData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A896),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add_business_rounded),
                          label: const Text('Register Hospital'),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: _hospitals.map((h) => _buildHospitalCard(context, h as Map<String, dynamic>)).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard(BuildContext context, Map<String, dynamic> hospital) {
    final String name = hospital['name'] ?? 'Unnamed Hospital';
    final String verStatus = hospital['verification_status'] ?? 'PENDING';
    final String hospStatus = hospital['status'] ?? 'INACTIVE';
    final bool emergency = hospital['emergency_available'] ?? false;

    // Status colors and icons
    Color verColor;
    IconData verIcon;
    switch (verStatus) {
      case 'VERIFIED':
        verColor = Colors.greenAccent;
        verIcon = Icons.verified_rounded;
        break;
      case 'REJECTED':
        verColor = Colors.redAccent;
        verIcon = Icons.cancel_rounded;
        break;
      case 'SUSPENDED':
        verColor = Colors.orangeAccent;
        verIcon = Icons.pause_circle_filled_rounded;
        break;
      default:
        verColor = Colors.amber;
        verIcon = Icons.pending_rounded;
    }

    final isStatusActive = hospStatus == 'ACTIVE';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Color(0xFF00A896)),
                tooltip: 'Edit Hospital Profile',
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HospitalProfileScreen(hospital: hospital),
                    ),
                  );
                  if (res == true) _loadHospitalData();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${hospital['address']}, ${hospital['city']}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFF1E293B)),

          // Status Cards Grid
          Row(
            children: [
              // Verification Status Badge
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: verColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: verColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Verification', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(verIcon, color: verColor, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              verStatus,
                              style: TextStyle(color: verColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Hospital Status Badge
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isStatusActive ? Colors.teal.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isStatusActive ? Colors.teal.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isStatusActive ? Icons.check_circle_rounded : Icons.offline_bolt_rounded,
                            color: isStatusActive ? Colors.tealAccent : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hospStatus,
                            style: TextStyle(
                              color: isStatusActive ? Colors.tealAccent : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Emergency Services Badge
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: emergency ? Colors.redAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: emergency ? Colors.redAccent.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Emergency', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.emergency_rounded,
                            color: emergency ? Colors.redAccent : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            emergency ? 'Available' : 'Disabled',
                            style: TextStyle(
                              color: emergency ? Colors.redAccent : Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
