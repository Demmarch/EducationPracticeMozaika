class StaffModel {
  final int id;
  final String surname;
  final String name;
  final String patronymic;
  final int positionId;
  final String positionName;
  final String birthDate;
  final String phone;
  final String bankAccount;
  final String familyStatus;
  final String healthInfo;
  // Чувствительные данные (могут быть пустыми, если не расшифрованы или скрыты)
  final String passportDetails;
  final String login;

  StaffModel({
    required this.id,
    required this.surname,
    required this.name,
    required this.patronymic,
    required this.positionId,
    required this.positionName,
    required this.birthDate,
    required this.phone,
    required this.bankAccount,
    required this.familyStatus,
    required this.healthInfo,
    this.passportDetails = '',
    this.login = '',
  });

  String get fullName => "$surname $name $patronymic";

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] ?? 0,
      surname: json['surname'] ?? '',
      name: json['name'] ?? '',
      patronymic: json['patronymic'] ?? '',
      positionId: json['position_id'] ?? 1,
      positionName: json['position_name'] ?? 'Сотрудник',
      birthDate: json['birth_date'] ?? '',
      phone: json['phone'] ?? '',
      bankAccount: json['bank_account'] ?? '',
      familyStatus: json['family_status'] ?? '',
      healthInfo: json['health_info'] ?? '',
      passportDetails: json['passport_details'] ?? '',
      login: json['login'] ?? '',
    );
  }
}