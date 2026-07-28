# Build Stage
FROM dart:stable AS build
WORKDIR /app

# Copy dependency files and resolve them
COPY pubspec.* ./
RUN dart pub get

# Copy the rest of the application code
COPY . .
RUN dart pub get --offline

# Compile the Dart server into a standalone executable
RUN dart compile exe bin/server.dart -o bin/server

# Runtime Stage
FROM debian:bookworm-slim

# Install CA certificates (Required for your server to make secure HTTPS requests to Supabase)
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy the compiled executable from the build stage
COPY --from=build /app/bin/server /app/bin/server

# Google Cloud Run automatically injects the PORT environment variable (default 8080)
ENV PORT=8080
EXPOSE 8080

# Start the server
CMD ["/app/bin/server"]
