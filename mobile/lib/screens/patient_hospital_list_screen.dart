// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:smartcare/core/hospital_service.dart';
import 'package:smartcare/screens/hospital_details_screen.dart';

class PatientHospitalListScreen extends StatefulWidget {
  const PatientHospitalListScreen({super.key});

  @override
  State<PatientHospitalListScreen> createState() => _PatientHospitalListScreenState();
}

class _PatientHospitalListScreenState extends State<PatientHospitalListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _hospitals = [];

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

    final result = await HospitalService.getHospitals();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verified Hospitals'),
        backgroundColor: const Color(0xFF131B2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHospitals,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHospitals,
          color: const Color(0xFF00A896),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A896)))
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
                  : _hospitals.isEmpty
                      ? const Center(
                          child: Text('No active verified hospitals available', style: TextStyle(color: Colors.white38)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _hospitals.length,
                          itemBuilder: (context, index) {
                            final h = _hospitals[index] as Map<String, dynamic>;
                            return _buildHospitalTile(context, h);
                          },
                        ),
        ),
      ),
    );
  }

  Widget _buildHospitalTile(BuildContext context, Map<String, dynamic> hospital) {
    final String name = hospital['name'] ?? 'Unnamed Hospital';
    final String city = hospital['city'] ?? 'Unknown City';
    final String address = hospital['address'] ?? '';
    final bool emergency = hospital['emergency_available'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF00A896).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF00A896), size: 28),
        ),
        title: Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('$address, $city', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.emergency_rounded,
                  color: emergency ? Colors.redAccent : Colors.grey,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  emergency ? 'Emergency Available' : 'No Emergency',
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
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HospitalDetailsScreen(hospital: hospital)),
          );
        },
      ),
    );
  }
}
