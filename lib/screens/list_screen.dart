import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/engagement.dart';
import '../models/lookup_models.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';
import 'doctor_masterlist_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({Key? key}) : super(key: key);

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  int _currentTabIndex = 0; // 0: List, 1: Map
  List<Engagement> _allEngagements = [];
  List<Institution> _allInstitutions = [];
  List<Engagement> _filteredEngagements = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedSalesRep;
  String? _selectedStatus;

  // Cache sales reps list
  List<String> _salesReps = [];

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    _selectedSalesRep = apiService.loggedInEmail;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final engagements = await apiService.fetchEngagements();
      final institutions = await apiService.fetchInstitutions();
      
      setState(() {
        _allEngagements = engagements;
        _allInstitutions = institutions;
        
        // Extract unique sales reps
        final reps = engagements
            .map((e) => e.salesRep)
            .where((rep) => rep != null && rep.isNotEmpty)
            .map((rep) => rep!)
            .toSet()
            .toList();
        
        // Ensure default logins are in the filter list
        for (var defaultRep in [
          'jptan@profinsights.biz',
          'mmperalta@pims-marketing.com',
          'kmtaotao@pims-marketing.com'
        ]) {
          if (!reps.contains(defaultRep)) {
            reps.add(defaultRep);
          }
        }
        _salesReps = reps;
        
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading ERPNext data: $e')),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredEngagements = _allEngagements.where((item) {
        final nameMatches = item.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        final companyMatches = item.company?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        final contactMatches = item.contact?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        final lastNameMatches = item.lastName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        
        final matchesSearch = nameMatches || companyMatches || contactMatches || lastNameMatches;
        
        final matchesRep = _selectedSalesRep == null || item.salesRep == _selectedSalesRep;
        
        final isUnsuccessful = item.unsuccessfulCall;
        final matchesStatus = _selectedStatus == null ||
            (_selectedStatus == 'unsuccessful' && isUnsuccessful) ||
            (_selectedStatus == 'successful' && !isUnsuccessful);

        return matchesSearch && matchesRep && matchesStatus;
      }).toList();
    });
  }

  String _getCompanyLabel(String? companyId) {
    if (companyId == null) return 'No Company';
    final match = _allInstitutions.firstWhere(
      (inst) => inst.name == companyId,
      orElse: () => Institution(name: companyId, institutionName: ''),
    );
    return match.institutionName.isNotEmpty 
        ? match.institutionName 
        : companyId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      appBar: AppBar(
        title: Text(_currentTabIndex == 0 ? 'PIMS MCP' : 'Coverage Map'),
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5856D6)),
              ),
            )
          : _currentTabIndex == 0
              ? _buildListView()
              : _buildMapView(),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF5856D6),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(
                      institutions: _allInstitutions,
                      salesReps: _salesReps,
                    ),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        backgroundColor: const Color(0xFF1C1C1E),
        selectedItemColor: const Color(0xFF5856D6),
        unselectedItemColor: const Color(0xFF8E8E93),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        // Search & Filters Header
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1C1C1E),
          child: Column(
            children: [
              // Search Input
              TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _applyFilters();
                  });
                },
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by ID or Location...',
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
                  // Sales Rep Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSalesRep,
                          hint: const Text('All Reps', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                          dropdownColor: const Color(0xFF1C1C1E),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8E8E93)),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          onChanged: (val) {
                            setState(() {
                              _selectedSalesRep = val;
                              _applyFilters();
                            });
                          },
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Reps'),
                            ),
                            ..._salesReps.map((rep) {
                              return DropdownMenuItem<String>(
                                value: rep,
                                child: Text(
                                  rep,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Status Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          hint: const Text('All Status', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                          dropdownColor: const Color(0xFF1C1C1E),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8E8E93)),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          onChanged: (val) {
                            setState(() {
                              _selectedStatus = val;
                              _applyFilters();
                            });
                          },
                          items: const [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Status'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'successful',
                              child: Text('Successful'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'unsuccessful',
                              child: Text('Unsuccessful'),
                            ),
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
        // Engagement Cards List
        Expanded(
          child: _filteredEngagements.isEmpty
              ? const Center(
                  child: Text(
                    'No profiling logs found.',
                    style: TextStyle(color: Color(0xFF8E8E93)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredEngagements.length,
                  itemBuilder: (context, index) {
                    final item = _filteredEngagements[index];
                    final companyName = _getCompanyLabel(item.company);
                    final isUnsuccessful = item.unsuccessfulCall;

                    return Card(
                      color: const Color(0xFF1C1C1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFF38383A)),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(
                                engagement: item,
                                institutions: _allInstitutions,
                                salesReps: _salesReps,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadData();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name ?? 'NEW',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isUnsuccessful
                                          ? const Color(0xFFFF453A).withOpacity(0.15)
                                          : const Color(0xFF30D158).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isUnsuccessful ? 'Unsuccessful' : 'Successful',
                                      style: TextStyle(
                                        color: isUnsuccessful 
                                            ? const Color(0xFFFF453A) 
                                            : const Color(0xFF30D158),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Icon(Icons.business, color: Color(0xFF8E8E93), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      companyName,
                                      style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Color(0xFF8E8E93), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.salesRep ?? 'No Sales Rep',
                                      style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    // Collect coordinates from engagements
    final points = <Marker>[];
    double latSum = 0;
    double lngSum = 0;
    int count = 0;

    for (var item in _filteredEngagements) {
      if (item.latitude != null && item.longitude != null) {
        final lat = double.tryParse(item.latitude!);
        final lng = double.tryParse(item.longitude!);
        if (lat != null && lng != null) {
          latSum += lat;
          lngSum += lng;
          count++;

          final isUnsuccessful = item.unsuccessfulCall;

          points.add(
            Marker(
              width: 40.0,
              height: 40.0,
              point: LatLng(lat, lng),
              child: GestureDetector(
                onTap: () {
                  _showMapPinDetails(item);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isUnsuccessful ? const Color(0xFFFF453A) : const Color(0xFF5856D6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    final center = count > 0 
        ? LatLng(latSum / count, lngSum / count) 
        : LatLng(14.3129, 121.1009); // Default to Canossa

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 11.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
        ),
        MarkerLayer(markers: points),
      ],
    );
  }

  void _showMapPinDetails(Engagement item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final companyName = _getCompanyLabel(item.company);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.unsuccessfulCall
                            ? const Color(0xFFFF453A).withOpacity(0.15)
                            : const Color(0xFF30D158).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.unsuccessfulCall ? 'Unsuccessful' : 'Successful',
                        style: TextStyle(
                          color: item.unsuccessfulCall 
                              ? const Color(0xFFFF453A) 
                              : const Color(0xFF30D158),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Institution: $companyName', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 6),
                Text('Sales Rep: ${item.salesRep ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                if (item.latitude != null && item.longitude != null) ...[
                  const SizedBox(height: 6),
                  Text('Coords: ${item.latitude}, ${item.longitude}', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // dismiss sheet
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(
                          engagement: item,
                          institutions: _allInstitutions,
                          salesReps: _salesReps,
                        ),
                      ),
                    ).then((value) {
                      if (value == true) {
                        _loadData();
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5856D6),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('View Profiling Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
