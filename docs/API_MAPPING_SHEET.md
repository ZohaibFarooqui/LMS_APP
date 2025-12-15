# LMS API Mapping Sheet

## Base URL
`http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/`

---

## Authentication APIs

### Sign In Screen

| Field | Value |
|-------|-------|
| **Screen Name** | Sign in Screen |
| **URL** | `http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/login/{phoneNumber}` |
| **Method** | POST |
| **Endpoint** | `/login` |

**Request JSON:**
```json
{
  "phoneNumber": "Number(10)",
  "passcode": "string"
}
```

**Response JSON:**
```json
{
  "header": {
    "code": 100,
    "status": "success",
    "message": ""
  },
  "body": {
    "token": "string",
    "refreshToken": "string",
    "expiresIn": 86400,
    "phone_number": "string"
  }
}
```

**Remarks:** Authentication endpoint for user login with phone number and passcode.

---

## Dashboard APIs

### Dashboard Data

| Field | Value |
|-------|-------|
| **Screen Name** | Dashboard |
| **URL** | `http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/data/{phoneNumber}` |
| **Method** | GET |
| **Endpoint** | `/data/{phoneNumber}` |

**Request JSON:**
```json
{
  "token": "string",
  "refreshToken": "string",
  "phoneNumber": "number(10)"
}
```

**Response JSON:**
```json
{
  "header": {
    "code": 100,
    "status": "success",
    "message": ""
  },
  "body": {
    "emp_pk": 106,
    "card_no1": "10000106.1.2",
    "emp_no": "F-84",
    "emp_name": "FURQAN HASAN",
    "date_of_join": "2019-11-21T19:00:00Z",
    "nic_no": "42201-1129652-9",
    "designation": "DY. GENERAL MANAGER",
    "department": "IT",
    "compcnm": "KARACHI",
    "brnchnm": "Head Office",
    "hod": 3008228498,
    "hod_nm": "ALTAF HUSSAIN"
  }
}
```

**Remarks:** Fetches employee dashboard data including personal info, department, and HOD details.

---

## Attendance APIs

### Mark Biometric Attendance

| Field | Value |
|-------|-------|
| **Screen Name** | Biometric Attendance Screen |
| **URL** | `http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/attendance/biometric` |
| **Method** | POST |
| **Endpoint** | `/attendance/biometric` |

**Request JSON:**
```json
{
  "employee_id": "string",
  "attendance_type": "check_in | check_out",
  "biometric_type": "fingerprint | face",
  "location": {
    "latitude": "number (decimal)",
    "longitude": "number (decimal)",
    "accuracy": "number (meters)",
    "timestamp": "ISO8601 datetime string",
    "address": "string (optional)",
    "street_address": "string (optional)",
    "locality": "string (city/town)",
    "sub_locality": "string (neighborhood)",
    "postal_code": "string (optional)",
    "country": "string",
    "nearest_landmark": "string (nearby notable place)",
    "famous_place": "string (well-known location nearby)",
    "distance_to_landmark": "number (meters)",
    "formatted_address": "string (full human-readable address)"
  },
  "timestamp": "ISO8601 datetime string",
  "device_id": "string (optional)",
  "device_model": "string (optional)",
  "app_version": "string (optional)"
}
```

**Response JSON (Success):**
```json
{
  "header": {
    "code": 100,
    "status": "success",
    "message": "Attendance marked successfully"
  },
  "body": {
    "attendance_id": "ATT-1702056789123",
    "marked_at": "2024-12-08T09:30:00Z",
    "location_verified": true,
    "biometric_verified": true
  }
}
```

**Response JSON (Error):**
```json
{
  "header": {
    "code": 400,
    "status": "error",
    "message": "Biometric verification failed",
    "error_code": "BIO_VERIFY_FAILED"
  },
  "body": null
}
```

**Remarks:** 
- Marks attendance using biometric (fingerprint or face) authentication
- Sends complete location data including coordinates, address, and nearest landmarks
- Location data is used for geofence verification and audit trail
- Device info helps in identifying the source device for security purposes

---

### Get Attendance Report

| Field | Value |
|-------|-------|
| **Screen Name** | Attendance History Screen |
| **URL** | `http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/attendance/report` |
| **Method** | GET |
| **Endpoint** | `/attendance/report` |

**Request JSON (Query Parameters):**
```json
{
  "token": "string",
  "from_date": "YYYY-MM-DD",
  "to_date": "YYYY-MM-DD",
  "employee_id": "string"
}
```

**Response JSON:**
```json
{
  "header": {
    "code": 100,
    "status": "success",
    "message": ""
  },
  "body": {
    "records": [
      {
        "date": "2024-12-08",
        "shift": "General",
        "day": 1,
        "time_in": "09:00:00",
        "time_out": "18:00:00",
        "work_hours": "09:00",
        "late_arrival": "00:00",
        "approved_hours": "00:00",
        "remarks": "",
        "is_absent": false,
        "check_in_location": {
          "latitude": 24.8585,
          "longitude": 67.0500,
          "address": "Office Building, Karachi",
          "landmark": "Near Dolmen Mall"
        },
        "check_out_location": {
          "latitude": 24.8585,
          "longitude": 67.0500,
          "address": "Office Building, Karachi",
          "landmark": "Near Dolmen Mall"
        }
      }
    ]
  }
}
```

