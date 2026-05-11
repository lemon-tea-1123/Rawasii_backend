FROM dart:stable AS build
WORKDIR /app

# Install Dart Frog CLI
RUN dart pub global activate dart_frog_cli
ENV PATH="$PATH:/root/.pub-cache/bin"

# Get dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy everything
COPY . .

# This generates bin/server.dart automatically
RUN dart_frog build

# Get dependencies for built server
WORKDIR /app/build
RUN dart pub get

FROM dart:stable
WORKDIR /app
COPY --from=build /app/build .
EXPOSE 8080
CMD ["dart", "bin/server.dart"]
