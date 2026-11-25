FROM node:20-bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends tesseract-ocr tesseract-ocr-ara tesseract-ocr-fra poppler-utils python3 make g++ && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY server.js ./
COPY static ./static
COPY lib ./lib
RUN mkdir -p /data && chown node:node /data
USER node
ENV PORT=3000 DB_PATH=/data/horoof.sqlite OCR_ENABLED=1 OCR_LANGUAGES=ara+fra+eng
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s CMD node -e "fetch('http://127.0.0.1:3000/api/subjects').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "server.js"]
