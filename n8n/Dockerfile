FROM node:22-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        chromium \
        ca-certificates \
        fonts-freefont-ttf \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g n8n playwright

RUN useradd --create-home --shell /bin/bash nodeuser

USER nodeuser

CMD ["n8n"]
