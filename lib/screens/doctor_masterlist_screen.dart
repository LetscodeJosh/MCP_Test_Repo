import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hcp.dart';
import '../models/lookup_models.dart';
import '../services/api_service.dart';
import 'hcp_wizard_screen.dart';
import 'self_service_qr_screen.dart';
import 'list_screen.dart';
import 'submission_history_screen.dart';
import 'login_screen.dart';

class DoctorMasterlistScreen extends StatefulWidget {
  const DoctorMasterlistScreen({Key? key}) : super(key: key);

  @override
  State<DoctorMasterlistScreen> createState() => _DoctorMasterlistScreenState();
}

class _DoctorMasterlistScreenState extends State<DoctorMasterlistScreen> {
  List<Hcp> _allDoctors = [];
  List<Hcp> _filteredDoctors = [];
  List<Institution> _institutions = [];
  List<Specialization> _specializations = [];
  List<PsgcLocation> _psgcLocations = [];

  bool _isLoading = true;
  String _searchQuery = '';
  
  // Selected filter values
  String? _selectedSpecialty;
  String? _selectedInstitution;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final doctors = await apiService.fetchDoctors();
      final institutions = await apiService.fetchInstitutions();
      final specializations = await apiService.fetchSpecializations();
      final psgc = await apiService.fetchPsgcLocations();

