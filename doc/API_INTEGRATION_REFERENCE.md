# API Integration Reference

This document summarizes the API integration approach from your previous project (**cavaleca-900**) so you can implement new APIs in **stev_california--900** with the same structure and consistency.

---

## 1. Folder structure (align with cavaleca-900)

### API constants (endpoints only)

- **Location:** `lib/core/constants/api_control/`
- **Files:**
  - `global_api.dart` – base URL only (e.g. `String api = "http://..."`)
  - `auth_api.dart` – auth endpoints (login, signup, profile, logout, etc.)
  - `*_api.dart` – one file per domain (e.g. `customer_api.dart`, `notificiaon_api.dart`)

**Pattern:** Each `*_api.dart` imports `global_api.dart`, defines a class like `AuthAPIController`, uses `static final String _base_api = "$api/..."` and static getters/methods for URLs (including dynamic parts like `singleUser(id)` or `readNotifications(id)`).

### Services / API call layer

- **Location:** `lib/core/services/` for app-wide services (e.g. `auth_service.dart`)
- **Feature-specific:** `lib/features/<feature>/data/` or `lib/features/<feature>/logic/` for repositories or API classes (e.g. `internal_job_logic.dart`, `notificaion_data.dart`)

### Auth & token storage

- **Location:** `lib/core/utils/auth_local_storage.dart` (current project uses this; cavaleca used `global_save_login_data.dart` with `getToken()`, `saveLoginData()`, `clearLoginData()`)
- Your current project already has `AuthLocalStorage` with `getToken()`, `saveSession()`, `clearSession()` – keep this naming.

---

## 2. Endpoint constants pattern (from cavaleca-900)

**global_api.dart** – single source for base URL:

```dart
String api = "http://103.208.183.253:5000/api/v1";  // or your real base
```

**auth_api.dart** (and similar):

```dart
import 'global_api.dart';

class AuthAPIController {
  static final String _base_api = "$api/users";   // or "$api/api" etc.
  static String userLogin = "$_base_api/login";
  static String userSignUp = "$_base_api/signup";
  static String singleUser(String id) => "$_base_api/$id";
  static String profile = "$_base_api/profile";  // if you have it
}
```

- Use **static strings** for fixed paths and **static methods** for paths with parameters (e.g. `singleUser(id)`).

---

## 3. HTTP client and headers

- **Package:** `http` (package `http`), no Dio in the previous project.
- **Public (no auth):**  
  `Content-Type: application/json`, `Accept: application/json`
- **Authenticated:**  
  Same + `Authorization: Bearer <token>`  
  Token from: `await AuthLocalStorage.getToken()` (current project) or `AuthLocalStorage.getToken()` (cavaleca).

**Pattern for authenticated calls:**

```dart
import 'package:renizo/core/utils/auth_local_storage.dart';

static Future<String> _getToken() async {
  final token = await AuthLocalStorage.getToken();
  if (token == null) throw Exception('No auth token found');
  return token;
}

// In each request:
final token = await _getToken();
final res = await http.get(
  Uri.parse(AuthAPIController.someEndpoint),
  headers: {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  },
);
```

For POST/PATCH with body:

```dart
headers: {
  'Accept': 'application/json',
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',
},
body: jsonEncode({ ... }),
```

---

## 4. Response handling

- Parse with `jsonDecode(response.body)`.
- Check `response.statusCode` (e.g. 200) and throw on failure:  
  `throw Exception(errorBody['message'] ?? 'Request failed');`
- Use **typed model classes** with `fromJson` (e.g. `SignupResponse`, `UserData`, `Tokens` in your current `auth_service.dart`) and keep DTOs in the same file or in `lib/core/models/` / feature `model/` folders.

---

## 5. Where to put API call code

| Approach | Location | Example (cavaleca) |
|----------|----------|--------------------|
| **Static service class** | `lib/core/services/auth_service.dart` | `AuthService.signup(...)` (current project) |
| **Repository class** | `lib/features/<feature>/data/*_data.dart` or `logic/*.dart` | `InternalProfileRepository`, `NotificationsRepository` |
| **API class (static)** | `lib/features/<feature>/.../logic/*_api.dart` or `*_logic.dart` | `TechnicianJobsApi`, `TechnicianEarningsApi`, `CommissionApi` |

- **Auth (login/signup):** Keep in `core/services/auth_service.dart` and use endpoint constants from `api_control/auth_api.dart`.
- **Feature-specific (bookings, notifications, profile):** Use either a **Repository** (injectable, testable) or a **static Api class** in that feature’s `data/` or `logic/`, and use the corresponding `*_api.dart` controller for URLs.

---

## 6. Current project (stev_california--900) – what you already have

- **global_api.dart** – base URL.
- **auth_api.dart** – endpoints: `allUsers`, `singleUser(id)`, `userLogin`, `userSignUp`.
- **auth_service.dart** – signup only: `AuthService.signup(...)` with `SignupResponse` / `SignupData` / `UserData` / `Tokens`; uses `$api/auth/signup` (note: auth_api uses `$api/users`; confirm with backend which base path to use).
- **Auth local storage** – `AuthLocalStorage.saveSession()`, `getToken()`, `clearSession()`, etc.
- **Auth provider** – `auth_provider.dart` (signup) using `AuthService` and `AuthLocalStorage`.

**Gap:** Login is not yet implemented in the API layer; the login screen does not call an API. Add `AuthService.login(...)` (or equivalent) using `AuthAPIController.userLogin` and the same token/session saving pattern as signup.

---

## 7. Checklist for adding a new API (e.g. login, bookings, notifications)

1. **Endpoints**  
   Add URLs in `lib/core/constants/api_control/` – either in `auth_api.dart` or a new `*_api.dart` (e.g. `bookings_api.dart`) following the `AuthAPIController` pattern.

2. **Models**  
   Add request/response DTOs with `fromJson` (and `toJson` if you send body). Place in `core/models/` or in the feature’s `model/` folder.

3. **Service / Repository / Api class**  
   - For auth: extend `lib/core/services/auth_service.dart` (e.g. add `login`).
   - For other features: add a class in `lib/features/<feature>/data/` or `logic/` that uses the corresponding `*_api.dart` and `AuthLocalStorage.getToken()` for authenticated calls.

4. **Headers**  
   Use `Content-Type` and `Accept: application/json`; add `Authorization: Bearer $token` for protected routes.

5. **Errors**  
   On non-2xx, parse body and throw `Exception(message)` (or a custom app exception if you introduce one later).

6. **Provider (if needed)**  
   Wire the new service/repository in a Riverpod provider (e.g. `StateNotifierProvider` or `FutureProvider`) and use it from the screen, same as `auth_provider` and signup.

---

## 8. Naming and style (from previous project)

- **API controller classes:** `AuthAPIController`, `CustomerAPIController`, `NotificiaonAPIController`.
- **Repository:** `InternalProfileRepository`, `NotificationsRepository` – used with Riverpod `Provider`.
- **Static API classes:** `TechnicianJobsApi`, `TechnicianEarningsApi`, `CommissionApi` – static methods, optional `_getToken()` helper.
- **Token:** Always `Bearer $token` in `Authorization` header; token from `AuthLocalStorage.getToken()`.

Using this structure will keep **stev_california--900** consistent with your previous project and ready for new APIs.