**Remarks:** Fetches attendance records for a date range with location details for each check-in/check-out.

---

### Get Attendance Summary

| Field | Value |
|-------|-------|
| **Screen Name** | Attendance Summary Section |
| **URL** | `http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/attendance/summary` |
| **Method** | GET |
| **Endpoint** | `/attendance/summary` |

**Request JSON (Query Parameters):**
```json
{
  "token": "string",
  "from_date": "YYYY-MM-DD",
  "to_date": "YYYY-MM-DD",
  "employee_id": "string"
}
```

**Response JSON:**
```json
{
  "header": {
    "code": 100,
    "status": "success",
    "message": ""
  },
  "body": {
    "casual_leave": 2,
    "earned_leave": 10,
    "medical_leave": 5,
    "compensatory_leave": 0,
    "sick_leave": 3,
    "loss_of_pay": 0,
    "absent": 1,
    "outdoor_duty": 2,
    "approved_extra_work": 5,
    "late_count": 3,
    "total_working_days": 22,
    "present_days": 19
  }
}
```

**Remarks:** Provides summary statistics for attendance including various leave types and late counts.

---

### GeoFence Check-in (Automatic)

| Field | Value |
|-------|-------|
| **Screen Name** | GeoFence Service (Background) |
| **URL** | `http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/attendance/check-in` |
| **Method** | POST |
| **Endpoint** | `/attendance/check-in` |

**Request JSON:**
```json
{
  "automatic": true,
  "employee_id": "string",
  "location": {
    "latitude": "number",
    "longitude": "number",
    "accuracy": "number",
    "timestamp": "ISO8601 datetime string"
  },
  "geofence_status": {
    "is_inside": true,
    "distance_meters": "number",
    "location_quality": "high | good | poor",
    "consecutive_readings": "number"
  },
  "note": "string (optional)"
}
```

**Response JSON:**
```json
{
  "header": {
    "code": 100,
    "status": "success",
    "message": "Automatic check-in successful"
  },
  "body": {
    "attendance_id": "ATT-1702056789123",
    "marked_at": "2024-12-08T09:00:00Z"
  }
}
```

**Remarks:** Automatic attendance marking when user enters the geofenced office area.

---

## Leave APIs

### Get Leave Balances

| Field | Value |
|-------|-------|
| **Screen Name** | Leave Balance Screen |
| **URL** | `http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/leave/balances` |
| **Method** | GET |
| **Endpoint** | `/leave/balances` |

**Request JSON (Query Parameters):**
```json
{
  "token": "string",
  "employee_id": "string"
}
```

**Response JSON:**
```json
{
  "header": {
    "code": 100,
    "status": "success",
    "message": ""
  },
  "body": {
    "balances": [
      {
        "leave_type": "Casual Leave",
        "code": "CL",
        "total": 12,
        "used": 2,
        "available": 10
      },
      {
        "leave_type": "Earned Leave",
        "code": "EL",
        "total": 21,
        "used": 5,
        "available": 16
      },
      {
        "leave_type": "Medical Leave",
        "code": "ML",
        "total": 10,
        "used": 0,
        "available": 10
      }
    ]
  }
}
```

**Remarks:** Fetches all leave type balances for the employee.

---

### Get Leave Requests

| Field | Value |
|-------|-------|
| **Screen Name** | Leave History Screen |
| **URL** | `http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/leave/applications` |
| **Method** | GET |
| **Endpoint** | `/leave/applications` |

**Request JSON (Query Parameters):**
```json
{
  "token": "string",
  "employee_id": "string",
  "status": "all | pending | approved | rejected (optional)"
}
```

**Response JSON:**
```json
{
  "header": {
    "code": 100,
    "status": "success",
    "message": ""
  },
  "body": {
    "requests": [
      {
        "id": "LEV-001",
        "type": "Casual Leave",
        "from_date": "2024-12-10",
        "to_date": "2024-12-11",
        "days": 2,
        "half_day": false,
        "reason": "Personal work",
        "status": "pending",
        "applied_on": "2024-12-08T10:00:00Z",
        "approved_by": null,
        "approved_on": null,
        "remarks": null
      }
    ]
  }
}
```

**Remarks:** Fetches all leave applications with their status.

---

### Submit Leave Request

| Field | Value |
|-------|-------|
| **Screen Name** | Apply Leave Screen |
| **URL** | `http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/leave/applications` |
| **Method** | POST |
| **Endpoint** | `/leave/applications` |

**Request JSON:**
```json
{
  "token": "string",
  "type": "CL | EL | ML | SL | CP | LWP",
  "from_date": "YYYY-MM-DD",
  "to_date": "YYYY-MM-DD",
  "half_day": false,
  "half_day_type": "first_half | second_half (if half_day is true)",
  "reason": "string"
}
```

