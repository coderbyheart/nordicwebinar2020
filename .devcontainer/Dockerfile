FROM mcr.microsoft.com/vscode/devcontainers/javascript-node:14

RUN wget https://github.com/jgm/pandoc/releases/download/2.10.1/pandoc-2.10.1-1-amd64.deb && \
    sudo dpkg -i pandoc-2.10.1-1-amd64.deb && \
    pandoc -v