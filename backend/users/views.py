from rest_framework import status, viewsets, permissions, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from validate_email_address import validate_email
from rest_framework.decorators import api_view
from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.utils.crypto import get_random_string
from django.http import JsonResponse
from datetime import datetime, timedelta, date
import random
from .models import (
    Symptom, SymptomLog, MenstrualFlow, PeriodLog,
    Doctor, Appointment, Reminder
)
from .serializers import (
    EmailTokenObtainPairSerializer,
    MyTokenObtainPairSerializer,
    SymptomSerializer,
    MenstrualFlowSerializer,
    UserProfileSerializer,
    PeriodLogSerializer,
    DoctorSerializer,
    AppointmentSerializer,
    ReminderSerializer,
    DoctorSerializer
)
from rest_framework.parsers import JSONParser, MultiPartParser, FormParser
from .prediction_utils import predict_cycle_dates
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import EmailVerification, CustomUser
from django.core.mail import send_mail
from datetime import timedelta
from django.utils import timezone
from users.models import CustomUser
from users.models import Doctor  # ✅ Correct!

from users.models import Appointment

User = get_user_model()

# ✅ Register New User
@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    username = request.data.get("username")
    email = request.data.get("email")
    password = request.data.get("password")
    role = request.data.get("role", "user")

    # ✅ 1. Check if email ends with @gmail.com
    if not email or not email.lower().endswith('@gmail.com'):
        return Response({"error": "Only Gmail addresses are allowed."}, status=status.HTTP_400_BAD_REQUEST)

    # ✅ 2. Check if email actually exists (SMTP ping)
    #if not validate_email(email, verify=True):
        #return Response({"error": "This Gmail address does not exist."}, status=status.HTTP_400_BAD_REQUEST)

    # ✅ 3. Check if already exists
    if User.objects.filter(email=email).exists():
        return Response({"error": "Email already exists."}, status=status.HTTP_400_BAD_REQUEST)

    # ✅ 4. Create the user
    user = User.objects.create_user(username=username, email=email, password=password)
    user.first_name = username
    user.role = role
    user.save()

    # ✅ 5. Send Welcome Email
    send_mail(
        subject='🎉 Welcome to LunaTrack!',
        message=f"Hi {username},\n\nThanks for joining LunaTrack! 🌙✨",
        from_email='luntrackk@gmail.com',
        recipient_list=[email],
        fail_silently=False,
    )

    return Response({"message": "User registered successfully."}, status=status.HTTP_201_CREATED)

# ✅ JWT Login using Email
class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = EmailTokenObtainPairSerializer

# ✅ JWT Login for the Doctors
class MyTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer


@api_view(['POST'])
def verify_email(request):
    email = request.data.get('email')
    code = request.data.get('code')

    try:
        record = EmailVerification.objects.get(email=email)
        if record.code == code:
            user = CustomUser.objects.get(email=email)
            user.is_verified = True
            user.save()
            record.delete()
            return Response({'message': '✅ Verified'}, status=200)
        else:
            return Response({'error': 'Invalid code'}, status=400)
    except EmailVerification.DoesNotExist:
        return Response({'error': 'No verification record'}, status=404)


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

        parsed_dates = []
        for date_str in dates:
            try:
                parsed_date = datetime.fromisoformat(date_str.replace('Z', '+00:00')).date()
                PeriodLog.objects.create(user=user, date=parsed_date)
                parsed_dates.append(parsed_date)
            except Exception as e:
                return Response({"error": f"Failed to save date {date_str}: {e}"}, status=400)

        # ✅ STEP: Trigger prediction reminders
        if parsed_dates:
            last_period_start = max(parsed_dates)
            period_length = user.period_duration or 5
            cycle_length = user.cycle_length or 28

            next_period = last_period_start + timedelta(days=cycle_length)
            fertile_start = next_period - timedelta(days=14)
            ovulation_day = fertile_start + timedelta(days=2)

            create_prediction_reminders(user, next_period, fertile_start, ovulation_day)

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
        # ✅ Prevent Swagger from crashing on this view
        if getattr(self, 'swagger_fake_view', False):
            return Appointment.objects.none()  # Empty dummy queryset

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
    khalti_token = data.get('payment_token')  # match Flutter key


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

