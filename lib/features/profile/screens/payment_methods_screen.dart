import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:renizo/core/models/town.dart';
import 'package:renizo/core/services/stripe_service.dart';
import 'package:renizo/features/home/widgets/customer_header.dart';
import 'package:renizo/features/nav_bar/screen/bottom_nav_bar.dart';
import 'package:renizo/features/notifications/screens/notifications_screen.dart';
import 'package:renizo/features/profile/logic/payment_methods_logic.dart';
import 'package:renizo/features/profile/model/payment_method_model.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';

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

  /// From API model (GET /payments/methods).
  static PaymentMethodItem fromApi(PaymentMethodApiModel m) {
    final brand = m.brand.toLowerCase();
    PaymentMethodType type = PaymentMethodType.visa;
    if (brand.contains('master')) {
      type = PaymentMethodType.mastercard;
    } else if (brand.contains('amex') || brand.contains('american')) {
      type = PaymentMethodType.amex;
    }
    final year = m.expYear >= 2000 ? m.expYear % 100 : m.expYear;
    return PaymentMethodItem(
      id: m.id,
      type: type,
      last4: m.last4,
      expiryMonth: m.expMonth.toString().padLeft(2, '0'),
      expiryYear: year.toString().padLeft(2, '0'),
      isDefault: m.isDefault,
      holderName: m.holderName ?? 'Cardholder',
    );
  }
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

  Future<void> _handleSetDefault(String id) async {
    try {
      await setDefaultPaymentMethod(id);
      ref.invalidate(paymentMethodsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default payment method updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _handleDelete(String id, List<PaymentMethodItem> paymentMethods) {
    final method = paymentMethods.firstWhere((m) => m.id == id);
    if (method.isDefault && paymentMethods.length > 1) {
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
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await deletePaymentMethod(id);
                ref.invalidate(paymentMethodsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment method removed')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            e.toString().replaceFirst('Exception: ', ''))),
                  );
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _onPaymentMethodSaved() {
    _setShowAddCard(false);
    ref.invalidate(paymentMethodsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment method added successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showAddCard) {
      return AddCardScreen(
        onBack: () => _setShowAddCard(false),
        onSaved: _onPaymentMethodSaved,
        selectedTownName: widget.selectedTownName ?? _selectedTownName,
        selectedTownId: widget.selectedTownId ?? _selectedTownId,
        onChangeTown: _onChangeTown,
        onNotifications: _onNotifications,
        onNavTabTap: _onNavTabTap,
      );
    }
    final asyncMethods = ref.watch(paymentMethodsProvider);
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
            child: asyncMethods.when(
              data: (apiList) {
                final paymentMethods = apiList
                    .map(PaymentMethodItem.fromApi)
                    .toList();
                return paymentMethods.isEmpty
                    ? _buildEmptyState()
                    : _buildList(paymentMethods);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        err.toString().replaceFirst('Exception: ', ''),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(paymentMethodsProvider),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildList(List<PaymentMethodItem> paymentMethods) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Column(
        children: [
          ...paymentMethods.map(
            (method) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _CardTile(
                method: method,
                onSetDefault: _handleSetDefault,
                onDelete: (id) => _handleDelete(id, paymentMethods),
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
/// Uses Stripe SDK to create a PaymentMethod and saves it via API.
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({
    super.key,
    required this.onBack,
    this.onSaved,
    this.selectedTownName,
    this.selectedTownId,
    this.onChangeTown,
    this.onNotifications,
    this.onNavTabTap,
  });

  final VoidCallback onBack;
  /// Called after successfully adding via API.
  final VoidCallback? onSaved;
  final String? selectedTownName;
  final String? selectedTownId;
  final Future<void> Function()? onChangeTown;
  final VoidCallback? onNotifications;
  final void Function(int index)? onNavTabTap;

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _holderNameController = TextEditingController();
  CardFieldInputDetails? _cardDetails;
  bool _stripeReady = false;
  bool _saving = false;
  String? _selectedTownName;
  String? _selectedTownId;

  static const Color _bgBlue = Color(0xFF2384F4);

  @override
  void initState() {
    super.initState();
    _initStripe();
  }

  Future<void> _initStripe() async {
    try {
      await StripeService.ensureInitialized();
      if (mounted) setState(() => _stripeReady = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
    }
  }

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
    _holderNameController.dispose();
    super.dispose();
  }

  Future<void> _onAdd() async {
    if (_saving) return;
    final holderName = _holderNameController.text.trim();
    if (!_stripeReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stripe is not ready yet. Try again.')),
      );
      return;
    }
    if (holderName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter cardholder name')),
      );
      return;
    }
    if (!(_cardDetails?.complete ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid card details')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(name: holderName),
          ),
        ),
      );
      await addPaymentMethod(paymentMethod.id);
      widget.onSaved?.call();
      if (mounted) widget.onBack();
    } on StripeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.error.message ?? 'Failed to add card')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                  Text(
                    'Card Details',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  CardField(
                    onCardChanged: (details) {
                      setState(() => _cardDetails = details);
                    },
                    style: TextStyle(fontSize: 16.sp, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Card number',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide:
                            const BorderSide(color: Colors.white, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildField(
                    'Cardholder Name',
                    _holderNameController,
                    'John Doe',
                    null,
                    null,
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
              onTap: _saving ? null : _onAdd,
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: _saving
                    ? SizedBox(
                        height: 18.h,
                        width: 18.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF003E93),
                        ),
                      )
                    : Text(
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

