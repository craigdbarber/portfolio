# Craig Barber | Professional Portfolio

This project contains the code and deployment infrastructure for the website: [craigdbarber.net](https://craigdbarber.net). This site is a portfolio and professional profile for [Craig Barber](https://github.com/craigdbarber).

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Infrastructure](#infrastructure)
- [Deployment](#deployment)
- [Project Structure](#project-structure)
- [Setup](#setup)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Development](#development)
  - [Linting](#linting)
  - [Building for Production](#building-for-production)
  - [Deployment](#deployment)
- [Configuration](#configuration)

---

## Tech Stack

- **Build Tool:** [Vite](https://vitejs.dev/)
- **Styling:** [Tailwind CSS v4](https://tailwindcss.com/)
- **Language:** HTML5, Vanilla JavaScript (ES6+)
- **Typography:** Inter (via Google Fonts)
- **Linting:** [ESLint](https://eslint.org/) (JavaScript) and [HTMLHint](https://htmlhint.com/) (HTML)

## Infrastructure

This project is architected for high reliability and security using modern GCP best practices:
- **Compute:** [Google Cloud Run](https://cloud.google.com/run) (Serverless / Auto-scaling)
- **Containerization:** Multi-stage Docker build with a **non-root Nginx** hardened runtime.
- **CI/CD:** [GitHub Actions](https://github.com/features/actions) with **Workload Identity Federation** for secure, keyless authentication.
- **Security:** Implements **Least Privilege** principles and graceful shutdown handling.
- **Delivery:** Immutable infrastructure with automated rollouts.

## Deployment

- **Deployment Flow:** See [deployment.md](./deployment.md) for the containerized delivery pipeline on GCP.

## Project Structure

```text
.
├── dist/                # Production build output
├── public/              # Static assets (favicons, resume.pdf)
├── src/
│   ├── style.css        # Tailwind CSS entry & theme configuration
│   └── main.js          # JavaScript entry point
├── index.html           # Main semantic HTML structure
├── package.json         # Dependencies and scripts
├── tailwind.config.js   # Tailwind configuration
└── vite.config.js       # Vite configuration
```

## Setup

### Prerequisites

- [Node.js](https://nodejs.org/) (v18.0.0 or higher)
- [npm](https://www.npmjs.com/)

### Installation

Clone the repository and install the dependencies:

```bash
npm install
```

### Development

Start the local development server with Hot Module Replacement (HMR):

```bash
npm run dev
```

The site will be available at `http://localhost:5173`.

### Linting

Run the linters to ensure code quality and catch syntax errors:

```bash
# Run all linters (JS and HTML)
npm run lint

# Run only JavaScript linting
npm run lint:js

# Run only HTML linting
npm run lint:html
```

### Building for Production

To create an optimized production build (includes a linting step for HTML and JavaScript):

```bash
npm run build
```