# Doctor appointmnet things
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def doctor_appointments(request):
    user = request.user
    try:
        doctor = Doctor.objects.get(user=user)
    except Doctor.DoesNotExist:
        return Response({"error": "Doctor not found"}, status=404)

    date_str = request.GET.get('date')
    if date_str:
        appointments = Appointment.objects.filter(
            doctor=doctor,
            appointment_date=date_str
        )
    else:
        appointments = Appointment.objects.filter(doctor=doctor)

    data = [
        {
            "id": appt.id,
            "user_name": appt.user.first_name,
            "appointment_date": str(appt.appointment_date),
            "appointment_time": str(appt.appointment_time),
            "reason": appt.reason,
            "payment_token": appt.payment_token,
            "status": appt.status,  # ✅ include status
        }
        for appt in appointments.order_by("appointment_time")
    ]
    return Response(data)

#appointmnet status completed or what
@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_appointment_status(request, pk):
    try:
        appointment = Appointment.objects.get(pk=pk)
    except Appointment.DoesNotExist:
        return Response({"error": "Appointment not found"}, status=404)

    # ✅ Check if the appointment date is in the past or today
    if appointment.appointment_date > date.today():
        return Response({"error": "Cannot mark future appointments as completed."}, status=400)

    appointment.status = 'completed'
    appointment.save()

    return Response({"message": "Appointment marked as completed"}, status=200)



#Doctor profile view
@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def doctor_profile_view(request):
    try:
        doctor = Doctor.objects.get(user=request.user)
    except Doctor.DoesNotExist:
        return Response({"error": "Doctor profile not found."}, status=404)

    if request.method == 'GET':
        serializer = DoctorSerializer(doctor, context={'request': request})
        return Response(serializer.data)

    elif request.method == 'PATCH':
        serializer = DoctorSerializer(doctor, data=request.data, partial=True, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)



@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_doctor_profile(request):
    user = request.user
    try:
        doctor = Doctor.objects.get(user=user)
    except Doctor.DoesNotExist:
        return Response({"error": "Doctor not found"}, status=404)

    serializer = DoctorSerializer(doctor, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=400)



@api_view(['POST'])
def initiate_khalti_payment(request):
    data = request.data
    headers = {
        "Authorization": "Key ba1fbdff7f16467c9648b3fe412f1448",
        "Content-Type": "application/json"
    }
    payload = {
        "return_url": "https://your-app.com/payment-success",  # change to your return page
        "website_url": "https://your-app.com",
        "amount": data.get("amount"),  # e.g., 50000 paisa
        "purchase_order_id": data.get("order_id"),  # unique per transaction
        "purchase_order_name": "Doctor Appointment",
        "customer_info": {
            "name": data.get("name"),
            "email": data.get("email"),
            "phone": data.get("phone")
        }
    }

    response = requests.post(
        "https://dev.khalti.com/api/v2/epayment/initiate/",
        json=payload,
        headers=headers
    )
    return Response(response.json())

# ✅ Verify Khalti Payment Token with Khalti Sandbox API
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def verify_khalti_payment(request):
    import requests

    pidx = request.data.get("pidx")
    if not pidx:
        return Response({"error": "Missing pidx"}, status=400)

    headers = {
        "Authorization": "Key ba1fbdff7f16467c9648b3fe412f1448",  # ✅ Sandbox secret key
        "Content-Type": "application/json"
    }

    response = requests.post(
        "https://dev.khalti.com/api/v2/epayment/lookup/",
        json={"pidx": pidx},
        headers=headers
    )

    return Response(response.json(), status=response.status_code)


# users/views.py
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def submit_review(request):
    serializer = ReviewSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save(user=request.user)
        return Response(serializer.data, status=201)
    return Response(serializer.errors, status=400)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def reschedule_appointment(request, pk):
    try:
        appointment = Appointment.objects.get(pk=pk, user=request.user)
    except Appointment.DoesNotExist:
        return Response({'error': 'Appointment not found or unauthorized'}, status=404)

    appointment_date = request.data.get('appointment_date')
    appointment_time = request.data.get('appointment_time')

    if not appointment_date or not appointment_time:
        return Response({'error': 'Date and time are required'}, status=400)

    # Optional: Prevent past dates/times
    from datetime import datetime
    date_time_obj = datetime.strptime(f"{appointment_date} {appointment_time}", "%Y-%m-%d %H:%M")
    if date_time_obj < datetime.now():
        return Response({'error': 'Cannot schedule to a past time'}, status=400)

    # Save new values
    appointment.appointment_date = appointment_date
    appointment.appointment_time = appointment_time
    appointment.save()

    return Response({'success': 'Appointment rescheduled successfully'})





