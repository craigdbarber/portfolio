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
This template supports **non-root execution** by moving PID and temp files to `/tmp`. This satisfies the "Least Privilege" security principle.
```nginx
pid /tmp/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    
    # Temp directories for non-root execution
    client_body_temp_path /tmp/client_temp;
    proxy_temp_path       /tmp/proxy_temp;
    fastcgi_temp_path     /tmp/fastcgi_temp;
    uwsgi_temp_path       /tmp/uwsgi_temp;
    scgi_temp_path        /tmp/scgi_temp;

    server {
        listen ${PORT};
        server_name localhost;

        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
            try_files $uri $uri/ /index.html;
        }

        # Cache static assets
        location ~* \.(?:ico|css|js|gif|jpe?g|png|woff2?|eot|otf|ttf|svg|pdf)$ {
            root /usr/share/nginx/html;
            expires 6M;
            access_log off;
            add_header Cache-Control "public";
        }
    }
}
```

### File 3: `Dockerfile`
A multi-stage build that compiles assets in Node.js and serves them via a hardened, non-root Nginx image.
```dockerfile
# Build Stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production Stage
FROM nginx:alpine
COPY nginx.conf.template /etc/nginx/templates/nginx.conf.template

# Copy assets and harden permissions
COPY --from=builder /app/dist /usr/share/nginx/html
RUN touch /tmp/nginx.pid && \
    chown -R nginx:nginx /tmp/nginx.pid /var/cache/nginx /var/log/nginx /etc/nginx/conf.d

USER nginx
STOPSIGNAL SIGQUIT
EXPOSE 8080
ENV PORT=8080
```

---

## 2. CI/CD with GitHub Actions

The professional standard for L5 engineers is automated delivery. This project includes a workflow in `.github/workflows/deploy.yml` that uses **Workload Identity Federation** (no long-lived secrets/keys).

### Prerequisites for CI/CD
1. **Workload Identity Federation:** Set up a Pool and Provider in GCP.
2. **Service Account:** Create a dedicated SA with `roles/run.admin` and `roles/artifactregistry.writer`.
3. **GitHub Secrets:** Add `GCP_PROJECT_ID`, `GCP_WIF_PROVIDER`, and `GCP_WIF_SERVICE_ACCOUNT` to your repo.

---

## 3. Manual Deployment (Using Google Cloud CLI)

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
