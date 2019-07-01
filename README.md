# flake8-your-pr

Github Action to flake8 your pull requests

# wait, what?

This is a github action to automatically run flake8 on your pull request and also add annotations if there are errors.

Here be a screenshot

# but why?

If you are working in a team you would be better off adding checks on pull requests. Of course you already have linters run automatically through vim and all (right? right?!) but just in case your colleague(s) inadvertently disable them it's good to have them.

The trouble is it's a lot of effort to configure these well. You'd need a CI/CD server with some plugins that needs to be configured, updated etc. 

This is where Github Actions comes along. Github actions basically runs a docker image on several events. These could be pull requests, issues, comments, code pushes etc. etc.

# where can i get this?

Easy, tiger. Sign up for beta on [Github](https://github.com/features/actions). And then simply add the following code in your repo root `.github/main.workflow`:

```
workflow "on check suite creation, run flake8 and post results" {
    on = "pull_request"
    resolves = "run flake8"
}

action "run flake8" {
    uses = "tayfun/flake8-your-pr@master"
    secrets = ["GITHUB_TOKEN"]
}
```

Create a pull request with some Python code and voila, you should see any errors as annotations.

Oh and this is only available for private repos at the moment. I guess Github is testing this, API is changing and they would like to fix all bugs before releasing to the whole wide world. Free plan comes with private repos now, go and test it out.

# next up?

 * Once Github Actions is open to public and this gets used more, I want this action to be configurable. Github Actions can use an `args` field and I can send the errors to be ignored etc.

If you use this and like it let me know and any pull requests are more than welcome.

# dev ramblings

I really like the idea behind Github Actions very much. It simplifies devops and adds to the overall software development experience really. Thanks to usage of docker images, you can pretty much do anything with it. 

My plan originally was to create a [Github App](https://developer.github.com/apps/quickstart-guides/creating-ci-tests-with-the-checks-api/#introduction), deploy it on AWS using API Gateway and Lambda and use that to run flake8 or anything else I needed. Then I remembered Github Actions. It's much more easier to setup than API Gateways and Lambdas really. What's more, I think it is much more powerful too. With Lambda you are restricted in your environment (Python version this and Node version that etc.) but with Github Actions you can use any image you like. 


### Gotchas

 - You [cannot use WORKDIR in action's Dockerfile](https://developer.github.com/actions/creating-github-actions/creating-a-docker-container/#workdir), as Github overrides it: 

 - Note that Github creates only [one check_suite event per commit hash](https://developer.github.com/v3/checks/suites/), even if that commit is pushed to other pull requests.
