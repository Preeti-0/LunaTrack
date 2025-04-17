from rest_framework import status, viewsets, permissions, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.utils.crypto import get_random_string
from django.http import JsonResponse
from datetime import datetime, timedelta

from .models import (
    Symptom, SymptomLog, MenstrualFlow, PeriodLog,
    Doctor, Appointment
)
from .serializers import (
    EmailTokenObtainPairSerializer,
    SymptomSerializer,
    MenstrualFlowSerializer,
    UserProfileSerializer,
    PeriodLogSerializer,
    DoctorSerializer,
    AppointmentSerializer
)
from rest_framework.parsers import JSONParser, MultiPartParser, FormParser
from .prediction_utils import predict_cycle_dates

User = get_user_model()

# ✅ Register New User
@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    username = request.data.get("username")
    email = request.data.get("email")
    password = request.data.get("password")
    role = request.data.get("role", "user")

    if User.objects.filter(email=email).exists():
        return Response({"error": "Email already exists."}, status=status.HTTP_400_BAD_REQUEST)

    user = User.objects.create_user(username=username, email=email, password=password)
    user.first_name = username
    user.role = role
    user.save()

    send_mail(
        subject='🎉 Welcome to LunaTrack!',
        message=f"Hi {username},\n\nThanks for joining LunaTrack! 🌙✨\nWe're glad you're here.",
        from_email='luntrackk@gmail.com',
        recipient_list=[email],
        fail_silently=False,
    )

    return Response({"message": "User registered successfully."}, status=status.HTTP_201_CREATED)


# ✅ JWT Login using Email
class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = EmailTokenObtainPairSerializer


# ✅ Forgot Password - Send Reset Code
@api_view(['POST'])
@permission_classes([AllowAny])
def forgot_password(request):
    email = request.data.get('email')
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({'error': 'User with this email does not exist.'}, status=status.HTTP_404_NOT_FOUND)

    reset_code = get_random_string(6, allowed_chars='0123456789')
    user.reset_code = reset_code
    user.save()

    send_mail(
        subject='Reset Your LunaTrack Password',
        message=f'Hi {user.username},\n\nYour LunaTrack password reset code is: {reset_code}',
        from_email='luntrackk@gmail.com',
        recipient_list=[email],
        fail_silently=False,
    )

    return Response({'message': 'Reset code sent to email.'}, status=status.HTTP_200_OK)


# ✅ Reset Password - Submit Code + New Password
@api_view(['POST'])
@permission_classes([AllowAny])
def reset_password(request):
    email = request.data.get("email")
    code = request.data.get("code")
    new_password = request.data.get("new_password")

    try:
        user = User.objects.get(email=email)
        if user.reset_code != code:
            return Response({"error": "Invalid reset code"}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(new_password)
        user.reset_code = None
        user.save()
        return Response({"message": "Password reset successfully!"})

    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)


# ✅ Public Symptom List
class SymptomListView(generics.ListAPIView):
    queryset = Symptom.objects.all()
    serializer_class = SymptomSerializer
    permission_classes = [permissions.AllowAny]


# ✅ Log Symptoms for User
class LogSymptomView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        symptom_ids = request.data.get("symptom_ids", [])
        if not symptom_ids:
            return Response({"error": "No symptoms provided."}, status=400)

        for sid in symptom_ids:
            SymptomLog.objects.create(user=request.user, symptom_id=sid)

        return Response({"message": "Symptoms logged successfully."})


# ✅ Admin CRUD for Symptoms & Menstrual Flow
class SymptomAdminViewSet(viewsets.ModelViewSet):
    queryset = Symptom.objects.all()
    serializer_class = SymptomSerializer
    permission_classes = [IsAdminUser]


class MenstrualFlowAdminViewSet(viewsets.ModelViewSet):
    queryset = MenstrualFlow.objects.all()
    serializer_class = MenstrualFlowSerializer
    permission_classes = [IsAdminUser]


# ✅ Profile View + PATCH
class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get(self, request):
        try:
            serializer = UserProfileSerializer(request.user, context={'request': request})
            return Response(serializer.data)
        except Exception as e:
            print("❌ Profile fetch error:", e)
            return Response({"error": "Server error", "details": str(e)}, status=500)

    def patch(self, request):
        user = request.user

        if request.data.get("profile_image") in ["", "null", None]:
            if user.profile_image:
                user.profile_image.delete(save=True)
            if hasattr(request.data, '_mutable'):
                request.data._mutable = True
            request.data.pop("profile_image", None)
            if hasattr(request.data, '_mutable'):
                request.data._mutable = False

        serializer = UserProfileSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)


