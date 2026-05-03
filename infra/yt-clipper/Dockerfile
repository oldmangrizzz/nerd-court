FROM python:3.12-slim
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg ca-certificates curl && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir fastapi==0.115.0 uvicorn[standard]==0.30.6 yt-dlp==2026.3.17 pydantic==2.9.2 bgutil-ytdlp-pot-provider==1.3.1
WORKDIR /app
COPY server.py /app/server.py
EXPOSE 8080
CMD ["uvicorn","server:app","--host","0.0.0.0","--port","8080","--workers","2"]
