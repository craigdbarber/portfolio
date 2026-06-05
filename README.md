# Craig Barber | Professional Portfolio

A high-performance, minimalist personal portfolio designed for technical recruiters and hiring managers at Big Tech companies. This site showcases the engineering career of Craig Barber, focusing on cloud infrastructure, developer tooling, and technical leadership.

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Development](#development)
  - [Linting](#linting)
  - [Building for Production](#building-for-production)
  - [Deployment](#deployment)
- [Configuration](#configuration)
- [License](#license)

---

## Overview

The portfolio is designed with a "Google-tier" aesthetic: clean, typography-driven, and impact-focused. It utilizes the "XYZ Formula" to highlight measurable accomplishments, such as managing systems with 4 billion+ quarterly API requests and securing 220,000+ cloud VMs.

## Tech Stack

- **Build Tool:** [Vite](https://vitejs.dev/)
- **Styling:** [Tailwind CSS v4](https://tailwindcss.com/)
- **Language:** HTML5, Vanilla JavaScript (ES6+)
- **Typography:** Inter (via Google Fonts)
- **Linting:** [ESLint](https://eslint.org/) (JavaScript) and [HTMLHint](https://htmlhint.com/) (HTML)

## Infrastructure (Cloud-Native)

This project is architected for high reliability and security using modern GCP best practices:
- **Compute:** [Google Cloud Run](https://cloud.google.com/run) (Serverless / Auto-scaling)
- **Containerization:** Multi-stage Docker build with a **non-root Nginx** hardened runtime.
- **CI/CD:** [GitHub Actions](https://github.com/features/actions) with **Workload Identity Federation** for secure, keyless authentication.
- **Security:** Implements **Least Privilege** principles and graceful shutdown handling.
- **Delivery:** Immutable infrastructure with automated rollouts.

## System Architecture

The following diagrams illustrate the design principles applied to this project:

- **[Private Query Architecture](./public/private-query-arch.svg):** Demonstrates locally-hosted RAG platform design for data sovereignty.
- **[Bazel Python Architecture](./public/bazel-python-arch.svg):** Shows the hermetic build pattern for Python microservices.
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

## Getting Started

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

The output will be generated in the `dist/` directory, ready to be deployed to any static hosting provider (GitHub Pages, Netlify, Vercel, etc.).

### Deployment

For a detailed, low-cost GCP-native deployment strategy using **Cloud Run** and **Docker**, see:
👉 [**GCP Deployment Strategy (deployment.md)**](./deployment.md)

## Configuration

### Customizing Styles

Global styles and Tailwind theme overrides (colors, fonts) are located in `src/style.css`:

```css
@theme {
  --color-google-blue: #4285F4;
  --font-sans: "Inter", ...;
}
```

### Updating Content

The primary content resides in `index.html`. It is structured into semantic sections:
- `#experience`: Professional history with measurable impact.
- `#projects`: Deep dives into specific technical contributions.
- `#leadership`: Public speaking and community engagement.
- `#skills`: Categorized technical proficiencies.

## License

This project is private and intended for personal portfolio use.
