# ---- Imagen base ligera ----
FROM python:3.12-slim

# Evitar cachés y asegurar logs en stdout
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Paquetes de sistema mínimos (compilación de greenlet/eventlet)
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      curl \
    && rm -rf /var/lib/apt/lists/*

# Carpeta de trabajo
WORKDIR /app

# Instalar dependencias primero (aprovecha cache)
COPY requirements.txt .
RUN pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt \
 && pip install --no-cache-dir gunicorn eventlet

# Copiar código de la app
COPY app.py ./app.py
COPY templates/ ./templates/

# Puerto interno
EXPOSE 8000

# Healthcheck simple (opcional: crea ruta /health en tu app)
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8000/health || exit 1

# Ejecutar con Gunicorn + eventlet (requerido para Flask-SocketIO)
# Si tu objeto Flask se llama "app" dentro de app.py, esto funciona.
CMD ["gunicorn", "-k", "eventlet", "-w", "1", "-b", "0.0.0.0:8000", "app:app"]
