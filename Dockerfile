# --- STAGE 1: The Builder ---
FROM ubuntu:22.04 AS builder

ENV ANDROID_HOME="/opt/android-sdk" \
    FLUTTER_HOME="/opt/flutter" \
    PATH="$PATH:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/flutter/bin"

RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa openjdk-17-jdk wget \
    && rm -rf /var/lib/apt/lists/*

# Install Android SDK
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O android-tools.zip && \
    unzip -q android-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm android-tools.zip && \
    yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Install Flutter 3.38.0 (Updated to match your workflow)
RUN wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.38.0-stable.tar.xz -O flutter.tar.xz && \
    tar xf flutter.tar.xz -C /opt && rm flutter.tar.xz

# Fix ownership issues before running Flutter commands
RUN git config --global --add safe.directory /opt/flutter && \
    git config --global --add safe.directory /build-temp

WORKDIR /build-temp

# Clone and populate all Gradle/Pub caches
RUN git clone https://github.com/gmanpro/wavemart-app.git . && \
    flutter config --no-analytics && \
    flutter pub get && \
    flutter build apk --release

# --- STAGE 2: The Final Slim Image ---
FROM ubuntu:22.04

ENV ANDROID_HOME="/opt/android-sdk" \
    FLUTTER_HOME="/opt/flutter" \
    PATH="$PATH:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/flutter/bin"

RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/android-sdk /opt/android-sdk
COPY --from=builder /opt/flutter /opt/flutter
COPY --from=builder /root/.pub-cache /root/.pub-cache
COPY --from=builder /root/.gradle /root/.gradle

# Ensure the final image also trusts the Flutter directory
RUN git config --global --add safe.directory /opt/flutter

WORKDIR /app
