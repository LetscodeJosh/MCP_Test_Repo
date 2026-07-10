class Hcp {
  final String? name;
  final String? hcpFullName;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? hcpPhoto;
  final String hcpType;
  final String hcpPractice;
  final bool isActive;
  final bool isPendingApproval;
  final List<HcpSpecialty> specialties;
  final List<HcpWorkplace> workplaces;
  final List<HcpContact> contacts;
  final String? regionName;
  final String? provinceName;
  final String? cityMunicipality;
  final String? barangayName;
  final String? institution;

  Hcp({
    this.name,
    this.hcpFullName,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.hcpPhoto,
    required this.hcpType,
    required this.hcpPractice,
    this.isActive = true,
    this.isPendingApproval = false,
    this.specialties = const [],
    this.workplaces = const [],
    this.contacts = const [],
    this.regionName,
    this.provinceName,
    this.cityMunicipality,
    this.barangayName,
    this.institution,
  });

  factory Hcp.fromJson(Map<String, dynamic> json) {
    return Hcp(
      name: json['name'],
      hcpFullName: json['hcp_full_name'],
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'],
      lastName: json['last_name'] ?? '',
      hcpPhoto: json['hcp_photo'],
      hcpType: json['hcp_type'] ?? '',
      hcpPractice: json['hcp_practice'] ?? 'Both',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      isPendingApproval: json['is_pending_approval'] == 1 || json['is_pending_approval'] == true,
      specialties: (json['hcp_specialty'] as List?)
              ?.map((e) => HcpSpecialty.fromJson(e))
              .toList() ?? [],
      workplaces: (json['hcp_workplace'] as List?)
              ?.map((e) => HcpWorkplace.fromJson(e))
              .toList() ?? [],
      contacts: (json['hcp_contact_info'] as List?)
              ?.map((e) => HcpContact.fromJson(e))
              .toList() ?? [],
      regionName: json['region_name'],
      provinceName: json['province_name'],
      cityMunicipality: json['city_municipality'],
      barangayName: json['barangay_name'],
      institution: json['institution'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      'first_name': firstName,
      if (middleName != null) 'middle_name': middleName,
      'last_name': lastName,
      if (hcpFullName != null) 'hcp_full_name': hcpFullName,
      if (hcpPhoto != null) 'hcp_photo': hcpPhoto,
      'hcp_type': hcpType,
      'hcp_practice': hcpPractice,
      'is_active': isActive ? 1 : 0,
      'is_pending_approval': isPendingApproval ? 1 : 0,
      'hcp_specialty': specialties.map((e) => e.toJson()).toList(),
      'hcp_workplace': workplaces.map((e) => e.toJson()).toList(),
      'hcp_contact_info': contacts.map((e) => e.toJson()).toList(),
      if (regionName != null) 'region_name': regionName,
      if (provinceName != null) 'province_name': provinceName,
      if (cityMunicipality != null) 'city_municipality': cityMunicipality,
      if (barangayName != null) 'barangay_name': barangayName,
      if (institution != null) 'institution': institution,
    };
  }
}

class HcpSpecialty {
  final String hcpSpecialty; // Link -> Specialization
  final String? subSpecialty; // Link -> Specialization

  HcpSpecialty({
    required this.hcpSpecialty,
    this.subSpecialty,
  });

  factory HcpSpecialty.fromJson(Map<String, dynamic> json) {
    return HcpSpecialty(
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

class HcpWorkplace {
  final String workplace; // Link -> Institution
  final String? address; // Street address / details
  final bool isPrimary;

  HcpWorkplace({
    required this.workplace,
    this.address,
    this.isPrimary = false,
  });

  factory HcpWorkplace.fromJson(Map<String, dynamic> json) {
    return HcpWorkplace(
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

class HcpContact {
  final String contactType; // Mobile, Email, Telephone, etc.
  final String contactValue;

  HcpContact({
    required this.contactType,
    required this.contactValue,
  });

  factory HcpContact.fromJson(Map<String, dynamic> json) {
    return HcpContact(
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