def send_appointment_reminders():
    tomorrow = timezone.now() + timedelta(days=1)
    appts = Appointment.objects.filter(
        appointment_date=tomorrow.date(),
        reminder_sent=False
    )
    for appt in appts:
        send_mail(
            subject="Appointment Reminder",
            message=f"You have an appointment with Dr. {appt.doctor.name} tomorrow at {appt.appointment_time}.",
            from_email="luntrackk@gmail.com",
            recipient_list=[appt.user.email],
        )
        appt.reminder_sent = True
        appt.save()



class ReminderViewSet(viewsets.ModelViewSet):
    serializer_class = ReminderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Reminder.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

def create_prediction_reminders(user, next_period, fertile_start, ovulation_day):
    reminders = [
        Reminder(
            user=request.user,
            reminder_type="appointment_booked",
            message=f"Your appointment with Dr. {appt.doctor.name} is confirmed 🩺",
            date=timezone.now().date(),  # ✅ today
            time=timezone.now().time()
        ),

        Reminder(
            user=user,
            reminder_type="fertile_window_start",
            message="Your fertile window starts tomorrow 🌱",
            date=fertile_start - timedelta(days=1),
            time=timezone.now().time().replace(second=0, microsecond=0),
        ),
        Reminder(
            user=user,
            reminder_type="ovulation_day",
            message="Your ovulation day is in 2 days 💡",
            date=ovulation_day - timedelta(days=2),
            time=timezone.now().time().replace(second=0, microsecond=0),
        )
    ]
    Reminder.objects.bulk_create(reminders)



#booking appointmnet
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def book_appointment(request):
    user = request.user
    data = request.data

    doctor_id = data.get('doctor_id')
    date = data.get('appointment_date')
    time = data.get('appointment_time')
    reason = data.get('reason', '')

    if not all([doctor_id, date, time]):
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
        reason=reason
    )

    # 🔔 Appointment reminders for USER
    appointment_datetime = datetime.combine(appt.appointment_date, appt.appointment_time)
    reminder_time = appointment_datetime - timedelta(hours=2)

    Reminder.objects.bulk_create([
        Reminder(
            Reminder(
                user=appt.doctor.user,
                reminder_type="new_appointment",
                message=f"You have a new appointment with {request.user.first_name}",
                date=timezone.now().date(),  # ✅ today
                time=timezone.now().time()
            ),

        ),
        Reminder(
            user=request.user,
            reminder_type="appointment_reminder",
            message=f"Your appointment with Dr. {appt.doctor.name} is in 2 hours ⏰",
            date=reminder_time.date(),
            time=reminder_time.time()
        )
    ])

    # 🔔 Appointment reminder for DOCTOR
    Reminder.objects.bulk_create([
        Reminder(
            user=appt.doctor.user,
            reminder_type="new_appointment",
            message=f"You have a new appointment with {request.user.first_name}",
            date=timezone.now().date(),  # ✅ today
            time=timezone.now().time()
        ),

        Reminder(
            user=appt.doctor.user,
            reminder_type="same_day_reminder",
            message=f"Reminder: Appointment today with {request.user.first_name}",
            date=appt.appointment_date,
            time=datetime.strptime("08:00", "%H:%M").time()
        )
    ])

    return Response({"message": "Appointment booked!"}, status=201)








#Admin 
@api_view(['GET'])
def user_count(request):
    count = CustomUser.objects.count()
    return Response({'count': count})

@api_view(['GET'])
def doctor_count(request):
    count = Doctor.objects.count()
    return Response({'count': count})

@api_view(['GET'])
def appointment_count(request):
    count = Appointment.objects.count()
    return Response({'count': count})


@api_view(['PUT'])
def update_doctor(request, pk):
    try:
        doctor = Doctor.objects.get(pk=pk)
    except Doctor.DoesNotExist:
        return Response({'error': 'Doctor not found'}, status=status.HTTP_404_NOT_FOUND)

    serializer = DoctorSerializer(doctor, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)