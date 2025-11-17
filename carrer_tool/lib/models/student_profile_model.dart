class StudentProfileModel {
  String? fullName;
  String? phone;
  String? profileImageUrl;

  List<Map<String, dynamic>> education = [];
  List<String> skills = [];

  Map<String, dynamic> toJson() => {
    "fullName": fullName,
    "phone": phone,
    "profileImageUrl": profileImageUrl,
    "education": education,
    "skills": skills,
  };
}
