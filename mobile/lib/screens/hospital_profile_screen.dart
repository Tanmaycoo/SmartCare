// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:smartcare/core/hospital_service.dart';

class HospitalProfileScreen extends StatefulWidget {
  final Map<String, dynamic> hospital;
  const HospitalProfileScreen({super.key, required this.hospital});

  @override
  State<HospitalProfileScreen> createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends State<HospitalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late bool _emergencyAvailable;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final h = widget.hospital;
    _nameController = TextEditingController(text: h['name'] ?? '');
    _addressController = TextEditingController(text: h['address'] ?? '');
    _cityController = TextEditingController(text: h['city'] ?? '');
    _stateController = TextEditingController(text: h['state'] ?? '');
    _postalCodeController = TextEditingController(text: h['postal_code'] ?? '');
    _phoneController = TextEditingController(text: h['phone'] ?? '');
    _emailController = TextEditingController(text: h['email'] ?? '');
    _latitudeController = TextEditingController(text: (h['latitude'] ?? 0.0).toString());
    _longitudeController = TextEditingController(text: (h['longitude'] ?? 0.0).toString());
    _emergencyAvailable = h['emergency_available'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final int hospitalId = widget.hospital['id'] as int;
    final lat = double.tryParse(_latitudeController.text.trim()) ?? 0.0;
    final lng = double.tryParse(_longitudeController.text.trim()) ?? 0.0;

    final updateData = {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'postal_code': _postalCodeController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'latitude': lat,
      'longitude': lng,
      'emergency_available': _emergencyAvailable,
    };

    final result = await HospitalService.updateHospital(hospitalId, updateData);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hospital profile updated successfully!'),
          backgroundColor: const Color(0xFF00A896),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _errorMessage = result['error'] as String? ?? 'Failed to update hospital';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Hospital Profile'),
        backgroundColor: const Color(0xFF131B2E),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Hospital Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Hospital Name *', Icons.business_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),

                // Address
                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: _inputDecoration('Full Address *', Icons.location_on_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                ),
                const SizedBox(height: 14),

                // City & State
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('City', Icons.location_city_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('State', Icons.map_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Postal Code & Phone
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _postalCodeController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Postal Code', Icons.local_post_office_outlined),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Phone *', Icons.phone_outlined),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Email *', Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Latitude & Longitude
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Latitude *', Icons.my_location_rounded),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null || val < -90 || val > 90) return 'Between -90 and 90';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Longitude *', Icons.my_location_rounded),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null || val < -180 || val > 180) return 'Between -180 & 180';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Emergency Available Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.emergency_rounded, color: Colors.redAccent, size: 22),
                          SizedBox(width: 12),
                          Text('Emergency Services Available', style: TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                      Switch(
                        value: _emergencyAvailable,
                        activeColor: const Color(0xFF00A896),
                        onChanged: (val) => setState(() => _emergencyAvailable = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A896),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('SAVE CHANGES', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      filled: true,
      fillColor: const Color(0xFF131B2E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1E293B))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1E293B))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00A896), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }
}
