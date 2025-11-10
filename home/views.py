from django.shortcuts import render
from . models import *
# Create your views here.

def home_page(request):
    nms=sampledb.objects.all()
    return render(request,'home.html')