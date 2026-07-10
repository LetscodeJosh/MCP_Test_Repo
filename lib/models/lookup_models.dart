class Institution {
  final String name; // e.g. INST-00001
  final String institutionName;
  final String? regionName;
  final String? provinceName;
  final String? cityMunicipality;
  final String? barangayName;
  final String? streetAddress;

  Institution({
    required this.name,
    required this.institutionName,
    this.regionName,
    this.provinceName,
    this.cityMunicipality,
    this.barangayName,
    this.streetAddress,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      name: json['name'] ?? '',
      institutionName: json['institution_name'] ?? '',
      regionName: json['region_name'],
      provinceName: json['province_name'],
      cityMunicipality: json['city_municipality'],
      barangayName: json['barangay_name'],
      streetAddress: json['street_address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'institution_name': institutionName,
      if (regionName != null) 'region_name': regionName,
      if (provinceName != null) 'province_name': provinceName,
      if (cityMunicipality != null) 'city_municipality': cityMunicipality,
      if (barangayName != null) 'barangay_name': barangayName,
      if (streetAddress != null) 'street_address': streetAddress,
    };
  }
}

class Specialization {
  final String name; // e.g. SPEC-00001
  final String specialty;
  final String specialtyGroup;
  final String? parentSpecialization;
  final bool isGroup;

  Specialization({
    required this.name,
    required this.specialty,
    required this.specialtyGroup,
    this.parentSpecialization,
    this.isGroup = false,
  });

  factory Specialization.fromJson(Map<String, dynamic> json) {
    return Specialization(
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      specialtyGroup: json['specialty_group'] ?? '',
      parentSpecialization: json['parent_specialization'],
      isGroup: json['is_group'] == 1 || json['is_group'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialty': specialty,
      'specialty_group': specialtyGroup,
      if (parentSpecialization != null) 'parent_specialization': parentSpecialization,
      'is_group': isGroup ? 1 : 0,
    };
  }
}

class PsgcLocation {
  final String name; // ID
  final String locationLabel;
  final String locationType; // Region, Province, City, Barangay
  final String? parentPsgcLocation;
  final String? psgcCode;
  final bool isGroup;

  PsgcLocation({
    required this.name,
    required this.locationLabel,
    required this.locationType,
    this.parentPsgcLocation,
    this.psgcCode,
    this.isGroup = false,
  });

  factory PsgcLocation.fromJson(Map<String, dynamic> json) {
    return PsgcLocation(
      name: json['name'] ?? '',
      locationLabel: json['location_label'] ?? '',
      locationType: json['location_type'] ?? '',
      parentPsgcLocation: json['parent_psgc_location'],
      psgcCode: json['psgc_code'],
      isGroup: json['is_group'] == 1 || json['is_group'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location_label': locationLabel,
      'location_type': locationType,
      if (parentPsgcLocation != null) 'parent_psgc_location': parentPsgcLocation,
      if (psgcCode != null) 'psgc_code': psgcCode,
      'is_group': isGroup ? 1 : 0,
    };
  }
}

class HcpSurveyTemplate {
  final String name; // ID
  final String templateName;
  final bool isActive;
  final String? accountOrProgram;
  final String? description;
  final List<HcpSurveyQuestion> questions;

  HcpSurveyTemplate({
    required this.name,
    required this.templateName,
    this.isActive = true,
    this.accountOrProgram,
    this.description,
    this.questions = const [],
  });

  factory HcpSurveyTemplate.fromJson(Map<String, dynamic> json) {
    return HcpSurveyTemplate(
      name: json['name'] ?? '',
      templateName: json['template_name'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      accountOrProgram: json['account_or_program'],
      description: json['description'],
      questions: (json['questions'] as List?)
              ?.map((e) => HcpSurveyQuestion.fromJson(e))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'template_name': templateName,
      'is_active': isActive ? 1 : 0,
      if (accountOrProgram != null) 'account_or_program': accountOrProgram,
      if (description != null) 'description': description,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }
}

class HcpSurveyQuestion {
  final String question; // e.g., "What products do you prescribe?"
  final String questionType; // Select, Multi-select, Data, etc.
  final String? options; // newline-separated choices

  HcpSurveyQuestion({
    required this.question,
    required this.questionType,
    this.options,
  });

  factory HcpSurveyQuestion.fromJson(Map<String, dynamic> json) {
    return HcpSurveyQuestion(
      question: json['question'] ?? '',
      questionType: json['question_type'] ?? 'Data',
      options: json['options'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'question_type': questionType,
      if (options != null) 'options': options,
    };
  }
}

class HcpType {
  final String name;
  final String? description;

  HcpType({
    required this.name,
    this.description,
  });

  factory HcpType.fromJson(Map<String, dynamic> json) {
    return HcpType(
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
    };
  }
}

class HcpSurveyResponse {
  final String? name;
  final String surveyTemplate; // Link -> HCP Survey Template
  final String hcp; // Link -> HCP
  final String? surveyDate;
  final String? respondent; // Medrep email or username
  final List<HcpSurveyAnswer> answers;

  HcpSurveyResponse({
    this.name,
    required this.surveyTemplate,
    required this.hcp,
    this.surveyDate,
    this.respondent,
    this.answers = const [],
  });

  factory HcpSurveyResponse.fromJson(Map<String, dynamic> json) {
    return HcpSurveyResponse(
      name: json['name'],
      surveyTemplate: json['survey_template'] ?? '',
      hcp: json['hcp'] ?? '',
      surveyDate: json['survey_date'],
      respondent: json['respondent'],
      answers: (json['answers'] as List?)
              ?.map((e) => HcpSurveyAnswer.fromJson(e))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      'survey_template': surveyTemplate,
      'hcp': hcp,
      if (surveyDate != null) 'survey_date': surveyDate,
      if (respondent != null) 'respondent': respondent,
      'answers': answers.map((e) => e.toJson()).toList(),
    };
  }
}

class HcpSurveyAnswer {
  final String question; // Link -> HCP Survey Question or question text
  final String answer; // Answer selection / input text

  HcpSurveyAnswer({
    required this.question,
    required this.answer,
  });

  factory HcpSurveyAnswer.fromJson(Map<String, dynamic> json) {
    return HcpSurveyAnswer(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
    };
  }
}


