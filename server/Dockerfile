FROM dart:stable
WORKDIR /app
COPY server /app/server
COPY mobile/lib/game/puzzle.dart /app/mobile/lib/game/puzzle.dart
RUN dart compile exe server/duel_server.dart -o /app/duel
ENV HOST=0.0.0.0
ENV PORT=8788
EXPOSE 8788
CMD ["/app/duel"]
