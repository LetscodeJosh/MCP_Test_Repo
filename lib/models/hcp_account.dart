class HcpAccount {
  final String? name;
  final String accountName;
  final String? accountType;
  final bool isActive;
  final List<HcpAccountSpecialization> specialties;
  final List<HcpAccountWorkplace> workplaces;
  final List<HcpAccountContact> contacts;

  HcpAccount({
    this.name,
    required this.accountName,
    this.accountType,
    this.isActive = true,
    this.specialties = const [],
    this.workplaces = const [],
    this.contacts = const [],
  });

  factory HcpAccount.fromJson(Map<String, dynamic> json) {
    return HcpAccount(
      name: json['name'],
      accountName: json['account_name'] ?? '',
      accountType: json['account_type'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      specialties: (json['specialties'] as List?)
              ?.map((e) => HcpAccountSpecialization.fromJson(e))
              .toList() ?? [],
      workplaces: (json['workplaces'] as List?)
              ?.map((e) => HcpAccountWorkplace.fromJson(e))
              .toList() ?? [],
      contacts: (json['contacts'] as List?)
              ?.map((e) => HcpAccountContact.fromJson(e))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      'account_name': accountName,
      if (accountType != null) 'account_type': accountType,
      'is_active': isActive ? 1 : 0,
      'specialties': specialties.map((e) => e.toJson()).toList(),
      'workplaces': workplaces.map((e) => e.toJson()).toList(),
      'contacts': contacts.map((e) => e.toJson()).toList(),
    };
  }
}

class HcpAccountSpecialization {
  final String specialty;
  final String? subSpecialty;

  HcpAccountSpecialization({
    required this.specialty,
    this.subSpecialty,
  });

  factory HcpAccountSpecialization.fromJson(Map<String, dynamic> json) {
    return HcpAccountSpecialization(
      specialty: json['specialty'] ?? '',
      subSpecialty: json['sub_specialty'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'specialty': specialty,
      if (subSpecialty != null) 'sub_specialty': subSpecialty,
    };
  }
}

class HcpAccountWorkplace {
  final String workplace;
  final String? address;
  final bool isPrimary;

  HcpAccountWorkplace({
    required this.workplace,
    this.address,
    this.isPrimary = false,
  });

  factory HcpAccountWorkplace.fromJson(Map<String, dynamic> json) {
    return HcpAccountWorkplace(
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

class HcpAccountContact {
  final String contactType;
  final String contactValue;

  HcpAccountContact({
    required this.contactType,
    required this.contactValue,
  });

  factory HcpAccountContact.fromJson(Map<String, dynamic> json) {
    return HcpAccountContact(
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

class HcpAccountDoctors {
  final String? name;
  final String hcp;
  final String hcpAccount;
  final String? role;

  HcpAccountDoctors({
    this.name,
    required this.hcp,
    required this.hcpAccount,
    this.role,
  });

  factory HcpAccountDoctors.fromJson(Map<String, dynamic> json) {
    return HcpAccountDoctors(
      name: json['name'],
      hcp: json['hcp'] ?? '',
      hcpAccount: json['hcp_account'] ?? '',
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      'hcp': hcp,
      'hcp_account': hcpAccount,
      if (role != null) 'role': role,
    };
  }
}
