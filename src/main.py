import json
import os


GITHUB_TOKEN = os.environ['GITHUB_TOKEN']
GITHUB_REPOSITORY = os.environ['GITHUB_REPOSITORY']
GITHUB_EVENT_PATH = os.environ['GITHUB_EVENT_PATH']

print(f'Repo is {GITHUB_REPOSITORY}')
print(f'Event path is {GITHUB_EVENT_PATH}')

with open(GITHUB_EVENT_PATH) as event_file:
    event = json.loads(event_file.read())

print(event)
action = event['action']
pull_request = event['pull_request']
# Run pylint, add annotations
