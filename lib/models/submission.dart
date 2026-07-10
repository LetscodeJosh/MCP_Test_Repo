class HcpProfileSubmission {
  final String? name;
  final String hcpName; // Link -> HCP
  final String? hcpFullName;
  final bool consentPrivacyUnderstood;
  final String? consentSignature;
  final String? consentPhoto;
  final String? hcpPhoto;
  final String? hcpType;
  final String? hcpPractice;
  final List<SubmissionSpecialty> specialties;
  final List<SubmissionWorkplace> workplaces;
  final List<SubmissionContact> contacts;
  final String? regionName;
  final String? provinceName;
  final String? cityMunicipality;
  final String? barangayName;
  final String? institution;
  final String? accountOrProgram; // Link -> Branch
  final String? surveyTemplate; // Link -> HCP Survey Template
  final String? surveyTemplateTitle;
  final String? medrepEmail; // Link -> User
  final String? submissionDate;
  final String? surveyResponse; // Link -> HCP Survey Response
  final List<SubmissionAnswer> answers; // Table -> HCP Profile Submission Answer
  final int docstatus; // 0: Draft, 1: Submitted, 2: Cancelled

  HcpProfileSubmission({
    this.name,
    required this.hcpName,
    this.hcpFullName,
    this.consentPrivacyUnderstood = false,
    this.consentSignature,
    this.consentPhoto,
    this.hcpPhoto,
    this.hcpType,
    this.hcpPractice,
    this.specialties = const [],
    this.workplaces = const [],
    this.contacts = const [],
    this.regionName,
    this.provinceName,
    this.cityMunicipality,
    this.barangayName,
    this.institution,
    this.accountOrProgram,
    this.surveyTemplate,
    this.surveyTemplateTitle,
    this.medrepEmail,
    this.submissionDate,
    this.surveyResponse,
    this.answers = const [],
    this.docstatus = 0,
  });

  factory HcpProfileSubmission.fromJson(Map<String, dynamic> json) {
    return HcpProfileSubmission(
      name: json['name'],
      hcpName: json['hcp_name'] ?? '',
      hcpFullName: json['hcp_full_name'],
      consentPrivacyUnderstood: json['consent_privacy_understood'] == 1 || json['consent_privacy_understood'] == true,
      consentSignature: json['consent_signature'],
      consentPhoto: json['consent_photo'],
      hcpPhoto: json['hcp_photo'],
      hcpType: json['hcp_type'],
      hcpPractice: json['hcp_practice'],
      specialties: (json['table_specialties'] as List?)
              ?.map((e) => SubmissionSpecialty.fromJson(e))
              .toList() ?? [],
      workplaces: (json['table_workplaces'] as List?)
              ?.map((e) => SubmissionWorkplace.fromJson(e))
              .toList() ?? [],
      contacts: (json['table_contact_info'] as List?)
              ?.map((e) => SubmissionContact.fromJson(e))
              .toList() ?? [],
      regionName: json['region_name'],
      provinceName: json['province_name'],
      cityMunicipality: json['city_municipality'],
      barangayName: json['barangay_name'],
      institution: json['institution'],
      accountOrProgram: json['account_or_program'],
      surveyTemplate: json['survey_template'],
      surveyTemplateTitle: json['survey_template_title'],
      medrepEmail: json['medrep_email'],
      submissionDate: json['submission_date'],
      surveyResponse: json['survey_response'],
      answers: (json['answers'] as List?)
              ?.map((e) => SubmissionAnswer.fromJson(e))
              .toList() ?? [],
      docstatus: json['docstatus'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      'hcp_name': hcpName,
      if (hcpFullName != null) 'hcp_full_name': hcpFullName,
      'consent_privacy_understood': consentPrivacyUnderstood ? 1 : 0,
      if (consentSignature != null) 'consent_signature': consentSignature,
      if (consentPhoto != null) 'consent_photo': consentPhoto,
      if (hcpPhoto != null) 'hcp_photo': hcpPhoto,
      if (hcpType != null) 'hcp_type': hcpType,
      if (hcpPractice != null) 'hcp_practice': hcpPractice,
      'table_specialties': specialties.map((e) => e.toJson()).toList(),
      'table_workplaces': workplaces.map((e) => e.toJson()).toList(),
      'table_contact_info': contacts.map((e) => e.toJson()).toList(),
      if (regionName != null) 'region_name': regionName,
      if (provinceName != null) 'province_name': provinceName,
      if (cityMunicipality != null) 'city_municipality': cityMunicipality,
      if (barangayName != null) 'barangay_name': barangayName,
      if (institution != null) 'institution': institution,
      if (accountOrProgram != null) 'account_or_program': accountOrProgram,
      if (surveyTemplate != null) 'survey_template': surveyTemplate,
      if (surveyTemplateTitle != null) 'survey_template_title': surveyTemplateTitle,
      if (medrepEmail != null) 'medrep_email': medrepEmail,
      if (submissionDate != null) 'submission_date': submissionDate,
      if (surveyResponse != null) 'survey_response': surveyResponse,
      'answers': answers.map((e) => e.toJson()).toList(),
      'docstatus': docstatus,
    };
  }
}

class SubmissionSpecialty {
  final String hcpSpecialty; // Link -> Specialization
  final String? subSpecialty; // Link -> Specialization

  SubmissionSpecialty({
    required this.hcpSpecialty,
    this.subSpecialty,
  });

  factory SubmissionSpecialty.fromJson(Map<String, dynamic> json) {
    return SubmissionSpecialty(
      hcpSpecialty: json['hcp_specialty'] ?? '',
      subSpecialty: json['sub_specialty'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hcp_specialty': hcpSpecialty,
      if (subSpecialty != null) 'sub_specialty': subSpecialty,
    };
  }
}

class SubmissionWorkplace {
  final String workplace; // Link -> Institution
  final String? address;
  final bool isPrimary;

  SubmissionWorkplace({
    required this.workplace,
    this.address,
    this.isPrimary = false,
  });

  factory SubmissionWorkplace.fromJson(Map<String, dynamic> json) {
    return SubmissionWorkplace(
      workplace: json['workplace'] ?? '',
      address: json['address'],
      isPrimary: json['is_primary'] == 1 || json['is_primary'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workplace': workplace,
      if (address != null) 'address': address,
      'is_primary': isPrimary ? 1 : 0,
    };
  }
}

class SubmissionContact {
  final String contactType;
  final String contactValue;

  SubmissionContact({
    required this.contactType,
    required this.contactValue,
  });

  factory SubmissionContact.fromJson(Map<String, dynamic> json) {
    return SubmissionContact(
      contactType: json['contact_type'] ?? '',
      contactValue: json['contact_value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact_type': contactType,
      'contact_value': contactValue,
    };
  }
}

class SubmissionAnswer {
  final String question; // Link -> HCP Survey Question or Data
  final String answer; // Answer string / select option

  SubmissionAnswer({
    required this.question,
    required this.answer,
  });

  factory SubmissionAnswer.fromJson(Map<String, dynamic> json) {
    return SubmissionAnswer(
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
