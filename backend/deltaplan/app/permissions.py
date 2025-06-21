from rest_framework.permissions import BasePermission, SAFE_METHODS

class IsAdminOrReadOnly(BasePermission):
    """ Доступ: Просмотр всем, редактирование - только администраторам. """
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True
        return request.user and request.user.is_staff

class IsAdmin(BasePermission):
    """ Доступ: Только для администраторов. """
    def has_permission(self, request, view):
        return request.user and request.user.is_staff

class IsTeacher(BasePermission):
    """ Доступ: Только для учителей. """
    def has_permission(self, request, view):
        return request.user and request.user.role == 'teacher'

class IsAdminOrTeacher(BasePermission):
    """ Доступ: Только для администраторов и учителей. """
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.is_staff or request.user.role == 'teacher'

class IsOwnerOrReadOnly(BasePermission):
    """ Доступ к объекту: Просмотр всем, редактирование - только владельцу. """
    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        owner = getattr(obj, 'author', None) or getattr(obj, 'user', None) or getattr(obj, 'added_by', None)
        return owner == request.user

class IsOwner(BasePermission):
    """ Доступ к объекту: Только для владельца. """
    def has_object_permission(self, request, view, obj):
        owner = getattr(obj, 'author', None) or getattr(obj, 'user', None) or getattr(obj, 'added_by', None)
        return owner == request.user

class IsOwnerOrAdminOrTeacher(BasePermission):
    """ Доступ к объекту: Просмотр всем, редактирование - владельцу, администратору или учителю. """
    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True 
        
        if not request.user.is_authenticated:
            return False
        
        if request.user.is_staff or request.user.role == 'teacher':
            return True
            
        owner = getattr(obj, 'author', None) or getattr(obj, 'user', None) or getattr(obj, 'added_by', None)
        return owner == request.user

class CanCreateButNotEditAllExceptAdmin(BasePermission):
    """ Доступ: Создание - всем авторизованным, редактирование - владельцу или администратору. """
    def has_permission(self, request, view):
        return request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        if request.user and request.user.is_staff:
            return True
        
        owner = getattr(obj, 'author', None) or getattr(obj, 'user', None) or getattr(obj, 'added_by', None)
        return owner == request.user

# === Классы прав для конкретных моделей ===

class CanVote(BasePermission):
    """ Голосование: Просмотр - всем авторизованным, голосовать - не студентам. """
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.method in SAFE_METHODS:
            return True
        return request.user.role in ['admin', 'teacher', 'parent']

class CanCreateInitiative(BasePermission):
    """ Инициативы: Просмотр - всем авторизованным, создание - не студентам. """
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.method in SAFE_METHODS:
            return True
        return request.user.role in ['admin', 'teacher', 'parent']

class CanAccessParentClub(BasePermission):
    """ Доступ к ParentClub: Просмотр - всем авторизованным, создание - не студентам. """
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.method in SAFE_METHODS:
            return True
        return request.user.role in ['admin', 'teacher', 'parent']