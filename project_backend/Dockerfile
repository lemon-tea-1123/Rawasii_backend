FROM dart:stable AS build
WORKDIR /app

# Install Dart Frog CLI
RUN dart pub global activate dart_frog_cli
ENV PATH="$PATH:/root/.pub-cache/bin"

# Copy pubspec first
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN dart pub get

# Copy everything else
COPY . .

# Run pub get again to make sure everything is resolved
RUN dart pub get --no-precompile

# Build
RUN dart_frog build

# Get dependencies for built output
WORKDIR /app/build
RUN dart pub get

FROM dart:stable
WORKDIR /app
COPY --from=build /app/build .
EXPOSE 8080
CMD ["dart", "bin/server.dart"]
