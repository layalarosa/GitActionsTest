FROM node:22-alpine AS build

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

FROM node:22-alpine AS production

WORKDIR /app
RUN addgroup -S app && adduser -S app -G app

COPY --from=build /app/node_modules ./node_modules
COPY . .

USER app

EXPOSE 3000
CMD ["node", "server.js"]
