# Payment flow – why it showed an error and how it works now

## What you see now

When you tap **Pay** on the payment screen, you see **“Payment successful”** and the screen closes. This doc explains why it used to show an error and how the current flow works.

---

## 1. What happens when you tap Pay

1. The app calls your backend: **`POST /api/v1/payments/intent`** with the `bookingId`.
2. The backend talks to Stripe, creates (and sometimes confirms) a PaymentIntent, and returns JSON like:

   ```json
   {
     "status": "success",
     "data": {
       "bookingId": "69916d8aa6363af8875dfa4d",
       "paymentIntentId": "pi_3T0zGSRpcSuxTvWY02zF8Txm",
       "clientSecret": "pi_3T0zGSRpcSuxTvWY02zF8Txm_secret_...",
       "status": "succeeded"
     }
   }
   ```

3. The app reads `data.clientSecret` and `data.status`.
4. **If `data.status` is `"succeeded"`** → the app treats payment as already done, shows “Payment successful” and closes the screen.
5. **If not** → the app opens the Stripe payment sheet with `clientSecret`, user pays there, then the app shows “Payment successful” and closes.

---

## 2. Why it was showing an error before

- Your backend sometimes returns **`data.status: "succeeded"`**. That means the **PaymentIntent is already confirmed** on the server (Stripe considers that payment done).
- The app was **always** doing:
  - take `clientSecret` from the response
  - call Stripe’s **present payment sheet** with that `clientSecret`
- For an intent that is already **succeeded**, Stripe does not allow showing the sheet again. The Stripe SDK then returns an error (e.g. “This PaymentIntent has already been succeeded”).
- That error was shown as the **“unexpected error”** message on the payment screen.

So: the API said “success”, but the app tried to collect payment again → Stripe error → user saw the error.

---

## 3. How we fixed it (why it shows “Payment successful” now)

We changed the app so it **checks the API response** before opening the Stripe sheet.

### In the app

1. **`lib/features/bookings/logic/payment_logic.dart`**
   - The API response is parsed and we read:
     - `data.clientSecret`
     - `data.status`
   - We return a small result object that includes:
     - `clientSecret`
     - `alreadySucceeded`: `true` when `data.status == "succeeded"`.

2. **`lib/features/bookings/screens/payment_screen.dart`**
   - After getting this result:
     - **If `alreadySucceeded` is true**  
       → We **do not** call Stripe’s payment sheet. We show “Payment successful” and pop the screen.
     - **If `alreadySucceeded` is false**  
       → We call Stripe’s `initPaymentSheet` and `presentPaymentSheet` with `clientSecret`, then on success show “Payment successful” and pop.

So when the backend returns `status: "success"` and `data.status: "succeeded"`, the app no longer tries to present the sheet and no longer hits the Stripe error. It just shows success. That’s why you now see **“Payment successful”** instead of the error.

---

## 4. Flow summary

| Backend returns              | App behavior                                                |
|-----------------------------|-------------------------------------------------------------|
| `data.status: "succeeded"`   | Skip Stripe sheet → show “Payment successful” → close      |
| `data.status` anything else | Open Stripe sheet with `clientSecret` → on success → show “Payment successful” → close |

---

## 5. Backend note (for your API)

If you want the **user to always see the Stripe payment sheet** (card form, etc.), the backend should:

- Create the PaymentIntent.
- **Not** confirm it on the server.
- Return `clientSecret` with `data.status` something like `"requires_payment_method"` or `"requires_confirmation"` (not `"succeeded"`).

Then the app will always open the sheet and Stripe will confirm the payment when the user completes it.

If the backend **intentionally** confirms the payment (e.g. zero amount or saved card) and returns `data.status: "succeeded"`, the current app behavior is correct: it shows “Payment successful” without opening the sheet.

---

## 6. Files involved

- **`lib/features/bookings/logic/payment_logic.dart`**  
  - Calls `POST /payments/intent`, parses response, returns `PaymentIntentResult` with `clientSecret` and `alreadySucceeded`.

- **`lib/features/bookings/screens/payment_screen.dart`**  
  - Calls `createPaymentIntent()`, then either shows success (when `alreadySucceeded`) or opens Stripe sheet and then shows success.

- **`lib/core/constants/api_control/user_api.dart`**  
  - `UserApi.paymentIntent` = payment intent URL.

- **`lib/core/constants/api_control/global_api.dart`**  
  - Base API URL used for the request.

This is the full picture of **why** it showed an error before and **how** it now shows “Payment successful” and when each path is used.