      setState(() {
        _allDoctors = doctors;
        _institutions = institutions;
        _specializations = specializations.where((s) => !s.isGroup).toList();
        _psgcLocations = psgc;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading doctor list: $e')),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        final fullName = '${doctor.firstName} ${doctor.lastName}'.toLowerCase();
        final matchesSearch = fullName.contains(_searchQuery.toLowerCase()) ||
            (doctor.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        final matchesSpecialty = _selectedSpecialty == null ||
            doctor.specialties.any((s) => s.hcpSpecialty == _selectedSpecialty);

        final matchesInstitution = _selectedInstitution == null ||
            doctor.workplaces.any((w) => w.workplace == _selectedInstitution);

        final matchesLocation = _selectedLocation == null ||
            doctor.regionName == _selectedLocation ||
            doctor.provinceName == _selectedLocation ||
            doctor.cityMunicipality == _selectedLocation ||
            doctor.barangayName == _selectedLocation;

        return matchesSearch && matchesSpecialty && matchesInstitution && matchesLocation;
      }).toList();
    });
  }

  void _showDoctorDetailsDialog(Hcp doctor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF5856D6).withOpacity(0.2),
              child: const Icon(Icons.person, color: Color(0xFF5856D6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Dr. ${doctor.firstName} ${doctor.lastName}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', doctor.name ?? 'New Doctor'),
              _buildDetailRow('Type', doctor.hcpType),
              _buildDetailRow('Practice Type', doctor.hcpPractice),
              _buildDetailRow('Status', doctor.isActive ? 'Active' : 'Inactive', 
                  color: doctor.isActive ? Colors.green : Colors.red),
              const Divider(color: Color(0xFF2C2C2E), height: 24),
              const Text('Specialties', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (doctor.specialties.isEmpty)
                const Text('No specialties declared.', style: TextStyle(color: Colors.white30, fontSize: 13))
              else
                ...doctor.specialties.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('• ${s.hcpSpecialty}${s.subSpecialty != null ? " (${s.subSpecialty})" : ""}', 
                          style: const TextStyle(color: Colors.white, fontSize: 14)),
                    )),
              const Divider(color: Color(0xFF2C2C2E), height: 24),
              const Text('Workplaces', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (doctor.workplaces.isEmpty)
                const Text('No workplaces linked.', style: TextStyle(color: Colors.white30, fontSize: 13))
              else
                ...doctor.workplaces.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text('• ${w.workplace}${w.isPrimary ? " (Primary)" : ""}', 
                          style: const TextStyle(color: Colors.white, fontSize: 14)),
                    )),
              const Divider(color: Color(0xFF2C2C2E), height: 24),
              const Text('Contact Information', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (doctor.contacts.isEmpty)
                const Text('No contact info listed.', style: TextStyle(color: Colors.white30, fontSize: 13))
              else
                ...doctor.contacts.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('${c.contactType}: ${c.contactValue}', 
                          style: const TextStyle(color: Colors.white, fontSize: 14)),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5856D6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.qr_code, color: Colors.white, size: 16),
            label: const Text('Self-Service QR', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SelfServiceQrScreen(doctor: doctor),
                ),
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.assignment_ind, color: Colors.white, size: 16),
            label: const Text('Profile Doctor', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HcpWizardScreen(doctor: doctor),
                ),
              );
              if (result == true) {
                _loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Expanded(
            child: Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showAddDoctorDialog() {
    final formKey = GlobalKey<FormState>();
    String firstName = '';
    String lastName = '';
    String selectedType = 'Physician';
    String selectedPractice = 'Both';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Register New Doctor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => firstName = val!,
              ),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => lastName = val!,
              ),
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: const Color(0xFF1C1C1E),
                decoration: const InputDecoration(
                  labelText: 'HCP Type',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
                items: const [
                  DropdownMenuItem(value: 'Physician', child: Text('Physician', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'Pharmacist', child: Text('Pharmacist', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'Nurse', child: Text('Nurse', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (val) => selectedType = val!,
              ),
              DropdownButtonFormField<String>(
                value: selectedPractice,
                dropdownColor: const Color(0xFF1C1C1E),
                decoration: const InputDecoration(
                  labelText: 'Practice Mode',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
                items: const [
                  DropdownMenuItem(value: 'Dispensing', child: Text('Dispensing', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'Prescribing', child: Text('Prescribing', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'Both', child: Text('Both', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (val) => selectedPractice = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5856D6)),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                final apiService = Provider.of<ApiService>(context, listen: false);
                try {
                  final newDoctor = Hcp(
                    firstName: firstName,
                    lastName: lastName,
                    hcpType: selectedType,
                    hcpPractice: selectedPractice,
                  );
                  await apiService.createDoctor(newDoctor);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Doctor registered successfully!')),
                  );
                  _loadData();
                } catch (e) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save: $e')),
                  );
                }
              }
            },
            child: const Text('Register', style: TextStyle(color: Colors.white)),
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
        title: const Text('Doctor Masterlist'),
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1C1C1E),
        child: SafeArea(
          child: Column(
            children: [
              // Drawer Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5856D6), Color(0xFF7D7BF2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.donut_large, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'PIMS MCP',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Provider.of<ApiService>(context, listen: false).loggedInEmail ?? '',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Navigation Items
              ListTile(
                leading: const Icon(Icons.people_alt, color: Color(0xFF5856D6)),
                title: const Text('Doctor Masterlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                selected: true,
                selectedTileColor: const Color(0xFF5856D6).withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.assignment, color: Color(0xFF30D158)),
                title: const Text('Engagements', style: TextStyle(color: Colors.white)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ListScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Color(0xFFFF9F0A)),
                title: const Text('Submission History', style: TextStyle(color: Colors.white)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmissionHistoryScreen()));
                },
              ),
              const Spacer(),
              const Divider(color: Color(0xFF2C2C2E)),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFFF453A)),
                title: const Text('Logout', style: TextStyle(color: Color(0xFFFF453A))),
                onTap: () {
                  Provider.of<ApiService>(context, listen: false).logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5856D6)),
              ),
            )
          : Column(
              children: [
                // Filter Header
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFF1C1C1E),
                  child: Column(
                    children: [
                      // Search Doctor
                      TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                            _applyFilters();
                          });
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search doctors by name or ID...',
                          hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93)),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2C),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Dropdown Filters
                      Row(
                        children: [
                          // Specialty Filter
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedSpecialty,
                                  dropdownColor: const Color(0xFF1C1C1E),
                                  hint: const Text('Specialty', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8E8E93)),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedSpecialty = val;
                                      _applyFilters();
                                    });
                                  },
                                  items: [
                                    const DropdownMenuItem<String>(value: null, child: Text('All Specialties')),
                                    ..._specializations.map((spec) => DropdownMenuItem(
                                          value: spec.specialty,
                                          child: Text(spec.specialty),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Hospital Filter
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedInstitution,
                                  dropdownColor: const Color(0xFF1C1C1E),
                                  hint: const Text('Hospital', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8E8E93)),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedInstitution = val;
                                      _applyFilters();
                                    });
                                  },
                                  items: [
                                    const DropdownMenuItem<String>(value: null, child: Text('All Hospitals')),
                                    ..._institutions.map((inst) => DropdownMenuItem(
                                          value: inst.name,
                                          child: Text(inst.institutionName),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Area / Location Filter
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedLocation,
                                  dropdownColor: const Color(0xFF1C1C1E),
                                  hint: const Text('Area / Location', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8E8E93)),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedLocation = val;
                                      _applyFilters();
                                    });
                                  },
                                  items: [
                                    const DropdownMenuItem<String>(value: null, child: Text('All Areas')),
                                    ..._psgcLocations.map((loc) => DropdownMenuItem(
                                          value: loc.name,
                                          child: Text('${loc.locationLabel} (${loc.locationType})'),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Doctor List View
                Expanded(
                  child: _filteredDoctors.isEmpty
                      ? const Center(
                          child: Text('No doctors match your criteria.', style: TextStyle(color: Colors.white38)),
                        )
                      : ListView.builder(
                          itemCount: _filteredDoctors.length,
                          itemBuilder: (ctx, index) {
                            final doctor = _filteredDoctors[index];
                            final primarySpecialty = doctor.specialties.isNotEmpty
                                ? doctor.specialties.first.hcpSpecialty
                                : 'No Specialty Declared';
                            return Card(
                              color: const Color(0xFF1C1C1E),
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF5856D6).withOpacity(0.1),
                                  child: const Icon(Icons.person, color: Color(0xFF5856D6)),
                                ),
                                title: Text(
                                  'Dr. ${doctor.firstName} ${doctor.lastName}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '$primarySpecialty • ${doctor.hcpType}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Color(0xFF8E8E93)),
                                onTap: () => _showDoctorDetailsDialog(doctor),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5856D6),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _showAddDoctorDialog,
      ),
    );
  }
}
