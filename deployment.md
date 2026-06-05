# GCP Cloud Run Deployment Strategy

This document outlines the strategy for deploying the static Vite portfolio to Google Cloud Platform (GCP) using a containerized approach (Cloud Run). This strategy balances low cost (leveraging the massive Cloud Run free tier) with professional engineering signals (demonstrating containerization and immutable infrastructure).

## 1. The Configuration Files

Create these three files in the root of your project:

### File 1: `.dockerignore`
This ensures you don't upload your massive local `node_modules` folder to GCP, drastically speeding up the build.
```text
node_modules
dist
.env
.git
```

### File 2: `nginx.conf.template`
Standard Nginx configurations hardcode port 80. By using a template, the `nginx:alpine` image will automatically swap `${PORT}` with the port Cloud Run assigns at runtime.
```nginx
server {
    # Cloud Run expects the container to listen on $PORT
    listen ${PORT};
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        
        # Fallback routing for Single Page Applications
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets for high performance
    location ~* \.(?:ico|css|js|gif|jpe?g|png|woff2?|eot|otf|ttf|svg|pdf)$ {
        root /usr/share/nginx/html;
        expires 6M;
        access_log off;
        add_header Cache-Control "public";
    }
}
```

### File 3: `Dockerfile`
This multi-stage build first compiles your Vite code using Node.js, and then transfers only the compiled, minified static files (`/dist`) into a tiny, highly secure Nginx server.
```dockerfile
# Stage 1: Build the static assets
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Serve via Nginx
FROM nginx:alpine
# Copy the template. Nginx alpine natively processes templates ending in .template using envsubst
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
# Copy the built Vite assets from Stage 1
COPY --from=builder /app/dist /usr/share/nginx/html

# Cloud Run defaults to 8080. Expose it for local testing as well.
EXPOSE 8080
ENV PORT=8080
```

---

## 2. The Deployment Steps (Using Google Cloud CLI)

Make sure you have the `gcloud` CLI installed and authenticated (`gcloud auth login`). Then, follow these steps in your terminal:

**Step 1: Set your Project ID and Region**
```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"
gcloud config set project $PROJECT_ID
```

**Step 2: Enable Required APIs**
Cloud Run needs these services turned on to build and host your container.
```bash
gcloud services enable run.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com
```

**Step 3: Create an Artifact Registry Repository**
This is where your built Docker images will be securely stored.
```bash
gcloud artifacts repositories create portfolio-repo \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository for personal portfolio"
```

**Step 4: Build the Image using Cloud Build**
Instead of building Docker locally, you can offload the build to Google's servers. This packages your code and pushes it straight to the registry.
```bash
gcloud builds submit \
  --tag $REGION-docker.pkg.dev/$PROJECT_ID/portfolio-repo/web:latest
```

**Step 5: Deploy to Cloud Run**
This command takes your image and spins it up. The `--allow-unauthenticated` flag is required so the public internet can view your portfolio.
```bash
gcloud run deploy portfolio-web \
  --image $REGION-docker.pkg.dev/$PROJECT_ID/portfolio-repo/web:latest \
  --region $REGION \
  --allow-unauthenticated \
  --max-instances 2 \
  --memory 256Mi
```

---

## 3. Custom Domain Configuration

Once your service is live, you'll likely want to point a custom domain (e.g., `craigdbarber.com`) to it. GCP provides two main ways to do this:

### Option A: Cloud Run Domain Mapping (Easiest)
*Note: This feature is in "Limited Preview" and is only available in specific regions.*

1. In the GCP Console, go to **Cloud Run** > **Manage Custom Domains**.
2. Click **Add Mapping**.
3. Select your service (`portfolio-web`) and enter your domain name.
4. Update your DNS provider (e.g., Namecheap, Google Domains, Cloudflare) with the **CNAME** or **A** records provided by GCP.
5. GCP will automatically provision and renew an SSL certificate for you.

### Option B: Firebase Hosting as a Proxy (Recommended for Free Tier SSL)
Firebase Hosting can act as a global CDN and SSL termination point for Cloud Run.

1. Initialize Firebase in your project: `firebase init hosting`.
2. Select "Configure as a rewrites to Cloud Run".
3. Point your domain to Firebase. This gives you global edge caching and free SSL without the "Load Balancer tax" mentioned earlier.

---

## 4. Cost Analysis

Because we limited the memory to `256Mi` and `max-instances` to 2, this configuration ensures you stay well within the generous GCP Free Tier.

- **Cloud Run:** Free for the first 2 million requests and 360,000 GB-seconds per month. (Estimated Cost: $0.00/mo).
- **Artifact Registry:** $0.10 per GB per month. A lightweight Nginx Alpine image is ~20MB. (Estimated Cost: ~$0.01/mo).
- **Network Egress:** Standard GCP tier pricing, negligible for a static portfolio.
- **Total Estimated Cost:** < $0.10 / month.
