# Use latest stable Debian slim image as base
FROM debian:stable-slim

# Fix for corporate network hash sum mismatches
RUN printf "Acquire::http::Pipeline-Depth 0;\nAcquire::http::No-Cache true;\nAcquire::BrokenProxy true;" > /etc/apt/apt.conf.d/99fixbadproxy

ARG \
    NEOVIM_CONFIG_URL="https://github.com/Vakarva/nvim" \
    NVM_VERSION="0.40.3" \
    # Defaults to latest LTS Node.js version
    NODE_VERSION="lts/*" \
    # Defaults to latest stable Python version
    PYTHON_VERSIONS=""

ENV \
    # Prevent interactive prompts during apt package installation
    DEBIAN_FRONTEND="noninteractive"

# Load custom configuration files
COPY ./shell-config/xterm-ghostty.terminfo /tmp/

# Install essential tools
RUN apt-get update && apt-get -y install --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    fzf \
    git \
    gpg \
    less \
    openssh-client \
    # Python for system installs
    python3 \
    python3-venv \
    ripgrep \
    tmux \
    unzip \
    wget \
    zsh \
    # Install GitHub CLI, which isn't in Debian default repos (https://github.com/cli/cli/blob/trunk/docs/install_linux.md)
    && wget -nv -O /etc/apt/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install gh -y \
    # Install eza
    && wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list \
    && chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list \
    && apt-get update \
    && apt-get install -y eza \
    # Clean apt cache and package lists (saves ~20-50MB)
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # Set zsh as the default shell for root user
    && chsh -s /bin/zsh root \
    # Download zsh and tmux configurations
    && curl -fsSL https://raw.githubusercontent.com/Vakarva/dotfiles/main/zsh/.p10k.zsh -o /root/.p10k.zsh \
    && curl -fsSL https://raw.githubusercontent.com/Vakarva/dotfiles/main/zsh/.zshrc -o /root/.zshrc \
    && curl -fsSL https://raw.githubusercontent.com/Vakarva/dotfiles/main/tmux/.tmux.conf -o /root/.tmux.conf \
    # Download tpm and run plugin installer
    && git clone --depth 1 https://github.com/tmux-plugins/tpm /root/.config/tmux/plugins/tpm \
    && /root/.config/tmux/plugins/tpm/bin/install_plugins \
    # Install Node Version Manager (nvm), initialize nvm, and install selected Node.js version
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash \
    && bash -c "source $HOME/.nvm/nvm.sh && nvm install $NODE_VERSION && npm i -g @anthropic-ai/claude-code" \
    # Install uv, source uv environment variables, and install Python version(s)
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && . $HOME/.local/bin/env \
    && uv python install ${PYTHON_VERSIONS} \
    # Install latest stable Neovim directly to ~/opt and symlink to ~/.local/bin (https://github.com/neovim/neovim/blob/master/INSTALL.md)
    && mkdir -p /root/.local/bin \
    && curl -L https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz | tar -xz -C /opt \
    && ln -sf /opt/nvim-linux-arm64/bin/nvim /root/.local/bin/nvim \
    # Download Neovim configuration
    && git clone --depth 1 ${NEOVIM_CONFIG_URL} /root/.config/nvim \
    # Load Ghostty terminal info (https://ghostty.org/docs/help/terminfo) and clean up
    && tic -x /tmp/xterm-ghostty.terminfo \
    && rm /tmp/xterm-ghostty.terminfo
