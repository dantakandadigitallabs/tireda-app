import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationRequestModel {
  String? id;
  String? userId;
  String? userName;
  String? userEmail;
  String? userProfilePic;
  String? status; // 'pending', 'approved', 'rejected', 'resubmitted'
  String? adminNotes;
  List<SubmittedDocument>? submittedDocuments;
  Timestamp? createdAt;
  Timestamp? updatedAt;
  Timestamp? reviewedAt;

  VerificationRequestModel({
    this.id,
    this.userId,
    this.userName,
    this.userEmail,
    this.userProfilePic,
    this.status,
    this.adminNotes,
    this.submittedDocuments,
    this.createdAt,
    this.updatedAt,
    this.reviewedAt,
  });

  VerificationRequestModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    userName = json['userName'];
    userEmail = json['userEmail'];
    userProfilePic = json['userProfilePic'];
    status = json['status'];
    adminNotes = json['adminNotes'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    reviewedAt = json['reviewedAt'];
    if (json['submittedDocuments'] != null) {
      submittedDocuments = (json['submittedDocuments'] as List).map((e) => SubmittedDocument.fromJson(e)).toList();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userProfilePic': userProfilePic,
      'status': status,
      'adminNotes': adminNotes,
      'submittedDocuments': submittedDocuments?.map((e) => e.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'reviewedAt': reviewedAt,
    };
  }
}

class SubmittedDocument {
  String? documentId;
  String? documentName;
  String? type; // 'file', 'image', 'textfield'
  String? value; // for textfield
  String? fileUrl; // for file
  String? frontImageUrl; // for image
  String? backImageUrl; // for image (two-sided)

  SubmittedDocument({
    this.documentId,
    this.documentName,
    this.type,
    this.value,
    this.fileUrl,
    this.frontImageUrl,
    this.backImageUrl,
  });

  SubmittedDocument.fromJson(Map<String, dynamic> json) {
    documentId = json['documentId'];
    documentName = json['documentName'];
    type = json['type'];
    value = json['value'];
    fileUrl = json['fileUrl'];
    frontImageUrl = json['frontImageUrl'];
    backImageUrl = json['backImageUrl'];
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'documentName': documentName,
      'type': type,
      'value': value,
      'fileUrl': fileUrl,
      'frontImageUrl': frontImageUrl,
      'backImageUrl': backImageUrl,
    };
  }
}
