import 'package:cloud_firestore/cloud_firestore.dart';

/// A job application submitted by a seeker against a Job Category ad.
/// Stored in the [CollectionName.jobApplications] collection, separate from chat.
class JobApplicationModel {
  String? id;

  // Job / ad reference
  String? adId;
  String? adTitle;

  // Employer (the ad owner)
  String? employerId;

  // Applicant
  String? applicantId;
  String? applicantName;
  String? applicantEmail;
  String? applicantPhone;
  String? countryCode;

  // Application content
  String? coverNote;
  String? cvUrl;
  String? cvFileName;

  // Lifecycle: pending | reviewed | shortlisted | rejected
  String? status;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  JobApplicationModel({
    this.id,
    this.adId,
    this.adTitle,
    this.employerId,
    this.applicantId,
    this.applicantName,
    this.applicantEmail,
    this.applicantPhone,
    this.countryCode,
    this.coverNote,
    this.cvUrl,
    this.cvFileName,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  JobApplicationModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    adId = json['adId'];
    adTitle = json['adTitle'];
    employerId = json['employerId'];
    applicantId = json['applicantId'];
    applicantName = json['applicantName'];
    applicantEmail = json['applicantEmail'];
    applicantPhone = json['applicantPhone'];
    countryCode = json['countryCode'];
    coverNote = json['coverNote'];
    cvUrl = json['cvUrl'];
    cvFileName = json['cvFileName'];
    status = json['status'] ?? 'pending';
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['adId'] = adId;
    data['adTitle'] = adTitle;
    data['employerId'] = employerId;
    data['applicantId'] = applicantId;
    data['applicantName'] = applicantName;
    data['applicantEmail'] = applicantEmail;
    data['applicantPhone'] = applicantPhone;
    data['countryCode'] = countryCode;
    data['coverNote'] = coverNote;
    data['cvUrl'] = cvUrl;
    data['cvFileName'] = cvFileName;
    data['status'] = status;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}
