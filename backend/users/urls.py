# users/urls.py

from django.urls import path
from rest_framework.routers import DefaultRouter
from django.conf import settings
from django.conf.urls.static import static

from .views import (
    register_user,
    CustomTokenObtainPairView,
    reset_password,
    forgot_password,
    SymptomListView,
    LogSymptomView,
    SymptomAdminViewSet,
    MenstrualFlowAdminViewSet,
    UserProfileView,
    period_logs,
    predict_dates,
    DoctorListView,
    AppointmentViewSet,
    get_booked_times,
    book_appointment_with_payment
)

# Routers for ViewSets (admin and appointments)
router = DefaultRouter()
router.register(r'admin/symptoms', SymptomAdminViewSet, basename='admin-symptom')
router.register(r'admin/menstrual-flow', MenstrualFlowAdminViewSet, basename='admin-menstrualflow')
router.register(r'appointments', AppointmentViewSet, basename='appointment')

# Main API endpoints
urlpatterns = [
    path("register/", register_user, name="register"),
    path("token/", CustomTokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("forgot-password/", forgot_password, name="forgot-password"),
    path("reset-password/", reset_password, name="reset-password"),
    path("symptoms/", SymptomListView.as_view(), name="symptom-list"),
    path("log-symptoms/", LogSymptomView.as_view(), name="log-symptoms"),
    path("profile/", UserProfileView.as_view(), name="user-profile"),
    path("period-logs/", period_logs, name="period-logs"),
    path("predict-dates/", predict_dates, name="predict-dates"),
    path("doctors/", DoctorListView.as_view(), name="doctor-list"),
    path("booked-times/", get_booked_times, name="get-booked-times"),
    path('book-appointment/', book_appointment_with_payment),
]

# Include router-based endpoints
urlpatterns += router.urls

# Media file support (dev only)
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
