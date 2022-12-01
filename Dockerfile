FROM python:3.10.7-slim-buster

#RUN apt update; apt -y install --no-install-recommends default-libmysqlclient-dev build-essential

WORKDIR /app

COPY src/requirements.txt .

RUN pip3 install -r requirements.txt

COPY src/ .

USER 1001

EXPOSE 5000

CMD ["python3", "-u", "-m", "flask", "run", "--host=0.0.0.0"]
