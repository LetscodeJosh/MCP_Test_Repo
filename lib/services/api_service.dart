import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/engagement.dart';
import '../models/hcp.dart';
import '../models/submission.dart';
import '../models/lookup_models.dart';
import '../models/hcp_account.dart';

class ApiService {
  final String baseUrl = 'https://dev.pmii-marketing.com';
  String? _sessionCookie;
  String? loggedInEmail;

  late final FrappeRepository<Hcp> hcps = FrappeRepository<Hcp>(
    api: this,
    docType: 'HCP',
    fromJson: (json) => Hcp.fromJson(json),
    toJson: (item) => item.toJson(),
  );

  late final FrappeRepository<HcpAccount> hcpAccounts = FrappeRepository<HcpAccount>(
    api: this,
    docType: 'HCP Account',
    fromJson: (json) => HcpAccount.fromJson(json),
    toJson: (item) => item.toJson(),
  );

  late final FrappeRepository<HcpAccountDoctors> hcpAccountDoctors = FrappeRepository<HcpAccountDoctors>(
    api: this,
    docType: 'HCP Account Doctors',
    fromJson: (json) => HcpAccountDoctors.fromJson(json),
    toJson: (item) => item.toJson(),
  );

  late final FrappeRepository<HcpProfileSubmission> submissions = FrappeRepository<HcpProfileSubmission>(
    api: this,
    docType: 'HCP Profile Submission',
    fromJson: (json) => HcpProfileSubmission.fromJson(json),
    toJson: (item) => item.toJson(),
  );

  late final FrappeRepository<HcpSurveyTemplate> surveyTemplates = FrappeRepository<HcpSurveyTemplate>(
    api: this,
    docType: 'HCP Survey Template',
    fromJson: (json) => HcpSurveyTemplate.fromJson(json),
    toJson: (item) => item.toJson(),
  );

  late final FrappeRepository<HcpSurveyResponse> surveyResponses = FrappeRepository<HcpSurveyResponse>(
    api: this,
    docType: 'HCP Survey Response',
    fromJson: (json) => HcpSurveyResponse.fromJson(json),
    toJson: (item) => item.toJson(),
  );

  late final FrappeRepository<HcpType> hcpTypes = FrappeRepository<HcpType>(
    api: this,
    docType: 'HCP Type',
    fromJson: (json) => HcpType.fromJson(json),
    toJson: (item) => item.toJson(),
  );

  late final FrappeRepository<Institution> institutions = FrappeRepository<Institution>(
    api: this,
    docType: 'Institution',
    fromJson: (json) => Institution.fromJson(json),
    toJson: (item) => item.toJson(),
  );

  late final FrappeRepository<Specialization> specializations = FrappeRepository<Specialization>(
    api: this,
    docType: 'Specialization',
    fromJson: (json) => Specialization.fromJson(json),
    toJson: (item) => item.toJson(),
  );

  late final FrappeRepository<PsgcLocation> psgcLocations = FrappeRepository<PsgcLocation>(
    api: this,
    docType: 'PSGC Location',
    fromJson: (json) => PsgcLocation.fromJson(json),
    toJson: (item) => item.toJson(),
  );

  bool get isAuthenticated => _sessionCookie != null;

