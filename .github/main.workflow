workflow 'on pull request update, run flake8 and post results' {
    on = 'check_suite'
    resolves = 'run flake8'
}

action 'run flake8' {
    uses = 'tayfun/flake8-your-pr@master'
    secrets = ["GITHUB_TOKEN"]
}

