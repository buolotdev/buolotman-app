# Backend Deployment Guide (Render / Railway)

This guide shows you how to deploy your Boulot Man Dart Shelf backend to the cloud so your mobile app can access it from any IP address.

## Option 1: Deploying to Render (Recommended & Free)

1. **Sign Up / Log In**: Go to [Render](https://render.com) and log in with your GitHub account.
2. **Create Web Service**:
   * Click **New** -> **Web Service**.
   * Select your GitHub repository: `buolotman-app`.
3. **Configure Settings**:
   * **Name**: `buolot-man-backend` (or any name you like).
   * **Region**: Choose a region close to your database (e.g., Frankfurt/London if Neon is in eu-west-2).
   * **Branch**: `main`
   * **Root Directory**: `backend_dart`
   * **Runtime**: Select **Docker** (Render will automatically read the `Dockerfile` inside `backend_dart`).
   * **Instance Type**: **Free**
4. **Configure Environment Variables**:
   * Click **Advanced** -> **Add Environment Variable**.
   * Add `DATABASE_URL` and set its value to your Neon PostgreSQL connection string (the `postgresql://...` URI).
5. **Deploy**:
   * Click **Create Web Service**. 
   * Render will build the Docker container and start your server at a public URL (e.g., `https://buolot-man-backend.onrender.com`).

---

## Option 2: Deploying to Railway (Fastest)

1. **Sign Up**: Go to [Railway.app](https://railway.app) and log in with GitHub.
2. **Create Project**:
   * Click **New Project** -> **Deploy from GitHub repository**.
   * Choose `buolotman-app`.
3. **Configure Service**:
   * Set the root directory/sub-folder configuration to `backend_dart`.
   * Under **Variables**, add `DATABASE_URL` with your Neon PostgreSQL connection string.
4. **Deploy**: Railway will build the Dockerfile and expose a public domain (e.g., `https://buolot-man-backend.up.railway.app`).

---

## Updating the Mobile App URL

Once deployed, change the backend IP override inside your app to the new domain (without the `http://` prefix if using raw IP override, or update the default `baseUrl` in `lib/api_service.dart` to match your new HTTPS URL).
