from django.utils import timezone
from django.db.models import Q
from rest_framework import viewsets, generics, serializers, status, views
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.decorators import action
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializers import MyTokenObtainPairSerializer
from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from .permissions import (
    IsAdmin,
    IsAdminOrReadOnly,
    IsAdminOrTeacher,
    IsOwner,
    IsOwnerOrReadOnly,
    CanVote,
    CanCreateInitiative,
    IsOwnerOrAdminOrTeacher,
)

from .models import (
    User, EventCategory, Event, EventApplication, Initiative, Vote,
    Alumni, ParentClub, TheaterRole, SafetyTrain, ParentSchoolEvent,
    ParentSchoolRegistration, MuseumTask, File, Suggestion,
)
from .serializers import *


class UserViewSet(viewsets.ModelViewSet):
    """ Управление пользователями: Доступ только для администраторов. """
    queryset = User.objects.all().order_by('id')
    serializer_class = UserSerializer
    permission_classes = [IsAdmin] 

class EventCategoryViewSet(viewsets.ModelViewSet):
    """ Категории мероприятий: Просмотр всем, управление - администраторам. """
    queryset = EventCategory.objects.all()
    serializer_class = EventCategorySerializer
    permission_classes = [IsAdminOrReadOnly]

class EventViewSet(viewsets.ModelViewSet):
    """ Мероприятия (идеи): Просмотр всем, создание - авторизованным, управление - администраторам и учителям. """
    queryset = Event.objects.all()
    serializer_class = EventSerializer
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            self.permission_classes = [AllowAny]
        elif self.action == 'create':
            self.permission_classes = [IsAuthenticated]
        else:
            self.permission_classes = [IsAdminOrTeacher]
        return super().get_permissions()
    def perform_create(self, serializer):
        serializer.save(initiator=self.request.user, is_idea=True)

class EventApplicationViewSet(viewsets.ModelViewSet):
    """ Заявки на мероприятия: Создание и просмотр своих - авторизованным. Управление всеми заявками - администраторам и учителям. """
    serializer_class = EventApplicationSerializer
    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.role == 'teacher':
            return EventApplication.objects.all()
        return EventApplication.objects.filter(user=user)
    def get_permissions(self):
        if self.action in ['update', 'partial_update', 'destroy']:
            self.permission_classes = [IsAdminOrTeacher]
        else:
            self.permission_classes = [IsAuthenticated]
        return super().get_permissions()
    def perform_create(self, serializer):
        event = serializer.validated_data.get('event')
        if EventApplication.objects.filter(user=self.request.user, event=event).exists():
            raise serializers.ValidationError({'detail': 'Вы уже подали заявку на это мероприятие.'})
        serializer.save(user=self.request.user)

class AlumniViewSet(viewsets.ModelViewSet):
    """ Выпускники: Просмотр и добавление - авторизованным. Редактирование - владельцу или админу/учителю. Одобрение - админу/учителю. """
    serializer_class = AlumniSerializer
    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return Alumni.objects.none()
        if user.is_staff or user.role == 'teacher':
            return Alumni.objects.all().order_by('-added_at')
        return Alumni.objects.filter(
            Q(status='approved') | 
            Q(added_by=user, status='pending')
        ).distinct().order_by('-added_at')
    def get_permissions(self):
        if self.action in ['list', 'retrieve', 'create']:
            self.permission_classes = [IsAuthenticated]
        elif self.action in ['update', 'partial_update', 'destroy']:
            self.permission_classes = [IsOwnerOrAdminOrTeacher]
        elif self.action in ['approve', 'reject']:
            self.permission_classes = [IsAdminOrTeacher]
        else:
            self.permission_classes = [IsAdmin]
        return super().get_permissions()
    def perform_create(self, serializer):
        serializer.save(added_by=self.request.user, status='pending')
    @action(detail=True, methods=['post'], permission_classes=[IsAdminOrTeacher])
    def approve(self, request, pk=None):
        alumni_entry = self.get_object()
        alumni_entry.status = 'approved'
        alumni_entry.save()
        return Response({'status': 'approved'})
    @action(detail=True, methods=['post'], permission_classes=[IsAdminOrTeacher])
    def reject(self, request, pk=None):
        alumni_entry = self.get_object()
        alumni_entry.status = 'rejected'
        alumni_entry.save()
        return Response({'status': 'rejected'})

