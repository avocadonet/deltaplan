# Файл: backend/deltaplan/app/management/commands/seed_db.py

import datetime
from django.core.management.base import BaseCommand
from django.utils import timezone
from app.models import (
    User, EventCategory, Event, ParentSchoolEvent, Alumni,
    ParentClub, SafetyTrain, MuseumTask, Suggestion
)

class Command(BaseCommand):
    help = 'Заполняет базу данных начальными тестовыми данными.'

    def handle(self, *args, **kwargs):
        self.stdout.write('Начинаю очистку старых данных...')
        # Опционально: можно очищать таблицы перед заполнением,
        # но это опасно для связанных данных. Лучше использовать get_or_create.
        # Например: User.objects.filter(is_superuser=False).delete()

        self.stdout.write('Создание тестовых данных...')
        
        # --- 1. Создание пользователей ---
        self.stdout.write('-> Создание пользователей...')
        admin_user = self.create_superuser()
        teacher_user = self.create_user('teacher1', 'teacher1@deltaplan.dev', 'teacher', 'Марья Ивановна', 'Марья', 'Ивановна', 'teacherpass123')
        parent_user = self.create_user('parent1', 'parent1@deltaplan.dev', 'parent', 'Иванов Иван Иванович', 'Иван', 'Иванов', 'parentpass123')
        student_user1 = self.create_user('student1', 'student1@deltaplan.dev', 'student', 'Петров Петр', 'Петр', 'Петров', 'studentpass123')
        student_user2 = self.create_user('student2', 'student2@deltaplan.dev', 'student', 'Сидорова Анна', 'Анна', 'Сидорова', 'studentpass123')
        users = [admin_user, teacher_user, parent_user, student_user1, student_user2]

        # --- 2. Создание категорий мероприятий ---
        self.stdout.write('-> Создание категорий...')
        category_names = ["Спорт", "Наука", "Искусство", "Волонтерство", "Патриотизм"]
        categories = [EventCategory.objects.get_or_create(name=name)[0] for name in category_names]

        # --- 3. Создание мероприятий ---
        self.stdout.write('-> Создание мероприятий...')
        event_titles = ["Школьная спартакиада", "Научная конференция 'Юный Эрудит'", "Весенний концерт", "Субботник в парке", "Урок Мужества"]
        for i in range(5):
            Event.objects.get_or_create(
                title=event_titles[i],
                defaults={
                    'category': categories[i],
                    'description': f'Подробное описание мероприятия "{event_titles[i]}".',
                    'start_date': timezone.now() + datetime.timedelta(days=10 + i),
                    'status': 'upcoming',
                    'location': f'Актовый зал / Спортплощадка {i+1}',
                    'initiator': users[i % len(users)]
                }
            )
        
        # --- 4. Создание мероприятий "Школы для родителей" ---
        self.stdout.write('-> Создание мероприятий "Школы для родителей"...')
        pse_titles = ["Лекция о кибербезопасности", "Как помочь ребенку с выбором профессии", "Психология подростка", "Семинар по ЗОЖ", "Собрание родительского комитета"]
        for i in range(5):
            ParentSchoolEvent.objects.get_or_create(
                title=pse_titles[i],
                defaults={
                    'description': f'Описание для "{pse_titles[i]}".',
                    'event_date': timezone.now() + datetime.timedelta(days=30 + i),
                    'organizer': teacher_user
                }
            )

        # --- 5. Создание записей о выпускниках ---
        self.stdout.write('-> Создание записей о выпускниках...')
        alumni_names = ["Сергеев Сергей", "Кузнецова Ольга", "Попов Дмитрий", "Новикова Елена", "Морозов Алексей"]
        for i in range(5):
            Alumni.objects.get_or_create(
                full_name=alumni_names[i],
                defaults={
                    'status': 'approved',
                    'graduation_year': 2010 + i,
                    'institution': 'МГУ' if i % 2 == 0 else 'СПбГУ',
                    'position': 'Инженер' if i % 2 == 0 else 'Менеджер',
                    'added_by': parent_user
                }
            )

        # --- 6. Создание записей в "Родительском клубе" ---
        self.stdout.write('-> Создание записей в "Родительском клубе"...')
        sections = [choice[0] for choice in ParentClub.SECTION_CHOICES]
        for i in range(5):
            ParentClub.objects.get_or_create(
                author=parent_user,
                section=sections[i % len(sections)],
                defaults={'content': f'Интересный пост №{i+1} в разделе "{sections[i % len(sections)]}".'}
            )
        
        # ... (Аналогично можно добавить и остальные модели: SafetyTrain, MuseumTask, Suggestion)

        self.stdout.write(self.style.SUCCESS('База данных успешно заполнена тестовыми данными!'))

    def create_superuser(self):
        if not User.objects.filter(username='admin').exists():
            user = User.objects.create_superuser('admin', 'admin@deltaplan.dev', 'adminpass123')
            user.full_name = "Администратор Проекта"
            user.save()
            return user
        return User.objects.get(username='admin')

    def create_user(self, username, email, role, full_name, first_name, last_name, password):
        user, created = User.objects.get_or_create(
            username=username,
            defaults={
                'email': email, 'role': role, 'full_name': full_name,
                'first_name': first_name, 'last_name': last_name
            }
        )
        if created:
            user.set_password(password)
            user.save()
        return user