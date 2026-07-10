import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/hcp.dart';
import '../models/submission.dart';
import '../models/lookup_models.dart';
import '../services/api_service.dart';
import 'self_service_qr_screen.dart';

class HcpWizardScreen extends StatefulWidget {
  final Hcp doctor;

  const HcpWizardScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  State<HcpWizardScreen> createState() => _HcpWizardScreenState();
}

class _HcpWizardScreenState extends State<HcpWizardScreen> {
  int _currentStep = 0; // 0: Consent, 1: Info, 2: Survey, 3: Review
  bool _isLoading = false;

  // Step 1: Consent State
  bool _consentGiven = false;
  final ValueNotifier<List<Offset>> _signaturePoints = ValueNotifier<List<Offset>>([]);
  XFile? _consentPhotoFile;

  // Step 2: Info & Workplace State
  final List<SubmissionSpecialty> _selectedSpecialties = [];
  final List<SubmissionWorkplace> _selectedWorkplaces = [];
  final List<SubmissionContact> _contacts = [];
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;
  String? _selectedInstitution;

  // Lookup datasets
  List<Institution> _institutions = [];
  List<Specialization> _specializations = [];
  List<PsgcLocation> _psgcLocations = [];
  HcpSurveyTemplate? _activeSurvey;

  // Step 3: Survey State
  final Map<String, String> _surveyAnswers = {}; // Question -> Answer mapping

  // Step 4: Verification Signature pad for Profile edits
  final ValueNotifier<List<Offset>> _waiverSignaturePoints = ValueNotifier<List<Offset>>([]);

  @override
  void initState() {
    super.initState();
    _loadLookups();
    _prepopulateDoctorData();
  }

  void _prepopulateDoctorData() {
    // Fill in doctor's existing details
    for (var spec in widget.doctor.specialties) {
      _selectedSpecialties.add(SubmissionSpecialty(
        hcpSpecialty: spec.hcpSpecialty,
        subSpecialty: spec.subSpecialty,
      ));
    }
    for (var work in widget.doctor.workplaces) {
      _selectedWorkplaces.add(SubmissionWorkplace(
        workplace: work.workplace,
        address: work.address,
        isPrimary: work.isPrimary,
      ));
    }
    for (var contact in widget.doctor.contacts) {
      _contacts.add(SubmissionContact(
        contactType: contact.contactType,
        contactValue: contact.contactValue,
      ));
    }
    _selectedRegion = widget.doctor.regionName;
    _selectedProvince = widget.doctor.provinceName;
    _selectedCity = widget.doctor.cityMunicipality;
    _selectedBarangay = widget.doctor.barangayName;
    _selectedInstitution = widget.doctor.institution;
  }

  Future<void> _loadLookups() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final insts = await apiService.fetchInstitutions();
      final specs = await apiService.fetchSpecializations();
      final psgcs = await apiService.fetchPsgcLocations();
      final templates = await apiService.fetchSurveyTemplates();

      setState(() {
        _institutions = insts;
        _specializations = specs;
        _psgcLocations = psgcs;
        
        // Match active survey matching medrep's program
        if (templates.isNotEmpty) {
          _activeSurvey = templates.firstWhere(
            (t) => t.isActive,
            orElse: () => templates.first,
          );
          // Pre-populate survey answers map
          for (var q in _activeSurvey!.questions) {
            _surveyAnswers[q.question] = '';
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed loading lookups: $e')),
      );
    }
  }

  Future<void> _capturePhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (file != null) {
      setState(() {
        _consentPhotoFile = file;
      });
    }
  }

  // Convert custom canvas drawing coordinates into valid vector base64 SVG data-URI
  String _pointsToSvgDataUri(List<Offset> points, Size canvasSize) {
    if (points.isEmpty) return '';
    StringBuffer svg = StringBuffer();
    svg.write('<svg xmlns="http://www.w3.org/2000/svg" width="${canvasSize.width}" height="${canvasSize.height}" viewBox="0 0 ${canvasSize.width} ${canvasSize.height}">');
    svg.write('<path d="');
    bool newPath = true;
    for (var point in points) {
      if (point == Offset.infinite) {
        newPath = true;
      } else {
        if (newPath) {
          svg.write('M ${point.dx} ${point.dy} ');
          newPath = false;
        } else {
          svg.write('L ${point.dx} ${point.dy} ');
        }
      }
    }
    svg.write('" fill="none" stroke="black" stroke-width="3" stroke-linecap="round"/>');
    svg.write('</svg>');
    
    final bytes = utf8.encode(svg.toString());
    return 'data:image/svg+xml;base64,${base64Encode(bytes)}';
  }

