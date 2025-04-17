from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework import serializers
from django.contrib.auth import authenticate, get_user_model
from .models import (
    Symptom, SymptomLog, MenstrualFlow, DigestionSymptom, DigestionLog,
    CustomUser, PeriodLog, Doctor, Appointment
)

User = get_user_model()

# 🔐 JWT Login Serializer
class EmailTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = User.EMAIL_FIELD

    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')
        if email is None or password is None:
            raise serializers.ValidationError("Email and password are required.")
        user = authenticate(request=self.context.get('request'), username=email, password=password)
        if not user:
            raise serializers.ValidationError("Invalid email or password.")
        refresh = self.get_token(user)
        return {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        }

# 🔹 Symptom Serializers
class SymptomSerializer(serializers.ModelSerializer):
    class Meta:
        model = Symptom
        fields = ['id', 'name']

class SymptomLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = SymptomLog
        fields = ['id', 'user', 'symptom', 'date']

# 🔹 Menstrual & Digestion Serializers
class MenstrualFlowSerializer(serializers.ModelSerializer):
    class Meta:
        model = MenstrualFlow
        fields = '__all__'

class DigestionSymptomSerializer(serializers.ModelSerializer):
    class Meta:
        model = DigestionSymptom
        fields = ['id', 'name']

class DigestionLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = DigestionLog
        fields = ['id', 'user', 'symptom', 'date']

# 👤 User Profile Serializer
class UserProfileSerializer(serializers.ModelSerializer):
    profile_image = serializers.ImageField(use_url=True)

    class Meta:
        model = CustomUser
        fields = [
            'email', 'first_name', 'profile_image',
            'birth_date', 'cycle_regular', 'period_duration', 'cycle_length'
        ]

# 🩸 Period Log Serializer
class PeriodLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = PeriodLog
        fields = ['id', 'date']

# 🩺 Doctor Serializer
class DoctorSerializer(serializers.ModelSerializer):
    available_days = serializers.SerializerMethodField()
    available_time = serializers.SerializerMethodField()
    image_url = serializers.SerializerMethodField()  # ✅ Renamed from image → image_url

    class Meta:
        model = Doctor
        fields = [
            'id', 'name', 'specialization', 'experience_years',
            'location', 'phone', 'education', 'rating', 'about',
            'available_days', 'available_time', 'image_url', 'consultation_fee'
        ]

    def get_available_days(self, obj):
        return [day.strip() for day in obj.available_days.split(',')] if obj.available_days else []

    def get_available_time(self, obj):
        return [time.strip() for time in obj.available_time.split(',')] if obj.available_time else []

    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            return request.build_absolute_uri(obj.image.url) if request else obj.image.url
        return None


# 📅 Appointment Serializer
class AppointmentSerializer(serializers.ModelSerializer):
    doctor = DoctorSerializer(read_only=True)
    doctor_id = serializers.PrimaryKeyRelatedField(
        queryset=Doctor.objects.all(), source='doctor', write_only=True
    )

    class Meta:
        model = Appointment
        fields = [
            'id',
            'doctor', 'doctor_id',
            'appointment_date', 'appointment_time',
            'reason', 'created_at'
        ]
