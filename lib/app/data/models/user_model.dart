class UserModel {
  final String uid;
  final String email;
  final String phone;
  final double balance;
  final String userType; // client ou distributeur
  final String authProvider;

  UserModel({
    required this.uid,
    required this.email,
    required this.phone,
    required this.balance,
    required this.userType,
    required this.authProvider,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
      userType: map['userType'] ?? 'client', // Par défaut client
      authProvider: map['authProvider'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phone': phone,
      'balance': balance,
      'userType': userType,
      'authProvider': authProvider,
    };
  }
}
