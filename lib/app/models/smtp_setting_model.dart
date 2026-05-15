class SMTPSettingModel {
  String? smtpHost;
  String? smtpPort;
  String? username;
  String? password;
  String? encryption;

  SMTPSettingModel({this.smtpHost, this.smtpPort, this.username, this.password, this.encryption});

  SMTPSettingModel.fromJson(Map<String, dynamic> json) {
    smtpHost = json['smtp_host'];
    smtpPort = json['smtp_port'];
    username = json['username'];
    password = json['password'];
    encryption = json['encryption'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['smtp_host'] = smtpHost;
    data['smtp_port'] = smtpPort;
    data['username'] = username;
    data['password'] = password;
    data['encryption'] = encryption;
    return data;
  }
}
