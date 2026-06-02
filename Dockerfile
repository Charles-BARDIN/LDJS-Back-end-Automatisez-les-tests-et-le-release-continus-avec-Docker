# syntax=docker/dockerfile:1

# --- Stage 1: compile TypeScript into dist/ ---
FROM node:22-alpine AS build
WORKDIR /app

# Install all dependencies (incl. dev) needed to compile
COPY package.json package-lock.json ./
RUN npm ci

# Compile the NestJS application (nest build -> dist/main.js)
COPY . .
RUN npm run build

# --- Stage 2: lightweight runtime with production dependencies only ---
FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

# Install only production dependencies
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Bring in the compiled output from the build stage
COPY --from=build /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/main"]