class ParentClubViewSet(viewsets.ModelViewSet):
    """ Родительский клуб: Просмотр - авторизованным, создание - не студентам, редактирование - владельцу или админу/учителю. """
    serializer_class = ParentClubSerializer
    def get_queryset(self):
        return ParentClub.objects.all().order_by('-created_at')
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            self.permission_classes = [IsAuthenticated]
        elif self.action == 'create':
            if self.request.user.role == 'student':
                self.permission_denied(self.request, message="Студенты не могут создавать записи в Родительском клубе.")
            self.permission_classes = [IsAuthenticated]
        else:
            self.permission_classes = [IsOwnerOrAdminOrTeacher]
        return super().get_permissions()
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

class ParentSchoolEventViewSet(viewsets.ModelViewSet):
    """ Школа для родителей (мероприятия): Просмотр - авторизованным, управление - администраторам и учителям. """
    queryset = ParentSchoolEvent.objects.all()
    serializer_class = ParentSchoolEventSerializer
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            self.permission_classes = [IsAuthenticated] 
        else:
            self.permission_classes = [IsAdminOrTeacher]
        return super().get_permissions()

class ParentSchoolRegistrationViewSet(viewsets.ModelViewSet):
    """ Регистрации на Школу для родителей: Создание (не студентам) и просмотр своих - авторизованным. Управление всеми - админам и учителям. """
    serializer_class = ParentSchoolRegistrationSerializer
    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.role == 'teacher':
            return ParentSchoolRegistration.objects.all()
        return ParentSchoolRegistration.objects.filter(user=user)
    def get_permissions(self):
        if self.action in ['update', 'partial_update', 'destroy']:
            self.permission_classes = [IsAdminOrTeacher]
        else:
            self.permission_classes = [IsAuthenticated]
        return super().get_permissions()
    def perform_create(self, serializer):
        if self.request.user.role == 'student':
            raise serializers.ValidationError("Студенты не могут регистрироваться на мероприятия для родителей.")
        event = serializer.validated_data.get('event')
        if ParentSchoolRegistration.objects.filter(user=self.request.user, event=event).exists():
            raise serializers.ValidationError({'detail': 'Вы уже зарегистрированы на это мероприятие.'})
        serializer.save(user=self.request.user)

class InitiativeViewSet(viewsets.ModelViewSet):
    """ Инициативы: Просмотр - авторизованным, создание - не студентам, редактирование - владельцу или админу/учителю. """
    queryset = Initiative.objects.all()
    serializer_class = InitiativeSerializer
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            self.permission_classes = [IsAuthenticated]
        elif self.action == 'create':
            self.permission_classes = [CanCreateInitiative]
        else:
            self.permission_classes = [IsOwnerOrAdminOrTeacher]
        return super().get_permissions()
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

class VoteViewSet(viewsets.ModelViewSet):
    """ Голосования: Просмотр - авторизованным, создание голоса - не студентам. """
    queryset = Vote.objects.all()
    serializer_class = VoteSerializer
    permission_classes = [IsAuthenticated, CanVote]
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class TheaterRoleViewSet(viewsets.ModelViewSet):
    """ Театральные роли: Просмотр всем, подача заявки - авторизованным (кроме родителей), управление ролями - админам и учителям. """
    queryset = TheaterRole.objects.all()
    serializer_class = TheaterRoleSerializer
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            self.permission_classes = [AllowAny]
        elif self.action == 'apply':
             self.permission_classes = [IsAuthenticated]
        else:
            self.permission_classes = [IsAdminOrTeacher]
        return super().get_permissions()
    @action(detail=True, methods=['post'], url_path='apply')
    def apply(self, request, pk=None):
        role_instance = self.get_object()
        user = request.user
        if user.role == 'parent':
            return Response({'detail': 'Родители не могут участвовать в театре.'}, status=status.HTTP_403_FORBIDDEN)
        if role_instance.status != 'open':
            return Response({'detail': 'Роль уже занята.'}, status=status.HTTP_400_BAD_REQUEST)
        role_instance.user = user
        role_instance.save()
        return Response(TheaterRoleSerializer(role_instance).data)

class SafetyTrainViewSet(viewsets.ModelViewSet):
    """ Тренажеры по безопасности: Просмотр всем, управление - администраторам и учителям. """
    queryset = SafetyTrain.objects.all()
    serializer_class = SafetyTrainSerializer
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            self.permission_classes = [AllowAny]
        else:
            self.permission_classes = [IsAdminOrTeacher]
        return super().get_permissions()

