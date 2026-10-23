FROM dart:stable AS build
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/backend.dart -o servidor

FROM debian:stable-slim
WORKDIR /app
COPY --from=build /runtime/ /
COPY --from=build /app/servidor /app/servidor
COPY --from=build /app/public /app/public
CMD ["/app/servidor"]
