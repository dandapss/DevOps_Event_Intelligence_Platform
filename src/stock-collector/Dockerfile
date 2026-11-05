FROM python:3.12-slim
# Adding "app" user to not run container as root
RUN useradd app
WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY stock-collector.py ./
EXPOSE 9090

USER app

CMD ["python", "stock-collector.py"]
