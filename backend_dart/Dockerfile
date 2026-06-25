# Stage 1: Build
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# Stage 2: Final Runtime
FROM debian:bookworm-slim
WORKDIR /app
COPY --from=build /app/bin/server /app/bin/server

EXPOSE 8000

CMD ["/app/bin/server"]
