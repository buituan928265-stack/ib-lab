FROM python:3.12-slim
COPY data/*.ndjson /data/
COPY sigma/*.yml /sigma/
COPY images/loader/load.py /load.py
CMD ["python3", "-u", "/load.py"]
