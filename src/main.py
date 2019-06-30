import json
import os
import requests
from datetime import datetime, timezone


GITHUB_TOKEN = os.environ['GITHUB_TOKEN']
GITHUB_REPOSITORY = os.environ['GITHUB_REPOSITORY']
GITHUB_EVENT_PATH = os.environ['GITHUB_EVENT_PATH']

URI = 'https://api.github.com'
API_VERSION = 'antiope-preview'
ACCEPT_HEADER_VALUE = f"application/vnd.github.{API_VERSION}+json"
AUTH_HEADER_VALUE = f"token {GITHUB_TOKEN}"
# This is the max annotations Github API accepts in one go.
MAX_ANNOTATIONS = 50

print(f'Repo is {GITHUB_REPOSITORY}')
print(f'Event path is {GITHUB_EVENT_PATH}')

with open(GITHUB_EVENT_PATH) as event_file:
    event = json.loads(event_file.read())

print(event)
action = event['action']
repo_full_name = event['repository']['full_name']
head_sha = event['check_suite']['pull_requests'][0]['head']['sha']


with open('flake8_output.json') as flake8_output_file:
    flake8_output = json.loads(flake8_output_file.read())


def create_annotations():
    annotations = list()
    for file_path, error_list in flake8_output:
        for error in error_list:
            annotations.append(dict(
                path=file_path,
                start_line=error['line_number'],
                end_line=error['line_number'],
                annotation_level='notice',
                message='{} ({})'.format(error['text'], error['code']),
                start_column=error['column_number'],
                end_column=error['column_number'],
            ))
            if len(annotations) == 50:
                return annotations
    return annotations


annotations = create_annotations()

summary = """
Flake8 Run Summary:

Total Errors: {}
Files with errors: {}
""".format(
    len(annotations) if len(annotations) < 50 else '50+',
    len(flake8_output),
)
if len(annotations) == 0:
    conclusion = 'success'
else:
    conclusion = 'error'

requests.post(
    f'{URI}/repos/{repo_full_name}/check-runs/',
    headers={
        'Accept': ACCEPT_HEADER_VALUE,
        'Authorization': AUTH_HEADER_VALUE,
    },
    data={
        'name': 'flake8-your-pr',
        'head_sha': head_sha,
        'status': 'completed',
        'conclusion': conclusion,
        'completed_at': datetime.now(timezone.utc).isoformat(),
        'output': {
            'title': 'Flake8 Result',
            'summary': summary,
            'text': 'Flake8 results',
            'annotations': annotations,
        },
    },
)
