# Use latest stable Debian slim image as base
FROM debian:stable-slim

ARG \
    NVM_VERSION="0.40.3" \
    # Defaults to latest LTS Node.js version
    NODE_VERSION="lts/*" \
    # Defaults to latest stable Python version
    PYTHON_VERSIONS=""

ENV \
    # Prevent interactive prompts during apt package installation
    DEBIAN_FRONTEND="noninteractive"

# Load custom configuration files
COPY ./shell-config/.zshrc /root/.zshrc
COPY ./shell-config/p10k.zsh /root/.p10k.zsh
COPY ./shell-config/xterm-ghostty.terminfo /tmp/

# Install essential tools
RUN apt-get update && apt-get -y install --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    less \
    openssh-client \
    ripgrep \
    tree \
    wget \
    zsh \
    # Install GitHub CLI, which isn't in Debian default repos (https://github.com/cli/cli/blob/trunk/docs/install_linux.md)
    && wget -nv -O /etc/apt/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install gh -y \
    # Clean apt cache and package lists (saves ~20-50MB, which is trivial, but demonstrates apt caching behavior)
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # Set zsh as the default shell for root user
    && chsh -s /bin/zsh root \
    # Install Oh My Zsh and plugins (--depth=1 option and value: only clones the latest commit, reducing image size)
    && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" \
    && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting \
    # Install Node Version Manager (nvm), initialize nvm, and install selected Node.js version
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash \
    && bash -c "source $HOME/.nvm/nvm.sh && nvm install $NODE_VERSION" \
    # Install uv, source uv environment variables, and install Python version(s)
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && . $HOME/.local/bin/env \
    && uv python install ${PYTHON_VERSIONS} \
    # Install latest stable Neovim (https://github.com/neovim/neovim/blob/master/INSTALL.md)
    && curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz \
    && tar -C /opt -xzf nvim-linux-arm64.tar.gz \
    && rm nvim-linux-arm64.tar.gz \
    # Load Ghostty terminal info (https://ghostty.org/docs/help/terminfo) and clean up
    && tic -x /tmp/xterm-ghostty.terminfo \
    && rm /tmp/xterm-ghostty.terminfo