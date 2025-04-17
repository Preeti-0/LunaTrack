from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.contrib.auth import get_user_model
from django.conf import settings
from datetime import time


# Custom User Manager
class CustomUserManager(BaseUserManager):
    def create_user(self, email, username, password=None, **extra_fields):
        if not email:
            raise ValueError("The Email field must be set")
        email = self.normalize_email(email).lower().strip()
        user = self.model(email=email, username=username, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, username, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)

        if not extra_fields.get('is_staff'):
            raise ValueError('Superuser must have is_staff=True.')
        if not extra_fields.get('is_superuser'):
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, username, password, **extra_fields)


# Custom User Model
class CustomUser(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    username = models.CharField(max_length=255, unique=True)
    first_name = models.CharField(max_length=255, blank=True, null=True)
    role = models.CharField(max_length=50, default="user")
    reset_code = models.CharField(max_length=10, blank=True, null=True)
    profile_image = models.ImageField(upload_to='profiles/', null=True, blank=True)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    birth_date = models.DateField(null=True, blank=True)
    cycle_regular = models.CharField(max_length=20, null=True, blank=True)
    period_duration = models.IntegerField(null=True, blank=True)
    cycle_length = models.IntegerField(null=True, blank=True)

    objects = CustomUserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']
    EMAIL_FIELD = 'email'

    def __str__(self):
        return self.email


# Symptom Logging Models
class Symptom(models.Model):
    name = models.CharField(max_length=100)

    def __str__(self):
        return self.name


class SymptomLog(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    symptom = models.ForeignKey(Symptom, on_delete=models.CASCADE)
    date = models.DateField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} - {self.symptom.name} on {self.date}"


class MenstrualFlow(models.Model):
    label = models.CharField(max_length=100)

    def __str__(self):
        return self.label


class DigestionSymptom(models.Model):
    name = models.CharField(max_length=100)

    def __str__(self):
        return self.name


class DigestionLog(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    symptom = models.ForeignKey(DigestionSymptom, on_delete=models.CASCADE)
    date = models.DateField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} - {self.symptom.name} on {self.date}"


# Period Log
User = get_user_model()


class PeriodLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='period_logs')
    date = models.DateField()

    class Meta:
        unique_together = ('user', 'date')
        ordering = ['-date']

    def __str__(self):
        return f"{self.user.email} - {self.date}"


# Doctor Model
class Doctor(models.Model):
    name = models.CharField(max_length=100)
    specialization = models.CharField(max_length=100)
    experience_years = models.IntegerField()
    location = models.CharField(max_length=255, null=True, blank=True)
    phone = models.CharField(max_length=20, null=True, blank=True)
    education = models.CharField(max_length=255, null=True, blank=True)
    rating = models.FloatField(default=4.5)
    about = models.TextField(null=True, blank=True)
    available_days = models.CharField(max_length=200)  # e.g. "Mon, Wed, Fri"
    available_time = models.CharField(max_length=100)  # e.g. "10:00 AM - 5:00 PM"
    image = models.ImageField(upload_to='doctors/', null=True, blank=True)
    consultation_fee = models.DecimalField(max_digits=8, decimal_places=2, default=500.00)


    def __str__(self):
        return self.name


# Appointment Model
class Appointment(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE)
    appointment_date = models.DateField()
    appointment_time = models.TimeField()
    reason = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    payment_token = models.CharField(max_length=100, null=True, blank=True)# ✅ Khalti token


    class Meta:
        unique_together = ('doctor', 'appointment_date', 'appointment_time')

    def __str__(self):
        return f"{self.user.email} with {self.doctor.name} on {self.appointment_date} at {self.appointment_time}"
