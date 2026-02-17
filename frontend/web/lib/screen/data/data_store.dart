// 1. โมเดลข้อมูลการนัดหมาย
class AppointmentModel {
  String id;          
  String name;
  String date;
  String time;
  String treatment;
  String doctor;
  String phone;
  String status;      
  
  String? queueNumber;  
  String? assignedRoom; 

  AppointmentModel({
    required this.id,
    required this.name,
    required this.date,
    required this.time,
    required this.treatment,
    required this.doctor,
    required this.phone,
    required this.status,
    this.queueNumber,   
    this.assignedRoom,  
  });
}

// 2. โมเดลข้อมูลผู้ป่วย (ย้ายมาจาก pateints_table.dart)
class PatientInfo {
  String patientId;
  String idCard;
  String prefix;
  String firstName;
  String lastName;
  String gender;
  String birthDate;
  String phone;
  String email;
  String disease;
  String allergy;
  String medication;
  String history;
  String right;
  String insuranceLimit;
  String address;
  String subDistrict;
  String district;
  String province;
  String zipCode;

  String get fullName => "$prefix $firstName $lastName".trim();

  PatientInfo({
    required this.patientId,
    required this.idCard,
    required this.prefix,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.birthDate,
    required this.phone,
    required this.email,
    this.disease = "-",
    this.allergy = "-",
    this.medication = "-",
    this.history = "-",
    this.right = "-",
    this.insuranceLimit = "-",
    this.address = "-",
    this.subDistrict = "-",
    this.district = "-",
    this.province = "-",
    this.zipCode = "-",
  });
}

// 3. แหล่งเก็บข้อมูลกลาง (Shared Data Store)
class DataStore {
  static List<AppointmentModel> allAppointments = [];
  
  // เพิ่มตัวแปรสำหรับเก็บรายชื่อผู้ป่วยทั้งหมด
  static List<PatientInfo> allPatients = []; 
}