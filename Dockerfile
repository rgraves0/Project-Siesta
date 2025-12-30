FROM python:3.12-slim AS base

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Kolkata \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /usr/src/app

# လိုအပ်တဲ့ packages များသွင်းခြင်း
RUN apt-get update -qq && \
    apt-get install -qq -y ffmpeg gcc libffi-dev curl unzip && \
    rm -rf /var/lib/apt/lists/*

# Build stage (rclone အတွက်)
FROM base AS builder
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    curl -O https://downloads.rclone.org/v1.68.2/rclone-v1.68.2-linux-${ARCH}.zip && \
    unzip rclone-v1.68.2-linux-${ARCH}.zip && \
    install -m 755 rclone-v1.68.2-linux-${ARCH}/rclone /usr/bin/rclone

# Final stage
FROM base AS final

COPY --from=builder /usr/bin/rclone /usr/bin/rclone

# Requirements သွင်းခြင်း
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Source code အားလုံးကို ကူးခြင်း
COPY . .

# Folder များ ကြိုဆောက်ပြီး Permission အပြည့်ပေးခြင်း (Railway fix)
RUN mkdir -p /usr/src/app/bot/DOWNLOADS && \
    mkdir -p /usr/src/app/bot/DOWNLOADS-temp && \
    chmod -R 777 /usr/src/app/bot

# Railway က PORT ကို သုံးတတ်လို့ လိုအပ်ရင် PORT environment variable ပေးထားပါ
ENV PORT=8080

ENTRYPOINT ["python", "-m", "bot"]
