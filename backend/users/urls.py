# users/urls.py

from django.urls import path
from rest_framework.routers import DefaultRouter
from django.conf import settings
from django.conf.urls.static import static
from . import views 

from .views import (
    register_user,
    CustomTokenObtainPairView,
    MyTokenObtainPairView,
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
    book_appointment_with_payment,
    doctor_appointments,
    doctor_profile_view,
    verify_khalti_payment,
    ReminderViewSet,
    book_appointment,
)

# Routers for ViewSets (admin and appointments)
router = DefaultRouter()
router.register(r'admin/symptoms', SymptomAdminViewSet, basename='admin-symptom')
router.register(r'admin/menstrual-flow', MenstrualFlowAdminViewSet, basename='admin-menstrualflow')
router.register(r'appointments', AppointmentViewSet, basename='appointment')
router.register(r'reminders', ReminderViewSet, basename='reminder')


# Main API endpoints
urlpatterns = [
    path("register/", register_user, name="register"),
    path("token/", MyTokenObtainPairView.as_view(), name="token_obtain_pair"),
    path('verify-email/', views.verify_email, name='verify-email'),
    #path("token/", CustomTokenObtainPairView.as_view(), name="token_obtain_pair"),
    #path('api/token/', MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path("forgot-password/", forgot_password, name="forgot-password"),
    path("reset-password/", reset_password, name="reset-password"),
    path("symptoms/", SymptomListView.as_view(), name="symptom-list"),
    path("log-symptoms/", LogSymptomView.as_view(), name="log-symptoms"),
    path("profile/", UserProfileView.as_view(), name="user-profile"),
    path("period-logs/", period_logs, name="period-logs"),
    path("predict-dates/", predict_dates, name="predict-dates"),
    path("doctors/", DoctorListView.as_view(), name="doctor-list"),
    path("booked-times/", get_booked_times, name="get-booked-times"),
    path('book-appointment-with-payment/', book_appointment_with_payment, name='book-appointment-with-payment'),
    path("doctor-appointments/", doctor_appointments, name="doctor-appointments"),
    path('doctor-profile/', doctor_profile_view, name='doctor-profile'),
    path("initiate-khalti-payment/", views.initiate_khalti_payment),
    path("verify-khalti-payment/", views.verify_khalti_payment),
    path("update-appointment-status/<int:pk>/", views.update_appointment_status),
# users/urls.py
    path('submit-review/', views.submit_review),
    path('reschedule-appointment/<int:pk>/', views.reschedule_appointment, name='reschedule-appointment'),
    path("book-appointment/", book_appointment),
    path('doctor-update/<int:pk>/', views.update_doctor, name='doctor-update'),




#Admin thing
    path('user-count/', views.user_count),
    path('doctor-count/', views.doctor_count),
    path('appointment-count/', views.appointment_count),
    path('doctor-update/<int:pk>/', views.update_doctor, name='doctor-update'),
]

# Include router-based endpoints
urlpatterns += router.urls

# Media file support (dev only)
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
