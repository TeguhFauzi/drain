class TransactionModel {
  final String id;
  final String invoiceId;
  final String? userId;
  final String productId;
  final String gameUserId;
  final String? gameServerId;
  final double amount;
  final String status;
  final String? paymentMethod;
  final String? paymentUrl;
  final String? paymentId;
  final String? email;
  final String? phone;
  final String? notes;
  final String? completedAt;
  final String createdAt;

  // Joined product/game info
  final String? productName;
  final String? gameName;
  final String? gameImageUrl;

  TransactionModel({
    required this.id,
    required this.invoiceId,
    this.userId,
    required this.productId,
    required this.gameUserId,
    this.gameServerId,
    required this.amount,
    required this.status,
    this.paymentMethod,
    this.paymentUrl,
    this.paymentId,
    this.email,
    this.phone,
    this.notes,
    this.completedAt,
    required this.createdAt,
    this.productName,
    this.gameName,
    this.gameImageUrl,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    String? pName;
    String? gName;
    String? gImage;

    if (json['product'] != null) {
      pName = json['product']['name'];
      if (json['product']['game'] != null) {
        gName = json['product']['game']['name'];
        gImage = json['product']['game']['imageUrl'];
      }
    }

    return TransactionModel(
      id: json['id'] ?? '',
      invoiceId: json['invoiceId'] ?? '',
      userId: json['userId'],
      productId: json['productId'] ?? '',
      gameUserId: json['gameUserId'] ?? '',
      gameServerId: json['gameServerId'],
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'],
      paymentUrl: json['paymentUrl'],
      paymentId: json['paymentId'],
      email: json['email'],
      phone: json['phone'],
      notes: json['notes'],
      completedAt: json['completedAt'],
      createdAt: json['createdAt'] ?? '',
      productName: pName,
      gameName: gName,
      gameImageUrl: gImage,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
}
