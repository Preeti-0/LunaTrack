
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser, Doctor, Appointment


# 🔹 Admin for Custom Users
class CustomUserAdmin(UserAdmin):
    list_display = ('email', 'username', 'is_staff', 'is_active', 'role')
    search_fields = ('email', 'username')
    ordering = ('email',)

admin.site.register(CustomUser, CustomUserAdmin)

# 🔹 Admin for Doctors
@admin.register(Doctor)
class DoctorAdmin(admin.ModelAdmin):
    list_display = ('name', 'specialization', 'experience_years', 'available_days', 'available_time')
    search_fields = ('name', 'specialization')
    list_filter = ('specialization',)

# 🔹 Admin for Appointments
@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ('user', 'doctor', 'appointment_date', 'appointment_time', 'created_at')
    search_fields = ('user__email', 'doctor__name', 'reason')
    list_filter = ('appointment_date',)
