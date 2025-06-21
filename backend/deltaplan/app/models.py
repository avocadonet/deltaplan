from django.db import models
from django.core.validators import RegexValidator
from django.contrib.auth.models import AbstractUser


class User(AbstractUser):
    """ Кастомная модель пользователя с добавлением ролей (админ, учитель, родитель, студент). """
    ROLE_CHOICES = [
        ("admin", "Admin"),
        ("teacher", "Teacher"),
        ("parent", "Parent"),
        ("student", "Student"),
    ]

    username = models.CharField(max_length=50, unique=True)
    password_hash = models.CharField(max_length=100)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default="student")
    
    created_by = models.ForeignKey(
        "self",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="created_users",
    )
    full_name = models.CharField(max_length=100, blank=True, null=True)
    email = models.EmailField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.username


class EventCategory(models.Model):
    """ Категории для мероприятий (например, "Спорт", "Наука", "Искусство"). """
    name = models.CharField(max_length=50, unique=True)

    def __str__(self):
        return self.name


class Event(models.Model):
    """ Основная модель для школьных мероприятий. Может быть как полноценным событием, так и просто 'идеей'. """
    STATUS_CHOICES = [
        ("upcoming", "Upcoming"),
        ("completed", "Completed"),
    ]

    category = models.ForeignKey(
        EventCategory, on_delete=models.PROTECT, related_name="events"
    )
    title = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    start_date = models.DateTimeField(blank=True, null=True)
    end_date = models.DateTimeField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES)
    rules = models.TextField(blank=True, null=True)
    location = models.CharField(max_length=100, blank=True, null=True)
    is_idea = models.BooleanField(default=False)
    initiator = models.ForeignKey(
        User,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="initiated_events",
    )

    def __str__(self):
        return self.title


class EventApplication(models.Model):
    """ Заявка пользователя на участие в мероприятии. Хранит статус (одобрена, отклонена). """
    STATUS_CHOICES = [
        ("pending", "В ожидании"),
        ("approved", "Одобрена"),
        ("rejected", "Отклонена"),
    ]

    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="applications"
    )
    event = models.ForeignKey(
        Event, on_delete=models.CASCADE, related_name="applications"
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    applied_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "event")

    def __str__(self):
        return f"{self.user} -> {self.event} ({self.status})"


class Initiative(models.Model):
    """ Инициативы, предлагаемые пользователями. Проходят стадии подачи, голосования и утверждения. """
    PERIOD_VALIDATOR = RegexValidator(
        regex=r"^\d{4}-(09|01)$", message="Period must be in YYYY-09 or YYYY-01 format."
    )
    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("approved", "Approved"),
        ("rejected", "Rejected"),
    ]

    author = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="initiatives"
    )
    description = models.TextField()
    submission_period = models.CharField(max_length=7, validators=[PERIOD_VALIDATOR])
    voting_start = models.DateField(blank=True, null=True)
    voting_end = models.DateField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    votes_for = models.IntegerField(default=0)
    votes_against = models.IntegerField(default=0)

    def __str__(self):
        return f"Initiative {self.id} by {self.author}"


class Vote(models.Model):
    """ Запись о голосе пользователя за или против инициативы. Один пользователь - один голос. """
    initiative = models.ForeignKey(
        Initiative, on_delete=models.CASCADE, related_name="votes"
    )
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="votes")
    vote = models.BooleanField()
    voted_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("initiative", "user")

    def __str__(self):
        return f"{self.user} voted {'for' if self.vote else 'against'} initiative {self.initiative.id}"