  bool _detectProfileChanges() {
    // Checks if the user changed the doctor's primary workplace/specialty compared to original Doctor Master record
    if (widget.doctor.regionName != _selectedRegion) return true;
    if (widget.doctor.provinceName != _selectedProvince) return true;
    if (widget.doctor.cityMunicipality != _selectedCity) return true;
    if (widget.doctor.barangayName != _selectedBarangay) return true;
    
    if (widget.doctor.specialties.length != _selectedSpecialties.length) return true;
    if (widget.doctor.workplaces.length != _selectedWorkplaces.length) return true;

    return false;
  }

  Future<void> _submitForm() async {
    // If changes are detected, show the verification waiver dialog first
    if (_detectProfileChanges()) {
      final verified = await _showWaiverDialog();
      if (!verified) return; // User cancelled
    }

    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    // Convert signature
    final sigUri = _pointsToSvgDataUri(_signaturePoints.value, const Size(300, 150));
    
    // Convert photo to base64 if present
    String? photoBase64;
    if (_consentPhotoFile != null) {
      final bytes = await _consentPhotoFile!.readAsBytes();
      photoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    // Map Answers table
    final answersList = _surveyAnswers.entries.map((e) {
      return SubmissionAnswer(question: e.key, answer: e.value);
    }).toList();

    final submission = HcpProfileSubmission(
      hcpName: widget.doctor.name ?? '',
      hcpFullName: '${widget.doctor.firstName} ${widget.doctor.lastName}',
      consentPrivacyUnderstood: _consentGiven,
      consentSignature: sigUri.isNotEmpty ? sigUri : null,
      consentPhoto: photoBase64,
      specialties: _selectedSpecialties,
      workplaces: _selectedWorkplaces,
      contacts: _contacts,
      regionName: _selectedRegion,
      provinceName: _selectedProvince,
      cityMunicipality: _selectedCity,
      barangayName: _selectedBarangay,
      institution: _selectedInstitution,
      surveyTemplate: _activeSurvey?.name,
      surveyTemplateTitle: _activeSurvey?.templateName,
      answers: answersList,
      medrepEmail: apiService.loggedInEmail ?? 'jptan@profinsights.biz',
      docstatus: 1, // Submit automatically
    );

    try {
      await apiService.createSubmission(submission);
      
      // Also update the core doctor master record in ERPNext with the newly entered workplaces/specialties
      final updatedDoctor = Hcp(
        name: widget.doctor.name,
        firstName: widget.doctor.firstName,
        lastName: widget.doctor.lastName,
        hcpType: widget.doctor.hcpType,
        hcpPractice: widget.doctor.hcpPractice,
        specialties: _selectedSpecialties.map((e) => HcpSpecialty(hcpSpecialty: e.hcpSpecialty, subSpecialty: e.subSpecialty)).toList(),
        workplaces: _selectedWorkplaces.map((e) => HcpWorkplace(workplace: e.workplace, address: e.address, isPrimary: e.isPrimary)).toList(),
        contacts: _contacts.map((e) => HcpContact(contactType: e.contactType, contactValue: e.contactValue)).toList(),
        regionName: _selectedRegion,
        provinceName: _selectedProvince,
        cityMunicipality: _selectedCity,
        barangayName: _selectedBarangay,
        institution: _selectedInstitution,
      );
      await apiService.updateDoctor(widget.doctor.name!, updatedDoctor);

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profiling Submission Saved and Master Record Updated!')),
      );
      // Navigate to Self-Service QR screen (Feature 6) as the final step
      // Pop wizard first, then push QR screen so "Done" returns to masterlist
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SelfServiceQrScreen(doctor: widget.doctor),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    }
  }