class MuseumTaskViewSet(viewsets.ModelViewSet):
    """ Задания для музея: Просмотр всем, управление - администраторам и учителям. """
    queryset = MuseumTask.objects.all()
    serializer_class = MuseumTaskSerializer
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            self.permission_classes = [AllowAny]
        else:
            self.permission_classes = [IsAdminOrTeacher]
        return super().get_permissions()

class FileViewSet(viewsets.ModelViewSet):
    """ Файлы: Просмотр всем, управление - администраторам. """
    queryset = File.objects.all()
    serializer_class = FileSerializer
    permission_classes = [IsAdminOrReadOnly]

class SuggestionViewSet(viewsets.ModelViewSet):
    """ Предложения по улучшению: Создание и просмотр своих - авторизованным. Просмотр всех - админам и учителям. """
    serializer_class = SuggestionSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        if self.request.user.is_staff or self.request.user.role == 'teacher':
            return Suggestion.objects.all()
        return Suggestion.objects.filter(author=self.request.user)
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

class RegisterView(generics.CreateAPIView):
    """ Регистрация нового пользователя. Доступно всем. """
    queryset = User.objects.all()
    permission_classes = (AllowAny,)
    serializer_class = RegisterSerializer

class MyApplicationsView(views.APIView):
    """ Агрегированный список заявок пользователя (на мероприятия и в школу родителей). """
    permission_classes = [IsAuthenticated]
    def get(self, request, *args, **kwargs):
        user = self.request.user
        now = timezone.now()
        data = {'upcoming_approved': [], 'upcoming_pending': [], 'archived': []}
        event_applications = EventApplication.objects.filter(user=user).select_related('event', 'event__category')
        for app in event_applications:
            application_data = {'event_title': app.event.title, 'event_type': 'Мероприятие', 'status': app.get_status_display(), 'applied_at': app.applied_at}
            event_date = app.event.end_date or app.event.start_date
            if app.status == 'rejected' or (event_date and event_date < now):
                data['archived'].append(application_data)
            elif app.status == 'approved':
                data['upcoming_approved'].append(application_data)
            else: 
                data['upcoming_pending'].append(application_data)
        parent_school_registrations = ParentSchoolRegistration.objects.filter(user=user).select_related('event')
        for reg in parent_school_registrations:
            registration_data = {'event_title': reg.event.title, 'event_type': 'Школа для родителей', 'status': reg.get_status_display(), 'applied_at': reg.registered_at}
            if reg.status == 'rejected' or (reg.event.event_date and reg.event.event_date < now):
                data['archived'].append(registration_data)
            elif reg.status == 'approved':
                data['upcoming_approved'].append(registration_data)
            else:
                data['upcoming_pending'].append(registration_data)
        for key in data:
            data[key] = sorted(data[key], key=lambda x: x['applied_at'], reverse=True)
        return Response(data)

class CalendarEventsView(generics.ListAPIView):
    """ Единый список всех событий для календаря. Доступно всем. """
    serializer_class = CalendarEventSerializer
    permission_classes = [AllowAny]
    def get_queryset(self):
        events = Event.objects.filter(is_idea=False, start_date__isnull=False)
        parent_school_events = ParentSchoolEvent.objects.filter(event_date__isnull=False)
        unified_list = []
        for event in events:
            unified_list.append({'id': event.id, 'title': event.title, 'description': event.description or '', 'start_date': event.start_date, 'event_type': 'event', 'organizer_name': event.initiator.get_full_name() if event.initiator else 'Не указан', 'location': event.location or '', 'category_name': event.category.name if event.category else ''})
        for event in parent_school_events:
            unified_list.append({'id': event.id, 'title': event.title, 'description': event.description or '', 'start_date': event.event_date, 'event_type': 'parent_school', 'organizer_name': event.organizer.get_full_name() if event.organizer else 'Не указан', 'location': '', 'category_name': 'Школа для родителей'})
        return unified_list
    

class MyTokenObtainPairView(TokenObtainPairView):
    """
    Кастомное представление для получения токена,
    позволяет входить по email или username.
    """
    serializer_class = MyTokenObtainPairSerializer
    

@api_view(['GET'])
@permission_classes([AllowAny]) # <-- Разрешаем доступ всем
def health_check(request):
    return JsonResponse({"status": "ok", "timestamp": timezone.now()})