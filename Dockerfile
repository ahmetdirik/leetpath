# =============================================================================
# Stage 1: Builder - install dependencies with uv
# =============================================================================
FROM python:3.12-slim AS builder

# Install uv from the official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Configure uv for production builds
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    UV_PYTHON=python3.12

# Copy only dependency files first (better layer caching)
COPY pyproject.toml uv.lock ./

# Install dependencies (no dev dependencies, no project itself yet)
RUN uv sync --frozen --no-install-project --no-dev

# Now copy the actual source code
COPY src/ ./src/

# Install the project itself
RUN uv sync --frozen --no-dev


# =============================================================================
# Stage 2: Runtime - minimal image with just the app
# =============================================================================
FROM python:3.12-slim AS runtime

# Create non-root user for security
RUN groupadd --system app && \
    useradd --system --gid app --no-create-home app

WORKDIR /app

# Copy the virtual environment and source from builder
COPY --from=builder --chown=app:app /app/.venv /app/.venv
COPY --from=builder --chown=app:app /app/src /app/src

# Add venv to PATH so we can run binaries directly
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Switch to non-root user
USER app

# Expose the port FastAPI will run on
EXPOSE 8000

# Health check (Docker can verify the app is alive)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Run the app
CMD ["uvicorn", "src.leetpath.main:app", "--host", "0.0.0.0", "--port", "8000"]
