FROM python:3.10.7-slim-buster

WORKDIR /app

COPY src/requirements.txt .

RUN pip3 install -r requirements.txt

COPY src/ .

USER 1001

EXPOSE 5000

CMD ["python3", "-u", "-m", "flask", "run", "--host=0.0.0.0"]