class Alumni(models.Model):
    """ Информация о выпускниках школы. Записи проходят модерацию (статус pending/approved/rejected). """
    STATUS_CHOICES = [
        ("pending", "На рассмотрении"),
        ("approved", "Одобрено"),
        ("rejected", "Отклонено"),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending", verbose_name="Статус")
    full_name = models.CharField(max_length=150, blank=True, null=True, verbose_name="ФИО выпускника")
    display_name = models.BooleanField(default=True, verbose_name="Отображать ФИО в списке")
    graduation_year = models.IntegerField(blank=True, null=True)
    institution = models.CharField(max_length=100, blank=True, null=True)
    position = models.CharField(max_length=100, blank=True, null=True)
    photo_url = models.URLField(max_length=200, blank=True, null=True)
    added_by = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="added_alumni"
    )
    added_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.full_name or f"Alumni record {self.id}"


class ParentClub(models.Model):
    """ Записи в родительском клубе, разделенные по секциям. Возможна анонимная публикация. """
    SECTION_CHOICES = [
        ("professions_day", "Professions Day"),
        ("heroes", "Heroes"),
        ("patrol", "Patrol"),
    ]
    section = models.CharField(max_length=50, choices=SECTION_CHOICES)
    content = models.TextField()
    author = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="club_entries"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    is_anonymous = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.section} by {self.author}"


class TheaterRole(models.Model):
    """ Роли в театральных постановках, привязанные к конкретному мероприятию Event. """
    STATUS_CHOICES = [
        ("open", "Open"),
        ("assigned", "Assigned"),
    ]
    event = models.ForeignKey(
        Event, on_delete=models.CASCADE, related_name="theater_roles"
    )
    role = models.CharField(max_length=50)
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="theater_roles",
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')

    def __str__(self):
        return f"{self.role} ({self.status})"


class SafetyTrain(models.Model):
    """ Модель для тренингов по безопасности. """
    description = models.TextField()
    author = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="safety_trains"
    )
    participation_details = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Safety Train {self.id}"


class ParentSchoolEvent(models.Model):
    """ Мероприятия в рамках проекта 'Школа для родителей'. """
    title = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    event_date = models.DateTimeField(blank=True, null=True)
    organizer = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="organized_parent_school_events",
    )

    def __str__(self):
        return self.title


class ParentSchoolRegistration(models.Model):
    """ Заявка на участие в мероприятии 'Школы для родителей'. """
    STATUS_CHOICES = [
        ("pending", "В ожидании"),
        ("approved", "Одобрена"),
        ("rejected", "Отклонена"),
    ]
    event = models.ForeignKey(
        ParentSchoolEvent, on_delete=models.CASCADE, related_name="registrations"
    )
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="parent_school_registrations"
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    registered_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("event", "user")

    def __str__(self):
        return f"{self.user} registered for {self.event}"


class MuseumTask(models.Model):
    """ Задачи для проекта 'Наш музей', предлагаемые пользователями. """
    STATUS_CHOICES = [
        ("active", "Active"),
        ("completed", "Completed"),
    ]
    task = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="active")
    proposed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="museum_tasks",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Museum Task {self.id}: {self.status}"


class File(models.Model):
    """ Модель для прикрепленных к мероприятиям файлов. """
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name="files")
    file_url = models.URLField(max_length=200)
    file_type = models.CharField(max_length=50)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"File {self.id} for {self.event}"
    

class Suggestion(models.Model):
    """ Предложения по улучшению сайта от пользователей, собранные с определенных экранов. """
    SCREEN_CHOICES = [
        ('museum', 'Наш музей'),
        ('theater', 'Школьный театр'),
        ('safety_train', 'Поезд безопасности'),
        ('parents_school_topic', 'Школа для родителей (Тема)'),
        ('parents_school_experience', 'Школа для родителей (Опыт)'),
    ]
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='suggestions')
    content = models.TextField(verbose_name="Содержание предложения")
    screen_source = models.CharField(max_length=50, choices=SCREEN_CHOICES, verbose_name="Источник (экран)")
    created_at = models.DateTimeField(auto_now_add=True)
    is_reviewed = models.BooleanField(default=False, verbose_name="Рассмотрено")

    def __str__(self):
        return f"Предложение от {self.author.username} с экрана '{self.get_screen_source_display()}'"