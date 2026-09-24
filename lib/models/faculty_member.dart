class FacultyMember {
  final String name;
  final String designation; // e.g., Chairperson, Professor, Assistant Professor, Lecturer
  final String department;  // e.g., CSE, EEE, English, BBA, Pharmacy
  final String? email;
  final String? counselingHours;

  FacultyMember({
    required this.name,
    required this.designation,
    required this.department,
    this.email,
    this.counselingHours,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'designation': designation,
    'department': department,
    'email': email,
    'counselingHours': counselingHours,
  };

  factory FacultyMember.fromJson(Map<String, dynamic> json) => FacultyMember(
    name: json['name'] as String,
    designation: json['designation'] as String? ?? 'Faculty Member',
    department: json['department'] as String? ?? 'General',
    email: json['email'] as String?,
    counselingHours: json['counselingHours'] as String?,
  );
}
