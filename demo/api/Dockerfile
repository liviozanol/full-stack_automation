FROM python:3.8.12-alpine

WORKDIR /usr/src/app
COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

COPY *.py ./

CMD [ "uvicorn", "main:app", "--host", "0.0.0.0"]