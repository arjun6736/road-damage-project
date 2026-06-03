# Road Damage Detection and Reporting System

## Overview

Road Damage Detection and Reporting System is a full-stack application that automatically detects road damages such as potholes and cracks using the YOLOv8 object detection model. The system allows users to capture and upload road images through a Flutter mobile application, while a Django backend processes the images and stores the detected damage information along with GPS location data.

## Features

* Automated pothole and crack detection using YOLOv8
* Flutter mobile application for damage reporting
* ReactJS web-based admin dashboard
* Django REST API backend
* GPS location tracking
* Interactive map visualization for reported damages
* Real-time report management through admin panel
* Image upload and processing
* Database storage and retrieval
* Client-server architecture

## Technologies Used

### Mobile Application

* Flutter

### Web Application

* ReactJS

### Backend

* Django
* Django REST Framework

### AI/ML

* YOLOv8

### Database

* MySQL

### Tools

* Git
* GitHub
* Linux

## System Workflow

1. User captures or uploads a road image through the Flutter application.
2. GPS coordinates are collected automatically.
3. The image is sent to the Django backend through REST APIs.
4. YOLOv8 detects potholes and road cracks.
5. Detection results and location data are stored in MySQL.
6. Users can view reported damages on an interactive map in the mobile application.
7. Administrators can monitor reports, locations, and damage statistics through the ReactJS dashboard.
8. Map-based visualization helps authorities identify damage hotspots and prioritize maintenance.

## Dataset

The model was trained and evaluated using publicly available road damage datasets, including:

* RDD2022 (Road Damage Detection Dataset 2022)
* Additional road damage images sourced from Kaggle

The datasets contain annotated images of various road surface damages, including:

* Potholes
* Longitudinal Cracks
* Transverse Cracks
* Alligator Cracks

These datasets were used for model training, validation, and performance evaluation of the YOLOv8 detection model.

## Model Training

* Model: YOLOv8
* Training Data: RDD2022 + Kaggle Road Damage Datasets
* Task: Object Detection
* Output: Bounding boxes and damage classifications


## Team Information

This project was developed as part of a 4-member team during the final year B.Tech project.


