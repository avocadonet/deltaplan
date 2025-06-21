from rest_framework import serializers
from .models import *

class RegisterSerializer(serializers.ModelSerializer):
    """ Сериализатор для регистрации новых пользователей. """
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    password2 = serializers.CharField(write_only=True, required=True, label="Confirm Password")

    class Meta:
        model = User
        fields = ('username', 'password', 'password2', 'email', 'first_name', 'last_name', 'role')

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs

    def create(self, validated_data):
        user = User.objects.create(
            username=validated_data['username'],
            email=validated_data['email'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            role=validated_data.get('role', 'student')
        )
        user.set_password(validated_data['password'])
        user.save()
        return user

class UserSerializer(serializers.ModelSerializer):
    """ Базовое представление данных пользователя. """
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'role', 'full_name')

class EventCategorySerializer(serializers.ModelSerializer):
    """ Сериализатор для категорий мероприятий. """
    class Meta:
        model = EventCategory
        fields = "__all__"

class EventSerializer(serializers.ModelSerializer):
    """ Представление мероприятия. Используется для просмотра и создания. """
    category_name = serializers.CharField(source='category.name', read_only=True)
    class Meta:
        model = Event
        fields = "__all__"
        read_only_fields = ('category_name', 'initiator', 'is_idea')

class EventApplicationSerializer(serializers.ModelSerializer):
    """ Сериализатор для подачи заявки на участие в мероприятии. """
    event = EventSerializer(read_only=True)
    event_id = serializers.PrimaryKeyRelatedField(
        queryset=Event.objects.all(), source='event', write_only=True
    )
    class Meta:
        model = EventApplication
        fields = ('id', 'event', 'event_id', 'status', 'applied_at')
        read_only_fields = ('status', 'applied_at', 'event')

class InitiativeSerializer(serializers.ModelSerializer):
    """ Представление инициативы. Создание доступно не-студентам. """
    author_name = serializers.StringRelatedField(source='author')
    class Meta:
        model = Initiative
        fields = "__all__"
        read_only_fields = ('author_name',)

class VoteSerializer(serializers.ModelSerializer):
    """ Сериализатор для голосования за инициативу. Доступно не-студентам. """
    class Meta:
        model = Vote
        fields = "__all__"

class AlumniSerializer(serializers.ModelSerializer):
    """ Управление записями выпускников. Создание доступно всем, редактирование - владельцу или администратору. """
    # Поле для удобного отображения имени на фронтенде
    alumni_display_name = serializers.SerializerMethodField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    # Автор записи подставляется автоматически
    added_by = serializers.HiddenField(default=serializers.CurrentUserDefault())

    class Meta:
        model = Alumni
        fields = "__all__"
        
    def get_alumni_display_name(self, obj):
        if obj.display_name and obj.full_name:
            return obj.full_name
        return "Не указано"


class ParentClubSerializer(serializers.ModelSerializer):
    """ Записи в родительском клубе. Просмотр - всем авторизованным, создание - не студентам. """
    section_display = serializers.CharField(source='get_section_display', read_only=True)
    author_name = serializers.SerializerMethodField()
    class Meta:
        model = ParentClub
        fields = ('id', 'section', 'content', 'created_at', 'is_anonymous', 'section_display', 'author_name')
        read_only_fields = ('section_display', 'author_name', 'created_at')

    def get_author_name(self, obj):
        if obj.is_anonymous:
            return "Аноним"
        return obj.author.get_full_name() or obj.author.username

class TheaterRoleSerializer(serializers.ModelSerializer):
    """ Сериализатор для ролей в театральной студии. """
    class Meta:
        model = TheaterRole
        fields = "__all__"

class SafetyTrainSerializer(serializers.ModelSerializer):
    """ Представление тренинга по безопасности. """
    author_name = serializers.StringRelatedField(source='author')
    class Meta:
        model = SafetyTrain
        fields = "__all__"
        read_only_fields = ('author_name',)

class ParentSchoolEventSerializer(serializers.ModelSerializer):
    """ Представление мероприятия родительской школы. """
    organizer_name = serializers.StringRelatedField(source='organizer')
    class Meta:
        model = ParentSchoolEvent
        fields = "__all__"
        read_only_fields = ('organizer_name',)

class ParentSchoolRegistrationSerializer(serializers.ModelSerializer):
    """ Сериализатор для регистрации на мероприятие родительской школы. """
    class Meta:
        model = ParentSchoolRegistration
        fields = ('id', 'event', 'status', 'registered_at')
        read_only_fields = ('registered_at', 'status')

class MuseumTaskSerializer(serializers.ModelSerializer):
    """ Представление задания для музейного проекта. """
    proposed_by_name = serializers.StringRelatedField(source='proposed_by')
    class Meta:
        model = MuseumTask
        fields = "__all__"
        read_only_fields = ('proposed_by_name',)

class FileSerializer(serializers.ModelSerializer):
    """ Сериализатор для загрузки и отображения файлов. """
    class Meta:
        model = File
        fields = "__all__"
        
class SuggestionSerializer(serializers.ModelSerializer):
    """ Сериализатор для предложений по улучшению сайта. """
    author = serializers.HiddenField(default=serializers.CurrentUserDefault())
    class Meta:
        model = Suggestion
        fields = ('id', 'author', 'content', 'screen_source', 'created_at')
        read_only_fields = ('created_at',)

class UnifiedRegistrationSerializer(serializers.Serializer):
    """ Агрегированное представление заявок пользователя на разные мероприятия (только для чтения). """
    event_title = serializers.CharField()
    event_type = serializers.CharField()
    status = serializers.CharField()
    applied_at = serializers.DateTimeField()
    class Meta:
        fields = ('event_title', 'event_type', 'status', 'applied_at')
        
class CalendarEventSerializer(serializers.Serializer):
    """ Форматирование разных моделей для единого отображения в календаре (только для чтения). """
    id = serializers.IntegerField()
    title = serializers.CharField()
    description = serializers.CharField()
    start_date = serializers.DateTimeField()
    event_type = serializers.CharField()
    organizer_name = serializers.CharField(allow_blank=True, required=False)
    location = serializers.CharField(allow_blank=True, required=False)
    category_name = serializers.CharField(allow_blank=True, required=False)