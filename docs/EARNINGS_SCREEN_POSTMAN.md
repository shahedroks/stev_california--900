# Earnings Screen – Postman Testing Guide

This document describes how to test the **Earnings screen** APIs in Postman. All endpoints require a **provider** (service provider) account and use the same base URL and auth.

---

## Prerequisites

1. **Base URL**  
   Use your server base URL, e.g.:
   - Local: `http://localhost:5000`
   - Production: `https://your-api-domain.com`

2. **Provider token**  
   Log in as a **provider** user and use the returned JWT:
   - **POST** `{{base_url}}/api/v1/auth/login`  
   - Body (JSON): `{ "email": "provider@example.com", "password": "yourpassword" }`  
   - From the response, copy `data.token` (or `token`).

3. **Headers for all requests below**  
   - `Content-Type: application/json`  
   - `Authorization: Bearer <provider_token>`

---

## 1. Get combined earnings (Earnings screen)

Returns summary, performance metrics, and recent transactions in one call.

| Field | Value |
|-------|--------|
| **Method** | GET |
| **URL** | `{{base_url}}/api/v1/providers/me/earnings` |

**Query parameters (optional)**

| Param | Type | Default | Description |
|-------|------|---------|--------------|
| `transactionsLimit` | number | 10 | Max number of recent transactions in the combined response. |
| `page` | number | 1 | Page for transactions (used when fetching transactions). |
| `limit` | number | 20 | Limit per page for transactions. |

**Example request**

```
GET {{base_url}}/api/v1/providers/me/earnings?transactionsLimit=5
Authorization: Bearer <provider_token>
```

**Example response (200 OK)**

```json
{
  "status": "success",
  "data": {
    "summary": {
      "today": "0.00",
      "thisWeek": "45.50",
      "thisMonth": "128.00",
      "allTime": "128.00",
      "currency": "USD"
    },
    "performance": {
      "totalJobsCompleted": 2,
      "averageRating": 4.5,
      "ratingCount": 2,
      "averageResponseTime": "12.5 min",
      "jobSuccessRate": 100
    },
    "recentTransactions": [
      {
        "_id": "674a1b2c3d4e5f6789012345",
        "bookingId": "674a1b2c3d4e5f6789012345",
        "customerName": "John Doe",
        "serviceName": "Lawn Mowing",
        "completedAt": "2026-02-14T15:30:00.000Z",
        "amountEarnedCents": 1350,
        "amountEarned": "13.50",
        "totalAmountCents": 1500,
        "totalAmount": "15.00",
        "currency": "USD",
        "status": "completed"
      }
    ],
    "transactionsMeta": {
      "total": 2,
      "page": 1,
      "limit": 10
    }
  }
}
```

---

## 2. Get earnings summary only

Net earnings for today, this week, this month, and all time (completed + paid bookings only).

| Field | Value |
|-------|--------|
| **Method** | GET |
| **URL** | `{{base_url}}/api/v1/providers/me/earnings/summary` |

**Request body**  
None.

**Example request**

```
GET {{base_url}}/api/v1/providers/me/earnings/summary
Authorization: Bearer <provider_token>
```

**Example response (200 OK)**

```json
{
  "status": "success",
  "data": {
    "today": "0.00",
    "thisWeek": "45.50",
    "thisMonth": "128.00",
    "allTime": "128.00",
    "currency": "USD"
  }
}
```

---

## 3. Get earnings performance only

Metrics: total jobs completed, average rating, response time, job success rate.

| Field | Value |
|-------|--------|
| **Method** | GET |
| **URL** | `{{base_url}}/api/v1/providers/me/earnings/performance` |

**Request body**  
None.

**Example request**

```
GET {{base_url}}/api/v1/providers/me/earnings/performance
Authorization: Bearer <provider_token>
```

**Example response (200 OK)**

```json
{
  "status": "success",
  "data": {
    "totalJobsCompleted": 2,
    "averageRating": 4.5,
    "ratingCount": 2,
    "averageResponseTime": "12.5 min",
    "jobSuccessRate": 100
  }
}
```

