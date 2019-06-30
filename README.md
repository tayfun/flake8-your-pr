# flake8-your-pr
Github action to flake8 lint your pull requests

GOTCHAS
=======

    - You cannot use WORKDIR in action's Dockerfile, as Github overrides it: https://developer.github.com/actions/creating-github-actions/creating-a-docker-container/#workdir

    - Note that Github creates only one check_suite event per commit hash, even if that commit is pushed to other pull requests: https://developer.github.com/v3/checks/suites/
