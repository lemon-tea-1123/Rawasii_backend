FROM dart:stable AS build
WORKDIR /app

# Install Dart Frog CLI
RUN dart pub global activate dart_frog_cli
ENV PATH="$PATH:/root/.pub-cache/bin"

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies (respects lockfile exactly)
RUN dart pub get --enforce-lockfile

# Copy rest of project
COPY . .

# Build dart frog server
RUN dart_frog build

# Get dependencies for built server
WORKDIR /app/build
RUN dart pub get

# --- Runtime stage ---
FROM dart:stable
WORKDIR /app

COPY --from=build /app/build .
COPY --from=build /root/.pub-cache /root/.pub-cache

EXPOSE 8080
CMD ["dart", "bin/server.dart"]
