# ── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency manifests first — maximises Docker layer cache hits
COPY package.json package-lock.json ./

RUN npm ci

# Copy the rest of the source
COPY . .

# Build — skip tsc strict type-check, let vite bundle directly
RUN npx vite build


# ── Stage 2: Runtime ──────────────────────────────────────────────────────────
# Serve the compiled dist/ with a lightweight nginx image
FROM nginx:1.27-alpine AS runtime

# Remove the default nginx placeholder page
RUN rm -rf /usr/share/nginx/html/*

# Copy the compiled assets from the builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx config that handles React Router (SPA fallback)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
