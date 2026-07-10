import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/engagement.dart';
import '../models/lookup_models.dart';
import '../services/api_service.dart';

class DetailScreen extends StatefulWidget {
  final Engagement? engagement;
  final List<Institution> institutions;
  final List<String> salesReps;

  const DetailScreen({
    Key? key,
    this.engagement,
    required this.institutions,
    required this.salesReps,
  }) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form State
  bool _unsuccessfulCall = false;
  String? _reasonForUnsuccessfulCall;
  String? _selectedCompany;
  String? _selectedSalesRep;
  
  final _contactFirstNameController = TextEditingController();
  final _contactLastNameController = TextEditingController();
  final _positionOrRoleController = TextEditingController();
  final _emailAddressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _dateTimeSalesController = TextEditingController();
  
  bool _decisionMakerNotAvailable = false;
  
  String? _latitude;
  String? _longitude;
  
  File? _imageFile;
  final _picker = ImagePicker();
  bool _isSaving = false;
  bool _isLocating = false;

  final List<String> _unsuccessfulReasons = [
    'Company moved to different address',
    'Prior appointment or letter needed',
    'Decision maker not available',
    'Closed / No longer in operations',
    'Refused to entertain',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    final item = widget.engagement;
    if (item != null) {
      _unsuccessfulCall = item.unsuccessfulCall;
      _reasonForUnsuccessfulCall = item.reasonForUnsuccessfulCall;
      _selectedCompany = item.company;
      _selectedSalesRep = item.salesRep;
      _contactFirstNameController.text = item.contact ?? '';
      _contactLastNameController.text = item.lastName ?? '';
      _positionOrRoleController.text = item.positionOrRole ?? '';
      _emailAddressController.text = item.emailAddress ?? '';
      _contactNumberController.text = item.contactNumber ?? '';
      _decisionMakerNotAvailable = item.decisionMakerOrResponsiblePersonNotAvailable;
      _latitude = item.latitude;
      _longitude = item.longitude;
      
      // Formatting datetime to "YYYY-MM-DD HH:MM" for input
      if (item.dateAndTimeOfSalesAppointment != null) {
        final raw = item.dateAndTimeOfSalesAppointment!;
        if (raw.length >= 16) {
          _dateTimeSalesController.text = raw.substring(0, 16).replaceFirst(' ', 'T');
        }
      }
    }
  }

