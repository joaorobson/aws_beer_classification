import json
from urllib.request import Request, urlopen


URL = "https://api.punkapi.com/v2/beers/random"

def retrieve_random_beer_data(event, context) -> dict:
    req = Request(URL, headers={"User-Agent": "Mozilla/5.0"})        
    
    try:
        data_bytes = urlopen(req).read()
        data = json.loads(data_bytes.decode())
        print(f"Retrieved data: {data}")
    except Exception as e:
        print(f"Error retrieving data from punk API: {e}") 
        data = {}

    return data