# ✅ Period Log API
@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def period_logs(request):
    user = request.user

    if request.method == 'GET':
        logs = PeriodLog.objects.filter(user=user).order_by('date')
        dates = [log.date.isoformat() for log in logs]
        return Response(dates)

    elif request.method == 'POST':
        dates = request.data.get('dates', [])
        if not isinstance(dates, list):
            return Response({"error": "dates should be a list."}, status=400)

        PeriodLog.objects.filter(user=user).delete()

        for date_str in dates:
            try:
                parsed_date = datetime.fromisoformat(date_str.replace('Z', '+00:00')).date()
                PeriodLog.objects.create(user=user, date=parsed_date)
            except Exception as e:
                return Response({"error": f"Failed to save date {date_str}: {e}"}, status=400)

        return Response({"message": "Logs updated."}, status=201)


# ✅ Predict Period, Fertile, Ovulation Days
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def predict_dates(request):
    user = request.user
    period_logs = user.period_logs.order_by('-date').values_list('date', flat=True)

    if not period_logs:
        return Response({"period_days": [], "fertile_windows": [], "ovulation_days": []})

    last_period = period_logs[0]
    cycle_length = user.cycle_length or 28
    period_duration = user.period_duration or 5

    period_days = []
    fertile_windows = []
    ovulation_days = []

    for i in range(6):  # Predict 6 cycles
        start = last_period + timedelta(days=i * cycle_length)
        period = [start + timedelta(days=d) for d in range(period_duration)]
        ovulation = start + timedelta(days=(cycle_length // 2))
        fertile = [ovulation - timedelta(days=5) + timedelta(days=d) for d in range(7)]

        period_days += period
        ovulation_days.append(ovulation)
        fertile_windows += fertile

    return Response({
        "period_days": [d.isoformat() for d in period_days],
        "fertile_windows": [d.isoformat() for d in fertile_windows],
        "ovulation_days": [d.isoformat() for d in ovulation_days],
    })


# ✅ Doctor Listing (Public)
class DoctorListView(generics.ListAPIView):
    queryset = Doctor.objects.all()
    serializer_class = DoctorSerializer
    permission_classes = [AllowAny]

    def get_serializer_context(self):
        return {'request': self.request}


# ✅ Appointment Booking for Users
class AppointmentViewSet(viewsets.ModelViewSet):
    serializer_class = AppointmentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Appointment.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


# ✅ Get Booked Times for Specific Doctor + Date
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_booked_times(request):
    doctor_id = request.GET.get('doctor_id')
    date_str = request.GET.get('date')

    if not doctor_id or not date_str:
        return JsonResponse({'error': 'Missing parameters'}, status=400)

    try:
        date = datetime.strptime(date_str, "%Y-%m-%d").date()
    except ValueError:
        return JsonResponse({'error': 'Invalid date format'}, status=400)

    appointments = Appointment.objects.filter(
        doctor_id=doctor_id,
        appointment_date=date
    )

    booked_times = [appt.appointment_time.strftime("%H:%M") for appt in appointments]
    return JsonResponse({'booked_times': booked_times})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def book_appointment_with_payment(request):
    user = request.user
    data = request.data

    doctor_id = data.get('doctor_id')
    date = data.get('appointment_date')
    time = data.get('appointment_time')
    reason = data.get('reason', '')
    khalti_token = data.get('khalti_token')

    if not all([doctor_id, date, time, khalti_token]):
        return Response({"error": "Missing required fields"}, status=400)

    try:
        doctor = Doctor.objects.get(id=doctor_id)
    except Doctor.DoesNotExist:
        return Response({"error": "Doctor not found"}, status=404)

    if Appointment.objects.filter(doctor=doctor, appointment_date=date, appointment_time=time).exists():
        return Response({"error": "Slot already booked"}, status=409)

    appt = Appointment.objects.create(
        user=user,
        doctor=doctor,
        appointment_date=date,
        appointment_time=time,
        reason=reason,
        payment_token=khalti_token
    )

    return Response({"message": "Appointment booked!"}, status=201)