**Response JSON:**
```json
{
  "header": {
    "code": 100,
    "status": "success",
    "message": "Leave request submitted successfully"
  },
  "body": {
    "request_id": "LEV-002",
    "status": "pending"
  }
}
```

**Remarks:** Submits a new leave application for approval.

---

## Profile APIs

### Get Employee Profile

| Field | Value |
|-------|-------|
| **Screen Name** | Profile Screen |
| **URL** | `http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/employee/profile` |
| **Method** | GET |
| **Endpoint** | `/employee/profile` |

**Request JSON (Query Parameters):**
```json
{
  "token": "string",
  "employee_id": "string"
}
```

**Response JSON:**
```json
{
  "header": {
    "code": 100,
    "status": "success",
    "message": ""
  },
  "body": {
    "emp_pk": 106,
    "emp_no": "F-84",
    "emp_name": "FURQAN HASAN",
    "email": "furqan.hasan@company.com",
    "phone": "3458000041",
    "nic_no": "42201-1129652-9",
    "date_of_birth": "1990-05-15",
    "date_of_join": "2019-11-21",
    "designation": "DY. GENERAL MANAGER",
    "department": "IT",
    "branch": "Head Office",
    "company": "KARACHI",
    "reporting_to": {
      "emp_pk": 105,
      "emp_name": "ALTAF HUSSAIN",
      "designation": "GENERAL MANAGER",
      "phone": "3008228498"
    },
    "emergency_contact": {
      "name": "Contact Name",
      "relation": "Spouse",
      "phone": "0300XXXXXXX"
    }
  }
}
```

**Remarks:** Fetches complete employee profile information.

---

## Notification APIs

### Get Notifications

| Field | Value |
|-------|-------|
| **Screen Name** | Notifications Drawer |
| **URL** | `http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/notifications` |
| **Method** | GET |
| **Endpoint** | `/notifications` |

**Request JSON (Query Parameters):**
```json
{
  "token": "string",
  "employee_id": "string",
  "page": 1,
  "limit": 20
}
```

**Response JSON:**
```json
{
  "header": {
    "code": 100,
    "status": "success",
    "message": ""
  },
  "body": {
    "notifications": [
      {
        "id": "NOT-001",
        "title": "Leave Approved",
        "message": "Your casual leave request for Dec 10-11 has been approved",
        "type": "leave_approval",
        "is_read": false,
        "created_at": "2024-12-08T14:30:00Z",
        "action_url": "/leave/details/LEV-001"
      }
    ],
    "unread_count": 5,
    "total_count": 25
  }
}
```

**Remarks:** Fetches paginated notifications for the user.

---

### Mark Notification Read

| Field | Value |
|-------|-------|
| **Screen Name** | Notifications Drawer |
| **URL** | `http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/notifications/{id}/read` |
| **Method** | PUT |
| **Endpoint** | `/notifications/{id}/read` |

**Request JSON:**
```json
{
  "token": "string"
}
```

**Response JSON:**
```json
{
  "header": {
    "code": 100,
    "status": "success",
    "message": "Notification marked as read"
  }
}
```

**Remarks:** Marks a specific notification as read.

---

## Error Codes

| Code | Status | Description |
|------|--------|-------------|
| 100 | success | Request processed successfully |
| 400 | error | Bad request - Invalid parameters |
| 401 | error | Unauthorized - Invalid or expired token |
| 403 | error | Forbidden - Access denied |
| 404 | error | Not found - Resource doesn't exist |
| 500 | error | Internal server error |

### Biometric Error Codes
| Error Code | Description |
|------------|-------------|
| BIO_NOT_AVAILABLE | Biometric not available on device |
| BIO_NOT_ENROLLED | User hasn't enrolled biometrics |
| BIO_VERIFY_FAILED | Biometric verification failed |
| BIO_LOCKED_OUT | Too many failed attempts |

### Location Error Codes
| Error Code | Description |
|------------|-------------|
| LOC_PERMISSION_DENIED | Location permission not granted |
| LOC_SERVICE_DISABLED | Location services are disabled |
| LOC_MOCK_DETECTED | Mock location detected |
| LOC_OUTSIDE_GEOFENCE | User is outside office geofence |

---

## Data Types Reference

| Type | Format | Example |
|------|--------|---------|
| datetime | ISO8601 | `2024-12-08T09:30:00Z` |
| date | YYYY-MM-DD | `2024-12-08` |
| time | HH:MM:SS | `09:30:00` |
| phone | Number(10) | `3458000041` |
| coordinates | Decimal | `24.858510` |
| token | JWT String | `eyJhbGciOiJIUzI1...` |

---

## Notes

1. **Authentication**: All API calls (except login) require a valid Bearer token in the Authorization header.
2. **Location Data**: For biometric attendance, the app collects comprehensive location data including coordinates, address, and nearby landmarks for audit and verification purposes.
3. **Biometric Types**: The app supports both fingerprint and face recognition, depending on device capabilities.
4. **Geofence**: Automatic attendance marking is triggered when the user enters the predefined office geofence area.
5. **Offline Support**: The app queues attendance entries when offline and syncs when connectivity is restored.

