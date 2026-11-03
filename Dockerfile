# One image that runs on Google Cloud Run, AWS EC2/ECS, or any Docker host.
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    STREAMLIT_SERVER_HEADLESS=true \
    STREAMLIT_BROWSER_GATHER_USAGE_STATS=false

WORKDIR /app

# Install dependencies first so Docker can cache this layer
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# Optional warm-up: download the embedding model into the image so the first
# question after a cold start is not slow. If the download fails, the build still
# succeeds and the model is downloaded at runtime instead.
RUN python -c "from chromadb.utils.embedding_functions import DefaultEmbeddingFunction; DefaultEmbeddingFunction()(['warm up'])" || true

# Application code (.dockerignore keeps .env, virtual environments and caches out)
COPY . .

EXPOSE 8501

# Cloud Run supplies $PORT (default 8080); elsewhere the app listens on 8501
CMD ["sh", "-c", "streamlit run app.py --server.port=${PORT:-8501} --server.address=0.0.0.0"]
