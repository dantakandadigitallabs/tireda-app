class ContactUsModel {
  String? email;
  String? phoneNumber;
  String? androidURL;
  String? iosURL;
  String? webAppURL;

  ContactUsModel({
    this.email,
    this.phoneNumber,
    this.androidURL,
    this.iosURL,
    this.webAppURL,
  });

  ContactUsModel.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    phoneNumber = json['phoneNumber'];
    androidURL = json['androidURL'];
    iosURL = json['iosURL'];
    webAppURL = json['webAppURL'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['phoneNumber'] = phoneNumber;
    data['androidURL'] = androidURL;
    data['iosURL'] = iosURL;
    data['webAppURL'] = webAppURL;
    return data;
  }
}
