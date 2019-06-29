FROM python:3.7-alpine

LABEL "com.github.actions.name"="Run flake8 on your PR"
LABEL "com.github.actions.description"="GitHub Action to run flake8 on your Pull Requests"
LABEL "com.github.actions.icon"="upload-cloud"
LABEL "com.github.actions.color"="green"

# RUN apk add --no-cache build-base gcc
RUN pip install --upgrade pip
RUN pip install flake8
RUN python --version; pip --version; flake8 --version

COPY src /
WORKDIR /src
ENTRYPOINT ["python", "main.py"]
