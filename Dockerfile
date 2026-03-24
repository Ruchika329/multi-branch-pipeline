FROM node:18-alpine
WORKDIR /app
COPY . .
RUN echo "Build done"
CMD ["echo", "App running"]
