from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import (
    User,
    EventCategory,
    Event,
    EventApplication,
    Initiative,
    Vote,
    Alumni,
    ParentClub,
    TheaterRole,
    SafetyTrain,
    ParentSchoolEvent,
    ParentSchoolRegistration,
    MuseumTask,
    File,
    Suggestion,
)


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """ Кастомная модель пользователя с добавлением ролей (админ, учитель, родитель, студент). """
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Дополнительная информация', {'fields': ('role', 'full_name', 'created_by')}),
    )
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ('Дополнительная информация', {'fields': ('role', 'full_name', 'email')}),
    )
    list_display = ('username', 'email', 'full_name', 'role', 'is_staff')
    list_filter = ('role', 'is_staff', 'is_superuser', 'groups')
    search_fields = ('username', 'full_name', 'email')


@admin.register(EventCategory)
class EventCategoryAdmin(admin.ModelAdmin):
    """ Модель категорий для мероприятий. """
    list_display = ("name",)
    search_fields = ("name",)


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    """ Модель мероприятий с категориями, датами и статусами. """
    list_display = ("title", "category", "start_date", "end_date", "status", "is_idea")
    list_filter = ("category", "status", "is_idea")
    search_fields = ("title", "description")


@admin.register(EventApplication)
class EventApplicationAdmin(admin.ModelAdmin):
    """ Модель заявок на участие в мероприятиях. """
    list_display = ("user", "event", "status", "applied_at")
    list_filter = ("status",)
    search_fields = ("user__username", "event__title")


@admin.register(Initiative)
class InitiativeAdmin(admin.ModelAdmin):
    """ Модель инициатив от пользователей с голосованием. """
    list_display = (
        "id",
        "author",
        "submission_period",
        "status",
        "votes_for",
        "votes_against",
    )
    list_filter = ("status",)
    search_fields = ("description",)


@admin.register(Vote)
class VoteAdmin(admin.ModelAdmin):
    """ Модель голоса пользователя за конкретную инициативу. """
    list_display = ("initiative", "user", "vote", "voted_at")
    list_filter = ("vote",)
    search_fields = ("initiative__id", "user__username")


@admin.register(Alumni)
class AlumniAdmin(admin.ModelAdmin):
    """ Модель выпускников школы с информацией о карьере. """
    list_display = (
        "full_name",
        "display_name",
        "graduation_year",
        "institution",
        "position",
        "added_by",
        "added_at",
    )
    list_filter = ("graduation_year", "display_name",)
    search_fields = ("full_name", "institution", "position")


@admin.register(ParentClub)
class ParentClubAdmin(admin.ModelAdmin):
    """ Модель для обсуждений в родительском клубе. """
    list_display = ("section", "author", "created_at")
    list_filter = ("section",)
    search_fields = ("content",)


@admin.register(TheaterRole)
class TheaterRoleAdmin(admin.ModelAdmin):
    """ Модель для распределения ролей в театральных мероприятиях. """
    list_display = ("role", "event", "user", "status")
    list_filter = ("status",)
    search_fields = ("role",)


@admin.register(SafetyTrain)
class SafetyTrainAdmin(admin.ModelAdmin):
    """ Модель для тренингов по безопасности. """
    list_display = ("id", "author", "created_at")
    search_fields = ("description",)


@admin.register(ParentSchoolEvent)
class ParentSchoolEventAdmin(admin.ModelAdmin):
    """ Модель событий, организованных в рамках родительской школы. """
    list_display = ("title", "event_date", "organizer")
    search_fields = ("title",)


@admin.register(ParentSchoolRegistration)
class ParentSchoolRegistrationAdmin(admin.ModelAdmin):
    """ Модель регистрации пользователей на события родительской школы. """
    list_display = ("user", "event", "status", "registered_at")
    list_filter = ("status", "event")
    search_fields = ("user__username", "event__title")


@admin.register(MuseumTask)
class MuseumTaskAdmin(admin.ModelAdmin):
    """ Модель заданий для школьного музея. """
    list_display = ("id", "status", "proposed_by", "created_at")
    list_filter = ("status",)
    search_fields = ("task",)


@admin.register(File)
class FileAdmin(admin.ModelAdmin):
    """ Модель для прикрепления файлов к мероприятиям. """
    list_display = ("event", "file_type", "uploaded_at")
    search_fields = ("file_url",)


@admin.register(Suggestion)
class SuggestionAdmin(admin.ModelAdmin):
    """ Модель предложений по улучшению платформы от пользователей. """
    list_display = ('author', 'screen_source', 'content', 'created_at', 'is_reviewed')
    list_filter = ('screen_source', 'is_reviewed', 'created_at')
    search_fields = ('content', 'author__username')
    list_editable = ('is_reviewed',)