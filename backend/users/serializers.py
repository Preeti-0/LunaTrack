from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework import serializers
from django.contrib.auth import authenticate, get_user_model
from .models import (
    Symptom, SymptomLog, MenstrualFlow, DigestionSymptom, DigestionLog,
    CustomUser, PeriodLog, Doctor, Appointment, Doctor, Review, Reminder
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

#doctor side login by the admin

# serializers.py

class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role  # <- ✅ This is the key
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        data['role'] = self.user.role  # <- ✅ Flutter uses this key
        data['email'] = self.user.email
        data['first_name'] = self.user.first_name
        data['username'] = self.user.username

        # Optional: add image
        if self.user.profile_image:
            request = self.context.get("request")
            data['profile_image'] = request.build_absolute_uri(self.user.profile_image.url) if request else self.user.profile_image.url
        else:
            data['profile_image'] = None

        return data


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
    # ✅ Handle list input for these fields
    available_days = serializers.ListField(
        child=serializers.CharField(),
        write_only=True,
        required=False
    )
    available_time = serializers.ListField(
        child=serializers.CharField(),
        write_only=True,
        required=False
    )

    # ✅ New fields for user creation
    email = serializers.EmailField(write_only=True, required=False)
    password = serializers.CharField(write_only=True, required=False)

    # ✅ Computed read-only fields
    image_url = serializers.SerializerMethodField(read_only=True)
    consultation_fee = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Doctor
        fields = [
            'id', 'name', 'specialization', 'experience_years',
            'location', 'phone', 'education', 'rating', 'about',
            'available_days', 'available_time', 'image_url',
            'consultation_fee', 'email', 'password'
        ]
        read_only_fields = ['rating', 'image_url', 'id']

    def to_representation(self, instance):
        rep = super().to_representation(instance)
        rep['available_days'] = [d.strip() for d in instance.available_days.split(',')] if instance.available_days else []
        rep['available_time'] = [t.strip() for t in instance.available_time.split(',')] if instance.available_time else []
        return rep

    def create(self, validated_data):
        email = validated_data.pop('email', None)
        password = validated_data.pop('password', None)

        if not email or not password:
            raise serializers.ValidationError("Email and password are required to add a doctor.")

        # Convert list input to comma-separated strings
        available_days = validated_data.pop('available_days', [])
        available_time = validated_data.pop('available_time', [])
        validated_data['available_days'] = ', '.join(available_days)
        validated_data['available_time'] = ', '.join(available_time)

        # Create associated user
        user = CustomUser.objects.create_user(email=email, password=password, is_doctor=True)
        return Doctor.objects.create(user=user, **validated_data)

    def update(self, instance, validated_data):
        if 'available_days' in validated_data:
            instance.available_days = ', '.join(validated_data.pop('available_days'))
        if 'available_time' in validated_data:
            instance.available_time = ', '.join(validated_data.pop('available_time'))
        return super().update(instance, validated_data)

    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            return request.build_absolute_uri(obj.image.url) if request else obj.image.url
        return None

    def get_consultation_fee(self, obj):
        return float(obj.consultation_fee) if obj.consultation_fee else 0.0


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
            'reason', 'created_at', 'payment_token',
            'status'  # ✅ new field
        ]



class DoctorProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = Doctor
        fields = '__all__'


# users/serializers.py
class ReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = Review
        fields = '__all__'



class ReminderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Reminder
        fields = '__all__'
        read_only_fields = ['user', 'created_at']