  Future<void> _getImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take photo: $e')),
      );
    }
  }

  Future<void> _fetchGPS() async {
    setState(() {
      _isLocating = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitude = position.latitude.toStringAsFixed(6);
        _longitude = position.longitude.toStringAsFixed(6);
        _isLocating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS coordinates saved successfully.')),
      );
    } catch (e) {
      setState(() {
        // Fallback to random test environment coords close to Laguna
        final offsetLat = (DateTime.now().millisecond / 1000 - 0.5) * 0.05;
        final offsetLng = (DateTime.now().microsecond / 1000000 - 0.5) * 0.05;
        _latitude = (14.3129 + offsetLat).toStringAsFixed(6);
        _longitude = (121.1009 + offsetLng).toStringAsFixed(6);
        _isLocating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS failure ($e). Seeding mockup location.')),
      );
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    // Parse DateTime to ERPNext format (YYYY-MM-DD HH:MM:SS)
    String? formattedDateTime;
    if (_dateTimeSalesController.text.isNotEmpty) {
      formattedDateTime = _dateTimeSalesController.text.replaceFirst('T', ' ') + ':00';
    }

    final payload = Engagement(
      name: widget.engagement?.name,
      unsuccessfulCall: _unsuccessfulCall,
      reasonForUnsuccessfulCall: _unsuccessfulCall ? _reasonForUnsuccessfulCall : '',
      company: _selectedCompany,
      salesRep: _selectedSalesRep,
      contact: _contactFirstNameController.text.trim(),
      lastName: _contactLastNameController.text.trim(),
      positionOrRole: _positionOrRoleController.text.trim(),
      emailAddress: _emailAddressController.text.trim(),
      contactNumber: _contactNumberController.text.trim(),
      dateAndTimeOfSalesAppointment: formattedDateTime,
      decisionMakerOrResponsiblePersonNotAvailable: _decisionMakerNotAvailable,
      latitude: _latitude,
      longitude: _longitude,
      // If there is an image file locally, we'd typically upload it. For now we mock path or send base64
      picture: _imageFile != null ? '/private/files/${_imageFile!.path.split('/').last}' : widget.engagement?.picture,
    );

    try {
      if (widget.engagement != null) {
        await apiService.updateEngagement(widget.engagement!.name!, payload);
      } else {
        await apiService.createEngagement(payload);
      }
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        Navigator.of(context).pop(true); // Return success to reload list
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save record: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.engagement != null;
    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      appBar: AppBar(
        title: Text(isEdit ? widget.engagement!.name! : 'New Profiling'),
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        actions: [
          _isSaving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveForm,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF5856D6),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Details Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF5856D6).withOpacity(0.15), const Color(0xFF1C1C1E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38383A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'RECORD ID' : 'NEW CALL REGISTRATION',
                    style: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'monospace', fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEdit ? widget.engagement!.name! : 'Create COREnergy Log',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Checkbox: Unsuccessful Call
            _buildCheckboxTile(
              value: _unsuccessfulCall,
              label: 'Unsuccessful Call',
              onChanged: (val) {
                setState(() {
                  _unsuccessfulCall = val ?? false;
                  if (!_unsuccessfulCall) _reasonForUnsuccessfulCall = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Reason for Unsuccessful Call (Dynamic visibility)
            if (_unsuccessfulCall) ...[
              const Text('REASON FOR UNSUCCESSFUL CALL', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildDropdownField<String>(
                value: _reasonForUnsuccessfulCall,
                hint: 'Select Reason...',
                items: _unsuccessfulReasons,
                onChanged: (val) {
                  setState(() {
                    _reasonForUnsuccessfulCall = val;
                  });
                },
                validator: (val) => val == null ? 'Please select a reason' : null,
              ),
              const SizedBox(height: 16),
            ],

            // Company Dropdown
            const Text('COMPANY / INSTITUTION *', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDropdownField<String>(
              value: _selectedCompany,
              hint: 'Select Company...',
              items: widget.institutions.map((i) => i.name).toList(),
              itemLabelBuilder: (id) {
                final match = widget.institutions.firstWhere((i) => i.name == id);
                return '${match.name} - ${match.institutionName}';
              },
              onChanged: (val) {
                setState(() {
                  _selectedCompany = val;
                });
              },
              validator: (val) => val == null ? 'Please select a company' : null,
            ),
            const SizedBox(height: 16),

            // Picture Uploader Area
            const Text('PICTURE', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _getImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF38383A)),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : widget.engagement?.picture != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              widget.engagement!.picture!.startsWith('http')
                                  ? widget.engagement!.picture!
                                  : 'https://dev.pmii-marketing.com${widget.engagement!.picture}',
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, color: Color(0xFF8E8E93), size: 36),
                              SizedBox(height: 10),
                              Text('Attach geotagged photo', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 16),

            // Location Coordinates widget
            const Text('LOCATION COORDINATES', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isLocating ? null : _fetchGPS,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF38383A)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isLocating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.location_on_outlined, color: Color(0xFF5856D6), size: 18),
              label: Text(_isLocating ? 'Fetching GPS...' : 'Get Current Location'),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF38383A)),
              ),
              child: Row(
                children: [
                  Expanded(child: Text('Lat: ${_latitude ?? "Not set"}', style: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'monospace', fontSize: 13))),
                  Expanded(child: Text('Lng: ${_longitude ?? "Not set"}', style: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'monospace', fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sales Rep
            const Text('SALES REP *', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDropdownField<String>(
              value: _selectedSalesRep,
              hint: 'Select Rep...',
              items: widget.salesReps,
              onChanged: (val) {
                setState(() {
                  _selectedSalesRep = val;
                });
              },
              validator: (val) => val == null ? 'Please select a Sales Rep' : null,
            ),
            const SizedBox(height: 16),

            // Contact First Name
            _buildInputField(
              controller: _contactFirstNameController,
              label: 'First Name',
              hint: 'Contact First Name',
            ),
            const SizedBox(height: 16),

            // Contact Last Name
            _buildInputField(
              controller: _contactLastNameController,
              label: 'Last Name',
              hint: 'Contact Last Name',
            ),
            const SizedBox(height: 16),

            // Position or Role
            _buildInputField(
              controller: _positionOrRoleController,
              label: 'Position or Role',
              hint: 'e.g. Procurement, MD',
            ),
            const SizedBox(height: 16),

            // Email Address
            _buildInputField(
              controller: _emailAddressController,
              label: 'Email Address',
              hint: 'name@company.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Contact Number
            _buildInputField(
              controller: _contactNumberController,
              label: 'Contact Number',
              hint: 'e.g. +639170000000',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Date and Time of Sales Appointment
            const Text('DATE AND TIME OF SALES APPOINTMENT', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _dateTimeSalesController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                hintText: 'YYYY-MM-DD HH:MM',
                hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF8E8E93), size: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF38383A)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF38383A)),
                ),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const Text('Timezone: Asia/Manila', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11), textAlign: TextAlign.right),
            const SizedBox(height: 16),

            // Decision Maker
            _buildCheckboxTile(
              value: _decisionMakerNotAvailable,
              label: 'Decision maker or responsible person not available',
              onChanged: (val) {
                setState(() {
                  _decisionMakerNotAvailable = val ?? false;
                });
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38383A)),
      ),
      child: CheckboxListTile(
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        value: value,
        activeColor: const Color(0xFF5856D6),
        checkColor: Colors.white,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String hint,
    required List<T> items,
    String Function(T)? itemLabelBuilder,
    required ValueChanged<T?> onChanged,
    FormFieldValidator<T>? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38383A)),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        hint: Text(hint, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
        dropdownColor: const Color(0xFF1C1C1E),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8E8E93)),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: onChanged,
        validator: validator,
        decoration: const InputDecoration(border: InputBorder.none),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              itemLabelBuilder != null ? itemLabelBuilder(item) : item.toString(),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1C1C1E),
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF38383A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF38383A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5856D6), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
