import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/features/home/widgets/customer_header.dart';
import 'package:renizo/features/nav_bar/screen/bottom_nav_bar.dart';
import 'package:renizo/features/notifications/screens/notifications_screen.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';
import 'package:renizo/core/models/town.dart';

/// Payment method – mirrors React PaymentMethodsScreen PaymentMethod.
enum PaymentMethodType { visa, mastercard, amex }

class PaymentMethodItem {
  const PaymentMethodItem({
    required this.id,
    required this.type,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    required this.isDefault,
    required this.holderName,
  });

  final String id;
  final PaymentMethodType type;
  final String last4;
  final String expiryMonth;
  final String expiryYear;
  final bool isDefault;
  final String holderName;
}

/// Payment Methods – full conversion from React PaymentMethodsScreen.tsx.
/// Same app header and bottom nav as CustomerHomeScreen; list of cards (or empty state).
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({
    super.key,
    this.onBack,
    this.selectedTownName,
    this.selectedTownId,
    this.onChangeTown,
    this.onNotifications,
  });

  final VoidCallback? onBack;
  final String? selectedTownName;
  final String? selectedTownId;
  final VoidCallback? onChangeTown;
  final VoidCallback? onNotifications;

  static const String routeName = '/payment-methods';

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  List<PaymentMethodItem> _paymentMethods = [
    PaymentMethodItem(
      id: '1',
      type: PaymentMethodType.visa,
      last4: '4242',
      expiryMonth: '12',
      expiryYear: '25',
      isDefault: true,
      holderName: 'John Doe',
    ),
    PaymentMethodItem(
      id: '2',
      type: PaymentMethodType.mastercard,
      last4: '8888',
      expiryMonth: '08',
      expiryYear: '26',
      isDefault: false,
      holderName: 'John Doe',
    ),
  ];

  bool _showAddCard = false;
  String? _selectedTownName;
  String? _selectedTownId;

  static const Color _bgBlue = Color(0xFF2384F4);

  Future<void> _onChangeTown() async {
    widget.onChangeTown?.call();
    if (widget.onChangeTown != null) return;
    if (!mounted) return;
    final town = await Navigator.of(context).push<Town>(
      MaterialPageRoute<Town>(
        builder: (context) => TownSelectionScreen(
          onSelectTown: (t) => Navigator.of(context).pop(t),
          canClose: true,
        ),
      ),
    );
    if (town != null && mounted) {
      setState(() {
        _selectedTownName = town.name;
        _selectedTownId = town.id;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Now showing services in ${town.name}')),
        );
      }
    }
  }

  void _onNotifications() {
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            NotificationsScreen(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  void _onNavTabTap(int index) {
    if (index == 4) return; // Already on Profile
    Navigator.of(context).pop();
    ref.read(selectedIndexProvider.notifier).state = index;
  }

  void _onBack() {
    widget.onBack?.call();
    if (widget.onBack != null) return;
    if (mounted) Navigator.of(context).pop();
  }

  void _setShowAddCard(bool show) {
    setState(() => _showAddCard = show);
  }

  void _handleSetDefault(String id) {
    setState(() {
      _paymentMethods = _paymentMethods
          .map(
            (m) => PaymentMethodItem(
              id: m.id,
              type: m.type,
              last4: m.last4,
              expiryMonth: m.expiryMonth,
              expiryYear: m.expiryYear,
              isDefault: m.id == id,
              holderName: m.holderName,
            ),
          )
          .toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default payment method updated')),
    );
  }

  void _handleDelete(String id) {
    final method = _paymentMethods.firstWhere((m) => m.id == id);
    if (method.isDefault && _paymentMethods.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot delete default payment method. Set another card as default first.',
          ),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove payment method?'),
        content: const Text(
          'Are you sure you want to remove this payment method?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(
                () => _paymentMethods = _paymentMethods
                    .where((m) => m.id != id)
                    .toList(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment method removed')),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _onAddCard(PaymentMethodItem card) {
    setState(() {
      _paymentMethods = [..._paymentMethods, card];
      _showAddCard = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment method added successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showAddCard) {
      return AddCardScreen(
        onBack: () => _setShowAddCard(false),
        onAdd: _onAddCard,
        selectedTownName: widget.selectedTownName ?? _selectedTownName,
        selectedTownId: widget.selectedTownId ?? _selectedTownId,
        onChangeTown: _onChangeTown,
        onNotifications: _onNotifications,
        onNavTabTap: _onNavTabTap,
      );
    }
    return Scaffold(
      backgroundColor: _bgBlue,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: CustomerBottomNavBar(
        currentIndex: 4,
        onTabTap: _onNavTabTap,
      ),
      body: Column(
        children: [
          CustomerHeader(
            selectedTownName: widget.selectedTownName ?? _selectedTownName,
            onChangeTown: _onChangeTown,
            onNotifications: _onNotifications,
          ),
          _buildHeader(),
          Expanded(
            child: _paymentMethods.isEmpty ? _buildEmptyState() : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: _bgBlue,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _onBack,
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 22.sp,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Payment Methods',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _setShowAddCard(true),
            icon: Icon(Icons.add, size: 24.sp, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.credit_card, size: 40.sp, color: Colors.white),
            ),
            SizedBox(height: 16.h),
            Text(
              'No Payment Methods',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Add a payment method to start booking services',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Material(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16.r),
              child: InkWell(
                onTap: () => _setShowAddCard(true),
                borderRadius: BorderRadius.circular(16.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 14.h,
                  ),
                  child: Text(
                    'Add Payment Method',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF003E93),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Column(
        children: [
          ..._paymentMethods.map(
            (method) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _CardTile(
                method: method,
                onSetDefault: _handleSetDefault,
                onDelete: _handleDelete,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _setShowAddCard(true),
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 24.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 20.sp, color: Colors.white),
                    SizedBox(width: 8.w),
                    Text(
                      'Add New Payment Method',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.method,
    required this.onSetDefault,
    required this.onDelete,
  });

  final PaymentMethodItem method;
  final void Function(String id) onSetDefault;
  final void Function(String id) onDelete;

  static String _cardName(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.visa:
        return 'Visa';
      case PaymentMethodType.mastercard:
        return 'Mastercard';
      case PaymentMethodType.amex:
        return 'American Express';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.credit_card, size: 24.sp, color: Colors.white),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_cardName(method.type)} •••• ${method.last4}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            method.holderName,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            'Expires ${method.expiryMonth}/${method.expiryYear}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onDelete(method.id),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20.sp,
                        color: const Color(0xFFFCA5A5),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                if (method.isDefault)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14.sp, color: Colors.white),
                        SizedBox(width: 4.w),
                        Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => onSetDefault(method.id),
                    child: Text(
                      'Set as Default',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Add Card – full conversion from React AddCardScreen.
/// Same app header and bottom nav as CustomerHomeScreen.
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({
    super.key,
    required this.onBack,
    required this.onAdd,
    this.selectedTownName,
    this.selectedTownId,
    this.onChangeTown,
    this.onNotifications,
    this.onNavTabTap,
  });

  final VoidCallback onBack;
  final void Function(PaymentMethodItem card) onAdd;
  final String? selectedTownName;
  final String? selectedTownId;
  final Future<void> Function()? onChangeTown;
  final VoidCallback? onNotifications;
  final void Function(int index)? onNavTabTap;

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _cardNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvvController = TextEditingController();
  String? _selectedTownName;
  String? _selectedTownId;

  static const Color _bgBlue = Color(0xFF2384F4);

  Future<void> _onChangeTown() async {
    widget.onChangeTown?.call();
    if (widget.onChangeTown != null) return;
    if (!mounted) return;
    final town = await Navigator.of(context).push<Town>(
      MaterialPageRoute<Town>(
        builder: (context) => TownSelectionScreen(
          onSelectTown: (t) => Navigator.of(context).pop(t),
          canClose: true,
        ),
      ),
    );
    if (town != null && mounted) {
      setState(() {
        _selectedTownName = town.name;
        _selectedTownId = town.id;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Now showing services in ${town.name}')),
        );
      }
    }
  }

  void _onNotifications() {
    widget.onNotifications?.call();
    if (widget.onNotifications != null) return;
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            NotificationsScreen(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _holderNameController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String _formatCardNumber(String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < cleaned.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  void _onCardNumberChange(String value) {
    final formatted = _formatCardNumber(value);
    if (formatted != _cardNumberController.text) {
      _cardNumberController.text = formatted;
      _cardNumberController.selection = TextSelection.collapsed(
        offset: formatted.length,
      );
    }
  }

  void _onAdd() {
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final holderName = _holderNameController.text.trim();
    final expiryMonth = _expiryMonthController.text.trim();
    final expiryYear = _expiryYearController.text.trim();
    final cvv = _cvvController.text.trim();

    if (cardNumber.isEmpty ||
        holderName.isEmpty ||
        expiryMonth.isEmpty ||
        expiryYear.isEmpty ||
        cvv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (cardNumber.length != 16) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid card number')));
      return;
    }

    PaymentMethodType type;
    if (cardNumber.startsWith('4')) {
      type = PaymentMethodType.visa;
    } else if (cardNumber.startsWith('5')) {
      type = PaymentMethodType.mastercard;
    } else {
      type = PaymentMethodType.amex;
    }

    final newCard = PaymentMethodItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      last4: cardNumber.substring(12),
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: false,
      holderName: holderName,
    );
    widget.onAdd(newCard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlue,
      bottomNavigationBar: CustomerBottomNavBar(
        currentIndex: 4,
        onTabTap: widget.onNavTabTap ?? (_) {},
      ),
      body: Column(
        children: [
          CustomerHeader(
            selectedTownName: widget.selectedTownName ?? _selectedTownName,
            onChangeTown: _onChangeTown,
            onNotifications: _onNotifications,
          ),
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField(
                    'Card Number',
                    _cardNumberController,
                    '1234 5678 9012 3456',
                    19,
                    (v) => _onCardNumberChange(v),
                  ),
                  SizedBox(height: 16.h),
                  _buildField(
                    'Cardholder Name',
                    _holderNameController,
                    'John Doe',
                    null,
                    null,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          'Month',
                          _expiryMonthController,
                          'MM',
                          2,
                          (v) {
                            final d = _digitsOnly(v).length > 2
                                ? _digitsOnly(v).substring(0, 2)
                                : _digitsOnly(v);
                            if (d != _expiryMonthController.text) {
                              _expiryMonthController.text = d;
                              _expiryMonthController.selection =
                                  TextSelection.collapsed(offset: d.length);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildField(
                          'Year',
                          _expiryYearController,
                          'YY',
                          2,
                          (v) {
                            final d = _digitsOnly(v).length > 2
                                ? _digitsOnly(v).substring(0, 2)
                                : _digitsOnly(v);
                            if (d != _expiryYearController.text) {
                              _expiryYearController.text = d;
                              _expiryYearController.selection =
                                  TextSelection.collapsed(offset: d.length);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildField('CVV', _cvvController, '123', 3, (
                          v,
                        ) {
                          final d = _digitsOnly(v).length > 3
                              ? _digitsOnly(v).substring(0, 3)
                              : _digitsOnly(v);
                          if (d != _cvvController.text) {
                            _cvvController.text = d;
                            _cvvController.selection = TextSelection.collapsed(
                              offset: d.length,
                            );
                          }
                        }),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      'Secure Payment: Your payment information is encrypted and securely stored. We never share your card details with service providers.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: _bgBlue,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 22.sp,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Add Payment Method',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Material(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              onTap: _onAdd,
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Text(
                  'Add',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF003E93),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint,
    int? maxLength,
    void Function(String)? onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          maxLength: maxLength,
          onChanged: onChanged,
          style: TextStyle(fontSize: 16.sp, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');