  // Header helpers that inject session cookies
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }
    return headers;
  }

  /// Authenticate against ERPNext v15
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/method/login');
    try {
      final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'usr': username,
            'pwd': password,
          }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['message'] == 'Logged In') {
          // Store username as the logged-in email
          loggedInEmail = username.trim();
          
          // Parse cookie header to persist session (e.g. sid=xxxxxx)
          final rawCookie = response.headers['set-cookie'];
          if (rawCookie != null) {
            // Keep the relevant parts of the cookie
            _sessionCookie = rawCookie.split(';').firstWhere(
                  (c) => c.trim().startsWith('sid='),
                  orElse: () => '',
                );
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// Log out
  void logout() {
    _sessionCookie = null;
    loggedInEmail = null;
  }

  /// Retrieve list of COREnergy engagements
  Future<List<Engagement>> fetchEngagements() async {
    final url = Uri.parse(
      '$baseUrl/api/resource/Successful%20COREnergy%20Engagement?fields=["*"]&limit=100',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> dataList = body['data'] ?? [];
        return dataList.map((json) => Engagement.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load engagements: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch engagements error: $e');
      rethrow;
    }
  }

  /// Retrieve list of Company Institutions
  Future<List<Institution>> fetchInstitutions() async {
    final url = Uri.parse(
      '$baseUrl/api/resource/Institution?fields=["name","institution_name"]&limit=200',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> dataList = body['data'] ?? [];
        return dataList.map((json) => Institution.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load institutions: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch institutions error: $e');
      rethrow;
    }
  }

  /// Create a new engagement record
  Future<Engagement> createEngagement(Engagement engagement) async {
    final url = Uri.parse('$baseUrl/api/resource/Successful%20COREnergy%20Engagement');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(engagement.toJson()),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return Engagement.fromJson(body['data']);
      } else {
        throw Exception('Failed to create record: ${response.body}');
      }
    } catch (e) {
      print('Create engagement error: $e');
      rethrow;
    }
  }

  /// Update an existing engagement record
  Future<Engagement> updateEngagement(String name, Engagement engagement) async {
    final url = Uri.parse(
      '$baseUrl/api/resource/Successful%20COREnergy%20Engagement/${Uri.encodeComponent(name)}',
    );
    try {
      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(engagement.toJson()),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return Engagement.fromJson(body['data']);
      } else {
        throw Exception('Failed to update record: ${response.body}');
      }
    } catch (e) {
      print('Update engagement error: $e');
      rethrow;
    }
  }

  /// Retrieve list of HCP/Doctors
  Future<List<Hcp>> fetchDoctors() async {
    final url = Uri.parse(
      '$baseUrl/api/resource/HCP?fields=["*"]&limit=200',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> dataList = body['data'] ?? [];
        return dataList.map((json) => Hcp.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load doctors: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch doctors error: $e');
      rethrow;
    }
  }

  /// Fetch full details of a specific Doctor (HCP) including child tables
  Future<Hcp> fetchDoctorDetail(String name) async {
    final url = Uri.parse(
      '$baseUrl/api/resource/HCP/${Uri.encodeComponent(name)}',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return Hcp.fromJson(body['data']);
      } else {
        throw Exception('Failed to load doctor details: ${response.body}');
      }
    } catch (e) {
      print('Fetch doctor detail error: $e');
      rethrow;
    }
  }

  /// Create a new HCP/Doctor record
  Future<Hcp> createDoctor(Hcp hcp) async {
    final url = Uri.parse('$baseUrl/api/resource/HCP');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(hcp.toJson()),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return Hcp.fromJson(body['data']);
      } else {
        throw Exception('Failed to create doctor: ${response.body}');
      }
    } catch (e) {
      print('Create doctor error: $e');
      rethrow;
    }
  }

  /// Update an existing HCP/Doctor record
  Future<Hcp> updateDoctor(String name, Hcp hcp) async {
    final url = Uri.parse(
      '$baseUrl/api/resource/HCP/${Uri.encodeComponent(name)}',
    );
    try {
      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(hcp.toJson()),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return Hcp.fromJson(body['data']);
      } else {
        throw Exception('Failed to update doctor: ${response.body}');
      }
    } catch (e) {
      print('Update doctor error: $e');
      rethrow;
    }
  }

  /// Retrieve list of HCP Profile Submissions
  Future<List<HcpProfileSubmission>> fetchSubmissions() async {
    final url = Uri.parse(
      '$baseUrl/api/resource/HCP%20Profile%20Submission?fields=["*"]&limit=100',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> dataList = body['data'] ?? [];
        return dataList.map((json) => HcpProfileSubmission.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load submissions: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch submissions error: $e');
      rethrow;
    }
  }

  /// Create a new HCP Profile Submission record
  Future<HcpProfileSubmission> createSubmission(HcpProfileSubmission submission) async {
    final url = Uri.parse('$baseUrl/api/resource/HCP%20Profile%20Submission');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(submission.toJson()),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return HcpProfileSubmission.fromJson(body['data']);
      } else {
        throw Exception('Failed to create submission: ${response.body}');
      }
    } catch (e) {
      print('Create submission error: $e');
      rethrow;
    }
  }

  /// Retrieve list of Specializations
  Future<List<Specialization>> fetchSpecializations() async {
    final url = Uri.parse(
      '$baseUrl/api/resource/Specialization?fields=["name","specialty","specialty_group","parent_specialization","is_group"]&limit=500',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> dataList = body['data'] ?? [];
        return dataList.map((json) => Specialization.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load specializations: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch specializations error: $e');
      rethrow;
    }
  }

  /// Retrieve list of PSGC Locations
  Future<List<PsgcLocation>> fetchPsgcLocations() async {
    final url = Uri.parse(
      '$baseUrl/api/resource/PSGC%20Location?fields=["name","location_label","location_type","parent_psgc_location","psgc_code","is_group"]&limit=1000',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> dataList = body['data'] ?? [];
        return dataList.map((json) => PsgcLocation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load PSGC locations: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch PSGC locations error: $e');
      rethrow;
    }
  }

  /// Retrieve active Survey Templates
  Future<List<HcpSurveyTemplate>> fetchSurveyTemplates() async {
    final url = Uri.parse(
      '$baseUrl/api/resource/HCP%20Survey%20Template?fields=["name","template_name","is_active","account_or_program","description"]&filters=[["is_active","=",1]]',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> dataList = body['data'] ?? [];
        
        // Survey templates have nested questions child table, we load details for active ones
        List<HcpSurveyTemplate> templates = [];
        for (var item in dataList) {
          final detailUrl = Uri.parse('$baseUrl/api/resource/HCP%20Survey%20Template/${Uri.encodeComponent(item['name'])}');
          final detailResp = await http.get(detailUrl, headers: _headers);
          if (detailResp.statusCode == 200) {
            final detailBody = jsonDecode(detailResp.body);
            templates.add(HcpSurveyTemplate.fromJson(detailBody['data']));
          }
        }
        return templates;
      } else {
        throw Exception('Failed to load survey templates: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch survey templates error: $e');
      rethrow;
    }
  }
}

class FrappeRepository<T> {
  final ApiService _api;
  final String docType;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  FrappeRepository({
    required ApiService api,
    required this.docType,
    required this.fromJson,
    required this.toJson,
  }) : _api = api;

  /// Fetch list of records of this DocType
  Future<List<T>> list({
    List<String>? fields,
    List<dynamic>? filters,
    int? limit,
    int? limitStart,
    String? orderBy,
  }) async {
    final Map<String, String> queryParams = {};
    if (fields != null) {
      queryParams['fields'] = jsonEncode(fields);
    }
    if (filters != null) {
      queryParams['filters'] = jsonEncode(filters);
    }
    if (limit != null) {
      queryParams['limit_page_length'] = limit.toString();
    }
    if (limitStart != null) {
      queryParams['limit_start'] = limitStart.toString();
    }
    if (orderBy != null) {
      queryParams['order_by'] = orderBy;
    }

    final uri = Uri.parse('${_api.baseUrl}/api/resource/${Uri.encodeComponent(docType)}')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http.get(uri, headers: _api._headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> dataList = body['data'] ?? [];
        return dataList.map((json) => fromJson(json)).toList();
      } else {
        throw Exception('Failed to load list for $docType: ${response.statusCode}');
      }
    } catch (e) {
      print('FrappeRepository.list error on $docType: $e');
      rethrow;
    }
  }

  /// Fetch details of a single record by its name (ID), including its nested child tables
  Future<T> get(String name) async {
    final uri = Uri.parse('${_api.baseUrl}/api/resource/${Uri.encodeComponent(docType)}/${Uri.encodeComponent(name)}');
    try {
      final response = await http.get(uri, headers: _api._headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return fromJson(body['data']);
      } else {
        throw Exception('Failed to load detail for $docType ($name): ${response.statusCode}');
      }
    } catch (e) {
      print('FrappeRepository.get error on $docType: $e');
      rethrow;
    }
  }

  /// Create a new record with nested child table arrays
  Future<T> create(T item) async {
    final uri = Uri.parse('${_api.baseUrl}/api/resource/${Uri.encodeComponent(docType)}');
    try {
      final response = await http.post(
        uri,
        headers: _api._headers,
        body: jsonEncode(toJson(item)),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return fromJson(body['data']);
      } else {
        throw Exception('Failed to create $docType: ${response.body}');
      }
    } catch (e) {
      print('FrappeRepository.create error on $docType: $e');
      rethrow;
    }
  }

  /// Update an existing record and dynamically reconcile child tables
  Future<T> update(String name, T item) async {
    final uri = Uri.parse('${_api.baseUrl}/api/resource/${Uri.encodeComponent(docType)}/${Uri.encodeComponent(name)}');
    try {
      final response = await http.put(
        uri,
        headers: _api._headers,
        body: jsonEncode(toJson(item)),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return fromJson(body['data']);
      } else {
        throw Exception('Failed to update $docType ($name): ${response.body}');
      }
    } catch (e) {
      print('FrappeRepository.update error on $docType: $e');
      rethrow;
    }
  }
}

