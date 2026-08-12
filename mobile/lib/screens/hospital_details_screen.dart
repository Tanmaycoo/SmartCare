// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class HospitalDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> hospital;
  const HospitalDetailsScreen({super.key, required this.hospital});

  @override
  Widget build(BuildContext context) {
    final String name = hospital['name'] ?? 'Unnamed Hospital';
    final String address = hospital['address'] ?? '';
    final String city = hospital['city'] ?? '';
    final String state = hospital['state'] ?? '';
    final String postalCode = hospital['postal_code'] ?? '';
    final String phone = hospital['phone'] ?? '';
    final String email = hospital['email'] ?? '';
    final double latitude = (hospital['latitude'] as num?)?.toDouble() ?? 0.0;
    final double longitude = (hospital['longitude'] as num?)?.toDouble() ?? 0.0;
    final bool emergency = hospital['emergency_available'] ?? false;
    final String verStatus = hospital['verification_status'] ?? 'PENDING';
    final String hospStatus = hospital['status'] ?? 'INACTIVE';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Details'),
        backgroundColor: const Color(0xFF131B2E),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF00A896).withOpacity(0.2), const Color(0xFF131B2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF00A896).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_hospital_rounded, color: Color(0xFF00A896), size: 36),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                city.isNotEmpty ? '$city, $state' : address,
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Status Summary Row
              Row(
                children: [
                  Expanded(
                    child: _buildBadgeCard('Verification', verStatus, verColor, Icons.verified_user_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildBadgeCard('Status', hospStatus, hospStatus == 'ACTIVE' ? Colors.tealAccent : Colors.grey, Icons.power_settings_new_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildBadgeCard('Emergency', emergency ? 'Available' : 'Disabled', emergency ? Colors.redAccent : Colors.grey, Icons.emergency_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Detailed Info List
              const Text('General Information', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _buildInfoTile(Icons.location_on_outlined, 'Full Address', '$address\n$city, $state $postalCode'),
              _buildInfoTile(Icons.phone_outlined, 'Phone', phone),
              _buildInfoTile(Icons.email_outlined, 'Email', email),
              _buildInfoTile(Icons.my_location_rounded, 'Coordinates (Lat, Lng)', '$latitude, $longitude'),
              _buildInfoTile(Icons.medical_services_outlined, 'Emergency Availability', emergency ? '24/7 Emergency Services Available' : 'No Emergency Services'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00A896).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00A896), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
