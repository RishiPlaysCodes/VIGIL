from django.urls import path

from . import views

urlpatterns = [
    path("dashboard/", views.dashboard, name="dashboard"),
    path("alerts/<int:alert_id>/", views.alert_detail, name="alert_detail"),
    path("signup/", views.signup, name="signup"),
    path("login/", views.login, name="login"),
    path("users/<int:user_id>/contacts/", views.emergency_contacts, name="contacts"),
    path("users/<int:user_id>/alerts/", views.alerts, name="alerts"),
    path(
        "users/<int:user_id>/alerts/<int:alert_id>/photo/",
        views.upload_alert_photo,
        name="upload_alert_photo",
    ),
    path("users/<int:user_id>/location/", views.location_ping, name="location_ping"),
]
