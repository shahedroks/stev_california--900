// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import 'package:renizo/core/constants/image_control/image_path.dart';
// import 'package:renizo/features/auth/screens/home_screen.dart';
// import 'package:renizo/features/auth/screens/register_screen.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//   static final routeName = "/login";
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 24.w),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 40.h),
//
//                 // Logo at top left
//                 Image.asset(
//                   ImagePath.loginLogo,
//                   width: 40.w,
//                   height: 40.h,
//                 ),
//
//                 SizedBox(height: 30.h),
//
//                 // Title "Welcome to Aican"
//                 Text(
//                   'Welcome to Aican',
//                   style: TextStyle(
//                     fontSize: 26.sp,
//                     fontWeight: FontWeight.bold,
//                     color: const Color(0xFF111827),
//                     fontFamily: 'Inter',
//                   ),
//                 ),
//
//                 SizedBox(height: 12.h),
//
//                 // Subtitle
//                 Text(
//                   'Please enter your registration email and password.',
//                   style: TextStyle(
//                     fontSize: 16.sp,
//                     fontWeight: FontWeight.w400,
//                     color: const Color(0xFF111827),
//                     fontFamily: 'Inter',
//                   ),
//                 ),
//
//                 SizedBox(height: 48.h),
//
//                 // Email input field with light blue border
//                 Container(
//                   width: double.infinity,
//                   height: 52.h,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF3F4F6),
//                     borderRadius: BorderRadius.circular(26.r),
//                     border: Border.all(
//                       color: const Color(0xFF0088FE),
//                       width: 1,
//                     ),
//                   ),
//                   child: TextField(
//                     controller: _emailController,
//                     keyboardType: TextInputType.emailAddress,
//                     decoration: InputDecoration(
//                       hintText: 'Email',
//                       hintStyle: TextStyle(
//                         fontSize: 16.sp,
//                         color: const Color(0xFF0088FE),
//                         fontWeight: FontWeight.w400,
//                         fontFamily: 'Inter',
//                       ),
//                       border: InputBorder.none,
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 20.w,
//                         vertical: 16.h,
//                       ),
//                     ),
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       color: const Color(0xFF111827),
//                       fontWeight: FontWeight.w400,
//                       fontFamily: 'Inter',
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: 20.h),
//
//                 // Password input field
//                 Container(
//                   width: double.infinity,
//                   height: 52.h,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF3F4F6),
//                     borderRadius: BorderRadius.circular(26.r),
//                   ),
//                   child: TextField(
//                     controller: _passwordController,
//                     obscureText: true,
//                     decoration: InputDecoration(
//                       hintText: 'Password',
//                       hintStyle: TextStyle(
//                         fontSize: 16.sp,
//                         color: const Color(0xFF6B7280),
//                         fontWeight: FontWeight.w400,
//                         fontFamily: 'Inter',
//                       ),
//                       border: InputBorder.none,
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 20.w,
//                         vertical: 16.h,
//                       ),
//                     ),
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       color: const Color(0xFF111827),
//                       fontWeight: FontWeight.w400,
//                       fontFamily: 'Inter',
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: 32.h),
//
//                 // Login button with gradient
//                 GestureDetector(
//                   onTap: () {
//                  context.go(HomeScreen.routeName);
//                   },
//                   child: Container(
//                     width: double.infinity,
//                     height: 54.h,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(26.r),
//                       gradient: const LinearGradient(
//                         begin: Alignment.centerLeft,
//                         end: Alignment.centerRight,
//                         colors: [
//                           Color(0xFF0088FE),
//                           Color(0xFF15DFFE),
//                         ],
//                       ),
//                     ),
//                     child: Center(
//                       child: Text(
//                         'Login',
//                         style: TextStyle(
//                           fontSize: 16.sp,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                           fontFamily: 'Inter',
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: 32.h),
//
//                 // "Or via social networks" text
//                 Center(
//                   child: Text(
//                     'Or via social networks',
//                     style: TextStyle(
//                       fontSize: 14.sp,
//                       fontWeight: FontWeight.w400,
//                       color: const Color(0xFF6B7280),
//                       fontFamily: 'Inter',
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: 20.h),
//
//                 // Social login buttons - Apple first, then Google
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Apple login button
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: () {
//                           // Handle Apple login
//                         },
//                         child: Container(
//                           height: 54.h,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(13.r),
//                             border: Border.all(
//                               color: const Color(0xFFE1E1E1),
//                               width: 1,
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Image.asset(
//                                 ImagePath.appleLogo,
//                                 width: 26.w,
//                                 height: 26.h,
//                               ),
//                               SizedBox(width: 8.w),
//                               Text(
//                                 'Apple',
//                                 style: TextStyle(
//                                   fontSize: 16.sp,
//                                   fontWeight: FontWeight.w400,
//                                   color: const Color(0xFF111827),
//                                   fontFamily: 'Inter',
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     SizedBox(width: 12.w),
//
//                     // Google login button
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: () {
//                           // Handle Google login
//                         },
//                         child: Container(
//                           height: 54.h,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(13.r),
//                             border: Border.all(
//                               color: const Color(0xFFE1E1E1),
//                               width: 1,
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Image.asset(
//                                 ImagePath.googleLogo,
//                                 width: 26.w,
//                                 height: 26.h,
//                               ),
//                               SizedBox(width: 8.w),
//                               Text(
//                                 'Google',
//                                 style: TextStyle(
//                                   fontSize: 16.sp,
//                                   fontWeight: FontWeight.w400,
//                                   color: const Color(0xFF111827),
//                                   fontFamily: 'Inter',
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 SizedBox(height: 40.h),
//
//                 // "Forgot Password ?" link at bottom center
//                 Center(
//                   child: GestureDetector(
//                     onTap: () {
//                       // Handle forgot password
//                     },
//                     child: Text(
//                       'Forgot Password ?',
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w400,
//                         color: const Color(0xFF0088FE),
//                         fontFamily: 'Inter',
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: 90.h),
//
//                 // "Don't have an account? Register" text
//                 Center(
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         "Don't have an account? ",
//                         style: TextStyle(
//                           fontSize: 16.sp,
//                           fontWeight: FontWeight.w400,
//                           color: const Color(0xFF111827),
//                           fontFamily: 'Inter',
//                         ),
//                       ),
//                       GestureDetector(
//                         onTap: () {
//                           context.go(RegisterScreen.routeName);
//                         },
//                         child: Text(
//                           'Register',
//                           style: TextStyle(
//                             fontSize: 16.sp,
//                             fontWeight: FontWeight.w400,
//                             color: const Color(0xFF0088FE),
//                             fontFamily: 'Inter',
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 SizedBox(height: 40.h),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
