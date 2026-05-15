class EmailTemplateModel {
  String? id;
  String? subject;
  String? body;
  String? type;
  bool? status;

  EmailTemplateModel({this.id, this.subject, this.body, this.type, this.status});

  EmailTemplateModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    subject = json['subject'];
    body = json['body'];
    type = json['type'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['subject'] = subject;
    data['body'] = body;
    data['type'] = type;
    data['status'] = status;
    return data;
  }
}
