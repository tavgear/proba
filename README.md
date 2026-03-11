# Unistack Template

**Unistack Template** is a ready-to-go boilerplate for fast building and deploying modern web applications. The template combines a powerful **Symfony** Backend, a flexible **Next.js** Frontend, and a high-performance **FrankenPHP** server (based on Caddy). All components are Dockerized and ready for automated deployment via GitHub Actions.

## 1. Creating a Repository
1. Go to the [tavgear/unistack-template](https://github.com/tavgear/unistack-template) template page.
2. Click **Use this template** -> **Create a new repository**.
3. Specify your repository name — this will be your `PROJECT_NAME`.
   - *Example: `myproject`*

## 2. Server Configuration (Host)
1. Create a working directory on the server for your project.
   - *Example command:* `mkdir -p /home/devuser/myproject`
2. Copy the `.env` file from the repository root to this directory.
3. Edit `.env` for **Production** mode.

### Mandatory Parameters:
These values must be set exactly as shown for production operation:
- `MODE=prod`
- `MODE_NODE_ENV=production`

### Customizable Parameters (Examples):
- `PROJECT_NAME=myproject` — must match your repository name.
- `GITHUB_USER_NAME=devuser` — your GitHub username.
- `DOMAIN=mysite.org` — your site's domain.
- *Also, configure the database (MariaDB) parameters according to your requirements.*

## 3. GitHub Actions Setup
In your repository settings (**Settings -> Secrets and variables -> Actions**), add the following variables:

### "Repository variables" Section:
- `PROJECT_DIR`: Absolute path to the project folder on the server.
  - *Example: `/home/devuser/myproject`*
- `DOMAIN`: Host domain.
  - *Example: `mysite.org`*

### "Repository secrets" Section:
- `DEV_SSH_KEY`: Private part of the SSH key for server access (add the public part to `~/.ssh/authorized_keys` on the server).
- `DEV_USER`: Username on the server.
  - *Example: `devuser`*

## 4. Local Development
1. Clone the created repository to your local machine:
   ```bash
   git clone git@github.com:<YOUR_GITHUB_LOGIN>/<PROJECT_NAME>.git
   cd <PROJECT_NAME>
   ```
2. Initialize the project (download Symfony and Next.js skeletons):
   ```bash
   make init
   ```
3. Edit a `.env.local` file in the project root and specify basic variables (the same as on the server):
   - `PROJECT_NAME`
   - `GITHUB_USER_NAME`
   - *If necessary, add other local settings, overriding values from the main `.env`.*

4. Build and run the containers:
   ```bash
   make build
   make up
   ```

## 5. Deployment
To trigger the deployment, simply push your changes to the `main` branch:
```bash
git push origin main
```
GitHub Actions will automatically build Docker images, push them to the Registry, and update the project on the server.

**Project URLs after deployment:**
- **Frontend:** `https://<YOUR_DOMAIN>`
- **Backend (API):** `https://<YOUR_DOMAIN>/api/`
