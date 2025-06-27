from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from app import views
from django.conf import settings
from django.conf.urls.static import static
from rest_framework_simplejwt.views import TokenRefreshView
from app.views import MyTokenObtainPairView

router = DefaultRouter()

router.register(r"users", views.UserViewSet)
router.register(r"categories", views.EventCategoryViewSet)
router.register(r"initiatives", views.InitiativeViewSet)
router.register(r"votes", views.VoteViewSet)
router.register(r"theater-roles", views.TheaterRoleViewSet)
router.register(r"safety-trains", views.SafetyTrainViewSet)
router.register(r"parent-school-events", views.ParentSchoolEventViewSet)
router.register(r"museum-tasks", views.MuseumTaskViewSet)

router.register(r"events", views.EventViewSet, basename='event')
router.register(r"applications", views.EventApplicationViewSet, basename='eventapplication')
router.register(r"alumni", views.AlumniViewSet, basename='alumni')
router.register(r"parent-club", views.ParentClubViewSet, basename='parentclub')
router.register(r"suggestions", views.SuggestionViewSet, basename='suggestion')
router.register(r"files", views.FileViewSet, basename='file')
router.register(r"parent-school-registrations", views.ParentSchoolRegistrationViewSet, basename='parentschoolregistration')


urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/register/", views.RegisterView.as_view(), name="register"),
    path("api/token/", MyTokenObtainPairView.as_view(), name="token_obtain_pair"),    
    path("api/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("api/my-applications/", views.MyApplicationsView.as_view(), name="my-applications"),
    path("api/calendar-events/", views.CalendarEventsView.as_view(), name="calendar-events"),
    path("api/", include(router.urls)),
]   

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)