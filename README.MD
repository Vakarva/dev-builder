# Development Container Builder <!-- omit in toc -->

**A container for development with Neovim, Node.js, Python, and Zsh.**

This repository contains instructions for creating a containerized development environment that utilizes Neovim as its IDE, includes both Node.js and Python runtimes, and a nicely configured Zsh for the shell. It's designed as a starting point for projects that need these languages in a consistent, reproducible environment.

## Table of Contents <!-- omit in toc -->

-   [1. What's Inside?](#1-whats-inside)
-   [2. Prerequisites](#2-prerequisites)
-   [3. Setup](#3-setup)
    -   [3.1. Download](#31-download)
    -   [3.2. Configure `compose.yml`](#32-configure-composeyml)
    -   [3.3. (Optional) Font Installation](#33-optional-font-installation)
    -   [3.4. Running the Container](#34-running-the-container)
    -   [3.5. Exiting the Development Container](#35-exiting-the-development-container)
-   [4. You're In! Now What?](#4-youre-in-now-what)
    -   [4.1. Node.js](#41-nodejs)
    -   [4.2. Python](#42-python)
    -   [4.3. Terminal](#43-terminal)
-   [5. Customization](#5-customization)
    -   [5.1. Container Configuration](#51-container-configuration)
    -   [5.2. Shell Configuration](#52-shell-configuration)
-   [6. Troubleshooting](#6-troubleshooting)

## 1. What's Inside?

-   [Debian](https://www.debian.org)-Slim operating system
-   [Git](https://git-scm.com)
-   [GitHub CLI](https://cli.github.com)
-   [OpenSSH](https://www.openssh.com) client (for SSH agent forwarding to use host's Git credentials)
-   [curl](https://curl.se) & [Wget](https://www.gnu.org/software/wget/)
-   [ca-certificates](https://packages.debian.org/sid/ca-certificates) (for secure HTTPS connections and package downloads)
-   [Neovim](https://neovim.io) (IDE)
-   [Node.js](https://nodejs.org/) managed by [nvm](https://github.com/nvm-sh/nvm)
-   [Python](https://www.python.org) managed by [uv](https://docs.astral.sh/uv/)
-   [Zsh](https://www.zsh.org) with:
    -   [oh my zsh](https://ohmyz.sh) with [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) and [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) plugins
    -   [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme

## 2. Prerequisites

-   [Podman](https://podman.io) / [Docker](https://www.docker.com)

## 3. Setup

### 3.1. Download

`cd` into a suitable parent directory and clone this repository:

```sh
git clone https://github.com/Vakarva/dev-builder.git
cd dev-builder
```

### 3.2. Configure `compose.yml`

Make sure to configure your timezone (`TZ`), the terminal you're using (`TERM`), and any specific versions you want of Node.js and Python (latest are installed by default).

A persistent `workspace` volume is created/used. Change this according to your needs. This volume is managed by the container runtime (Podman/Docker) and maps to storage on the host system, ensuring data persists independently of container lifecycle. The volume contents remain available even when containers are stopped, removed, or recreated.

Your local `~/.gitconfig` file and `~/.ssh` directory are mounted as read-only into the container so that you can use Git and SSH as you've configured on your local machine. Additionally, your Neovim configuration (`~/.config/nvim`) is mounted with read-write access to both preserve your editor settings and allow you to modify them from within the container. Change the source paths of these mounts to match your local machine's file system structure.

### 3.3. (Optional) Font Installation

1. Install MesloLGS NF fonts ([Powerlevel10k's recommended font-family](https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#fonts)) from the `fonts/` directory if you do not already have them installed on your local machine:

    - **macOS**: Double-click each `.ttf` file and click "Install"
    - **Windows**: Right-click each `.ttf` file and select "Install"
    - **Linux**: Copy to `/usr/share/fonts/truetype/` and run `fc-cache -fv`

2. You can delete the `fonts/` directory, if you'd like

### 3.4. Running the Container

There are many ways to do this. We'll list two. First, `cd` into your `dev-builder/` directory.

#### Option 1: Temporary Container (Auto-removes on Exit): <!-- omit in toc -->

```sh
# Build the image
podman build -t dev-env -f Containerfile .

# Start the container (will automatically be removed when you exit)
podman compose run --name dev-container --rm dev zsh
```

#### Option 2: Persistent Container: <!-- omit in toc -->

##### Start the Environment <!-- omit in toc -->

```sh
# Build the image and start the container in detached mode
podman compose up --build -d

# Access the running container
podman compose exec dev zsh
```

##### Stop the Environment <!-- omit in toc -->

```sh
# Remove the container
podman compose down
```

_Note: Containerization platforms cache build images to save on build time. So if your Containerfile has not changed, your container will reuse the cached image. For this reason, if you have not modified your Containerfile (in particular, any instructions prior to any installations in the `Containerfile`): at some point in the future you will notice that your container is running older versions of packages (which were current when the image was first built). If you'd like to use the newest ones, rebuild your image._

### 3.5. Exiting the Development Container

To exit, you can run `exit` or press `Ctrl+D` in your container's zsh instance.

Remember, your container's fate is decided by your startup method. Did you use `compose up`? Then it will persist until you explicitly `compose down`. Did you set the `--rm` remove flag via `run`? Then your container will be stopped and removed. You can check active containers via `podman ps` or `docker ps`. Use the `-a` flag to view _all_ containers, both active and inactive.

## 4. You're In! Now What?

### 4.1. Node.js

By default, the latest LTS version of Node.js is installed by nvm. You can choose a specific version by passing a `NODE_VERSION` argument to the container build or write one into the `compose.yml` file.

You can read more about using nvm in the [nvm documentation](https://github.com/nvm-sh/nvm#readme). The `node` alias is available in the terminal.

### 4.2. Python

By default, the latest stable version of Python is installed by uv. You can choose Python versions by passing a `PYTHON_VERSIONS` argument (in the same ways as mentioned for Node.js). Note that you can install multiple Python versions by separating each version by a space: (ex: `"PYTHON_VERSIONS": "3.9 3.10 3.13"`).

While nvm adds `node` directly to your PATH, uv uses a different approach in which Python runs through the `uv` command. Read more about using uv in the [uv documentation](https://docs.astral.sh/uv/).

### 4.3. Terminal

Zsh loads automatically with all enhancements active.

## 5. Customization

### 5.1. Container Configuration

Edit the following files to customize the development container to your specific needs:

-   `Containerfile` - Add/remove packages or otherwise modify the image

-   `compose.yml` - The environment the container runs in (env variables, volumes, etc.)

### 5.2. Shell Configuration

-   `.devcontainer/shell-config/.zshrc` - Customize Zsh behavior

-   `.devcontainer/shell-config/p10k.zsh` - Configure Powerlevel10k theme

## 6. Troubleshooting

### My Terminal looks weird <!-- omit in toc -->

Powerlevel10k has been pre-configured via the `shell-config/p10k.zsh` file and it's very possible that this pre-configuration looks bad with your terminal emulator. Run the `p10k configure` command in a Zsh instance (from within your container) to set up Powerlevel10k's theme from scratch. Then rewrite `shell-config/p10k.zsh` in this repository with your new Powerlevel10k configuration (found at `/root/.p10k.zsh` in the container), so that your changes persist across container rebuilds.