**Notes**

- `averageResponseTime`: time from booking creation to provider acceptance (e.g. `"12.5 min"`, `"1.2 hrs"`, or `"—"` if none).
- `jobSuccessRate`: percentage of accepted/completed/cancelled/rejected jobs that are completed.

---

## 4. Get earnings transactions (paginated)

List of completed, paid jobs with earnings. Supports pagination.

| Field | Value |
|-------|--------|
| **Method** | GET |
| **URL** | `{{base_url}}/api/v1/providers/me/earnings/transactions` |

**Query parameters**

| Param | Type | Default | Description |
|-------|------|---------|--------------|
| `page` | number | 1 | Page number. |
| `limit` | number | 20 | Items per page (max 50). |

**Example request**

```
GET {{base_url}}/api/v1/providers/me/earnings/transactions?page=1&limit=10
Authorization: Bearer <provider_token>
```

**Example response (200 OK)**

```json
{
  "status": "success",
  "data": {
    "items": [
      {
        "_id": "674a1b2c3d4e5f6789012345",
        "bookingId": "674a1b2c3d4e5f6789012345",
        "customerName": "John Doe",
        "serviceName": "Lawn Mowing",
        "completedAt": "2026-02-14T15:30:00.000Z",
        "amountEarnedCents": 1350,
        "amountEarned": "13.50",
        "totalAmountCents": 1500,
        "totalAmount": "15.00",
        "currency": "USD",
        "status": "completed"
      },
      {
        "_id": "674a1b2c3d4e5f6789012346",
        "bookingId": "674a1b2c3d4e5f6789012346",
        "customerName": "Jane Smith",
        "serviceName": "Garden Weeding",
        "completedAt": "2026-02-13T10:00:00.000Z",
        "amountEarnedCents": 3200,
        "amountEarned": "32.00",
        "totalAmountCents": 3500,
        "totalAmount": "35.00",
        "currency": "USD",
        "status": "completed"
      }
    ],
    "meta": {
      "total": 2,
      "page": 1,
      "limit": 10
    }
  }
}
```

---

## 5. Set payout account (Stripe Connect)

Link the provider’s Stripe Connect account so they can receive payouts. Required for payments to be sent to the provider.

| Field | Value |
|-------|--------|
| **Method** | PATCH |
| **URL** | `{{base_url}}/api/v1/providers/me/payout` |

**Request body (JSON)**

| Field | Type | Required | Description |
|-------|------|----------|--------------|
| `accountId` | string | Yes | Stripe Connect account ID (e.g. `acct_1ABC...`). Use empty string to clear. |

**Example request**

```
PATCH {{base_url}}/api/v1/providers/me/payout
Authorization: Bearer <provider_token>
Content-Type: application/json

{
  "accountId": "acct_1ABC2defGHI3jkl"
}
```

**Example response (200 OK)**

```json
{
  "status": "success",
  "data": {
    "_id": "674a0f1e2d3c4b5a67890123",
    "userId": "674a0f1e2d3c4b5a67890122",
    "payout": {
      "processor": "stripe",
      "accountId": "acct_1ABC2defGHI3jkl"
    }
  }
}
```

**Clear payout account (body)**

```json
{
  "accountId": ""
}
```

---

## Quick reference

| Purpose | Method | Endpoint |
|--------|--------|----------|
| Full earnings screen data | GET | `/api/v1/providers/me/earnings` |
| Summary (today/week/month/all) | GET | `/api/v1/providers/me/earnings/summary` |
| Performance metrics | GET | `/api/v1/providers/me/earnings/performance` |
| Transactions (paginated) | GET | `/api/v1/providers/me/earnings/transactions` |
| Set Stripe payout account | PATCH | `/api/v1/providers/me/payout` |

**Auth:** All requests require `Authorization: Bearer <provider_jwt>`.

**Empty state:** With no completed + paid bookings, summary amounts are `"0.00"`, performance counts are `0`, and transactions `items` are `[]`.
