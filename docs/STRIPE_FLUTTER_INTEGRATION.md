# How to Connect Stripe in the Flutter App

This doc explains how to wire the **Stripe SDK** into the Renizo Flutter app so that:

- **Payment Methods screen:** Add card creates a Stripe PaymentMethod and saves it via `POST /payments/methods`.
- **Pay for booking:** Create PaymentIntent via your backend, then confirm with Stripe using `clientSecret` (new or saved card).

The backend **never** sees card numbers. The app uses Stripe’s **publishable key** and only sends `paymentMethodId` or `clientSecret` to your API. See also **PAYMENT_TESTING_FLOW_POSTMAN.md** (your payment flow doc) for the full API flow.

---

## 1. Add the Stripe Flutter package

Use the official Stripe Flutter SDK:

```yaml
# pubspec.yaml
dependencies:
  flutter_stripe: ^11.0.0   # or latest from pub.dev
```

Then run:

```bash
flutter pub get
```

- **Docs:** [Stripe Flutter SDK](https://pub.dev/packages/flutter_stripe)  
- **Stripe docs:** [Accept a payment - Flutter](https://stripe.com/docs/payments/accept-a-payment?platform=flutter)

---

## 2. Get the publishable key from your backend (do not hardcode)

Your backend exposes the Stripe publishable key so you can switch keys per environment.

| Step | What to do |
|------|------------|
| **API** | Call **GET** `{{base_url}}/payments/config` (no auth). |
| **Response** | Use `data.publishableKey`. |
| **In app** | Call this once at app startup (or when entering payment flow) and initialize Stripe with this key. |

Example (you can put this in a payment config service or app init):

```dart
// Example: fetch and init Stripe
Future<String?> getPublishableKey() async {
  final uri = Uri.parse('$api/payments/config');
  final res = await http.get(uri);
  final json = jsonDecode(res.body) as Map<String, dynamic>?;
  final data = json?['data'] as Map<String, dynamic>?;
  return data?['publishableKey'] as String?;
}

// In main() or before first payment screen:
void initStripe(String publishableKey) {
  Stripe.instance.applySettings(
    StripeSettings(publishableKey: publishableKey),
  );
}
```

Do **not** hardcode the publishable key; always load it from `GET /payments/config`.

---

## 3. Add card (Payment Methods screen) – create PaymentMethod and save

Flow from **PAYMENT_TESTING_FLOW_POSTMAN.md** Step 10:

1. User enters card number, expiry, CVC in your **Add Card** UI.
2. In Flutter, use the **Stripe SDK** to create a **PaymentMethod** with that card (using the publishable key). The SDK returns a **PaymentMethod id** (`pm_xxx`).
3. Send **only** that id to your backend: **POST** `{{base_url}}/payments/methods` with body `{ "paymentMethodId": "pm_xxx" }` and **customer** `Authorization: Bearer <accessToken>`.

The app already has:

- **POST** `/payments/methods` and `addPaymentMethod(paymentMethodId)` in `lib/features/profile/logic/payment_methods_logic.dart`.
- **AddCardScreen** with `getPaymentMethodId: () async => null`. When this returns a non-null id, the screen calls `addPaymentMethod(id)` and then `onSaved`.

So you only need to **create the PaymentMethod with Stripe** and pass its id into that flow.

### 3.1 Create PaymentMethod with Stripe (card details)

Stripe Flutter uses **payment sheet** or **card field**. For a custom form (card number, expiry, CVC), you create a PaymentMethod from card params. Example pattern:

```dart
import 'package:flutter_stripe/flutter_stripe.dart';

Future<String?> createPaymentMethodFromCard({
  required String number,
  required int expMonth,
  required int expYear,
  required String cvc,
}) async {
  final params = PaymentMethodParams.card(
    paymentMethodData: PaymentMethodData(
      billingDetails: BillingDetails(),
    ),
  );
  // For card collection, Stripe often uses CardField or PaymentSheet.
  // If you use CardField widget, Stripe collects the card and you create
  // the PaymentMethod from the CardFieldInputDetails.
  // See: https://stripe.com/docs/payments/accept-a-payment?platform=flutter
  final paymentMethod = await Stripe.instance.createPaymentMethod(
    params,
  );
  return paymentMethod.id; // "pm_xxx"
}
```

**Important:** The exact API depends on the `flutter_stripe` version. Newer versions use **CardField** or **PaymentSheet**; the SDK docs show how to get a `PaymentMethod` (or `PaymentMethodId`) from the collected card. Use that id as `paymentMethodId`.

### 3.2 Connect to your Add Card screen

In the place where you open **AddCardScreen** (e.g. `PaymentMethodsScreen`), pass a `getPaymentMethodId` that creates the PaymentMethod with Stripe and returns its id:

```dart
getPaymentMethodId: () async {
  // 1. Collect card from your form or Stripe CardField.
  // 2. Create PaymentMethod (see 3.1).
  final id = await createPaymentMethodFromCard(
    number: cardNumber,
    expMonth: int.parse(expiryMonth),
    expYear: 2000 + int.parse(expiryYear), // or full year
    cvc: cvv,
  );
  return id; // "pm_xxx" or null on error
},
```

When `getPaymentMethodId()` returns a non-null id, **AddCardScreen** already calls `addPaymentMethod(paymentMethodId)` and `onSaved`, so the new card appears in the list from **GET** `/payments/methods`.

---

## 4. Pay for a booking (PaymentIntent + confirm)

Flow from **PAYMENT_TESTING_FLOW_POSTMAN.md** Step 9b and “App flow summary”:

1. **Backend:** Customer calls **POST** `{{base_url}}/payments/intent` with:
   - `{ "bookingId": "<bookingId>" }`
   - Optionally `"paymentMethodId": "pm_xxx"` when paying with a saved card.
2. **Response:** Use `data.clientSecret` (and optionally `data.paymentIntentId`).
3. **Stripe SDK:** In Flutter, confirm the payment with that `clientSecret` and either:
   - The card just entered (new card), or  
   - The saved `paymentMethodId`.
4. **After success:** Backend receives Stripe’s webhook and marks the booking paid. Your app can then show “Booking confirmed” or poll the booking.

Example pattern:

```dart
// 1. Get clientSecret from your backend
final response = await http.post(
  Uri.parse('$api/payments/intent'),
  headers: {
    'Authorization': 'Bearer $customerToken',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'bookingId': bookingId,
    // optional: 'paymentMethodId': savedPmId,
  }),
);
final data = (jsonDecode(response.body) as Map)['data'] as Map?;
final clientSecret = data?['clientSecret'] as String?;

// 2. Confirm with Stripe (new card or saved)
await Stripe.instance.confirmPayment(
  paymentIntentClientSecret: clientSecret!,
  // If using saved card, pass paymentMethodId; otherwise Stripe may show sheet.
);
```

Exact method names may vary by `flutter_stripe` version; check the package’s **confirm payment** example.

---

## 5. Summary table (from PAYMENT_TESTING_FLOW_POSTMAN.md)

| What you want | API | Stripe in Flutter |
|---------------|-----|-------------------|
| Init / payment screen | GET `/payments/config` | Use `data.publishableKey` for `Stripe.instance.applySettings(...)`. |
| Add card (saved method) | POST `/payments/methods` with `paymentMethodId` | Create PaymentMethod from card (CardField/PaymentSheet), get `pm_xxx`, send to backend. |
| Pay with new card | POST `/payments/intent` → get `clientSecret` | `Stripe.instance.confirmPayment(clientSecret)` with card. |
| Pay with saved card | POST `/payments/intent` with `paymentMethodId` | Confirm with same `clientSecret` and that `paymentMethodId`. |
| List / set default / delete card | GET/PATCH/DELETE `/payments/methods` | No Stripe calls; already implemented in your app. |

---

## 6. Security rules (from the doc)

- **Never** send raw card number or CVC to your backend.
- **Always** use the Stripe SDK with the **publishable** key to create PaymentMethods or confirm PaymentIntents.
- Send only **paymentMethodId** (`pm_xxx`) or use **clientSecret** from your backend for confirmation.
- Use **customer** `accessToken` for all customer payment and payment-methods APIs.

---

## 7. Official references

- **Stripe Flutter:** [pub.dev/packages/flutter_stripe](https://pub.dev/packages/flutter_stripe)  
- **Accept a payment (Flutter):** [stripe.com/docs/payments/accept-a-payment?platform=flutter](https://stripe.com/docs/payments/accept-a-payment?platform=flutter)  
- **PaymentMethod API:** [stripe.com/docs/api/payment_methods](https://stripe.com/docs/api/payment_methods)  
- **Your API flow:** PAYMENT_TESTING_FLOW_POSTMAN.md (base URL, auth, and all endpoints).

Use this doc together with **PAYMENT_TESTING_FLOW_POSTMAN.md** to connect Stripe end-to-end in the app.
