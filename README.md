# flake8-your-pr
Github action to flake8 lint your pull requests

GOTCHAS
=======

- You cannot use WORKDIR in actions' Dockerfile, as Github overrides it: https://developer.github.com/actions/creating-github-actions/creating-a-docker-container/#workdir
