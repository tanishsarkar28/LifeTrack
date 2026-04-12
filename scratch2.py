import urllib.request
import re
import json

exercises = ['push-up-workout', 'crunch-exercise', 'lunge-workout', 'gym-workout']
found = {}

for ex in exercises:
    try:
        url = f'https://tenor.com/search/{ex}-gifs'
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        response = urllib.request.urlopen(req)
        html = response.read().decode('utf-8')
        
        matches = re.findall(r'"(https://media.tenor.com/[^\"]+\.gif)"', html)
        if matches:
            found[ex] = matches[0]
        else:
            found[ex] = 'Not found'
    except Exception as e:
        found[ex] = str(e)

print(json.dumps(found, indent=2))
