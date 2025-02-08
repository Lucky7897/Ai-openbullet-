#!/bin/bash
# Automated AI WebApp Installer for OpenBullet Config Generation (Non-Docker Edition)

set -e

USER="Lucky7897"
PROJECT_DIR="/home/$USER/ai_webapp"
PROJECT_NAME="ai_web"
APP_NAME="ai_model"
VENV_DIR="$PROJECT_DIR/venv"
SECRET_KEY=$(openssl rand -base64 32)

echo "🔧 Updating System..."
sudo apt update && sudo apt upgrade -y

echo "🐍 Installing Python & Dependencies..."
sudo apt install python3 python3-pip python3-venv nginx redis-server -y

echo "🌐 Setting Up Django AI WebApp..."
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR
python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate
pip install django djangorestframework numpy torch transformers gunicorn psycopg2-binary haralyzer

echo "📦 Creating Django Project..."
django-admin startproject $PROJECT_NAME
cd $PROJECT_NAME
django-admin startapp $APP_NAME

echo "⚙️ Configuring Django Settings..."
cat > $PROJECT_NAME/settings.py <<EOL
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', '$SECRET_KEY')
DEBUG = os.getenv('DJANGO_DEBUG', 'False') == 'True'
ALLOWED_HOSTS = os.getenv('DJANGO_ALLOWED_HOSTS', '*').split(',')

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'django_redis',
    '$APP_NAME',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = '$PROJECT_NAME.urls'
WSGI_APPLICATION = '$PROJECT_NAME.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://localhost:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        }
    }
}

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'static'

AUTH_PROFILE_MODULE = '$APP_NAME.UserProfile'

CELERY_BROKER_URL = 'redis://localhost:6379/0'
CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'
EOL

echo "🔧 Creating AI Model Selection Page..."
cat > $APP_NAME/models.py <<EOL
from django.db import models
from django.contrib.auth.models import User

class TrainingFile(models.Model):
    file = models.FileField(upload_to="uploads/")
    uploaded_at = models.DateTimeField(auto_now_add=True)

