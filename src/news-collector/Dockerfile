FROM python:3.12-slim
# Adding "app" user to not run container as root
RUN useradd app
WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY news-collector.py ./
EXPOSE 8080

USER app

CMD ["python", "news-collector.py"]
