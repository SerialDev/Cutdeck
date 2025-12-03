FROM node:22-alpine AS base

WORKDIR /app

# Install dependencies
COPY package.json ./
RUN npm install

# Copy source code
COPY . .

# Development stage
FROM base AS development
EXPOSE 3000
CMD ["npm", "run", "dev"]

# Build stage
FROM base AS build
RUN npm run build

# Production stage - serve with nginx
FROM nginx:alpine AS production
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
