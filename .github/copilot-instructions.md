# Copilot Instructions for tricloud-www

## Project Overview
This is a personal portfolio website for Craig Simpson, a cloud architect/engineer. It's a **static HTML + CSS website** deployed automatically via GitHub Pages (primary deployment) and optionally packaged as a Docker image for manual releases.

**Key principle**: Keep it simple. This is intentionally a lightweight, static site—no build tools, no frameworks, no JavaScript complexity.

## Architecture & Deployment Flow

### Primary Path: GitHub Pages (Automatic)
- **Trigger**: Push to `main` branch
- **Workflow**: `.github/workflows/static.yml`
- **What it does**: Uploads the entire repository root to GitHub Pages
- **Deployment URL**: https://tricloud.tech (via GitHub Pages)
- **Files served**: `index.html`, `stylesheet.css`, and everything in `docs/`

**Key constraint**: Since the entire repo is uploaded, ensure:
- All changes to HTML/CSS are production-ready on commit
- No build step—what's in the repo is what's deployed
- Test locally before pushing to `main`

### Secondary Path: Docker Release (Manual)
- **Trigger**: Workflow dispatch OR push with semver tags (e.g., `1.0.0`)
- **Workflow**: `.github/workflows/docker-build-v2.yml`
- **Image**: Publishes to Docker Hub as `scaffa/overcast-www` (note: uses old name "overcast")
- **Base**: Nginx serving files from `/usr/share/nginx/html`
- **Build context**: Dockerfile copies `/maverix-theme` directory (⚠️ currently not present in repo—likely historical artifact)

**Note**: Docker workflow is secondary and manual. Focus on GitHub Pages automation first.

## File Structure & Purpose

```
.
├── index.html              # Main portfolio page (141 lines, inline styles)
├── stylesheet.css          # Minimal external styles (image sizing rules)
├── Dockerfile              # Nginx container definition
├── docs/assets/            # Static assets (profile pic, CV PDFs, favicon)
│   └── pics/
├── .github/workflows/       # CI/CD automation
│   ├── static.yml          # GitHub Pages deployment
│   ├── docker-build-v2.yml # Docker image publication
│   └── docker-build.yml    # Older, unused Docker workflow
└── README.md               # Basic project description
```

## Content & Styling Conventions

### HTML Structure (`index.html`)
- **Architecture**: Single-file HTML with embedded `<style>` block (no external CSS required for core styles)
- **Theme**: Dark mode only (background: `#0e0e10`, text: `#e5e5e5`)
- **Responsive**: Mobile-first with flexbox layout; max-width 700px container
- **Fonts**: Google Fonts (Inter), Font Awesome 6.5.0 for social icons
- **Key sections**:
  - `<header>`: Profile image, name, title, summary
  - Content sections with professional background, projects, etc.
  - Social links (GitHub, LinkedIn, Instagram) using Font Awesome
  - Footer with copyright

### CSS Guidelines (`stylesheet.css`)
- Keep minimal—most styles are inline in `index.html`
- Current rule: image sizing with `max-width: 50vw` constraint
- When adding styles: prefer inline `<style>` in HTML for critical content, external CSS only for utilities

### Asset Management (`docs/assets/`)
- Profile picture: `docs/assets/pics/profile-pic.jpeg`
- Favicon: `docs/assets/pics/favicon.ico`
- PDFs: CV and projects documents (served via absolute URLs in HTML)
- All paths are **relative to site root** (not Markdown-relative)

## Development Workflow

### Local Testing
```bash
# No build step needed. Simply open in browser:
open index.html
# Or use a local server:
python3 -m http.server 8000
```

### Before Committing
1. **Visual check**: Open `index.html` in a browser (test responsive design with DevTools)
2. **Link validation**: Verify all external links (CDNs, PDFs, images) are accessible
3. **Mobile preview**: Check Font Awesome icons, flexbox layout at mobile width
4. **Git check**: Ensure only intended files are staged (avoid pushing `.DS_Store`)

### Deployment Triggers
- **To GitHub Pages**: `git push origin main` → automatic deploy via `static.yml`
- **To Docker Hub**: Create semver tag (`git tag 1.0.0 && git push origin 1.0.0`) → auto-build and publish

## Common Tasks & Patterns

### Updating Profile Content
- Edit `<header>` section in `index.html` (name, title, summary)
- Edit `<section>` for professional background, skills, projects
- Keep semantic HTML; avoid breaking the flexbox container structure

### Adding/Updating Links
- Inline links: Use `<a href="URL" target="_blank">text</a>`
- External resources: Use absolute URLs (https://) to ensure they work on hosted site
- Social icons: Add to `.social-links` div with Font Awesome classes

### Styling Changes
- For layout/typography affecting multiple elements → add to `<style>` block in `index.html`
- For one-off element styles → use inline `style` attribute
- **Color scheme locked**: Stick to dark theme palette (`#0e0e10`, `#1a1a1d`, `#e5e5e5`, `#60a5fa`)
- **Responsive breakpoints**: Mobile-first; test at 375px, 768px, and desktop widths

### Adding Assets
- Place in `docs/assets/pics/` (images) or appropriate subdirectory
- Reference in HTML with relative paths: `docs/assets/pics/filename.ext`
- Commit to repo (GitHub Pages serves from repo root)

## Secrets & Deployment Configuration

### GitHub Actions Secrets (for Docker build)
- `DOCKER_USERNAME`: Docker Hub credentials (stored in repo settings)
- `DOCKER_PASSWORD`: Docker Hub credentials (stored in repo settings)

These are only used in `docker-build-v2.yml`; GitHub Pages deployment requires no secrets.

## Known Issues & Historical Context

1. **Dockerfile bug**: References `/maverix-theme` directory which doesn't exist in repo. This is a legacy artifact from an older version. Docker builds may fail—this is expected until Dockerfile is updated.
2. **Old Docker workflow**: `docker-build.yml` exists but is unused; prefer `docker-build-v2.yml`
3. **README mismatch**: README title says "overcast-www" but project is "tricloud-www"—README is outdated

## Guidelines for AI Agents

- **Don't add complexity**: No JavaScript, no build tools, no frameworks
- **Preserve the deployment contract**: Anything you commit to `main` goes live immediately—no staging environment
- **Test locally first**: Always verify HTML/CSS changes in a browser before suggesting commits
- **Maintain dark theme**: Ensure all visual changes align with existing color palette
- **Reference URLs carefully**: Use absolute https URLs for external resources to avoid 404s on the live site
- **Keep styles simple**: Flexbox + CSS Grid for layout; inline styles for one-off tweaks
