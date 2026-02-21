/// API response shape for GET /payments/methods (data.methods[]).
/// Stripe-style: id, card: { last4, exp_month, exp_year, brand }, isDefault.
class PaymentMethodApiModel {
  const PaymentMethodApiModel({
    required this.id,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.brand,
    this.isDefault = false,
    this.holderName,
  });

  final String id;
  final String last4;
  final int expMonth;
  final int expYear;
  final String brand;
  final bool isDefault;
  final String? holderName;

  factory PaymentMethodApiModel.fromJson(Map<String, dynamic> json) {
    final card = (json['card'] as Map<String, dynamic>?) ?? {};
    final expMonth = _toInt(card['exp_month'] ?? json['exp_month']);
    final expYear = _toInt(card['exp_year'] ?? json['exp_year']);
    return PaymentMethodApiModel(
      id: (json['id'] ?? '').toString(),
      last4: (card['last4'] ?? json['last4'] ?? '').toString(),
      expMonth: expMonth <= 0 ? 1 : (expMonth > 12 ? 12 : expMonth),
      expYear: expYear < 50 ? 2000 + expYear : expYear,
      brand: (card['brand'] ?? json['brand'] ?? 'visa').toString().toLowerCase(),
      isDefault: json['isDefault'] == true,
      holderName: json['holderName']?.toString(),
    );
  }

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
}