class AIModel(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    specs = models.TextField()

class ConfigFile(models.Model):
    file = models.FileField(upload_to="config_uploads/")
    uploaded_at = models.DateTimeField(auto_now_add=True)
    training_file = models.ForeignKey(TrainingFile, on_delete=models.CASCADE, related_name="config_files")

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    bio = models.TextField(blank=True)
    location = models.CharField(max_length=30, blank=True)
    birth_date = models.DateField(null=True, blank=True)
EOL

cat > $APP_NAME/views.py <<EOL
import json
import torch
from transformers import pipeline
from django.shortcuts import render, redirect
from django.http import JsonResponse, HttpResponse
from django.contrib.auth.decorators import login_required
from .models import TrainingFile, AIModel, ConfigFile, UserProfile
from .forms import UploadFileForm, UploadConfigFileForm, UserProfileForm
from haralyzer import HarParser

def home(request):
    models = AIModel.objects.all()
    training_files = TrainingFile.objects.all()
    return render(request, "home.html", {"models": models, "training_files": training_files})

@login_required
def upload_file(request):
    if request.method == "POST":
        form = UploadFileForm(request.POST, request.FILES)
        if form.is_valid():
            file = form.save()
            return JsonResponse({"status": "success", "file_url": file.file.url})
    return JsonResponse({"status": "failed"}, status=400)

@login_required
def upload_config_file(request):
    if request.method == "POST":
        form = UploadConfigFileForm(request.POST, request.FILES)
        if form.is_valid():
            config_file = form.save()
            return JsonResponse({"status": "success", "file_url": config_file.file.url})
    return JsonResponse({"status": "failed"}, status=400)

def ai_predict(request):
    model_name = request.GET.get("model", "gpt2")
    model = pipeline("text-generation", model=model_name)
    text = request.GET.get("text", "Hello, AI!")
    result = model(text, max_length=50)
    return JsonResponse({"response": result})

def generate_openbullet_config(request):
    model_name = request.GET.get("model", "gpt2")
    text = request.GET.get("text", "Hello, AI!")
    loliscript = f"""
BLOCK NAME="MAIN"
  SETVAR VAR="input" VALUE="{text}"
  SETVAR VAR="model" VALUE="{model_name}"
  # Add more LoliScript commands as needed
ENDBLOCK
"""
    response = HttpResponse(loliscript, content_type='text/plain')
    response['Content-Disposition'] = 'attachment; filename="config.loli"'
    return response

@login_required
def admin_page(request):
    return render(request, "admin_page.html")

@login_required
def monitoring_page(request):
    return render(request, "monitoring_page.html")

@login_required
def profile(request):
    if request.method == 'POST':
        form = UserProfileForm(request.POST, instance=request.user.userprofile)
        if form.is_valid():
            form.save()
            return redirect('profile')
    else:
        form = UserProfileForm(instance=request.user.userprofile)
    return render(request, 'profile.html', {'form': form})

@login_required
def create_config_from_har(request):
    if request.method == "POST":
        har_file = request.FILES['har_file']
        har_data = har_file.read().decode('utf-8')
        har_parser = HarParser(json.loads(har_data))
        entries = har_parser.har_data['entries']
        loliscript = "BLOCK NAME=\"MAIN\"\n"
        for entry in entries:
            request_data = entry['request']
            method = request_data['method']
            url = request_data['url']
            headers = request_data['headers']
            loliscript += f"  REQUEST METHOD=\"{method}\" URL=\"{url}\"\n"
            for header in headers:
                loliscript += f"    HEADER NAME=\"{header['name']}\" VALUE=\"{header['value']}\"\n"
        loliscript += "ENDBLOCK"
        response = HttpResponse(loliscript, content_type='text/plain')
        response['Content-Disposition'] = 'attachment; filename="config.loli"'
        return response
    return render(request, "upload_har.html")
EOL

cat > $APP_NAME/forms.py <<EOL
from django import forms
from .models import TrainingFile, ConfigFile, UserProfile

class UploadFileForm(forms.ModelForm):
    class Meta:
        model = TrainingFile
        fields = ["file"]

class UploadConfigFileForm(forms.ModelForm):
    class Meta:
        model = ConfigFile
        fields = ["file", "training_file"]

class UserProfileForm(forms.ModelForm):
    class Meta:
        model = UserProfile
        fields = ['bio', 'location', 'birth_date']
EOL

echo "🔗 Configuring URLs..."
cat > $PROJECT_NAME/urls.py <<EOL
from django.contrib import admin
from django.urls import include, path
from $APP_NAME.views import home, upload_file, upload_config_file, ai_predict, generate_openbullet_config, admin_page, monitoring_page, create_config_from_har, profile

urlpatterns = [
    path('', home, name="home"),
    path('admin/', admin.site.urls),
    path('ai/upload/', upload_file, name="upload_file"),
    path('ai/upload-config/', upload_config_file, name="upload_config_file"),
    path('ai/predict/', ai_predict, name="ai_predict"),
    path('ai/openbullet-config/', generate_openbullet_config, name="generate_openbullet_config"),
    path('admin-page/', admin_page, name="admin_page"),
    path('monitoring-page/', monitoring_page, name="monitoring_page"),
    path('accounts/', include('django.contrib.auth.urls')),
    path('profile/', profile, name='profile'),
    path('create-config-from-har/', create_config_from_har, name='create_config_from_har'),
]
EOL

echo "🎨 Creating HTML Web Interface..."
mkdir -p $APP_NAME/templates
cat > $APP_NAME/templates/home.html <<EOL
<!DOCTYPE html>
<html>
<head>
    <title>AI OpenBullet Config Generator</title>
    <link rel="stylesheet" type="text/css" href="{% static 'css/style.css' %}">
</head>
<body>
    <h1>Choose an AI Model</h1>
    <form action="/ai/predict/" method="get">
        <label for="model">Select AI Model:</label>
        <select name="model">
            {% for model in models %}
                <option value="{{ model.name }}">{{ model.name }} - {{ model.description }}</option>
            {% endfor %}
        </select>
        <input type="text" name="text" placeholder="Enter text">
        <button type="submit">Generate</button>
    </form>
    
    <h2>Upload Training File</h2>
    <form action="/ai/upload/" method="post" enctype="multipart/form-data">
        {% csrf_token %}
        <input type="file" name="file">
        <button type="submit">Upload</button>
    </form>

    <h2>Upload Configuration File</h2>
    <form action="/ai/upload-config/" method="post" enctype="multipart/form-data">
        {% csrf_token %}
        <input type="file" name="file">
        <select name="training_file">
            {% for training_file in training_files %}
                <option value="{{ training_file.id }}">{{ training_file.file.name }}</option>
            {% endfor %}
        </select>
        <button type="submit">Upload Config</button>
    </form>

    <h2>Generate OpenBullet Config</h2>
    <form action="/ai/openbullet-config/" method="get">
        <label for="model">Select AI Model:</label>
        <select name="model">
            {% for model in models %}
                <option value="{{ model.name }}">{{ model.name }} - {{ model.description }}</option>
            {% endfor %}
        </select>
        <input type="text" name="text" placeholder="Enter text">
        <button type="submit">Generate Config</button>
    </form>

    <h2>Create Config from HAR File</h2>
    <form action="/create-config-from-har/" method="post" enctype="multipart/form-data">
        {% csrf_token %}
        <input type="file" name="har_file">
        <button type="submit">Upload HAR</button>
    </form>
</body>
</html>
EOL

cat > $APP_NAME/templates/upload_har.html <<EOL
<!DOCTYPE html>
<html>
<head>
    <title>Upload HAR File</title>
    <link rel="stylesheet" type="text/css" href="{% static 'css/style.css' %}">
</head>
<body>
    <h1>Upload HAR File</h1>
    <form action="/create-config-from-har/" method="post" enctype="multipart/form-data">
        {% csrf_token %}
        <input type="file" name="har_file">
        <button type="submit">Upload HAR</button>
    </form>
</body>
</html>
EOL

cat > $APP_NAME/templates/profile.html <<EOL
<!DOCTYPE html>
<html>
<head>
    <title>Profile</title>
    <link rel="stylesheet" type="text/css" href="{% static 'css/style.css' %}">
</head>
<body>
    <h1>Profile</h1>
    <form method="post">
        {% csrf_token %}
        {{ form.as_p }}
        <button type="submit">Save</button>
    </form>
</body>
</html>
EOL

cat > $APP_NAME/templates/admin_page.html <<EOL
<!DOCTYPE html>
<html>
<head>
    <title>Admin Page</title>
    <link rel="stylesheet" type="text/css
