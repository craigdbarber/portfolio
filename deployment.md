# GCP Cloud Run Deployment Strategy

This document outlines the strategy for deploying the static Vite portfolio to Google Cloud Platform (GCP) using a containerized approach (Cloud Run). This strategy balances low cost (leveraging the massive Cloud Run free tier) with professional engineering signals (demonstrating containerization and immutable infrastructure).

## 1. Core Configuration Files

This project uses a containerized architecture optimized for security and performance. The primary configuration files are:

*   **[.dockerignore](./.dockerignore):** Ensures local artifacts (like `node_modules`) aren't uploaded to the cloud, speeding up builds.
*   **[nginx.conf.template](./nginx.conf.template):** A dynamic Nginx server block that supports the `$PORT` variable injected by Cloud Run.
*   **[Dockerfile](./Dockerfile):** A multi-stage build that compiles assets and serves them via a hardened, non-root Nginx runtime.

---

## 2. Local Verification (DevOps Best Practice)

Before deploying to the cloud, a Senior engineer verifies the container locally to ensure the build and Nginx configuration are correct.

**Build the image locally:**
```bash
docker build -t portfolio:local .
```

**Run the container:**
```bash
docker run -p 8080:8080 portfolio:local
```

**Verify Health:**
The container includes a dedicated health check endpoint. You can verify the server is ready by visiting `http://localhost:8080/healthz`.

---

## 3. CI/CD with GitHub Actions

The professional standard for L5 engineers is automated delivery. This project includes a workflow in `.github/workflows/deploy.yml` that uses **Workload Identity Federation (WIF)**. This allows GitHub to authenticate with GCP without the need for long-lived Service Account JSON keys.

### Configuring Workload Identity Federation (Step-by-Step)

Follow these steps to authorize your GitHub repository to deploy to your GCP project:

#### 1. Create a Service Account
Create a dedicated service account that the GitHub Actions workflow will "impersonate."
```bash
gcloud iam service-accounts create "github-actions-deployer" \
  --display-name="GitHub Actions Deployer"
```

#### 2. Grant Necessary Roles
Assign roles to the service account so it can build images and deploy to Cloud Run.
```bash
# Grant Cloud Run Admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.admin"

# Grant Artifact Registry Writer
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Grant Cloud Build Editor
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.editor"

# Grant Service Account User (required to deploy as the SA)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Grant Service Usage Consumer (required to call APIs and upload source to Cloud Build)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageConsumer"

# Grant Storage access to upload code
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"
```

#### 3. Create Workload Identity Pool and Provider
```bash
# Create the Pool
gcloud iam workload-identity-pools create "github-pool" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Get the Pool ID
export POOL_ID=$(gcloud iam workload-identity-pools describe "github-pool" \
  --location="global" --format="value(name)")

# Create the OIDC Provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Actions Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository_owner == 'craigdbarber'" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

#### 4. Bind the GitHub Repo to the Service Account
This is the most critical security step. Replace `YOUR_ORG/YOUR_REPO` with your actual GitHub path (e.g., `craigdbarber/portfolio`).
```bash
gcloud iam service-accounts add-iam-policy-binding "github-actions-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/YOUR_ORG/YOUR_REPO"
```

#### 5. Add GitHub Secrets
In your GitHub repository, go to **Settings > Secrets and variables > Actions** and add:
- `GCP_PROJECT_ID`: Your project ID.
- `GCP_WIF_PROVIDER`: The full path to the provider (format: `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider`).
- `GCP_WIF_SERVICE_ACCOUNT`: `github-actions-deployer@$PROJECT_ID.iam.gserviceaccount.com`

---

## 4. Manual Deployment (Using Google Cloud CLI)

While CI/CD is preferred, you can deploy manually using these steps:

**Step 1: Set Environment Variables**
```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"
export REPO_NAME="portfolio-repo"
export IMAGE_NAME="web"

gcloud config set project $PROJECT_ID
```

**Step 2: Enable Required APIs**
```bash
gcloud services enable run.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com
```

**Step 3: Create an Artifact Registry Repository**
```bash
gcloud artifacts repositories create $REPO_NAME \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository for personal portfolio"
```

**Step 4: Build using Cloud Build**
```bash
gcloud builds submit \
  --tag $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:latest
```

**Step 5: Deploy to Cloud Run**
```bash
gcloud run deploy portfolio-web \
  --image $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:latest \
  --region $REGION \
  --allow-unauthenticated \
  --max-instances 2 \
  --memory 256Mi
```

---

## 5. Custom Domain Configuration

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

## 6. Cost Analysis

Because we limited the memory to `256Mi` and `max-instances` to 2, this configuration ensures you stay well within the generous GCP Free Tier.

- **Cloud Run:** Free for the first 2 million requests and 360,000 GB-seconds per month. (Estimated Cost: $0.00/mo).
- **Artifact Registry:** $0.10 per GB per month. A lightweight Nginx Alpine image is ~20MB. (Estimated Cost: ~$0.01/mo).
- **Network Egress:** Standard GCP tier pricing, negligible for a static portfolio.
- **Total Estimated Cost:** < $0.10 / month.
