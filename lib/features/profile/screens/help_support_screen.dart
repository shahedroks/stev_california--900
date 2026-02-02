import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/features/home/widgets/customer_header.dart';
import 'package:renizo/features/nav_bar/screen/bottom_nav_bar.dart';
import 'package:renizo/features/notifications/screens/notifications_screen.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';
import 'package:renizo/core/models/town.dart';

/// Help & Support – full conversion from React HelpSupportScreen.tsx.
/// Blue bg, CustomerHeader, bottom nav, search, Contact Us (Email), FAQs by category, Support Hours.
class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({
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

  static const String routeName = '/help-support';

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _expandedFaqIndex;
  String? _selectedTownName;
  String? _selectedTownId;

  static const Color _bgBlue = Color(0xFF2384F4);

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      category: 'Booking',
      question: 'How do I book a service?',
      answer:
          'Browse available services in your town, select a provider, choose your preferred date and time, and complete the booking with in-app payment.',
    ),
    _FaqItem(
      category: 'Booking',
      question: 'Can I cancel or reschedule a booking?',
      answer:
          'Yes, you can cancel or reschedule bookings up to 24 hours before the scheduled time. Go to your bookings tab, select the booking, and choose "Cancel" or "Reschedule".',
    ),
    _FaqItem(
      category: 'Payment',
      question: 'What payment methods do you accept?',
      answer:
          'We accept major credit and debit cards including Visa, Mastercard, and American Express. All payments are processed securely through our encrypted payment system.',
    ),
    _FaqItem(
      category: 'Payment',
      question: 'Why should I pay through the app?',
      answer:
          'Paying through the app provides secure payment processing, documented transactions, 30-day workmanship warranty, and protection for both customers and service providers.',
    ),
    _FaqItem(
      category: 'Warranty',
      question: 'What is the 30-day warranty?',
      answer:
          'All services booked and paid within Renizo include a free 30-day workmanship warranty. If you experience any issues with the service quality or workmanship within 30 days of completion, contact the provider through in-app chat to resolve the issue at no additional cost.',
    ),
    _FaqItem(
      category: 'Warranty',
      question: 'How do I file a warranty claim?',
      answer:
          'Contact the service provider through in-app chat within 30 days of service completion, describe the issue with photos if possible, and work with them to schedule a follow-up visit. If the issue remains unresolved, contact Renizo support for assistance.',
    ),
    _FaqItem(
      category: 'Warranty',
      question: 'What does the warranty cover?',
      answer:
          'The warranty covers defects in workmanship or service quality, issues directly related to the completed service, and follow-up repairs for warranty-valid issues. It does not cover normal wear and tear, damage from misuse, or issues reported after 30 days.',
    ),
    _FaqItem(
      category: 'Account',
      question: 'How do I update my profile information?',
      answer:
          'Go to Profile > Edit Profile to update your name, email, phone number, and profile photo.',
    ),
    _FaqItem(
      category: 'Account',
      question: 'Can I change my town selection?',
      answer:
          'Yes, tap the town name in the header or go to Profile > Change Town to switch between available towns.',
    ),
  ];

  List<_FaqItem> get _filteredFaqs {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _faqs;
    return _faqs
        .where(
          (faq) =>
              faq.question.toLowerCase().contains(q) ||
              faq.answer.toLowerCase().contains(q),
        )
        .toList();
  }

  List<String> get _categories {
    return _faqs.map((f) => f.category).toSet().toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _onNavTabTap(int index) {
    if (index == 4) return;
    Navigator.of(context).pop();
    ref.read(selectedIndexProvider.notifier).state = index;
  }

  void _onBack() {
    widget.onBack?.call();
    if (widget.onBack != null) return;
    if (mounted) Navigator.of(context).pop();
  }

  void _onContactSupport(String method) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Opening $method...')));
    }
  }

  void _toggleFaq(int globalIndex) {
    setState(() {
      _expandedFaqIndex = _expandedFaqIndex == globalIndex ? null : globalIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFaqs;
    return Scaffold(
      backgroundColor: _bgBlue,
      bottomNavigationBar: CustomerBottomNavBar(
        currentIndex: 4,
        onTabTap: _onNavTabTap,
      ),
      body: Column(
        children: [
          CustomerHeader(
            leading: IconButton(
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
            selectedTownName: widget.selectedTownName ?? _selectedTownName,
            onChangeTown: _onChangeTown,
            onNotifications: _onNotifications,
          ),
          _buildTitle(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  SizedBox(height: 24.h),
                  _buildSectionTitle('Contact Us'),
                  SizedBox(height: 12.h),
                  _buildContactCard(),
                  SizedBox(height: 24.h),
                  _buildSectionTitle('Frequently Asked Questions'),
                  SizedBox(height: 12.h),
                  _buildFaqByCategory(filtered),
                  if (filtered.isEmpty) _buildNoResults(),
                  SizedBox(height: 24.h),
                  _buildSupportHours(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _bgBlue,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Help & Support',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search for help...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15.sp),
        prefixIcon: Icon(
          Icons.search,
          color: Colors.grey.shade400,
          size: 22.sp,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
      style: TextStyle(color: Colors.black87, fontSize: 15.sp),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.7),
      ),
    );
  }

  Widget _buildContactCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onContactSupport('Email'),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.mail_outline,
                  color: Colors.white,
                  size: 26.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Support',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'support@renizo.com',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                color: Colors.white.withOpacity(0.7),
                size: 22.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqByCategory(List<_FaqItem> filtered) {
    final categories = _categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in categories) ...[
          Builder(
            builder: (context) {
              final categoryFaqs = filtered
                  .where((f) => f.category == category)
                  .toList();
              if (categoryFaqs.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...categoryFaqs.map((faq) {
                    final globalIndex = _faqs.indexOf(faq);
                    final isExpanded = _expandedFaqIndex == globalIndex;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: _FaqTile(
                        question: faq.question,
                        answer: faq.answer,
                        isExpanded: isExpanded,
                        onTap: () => _toggleFaq(globalIndex),
                      ),
                    );
                  }),
                  SizedBox(height: 16.h),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Column(
        children: [
          Text(
            'No results found for "${_searchController.text}"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try searching with different keywords',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportHours() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Hours',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Email: 24/7 (Response within 24 hours)',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });

  final String category;
  final String question;
  final String answer;
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        question,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white.withOpacity(0.7),
                      size: 24.sp,
                    ),
                  ],
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: Text(
                    answer,
                    style: TextStyle(
                      fontSize: 14.sp,
                      height: 1.4,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
