# Use the slim Linux base
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install bare minimum tools
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils openjdk-17-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

# 2. Setup Android CMD-Line Tools
ENV ANDROID_SDK_ROOT=/opt/android-sdk
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    curl -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip cmdline-tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    rm cmdline-tools.zip

# 3. Setup Flutter (Only the stable branch, no history)
ENV FLUTTER_HOME=/opt/flutter
RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git $FLUTTER_HOME

# 4. Set Paths
ENV PATH="$PATH:$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools"

# 5. Accept Android Licenses
RUN yes | sdkmanager --licenses

WORKDIR /app
