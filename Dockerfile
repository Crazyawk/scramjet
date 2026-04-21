# --- Stage 1: Build ---
FROM node:18-bullseye AS builder

# Install Rust and WASM tools needed for the Scramjet rewriter
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup target add wasm32-unknown-unknown
RUN npm install -g pnpm wasm-bindgen-cli

WORKDIR /app

# Copy dependency files
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install

# Copy source and build
COPY . .
RUN pnpm rewriter:build
RUN pnpm build

# --- Stage 2: Runtime ---
FROM node:18-slim
WORKDIR /app

# Install pnpm for the start command
RUN npm install -g pnpm

# Copy built assets from the first stage
COPY --from=builder /app /app

# Scramjet's default port
EXPOSE 1337

CMD ["pnpm", "start"]