  Future<bool> _showWaiverDialog() async {
    _waiverSignaturePoints.value = [];
    bool agreed = false;
    final formVerified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Mandatory profile update waiver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You are editing an existing doctor\'s master profile details (workplaces, specializations, or contact details).\n\n'
                    'By signing below, the doctor confirms that all edited details are accurate and gives explicit consent to save these changes to the master list records.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        activeColor: const Color(0xFF5856D6),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        value: agreed,
                        onChanged: (val) {
                          setModalState(() {
                            agreed = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Dr. explicitly waives and confirms the changes.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Waiver Signature:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SignatureCanvas(pointsNotifier: _waiverSignaturePoints),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _waiverSignaturePoints.value = [];
                          });
                        },
                        child: const Text('Clear Signature', style: TextStyle(color: Color(0xFFE45656), fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E8E93))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5856D6),
                  disabledBackgroundColor: const Color(0xFF2C2C2E),
                ),
                onPressed: agreed && _waiverSignaturePoints.value.isNotEmpty
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: const Text('Agree & Apply', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
    return formVerified ?? false;
  }

  void _archiveRefusedConsent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Consent Refused. Profiling process terminated and archived.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      appBar: AppBar(
        title: Text('HCP Profiling - Step ${_currentStep + 1} of 4'),
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5856D6)),
              ),
            )
          : _buildCurrentStepBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCurrentStepBody() {
    switch (_currentStep) {
      case 0:
        return _buildConsentStep();
      case 1:
        return _buildInfoStep();
      case 2:
        return _buildSurveyStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildConsentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Obtain Mandatory Consent',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2C2C2E)),
            ),
            child: const Text(
              'By signing this, the Doctor/HCP agrees to share their professional details, contact information, workplaces, and feedback regarding PIMS product lines. All data will be processed securely in compliance with the Data Privacy Act of 2012 and stored in the central database.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Checkbox(
                activeColor: const Color(0xFF5856D6),
                checkColor: Colors.white,
                side: const BorderSide(color: Colors.white30),
                value: _consentGiven,
                onChanged: (val) {
                  setState(() {
                    _consentGiven = val ?? false;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  'The Doctor gives verbal/written consent.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Doctor Signature', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2C2C2E)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SignatureCanvas(pointsNotifier: _signaturePoints),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _signaturePoints.value = [];
                  });
                },
                child: const Text('Clear Signature', style: TextStyle(color: Color(0xFFE45656))),
              ),
            ],
          ),
          const Divider(color: Color(0xFF2C2C2E), height: 32),
          const Text('Proof of Engagement / Meeting Photo', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _consentPhotoFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'file://${_consentPhotoFile!.path}',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              : OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2C2C2E)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text('Capture Meeting Photo', style: TextStyle(color: Colors.white)),
                  onPressed: _capturePhoto,
                ),
        ],
      ),
    );
  }

  Widget _buildInfoStep() {
    final regionList = _psgcLocations.where((l) => l.locationType == 'Region').toList();
    final provinceList = _psgcLocations.where((l) => l.locationType == 'Province' && l.parentPsgcLocation == _selectedRegion).toList();
    final cityList = _psgcLocations.where((l) => l.locationType == 'City' && l.parentPsgcLocation == _selectedProvince).toList();
    final barangayList = _psgcLocations.where((l) => l.locationType == 'Barangay' && l.parentPsgcLocation == _selectedCity).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workplace & Geography',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Region Selector
          DropdownButtonFormField<String>(
            value: _selectedRegion,
            dropdownColor: const Color(0xFF1C1C1E),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Region',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            ),
            items: regionList.map((r) => DropdownMenuItem(value: r.name, child: Text(r.locationLabel))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedRegion = val;
                _selectedProvince = null;
                _selectedCity = null;
                _selectedBarangay = null;
              });
            },
          ),
          const SizedBox(height: 12),
          // Province Selector
          DropdownButtonFormField<String>(
            value: _selectedProvince,
            dropdownColor: const Color(0xFF1C1C1E),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Province',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            ),
            items: provinceList.map((p) => DropdownMenuItem(value: p.name, child: Text(p.locationLabel))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedProvince = val;
                _selectedCity = null;
                _selectedBarangay = null;
              });
            },
          ),
          const SizedBox(height: 12),
          // City Selector
          DropdownButtonFormField<String>(
            value: _selectedCity,
            dropdownColor: const Color(0xFF1C1C1E),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'City/Municipality',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            ),
            items: cityList.map((c) => DropdownMenuItem(value: c.name, child: Text(c.locationLabel))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedCity = val;
                _selectedBarangay = null;
              });
            },
          ),
          const SizedBox(height: 12),
          // Barangay Selector
          DropdownButtonFormField<String>(
            value: _selectedBarangay,
            dropdownColor: const Color(0xFF1C1C1E),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Barangay',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            ),
            items: barangayList.map((b) => DropdownMenuItem(value: b.name, child: Text(b.locationLabel))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedBarangay = val;
              });
            },
          ),
          const Divider(color: Color(0xFF2C2C2E), height: 32),
          // workplaces section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hospitals / Workplaces', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF34C759)),
                onPressed: _showAddWorkplaceSelector,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedWorkplaces.isEmpty)
            const Text('No workplaces linked. Click the button above to link hospitals.', style: TextStyle(color: Colors.white38, fontSize: 13))
          else
            ..._selectedWorkplaces.asMap().entries.map((entry) {
              final idx = entry.key;
              final workplace = entry.value;
              final nameMatch = _institutions.firstWhere((i) => i.name == workplace.workplace, orElse: () => Institution(name: workplace.workplace, institutionName: workplace.workplace));
              return Card(
                color: const Color(0xFF1C1C1E),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(nameMatch.institutionName, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(workplace.isPrimary ? 'Primary Workplace' : 'Supporting Workplace', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Color(0xFFE45656)),
                    onPressed: () {
                      setState(() {
                        _selectedWorkplaces.removeAt(idx);
                      });
                    },
                  ),
                ),
              );
             }),
          const Divider(color: Color(0xFF2C2C2E), height: 32),
          // specialties section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Specialties', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF34C759)),
                onPressed: _showAddSpecialtySelector,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedSpecialties.isEmpty)
            const Text('No specialties linked. Click the button above to link specialties.', style: TextStyle(color: Colors.white38, fontSize: 13))
          else
            ..._selectedSpecialties.asMap().entries.map((entry) {
              final idx = entry.key;
              final specialty = entry.value;
              return Card(
                color: const Color(0xFF1C1C1E),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(specialty.hcpSpecialty, style: const TextStyle(color: Colors.white)),
                  subtitle: specialty.subSpecialty != null && specialty.subSpecialty!.isNotEmpty
                      ? Text(specialty.subSpecialty!, style: const TextStyle(color: Colors.white54, fontSize: 12))
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Color(0xFFE45656)),
                    onPressed: () {
                      setState(() {
                        _selectedSpecialties.removeAt(idx);
                      });
                    },
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showAddWorkplaceSelector() {
    String? selectedInst;
    bool isPrimary = false;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Link Hospital / Workplace', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1C1C1E),
                  value: selectedInst,
                  hint: const Text('Choose Hospital', style: TextStyle(color: Colors.white54)),
                  items: _institutions.map((i) => DropdownMenuItem(value: i.name, child: Text(i.institutionName))).toList(),
                  onChanged: (val) {
                    setModalState(() {
                      selectedInst = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      activeColor: const Color(0xFF5856D6),
                      value: isPrimary,
                      onChanged: (val) {
                        setModalState(() {
                          isPrimary = val ?? false;
                        });
                      },
                    ),
                    const Text('Mark as Primary Workplace', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5856D6)),
            onPressed: () {
              if (selectedInst != null) {
                setState(() {
                  _selectedWorkplaces.add(SubmissionWorkplace(
                    workplace: selectedInst!,
                    isPrimary: isPrimary,
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddSpecialtySelector() {
    String? selectedSpec;
    String? selectedSubSpec;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Link Specialty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1C1C1E),
                  value: selectedSpec,
                  hint: const Text('Choose Specialty', style: TextStyle(color: Colors.white54)),
                  items: _specializations.where((s) => !s.isGroup).map((s) => DropdownMenuItem(value: s.specialty, child: Text(s.specialty))).toList(),
                  onChanged: (val) {
                    setModalState(() {
                      selectedSpec = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1C1C1E),
                  value: selectedSubSpec,
                  hint: const Text('Choose Sub-Specialty (Optional)', style: TextStyle(color: Colors.white54)),
                  items: _specializations.where((s) => !s.isGroup).map((s) => DropdownMenuItem(value: s.specialty, child: Text(s.specialty))).toList(),
                  onChanged: (val) {
                    setModalState(() {
                      selectedSubSpec = val;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5856D6)),
            onPressed: () {
              if (selectedSpec != null) {
                setState(() {
                  _selectedSpecialties.add(SubmissionSpecialty(
                    hcpSpecialty: selectedSpec!,
                    subSpecialty: selectedSubSpec,
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyStep() {
    if (_activeSurvey == null) {
      return const Center(
        child: Text('No active profiling survey template available.', style: TextStyle(color: Colors.white38)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _activeSurvey!.templateName,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (_activeSurvey!.description != null) ...[
            const SizedBox(height: 6),
            Text(_activeSurvey!.description!, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ],
          const Divider(color: Color(0xFF2C2C2E), height: 32),
          ..._activeSurvey!.questions.map((q) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.question, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  q.questionType == 'Select'
                      ? DropdownButtonFormField<String>(
                          dropdownColor: const Color(0xFF1C1C1E),
                          style: const TextStyle(color: Colors.white),
                          value: _surveyAnswers[q.question]!.isNotEmpty ? _surveyAnswers[q.question] : null,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF1C1C1E),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF5856D6)), borderRadius: BorderRadius.circular(8)),
                          ),
                          items: q.options?.split('\n').map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList() ?? [],
                          onChanged: (val) {
                            setState(() {
                              _surveyAnswers[q.question] = val ?? '';
                            });
                          },
                        )
                      : TextFormField(
                          style: const TextStyle(color: Colors.white),
                          maxLines: q.questionType == 'Small Text' ? 3 : 1,
                          initialValue: _surveyAnswers[q.question],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF1C1C1E),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF5856D6)), borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            _surveyAnswers[q.question] = val;
                          },
                        ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile Summary Review', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Doctor: Dr. ${widget.doctor.firstName} ${widget.doctor.lastName}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Practice: ${widget.doctor.hcpPractice}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text('Region: ${_selectedRegion ?? "Not selected"}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text('Hospitals Linked: ${_selectedWorkplaces.length}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text('Specialties Linked: ${_selectedSpecialties.length}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Survey Answers Summary', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._surveyAnswers.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('• ${entry.key}: ${entry.value.isNotEmpty ? entry.value : "N/A"}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              )),
          const SizedBox(height: 32),
          const Text('To save, double check all fields and tap "Submit Profile" below.', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1C1C1E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentStep == 0
              ? OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFE45656))),
                  onPressed: _archiveRefusedConsent,
                  child: const Text('Doctor Refuses Consent / Exit', style: TextStyle(color: Color(0xFFE45656))),
                )
              : TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                    });
                  },
                  child: const Text('Previous', style: TextStyle(color: Color(0xFF8E8E93))),
                ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5856D6),
              disabledBackgroundColor: const Color(0xFF2C2C2E),
            ),
            onPressed: _currentStep == 0 && (!_consentGiven || _signaturePoints.value.isEmpty)
                ? null
                : () {
                    if (_currentStep < 3) {
                      setState(() {
                        _currentStep++;
                      });
                    } else {
                      _submitForm();
                    }
                  },
            child: Text(
              _currentStep == 3 ? 'Submit Profile' : 'Next',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class SignatureCanvas extends StatefulWidget {
  final ValueNotifier<List<Offset>> pointsNotifier;
  const SignatureCanvas({Key? key, required this.pointsNotifier}) : super(key: key);

  @override
  State<SignatureCanvas> createState() => _SignatureCanvasState();
}

class _SignatureCanvasState extends State<SignatureCanvas> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        RenderBox renderBox = context.findRenderObject() as RenderBox;
        Offset localPosition = renderBox.globalToLocal(details.globalPosition);
        widget.pointsNotifier.value = List.from(widget.pointsNotifier.value)..add(localPosition);
      },
      onPanEnd: (details) {
        widget.pointsNotifier.value = List.from(widget.pointsNotifier.value)..add(Offset.infinite);
      },
      child: ValueListenableBuilder<List<Offset>>(
        valueListenable: widget.pointsNotifier,
        builder: (context, points, child) {
          return CustomPaint(
            painter: SignaturePainter(points: points),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset> points;
  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
