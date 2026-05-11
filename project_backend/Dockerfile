FROM dart:stable AS build

WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY . .

RUN dart pub run build_runner build --delete-conflicting-outputs
RUN dart compile exe bin/server.dart -o bin/server

FROM debian:stable-slim
WORKDIR /app
COPY --from=build /app/bin/server ./bin/server

EXPOSE 8080
CMD ["./bin/server"]