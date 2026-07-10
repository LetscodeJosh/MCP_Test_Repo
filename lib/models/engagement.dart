class Engagement {
  final String? name;
  final bool unsuccessfulCall;
  final String? company;
  final String? latitude;
  final String? longitude;
  final double locationAccuracy;
  final String? picture;
  final String? salesRep;
  final String? contact; // Maps to "First Name" in ERPNext
  final String? lastName;
  final String? positionOrRole;
  final String? emailAddress;
  final String? contactNumber;
  final String? dateAndTimeOfSalesAppointment;
  final bool decisionMakerOrResponsiblePersonNotAvailable;
  final String? reasonForUnsuccessfulCall;
  final String? creation;
  final String? modified;

  Engagement({
    this.name,
    this.unsuccessfulCall = false,
    this.company,
    this.latitude,
    this.longitude,
    this.locationAccuracy = 0.0,
    this.picture,
    this.salesRep,
    this.contact,
    this.lastName,
    this.positionOrRole,
    this.emailAddress,
    this.contactNumber,
    this.dateAndTimeOfSalesAppointment,
    this.decisionMakerOrResponsiblePersonNotAvailable = false,
    this.reasonForUnsuccessfulCall,
    this.creation,
    this.modified,
  });

  factory Engagement.fromJson(Map<String, dynamic> json) {
    return Engagement(
      name: json['name'],
      unsuccessfulCall: json['unsuccessful_call'] == 1 || json['unsuccessful_call'] == true,
      company: json['company'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      locationAccuracy: (json['location_accuracy'] as num?)?.toDouble() ?? 0.0,
      picture: json['picture'],
      salesRep: json['sales_rep'],
      contact: json['contact'],
      lastName: json['last_name'],
      positionOrRole: json['position_or_role'],
      emailAddress: json['email_address'],
      contactNumber: json['contact_number'],
      dateAndTimeOfSalesAppointment: json['date_and_time_of_sales_appointment'],
      decisionMakerOrResponsiblePersonNotAvailable: 
          json['decision_maker_or_responsible_person_not_available'] == 1 || 
          json['decision_maker_or_responsible_person_not_available'] == true,
      reasonForUnsuccessfulCall: json['reason_for_unsuccessful_call'],
      creation: json['creation'],
      modified: json['modified'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      'unsuccessful_call': unsuccessfulCall ? 1 : 0,
      'company': company,
      'latitude': latitude,
      'longitude': longitude,
      'location_accuracy': locationAccuracy,
      'picture': picture,
      'sales_rep': salesRep,
      'contact': contact,
      'last_name': lastName,
      'position_or_role': positionOrRole,
      'email_address': emailAddress,
      'contact_number': contactNumber,
      'date_and_time_of_sales_appointment': dateAndTimeOfSalesAppointment,
      'decision_maker_or_responsible_person_not_available': 
          decisionMakerOrResponsiblePersonNotAvailable ? 1 : 0,
      'reason_for_unsuccessful_call': reasonForUnsuccessfulCall ?? '',
    };
  }
}


