import json
from io import BytesIO

from django.contrib.auth.models import User
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from PIL import Image


class AlertsApiTests(TestCase):
    def test_signup_login_contact_and_alert_flow(self):
        signup_response = self.client.post(
            "/api/signup/",
            data=json.dumps({"username": "riya", "password": "safe-pass-123"}),
            content_type="application/json",
        )
        self.assertEqual(signup_response.status_code, 201)
        user_id = signup_response.json()["id"]
        token = signup_response.json()["token"]

        login_response = self.client.post(
            "/api/login/",
            data=json.dumps({"username": "riya", "password": "safe-pass-123"}),
            content_type="application/json",
        )
        self.assertEqual(login_response.status_code, 200)

        contact_response = self.client.post(
            f"/api/users/{user_id}/contacts/",
            data=json.dumps(
                {
                    "name": "Maa",
                    "phone_number": "+919876543210",
                    "email": "maa@example.com",
                    "relationship": "Mother",
                }
            ),
            content_type="application/json",
            headers={"Authorization": f"Token {token}"},
        )
        self.assertEqual(contact_response.status_code, 201)

        alert_response = self.client.post(
            f"/api/users/{user_id}/alerts/",
            data=json.dumps(
                {
                    "reason": "Phone moved and screen woke up",
                    "status": "triggered",
                    "latitude": 28.6139,
                    "longitude": 77.2090,
                }
            ),
            content_type="application/json",
            headers={"Authorization": f"Token {token}"},
        )
        self.assertEqual(alert_response.status_code, 201)
        alert_id = alert_response.json()["id"]

        image_bytes = BytesIO()
        Image.new("RGB", (10, 10), "red").save(image_bytes, format="PNG")
        photo_response = self.client.post(
            f"/api/users/{user_id}/alerts/{alert_id}/photo/",
            data={
                "photo": SimpleUploadedFile(
                    "intruder.png",
                    image_bytes.getvalue(),
                    content_type="image/png",
                )
            },
            headers={"Authorization": f"Token {token}"},
        )
        self.assertEqual(photo_response.status_code, 200)
        location_response = self.client.post(
            f"/api/users/{user_id}/location/",
            data=json.dumps({"latitude": 28.6139, "longitude": 77.2090}),
            content_type="application/json",
            headers={"Authorization": f"Token {token}"},
        )
        self.assertEqual(location_response.status_code, 201)
        dashboard_response = self.client.get("/api/dashboard/")
        self.assertContains(dashboard_response, "Pocket Guardian Dashboard")
        self.assertContains(dashboard_response, "Sent")
        detail_response = self.client.get("/api/alerts/1/")
        self.assertContains(detail_response, "Alert #1")

        self.assertEqual(User.objects.count(), 1)
