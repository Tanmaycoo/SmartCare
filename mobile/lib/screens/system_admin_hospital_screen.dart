// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:smartcare/core/hospital_service.dart';
import 'package:smartcare/screens/hospital_details_screen.dart';

class SystemAdminHospitalScreen extends StatefulWidget {
  const SystemAdminHospitalScreen({super.key});

  @override
  State<SystemAdminHospitalScreen> createState() => _SystemAdminHospitalScreenState();
}

class _SystemAdminHospitalScreenState extends State<SystemAdminHospitalScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _hospitals = [];
  String _selectedFilter = 'ALL'; // ALL, PENDING, VERIFIED, REJECTED, SUSPENDED

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String? verParam = _selectedFilter == 'ALL' ? null : _selectedFilter;
    final result = await HospitalService.getHospitals(verificationStatus: verParam);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _hospitals = result['data'] as List<dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['error'] as String? ?? 'Failed to load hospitals';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmAction({
    required String title,
    required String content,
    required Color color,
    required Future<Map<String, dynamic>> Function() onConfirm,
  }) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await onConfirm();
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Action executed successfully!'),
            backgroundColor: const Color(0xFF00A896),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadHospitals();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] ?? 'Action failed'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Admin - Hospitals'),
        backgroundColor: const Color(0xFF131B2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHospitals,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: ['ALL', 'PENDING', 'VERIFIED', 'REJECTED', 'SUSPENDED'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(filter),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      selectedColor: const Color(0xFF00A896),
                      backgroundColor: const Color(0xFF131B2E),
                      side: BorderSide(color: isSelected ? const Color(0xFF00A896) : const Color(0xFF1E293B)),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = filter);
                          _loadHospitals();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // Main List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadHospitals,
                color: const Color(0xFF00A896),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A896)))
                    : _errorMessage != null
                        ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
                        : _hospitals.isEmpty
                            ? const Center(
                                child: Text('No hospitals found', style: TextStyle(color: Colors.white38)),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _hospitals.length,
                                itemBuilder: (context, index) {
                                  final h = _hospitals[index] as Map<String, dynamic>;
                                  return _buildAdminHospitalCard(context, h);
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHospitalCard(BuildContext context, Map<String, dynamic> hospital) {
    final int hospitalId = hospital['id'] as int;
    final String name = hospital['name'] ?? 'Unnamed';
    final String city = hospital['city'] ?? 'Unknown City';
    final String verStatus = hospital['verification_status'] ?? 'PENDING';
    final String hospStatus = hospital['status'] ?? 'INACTIVE';
    final bool emergency = hospital['emergency_available'] ?? false;

    Color verColor;
    switch (verStatus) {
      case 'VERIFIED':
        verColor = Colors.greenAccent;
        break;
      case 'REJECTED':
        verColor = Colors.redAccent;
        break;
      case 'SUSPENDED':
        verColor = Colors.orangeAccent;
        break;
      default:
        verColor = Colors.amber;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(16),
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
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.visibility_rounded, color: Color(0xFF00A896)),
                tooltip: 'View Details',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HospitalDetailsScreen(hospital: hospital)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_city_rounded, color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              Text(city, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const Spacer(),
              Icon(Icons.emergency_rounded, color: emergency ? Colors.redAccent : Colors.grey, size: 14),
              const SizedBox(width: 4),
              Text(
                emergency ? 'Emergency' : 'No Emergency',
                style: TextStyle(color: emergency ? Colors.redAccent : Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status Badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: verColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ver: $verStatus',
                  style: TextStyle(color: verColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hospStatus == 'ACTIVE' ? Colors.teal.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Status: $hospStatus',
                  style: TextStyle(
                    color: hospStatus == 'ACTIVE' ? Colors.tealAccent : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFF1E293B)),
          const SizedBox(height: 10),

          // Action Buttons Bar
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Verify Button
              if (verStatus != 'VERIFIED')
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: const Text('Verify', style: TextStyle(fontSize: 11)),
                  onPressed: () => _confirmAction(
                    title: 'Verify Hospital',
                    content: 'Approve "$name" and activate its services?',
                    color: Colors.green,
                    onConfirm: () => HospitalService.verifyHospital(hospitalId, 'VERIFIED'),
                  ),
                ),

              // Reject Button
              if (verStatus != 'REJECTED')
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('Reject', style: TextStyle(fontSize: 11)),
                  onPressed: () => _confirmAction(
                    title: 'Reject Hospital',
                    content: 'Reject verification for "$name"?',
                    color: Colors.redAccent,
                    onConfirm: () => HospitalService.verifyHospital(hospitalId, 'REJECTED'),
                  ),
                ),

              // Activate Button
              if (hospStatus != 'ACTIVE')
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.play_circle_outline, size: 14),
                  label: const Text('Activate', style: TextStyle(fontSize: 11)),
                  onPressed: () => _confirmAction(
                    title: 'Activate Hospital',
                    content: 'Set "$name" status to ACTIVE?',
                    color: Colors.teal,
                    onConfirm: () => HospitalService.activateHospital(hospitalId),
                  ),
                ),

              // Suspend Button
              if (verStatus != 'SUSPENDED')
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.pause_circle_outline, size: 14),
                  label: const Text('Suspend', style: TextStyle(fontSize: 11)),
                  onPressed: () => _confirmAction(
                    title: 'Suspend Hospital',
                    content: 'Suspend "$name"? It will be hidden from patient search.',
                    color: Colors.orangeAccent,
                    onConfirm: () => HospitalService.suspendHospital(hospitalId),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
