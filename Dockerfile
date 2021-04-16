FROM python:3.8-alpine

LABEL "com.github.actions.name"="Run flake8 on your PR - with annotations!"
LABEL "com.github.actions.description"="GitHub Action to run flake8 linter on your Pull Requests and add annotations on errors"
LABEL "com.github.actions.icon"="thumbs-up"
LABEL "com.github.actions.color"="green"
LABEL "com.github.actions.repository"="https://github.com/tayfun/flake8-your-pr"
LABEL "com.github.actions.homepage"="https://github.com/tayfun/flake8-your-pr"
LABEL "com.github.actions.maintainer"="Tayfun Sen"

# RUN apk add --no-cache build-base gcc
RUN apk add --no-cache git bash jq curl
RUN pip install --upgrade pip
RUN pip install flake8 flake8-json requests
RUN python --version; pip --version; flake8 --version

COPY src /src
CMD ["/src/entrypoint.sh"]
