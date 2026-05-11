FROM dart:stable AS build
WORKDIR /app
RUN dart pub global activate dart_frog_cli
ENV PATH="$PATH:/root/.pub-cache/bin"
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart_frog build
WORKDIR /app/build
RUN dart pub get
FROM dart:stable
WORKDIR /app
COPY --from=build /app/build .
EXPOSE 8080
CMD ["dart", "bin/server.dart"]
