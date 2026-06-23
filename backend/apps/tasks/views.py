from rest_framework import status, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from django.db.models import Count, Q
from django.utils import timezone

from utils.cache import cached
from apps.governance.services import create_notification, create_audit_log, notify_users

from .models import Task, Bid, Question, Category, Skill, TaskView
from .serializers import (
    TaskListSerializer, TaskDetailSerializer, TaskCreateSerializer,
    BidListSerializer, BidDetailSerializer, BidCreateSerializer,
    QuestionSerializer, QuestionCreateSerializer,
    CategorySerializer, SkillSerializer,
)


from django.utils.text import slugify

@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def category_list(request):
    if request.method == 'GET':
        categories = Category.objects.filter(is_active=True, parent=None)
        serializer = CategorySerializer(categories, many=True)
        return Response(serializer.data)
    
    elif request.method == 'POST':
        if not request.user.is_authenticated or request.user.role != 'ADMIN':
            return Response({"error": "Only admins can create categories"}, status=status.HTTP_403_FORBIDDEN)
        
        name = request.data.get('name')
        if not name:
            return Response({"error": "Name is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        base_slug = slugify(name)
        slug = base_slug
        counter = 1
        while Category.objects.filter(slug=slug).exists():
            counter += 1
            slug = f"{base_slug}-{counter}"
            
        parent_id = request.data.get('parent_id')
        parent = None
        if parent_id:
            try:
                parent = Category.objects.get(id=parent_id)
            except Category.DoesNotExist:
                return Response({"error": "Parent category not found"}, status=status.HTTP_400_BAD_REQUEST)
                
        category = Category.objects.create(
            name=name,
            slug=slug,
            description=request.data.get('description', ''),
            icon=request.data.get('icon', ''),
            parent=parent
        )
        return Response(CategorySerializer(category).data, status=status.HTTP_201_CREATED)


@api_view(['PATCH', 'DELETE'])
@permission_classes([IsAuthenticated])
def category_detail(request, category_id):
    if request.user.role != 'ADMIN':
        return Response({"error": "Only admins can delete categories"}, status=status.HTTP_403_FORBIDDEN)
    
    try:
        category = Category.objects.get(id=category_id)
    except Category.DoesNotExist:
        return Response({"error": "Category not found"}, status=status.HTTP_404_NOT_FOUND)
        
    if request.method == 'DELETE':
        category.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    data = request.data
    if 'name' in data:
        category.name = data['name'].strip() or category.name
        if 'slug' not in data or not str(data.get('slug', '')).strip():
            category.slug = slugify(category.name)
    if 'slug' in data and str(data['slug']).strip():
        category.slug = slugify(str(data['slug']).strip())
    if 'description' in data:
        category.description = data['description']
    if 'icon' in data:
        category.icon = data['icon']
    if 'is_active' in data:
        category.is_active = bool(data['is_active'])
    if 'order' in data:
        category.order = int(data['order'] or 0)
    if 'parent_id' in data:
        parent_id = data.get('parent_id')
        if parent_id:
            try:
                category.parent = Category.objects.get(id=parent_id)
            except Category.DoesNotExist:
                return Response({"error": "Parent category not found"}, status=status.HTTP_400_BAD_REQUEST)
        else:
            category.parent = None
    category.save()
    return Response(CategorySerializer(category).data)

@api_view(['GET'])
@permission_classes([AllowAny])
@cached("skills", ttl=600)
def skill_list(request):
    category_slug = request.query_params.get('category')
    skills = Skill.objects.all()
    if category_slug:
        skills = skills.filter(category__slug=category_slug)
    serializer = SkillSerializer(skills, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([AllowAny])
def task_list(request):
    tasks = Task.objects.select_related('client', 'category').filter(status='open')

    category = request.query_params.get('category')
    if category:
        tasks = tasks.filter(category__slug=category)

    city = request.query_params.get('city')
    if city:
        tasks = tasks.filter(city__icontains=city)

    budget_min = request.query_params.get('budget_min')
    if budget_min:
        tasks = tasks.filter(budget_max__gte=budget_min)

    budget_max = request.query_params.get('budget_max')
    if budget_max:
        tasks = tasks.filter(budget_min__lte=budget_max)

    urgency = request.query_params.get('urgency')
    if urgency:
        tasks = tasks.filter(urgency=urgency)

    search = request.query_params.get('q')
    if search:
        tasks = tasks.filter(Q(title__icontains=search) | Q(description__icontains=search))

    sort = request.query_params.get('sort', '-created_at')
    if sort == 'newest':
        tasks = tasks.order_by('-created_at')
    elif sort == 'budget_high':
        tasks = tasks.order_by('-budget_max')
    elif sort == 'budget_low':
        tasks = tasks.order_by('budget_min')
    else:
        tasks = tasks.order_by('-created_at')

    page = int(request.query_params.get('page', 1))
    limit = int(request.query_params.get('limit', 20))
    start = (page - 1) * limit
    end = start + limit
    total = tasks.count()

    serializer = TaskListSerializer(tasks[start:end], many=True)
    return Response({
        'results': serializer.data,
        'total': total,
        'page': page,
        'limit': limit,
        'total_pages': (total + limit - 1) // limit,
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def task_create(request):
    serializer = TaskCreateSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        task = serializer.save()
        create_audit_log(
            actor=request.user,
            action="task_created",
            entity_type="task",
            entity_id=task.id,
            summary=task.title,
            metadata={"status": task.status, "category_id": task.category_id},
            ip_address=request.META.get("REMOTE_ADDR"),
        )
        create_notification(
            user=request.user,
            category="task",
            title=f"Task drafted: {task.title}",
            body="Your task draft has been saved and is ready for review.",
            link=f"/dashboard/client/tasks/{task.id}",
            metadata={"task_id": task.id},
        )
        return Response(TaskDetailSerializer(task).data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PATCH', 'DELETE'])
@permission_classes([AllowAny])
def task_detail(request, task_id):
    try:
        task = Task.objects.select_related('client', 'category').prefetch_related('bids__technician', 'questions__asker', 'attachments', 'skills').get(id=task_id)
    except Task.DoesNotExist:
        return Response({"error": "Task not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        ip = request.META.get('HTTP_X_FORWARDED_FOR', request.META.get('REMOTE_ADDR', '')).split(',')[0].strip()
        if ip:
            _, created = TaskView.objects.get_or_create(task=task, viewer_ip=ip)
            if created:
                task.views_count = task.task_views.count()
                task.save(update_fields=['views_count'])
        serializer = TaskDetailSerializer(task)
        return Response(serializer.data)

    elif request.method == 'PATCH':
        if request.user != task.client:
            return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)
        serializer = TaskCreateSerializer(task, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(TaskDetailSerializer(task).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        if request.user != task.client:
            return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)
        task.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def task_bids(request, task_id):
    try:
        task = Task.objects.get(id=task_id)
    except Task.DoesNotExist:
        return Response({"error": "Task not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        accepted_bids = task.bids.select_related('technician').filter(status='accepted')
        bids = accepted_bids if accepted_bids.exists() else task.bids.select_related('technician').all()
        serializer = BidListSerializer(bids, many=True)
        return Response(serializer.data)

    elif request.method == 'POST':
        if not request.user.is_authenticated:
            return Response({"error": "Authentication required"}, status=status.HTTP_401_UNAUTHORIZED)
        if request.user.role != 'TECHNICIAN':
            return Response({"error": "Only technicians can submit bids"}, status=status.HTTP_403_FORBIDDEN)
        if task.status != 'open' or task.bids.filter(status='accepted').exists():
            return Response({"error": "This task is no longer accepting bids"}, status=status.HTTP_400_BAD_REQUEST)
        if Bid.objects.filter(task=task, technician=request.user).exclude(status='withdrawn').exists():
            return Response(
                {"error": "You already have an active bid on this task. Withdraw it first to submit a new one."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        serializer = BidCreateSerializer(data=request.data, context={'request': request, 'task': task})
        if serializer.is_valid():
            try:
                bid = serializer.save()
            except Exception as e:
                return Response({"error": "Could not submit bid. Please try again."}, status=status.HTTP_400_BAD_REQUEST)
            create_audit_log(
                actor=request.user,
                action="bid_created",
                entity_type="bid",
                entity_id=bid.id,
                summary=f"Bid on {task.title}",
                metadata={"task_id": task.id, "amount": str(bid.amount), "amount_type": bid.amount_type},
                ip_address=request.META.get("REMOTE_ADDR"),
            )
            create_notification(
                user=task.client,
                category="bid",
                title=f"New bid on {task.title}",
                body=f"{request.user.get_full_name() or request.user.email} submitted a bid.",
                link=f"/dashboard/client/tasks/{task.id}/proposals",
                metadata={"task_id": task.id, "bid_id": bid.id},
            )
            return Response(BidDetailSerializer(bid).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def bid_detail(request, bid_id):
    try:
        bid = Bid.objects.select_related('technician', 'task__client').get(id=bid_id)
    except Bid.DoesNotExist:
        return Response({"error": "Bid not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = BidDetailSerializer(bid)
        return Response(serializer.data)

    elif request.method == 'PATCH':
        new_status = request.data.get('status')
        if new_status not in ['accepted', 'rejected']:
            return Response({"error": "Invalid status"}, status=status.HTTP_400_BAD_REQUEST)

        if request.user != bid.task.client:
            return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)

        bid.status = new_status
        if new_status == 'accepted':
            bid.accepted_at = timezone.now()
            bid.task.status = 'in_progress'
            bid.task.assigned_to = bid.technician
            bid.task.save(update_fields=['status', 'assigned_to'])
            create_notification(
                user=bid.technician,
                category="bid",
                title=f"Bid accepted: {bid.task.title}",
                body="Your bid was accepted and the task is now in progress.",
                link=f"/dashboard/technician/tasks/{bid.task.id}",
                metadata={"task_id": bid.task.id, "bid_id": bid.id},
            )
        elif new_status == 'rejected':
            bid.rejected_at = timezone.now()
            create_notification(
                user=bid.technician,
                category="bid",
                title=f"Bid rejected: {bid.task.title}",
                body="Your bid was not selected this time.",
                link=f"/dashboard/technician/tasks/{bid.task.id}",
                metadata={"task_id": bid.task.id, "bid_id": bid.id},
            )
        bid.save()
        create_audit_log(
            actor=request.user,
            action="bid_updated",
            entity_type="bid",
            entity_id=bid.id,
            summary=f"{new_status.title()} bid on {bid.task.title}",
            metadata={"task_id": bid.task.id, "status": new_status},
            ip_address=request.META.get("REMOTE_ADDR"),
        )

        return Response(BidDetailSerializer(bid).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_bids(request):
    bids = Bid.objects.filter(technician=request.user).select_related('task__client', 'task__category')
    status_filter = request.query_params.get('status')
    if status_filter:
        bids = bids.filter(status=status_filter)
    serializer = BidListSerializer(bids, many=True)
    return Response(serializer.data)


@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def task_questions(request, task_id):
    try:
        task = Task.objects.get(id=task_id)
    except Task.DoesNotExist:
        return Response({"error": "Task not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        questions = task.questions.select_related('asker', 'replied_by').all()
        serializer = QuestionSerializer(questions, many=True)
        return Response(serializer.data)

    elif request.method == 'POST':
        if not request.user.is_authenticated:
            return Response({"error": "Authentication required"}, status=status.HTTP_401_UNAUTHORIZED)
        serializer = QuestionCreateSerializer(data=request.data, context={'request': request, 'task': task})
        if serializer.is_valid():
            serializer.save()
            return Response(QuestionSerializer(serializer.instance).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_tasks(request):
    tasks = (
        Task.objects
        .filter(client=request.user)
        .select_related('category', 'assigned_to')
        .annotate(accepted_bids_count=Count('bids', filter=Q(bids__status='accepted')))
    )
    status_filter = request.query_params.get('status')
    if status_filter:
        tasks = tasks.filter(status=status_filter)
    serializer = TaskListSerializer(tasks, many=True)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def task_publish(request, task_id):
    try:
        task = Task.objects.get(id=task_id)
    except Task.DoesNotExist:
        return Response({"error": "Task not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.user != task.client:
        return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)
    if task.status != 'draft':
        return Response({"error": f"Task is already {task.status}"}, status=status.HTTP_400_BAD_REQUEST)

    task.status = 'open'
    task.published_at = timezone.now()
    task.save(update_fields=['status', 'published_at'])
    create_audit_log(
        actor=request.user,
        action="task_published",
        entity_type="task",
        entity_id=task.id,
        summary=task.title,
        metadata={"status": task.status},
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    create_notification(
        user=request.user,
        category="task",
        title=f"Task published: {task.title}",
        body="Your task is now visible to professionals.",
        link=f"/dashboard/client/tasks/{task.id}",
        metadata={"task_id": task.id},
    )
    return Response(TaskDetailSerializer(task).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def task_complete(request, task_id):
    try:
        task = Task.objects.get(id=task_id)
    except Task.DoesNotExist:
        return Response({"error": "Task not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.user != task.client and request.user.role != 'ADMIN':
        accepted_bid = Bid.objects.filter(task=task, technician=request.user, status='accepted').exists()
        if not accepted_bid:
            return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)
    if task.status not in ['in_progress', 'open']:
        return Response({"error": f"Cannot complete a {task.status} task"}, status=status.HTTP_400_BAD_REQUEST)

    task.status = 'completed'
    task.save(update_fields=['status'])
    if task.client:
        create_notification(
            user=task.client,
            category="task",
            title=f"Task completed: {task.title}",
            body="The task has been marked completed.",
            link=f"/dashboard/client/tasks/{task.id}",
            metadata={"task_id": task.id},
        )
    if task.assigned_to:
        create_notification(
            user=task.assigned_to,
            category="task",
            title=f"Task completed: {task.title}",
            body="The client marked the task as completed.",
            link=f"/dashboard/technician/tasks/{task.id}",
            metadata={"task_id": task.id},
        )
    create_audit_log(
        actor=request.user,
        action="task_completed",
        entity_type="task",
        entity_id=task.id,
        summary=task.title,
        metadata={"status": task.status},
        ip_address=request.META.get("REMOTE_ADDR"),
    )

    return Response(TaskDetailSerializer(task).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def task_cancel(request, task_id):
    try:
        task = Task.objects.get(id=task_id)
    except Task.DoesNotExist:
        return Response({"error": "Task not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.user != task.client and request.user.role != 'ADMIN':
        return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)
    if task.status in ['completed', 'cancelled']:
        return Response({"error": f"Task is already {task.status}"}, status=status.HTTP_400_BAD_REQUEST)

    task.status = 'cancelled'
    task.save(update_fields=['status'])
    if task.client:
        create_notification(
            user=task.client,
            category="task",
            title=f"Task cancelled: {task.title}",
            body="The task has been cancelled.",
            link=f"/dashboard/client/tasks/{task.id}",
            metadata={"task_id": task.id},
        )
    if task.assigned_to:
        create_notification(
            user=task.assigned_to,
            category="task",
            title=f"Task cancelled: {task.title}",
            body="The task was cancelled by the client or admin.",
            link=f"/dashboard/technician/tasks/{task.id}",
            metadata={"task_id": task.id},
        )
    create_audit_log(
        actor=request.user,
        action="task_cancelled",
        entity_type="task",
        entity_id=task.id,
        summary=task.title,
        metadata={"status": task.status},
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    return Response(TaskDetailSerializer(task).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bid_withdraw(request, bid_id):
    try:
        bid = Bid.objects.get(id=bid_id)
    except Bid.DoesNotExist:
        return Response({"error": "Bid not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.user != bid.technician:
        return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)
    if bid.status != 'pending':
        return Response({"error": f"Cannot withdraw a {bid.status} bid"}, status=status.HTTP_400_BAD_REQUEST)
    if bid.task.status != 'open':
        return Response({"error": "Task is no longer open"}, status=status.HTTP_400_BAD_REQUEST)

    bid.status = 'withdrawn'
    bid.save(update_fields=['status'])
    create_audit_log(
        actor=request.user,
        action="bid_withdrawn",
        entity_type="bid",
        entity_id=bid.id,
        summary=f"Withdrawn from {bid.task.title}",
        metadata={"task_id": bid.task.id},
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    return Response(BidDetailSerializer(bid).data)
