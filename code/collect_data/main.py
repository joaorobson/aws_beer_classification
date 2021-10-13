import json
import sys
sys.path.insert(0, 'packages/')

import requests
import boto3


KINESIS_STREAM_NAME = "data_distributor"
kinesis_client = boto3.client("kinesis", region_name="us-west-2")


URL = "https://api.punkapi.com/v2/beers/random"


def write_to_kinesis_stream(data: dict) -> None:
    print("Sending data to Kinesis stream...")
    kinesis_client.put_record(StreamName=KINESIS_STREAM_NAME,
                              Data=json.dumps(data),
                              PartitionKey=str(data.get("id")))
    

def retrieve_random_beer_data(event, context) -> dict:
    try:
        req = requests.get(URL)
        data = req.json()
        print(f"Retrieved data: {data}")

        if data and isinstance(data, list):
            data = data[0]
            write_to_kinesis_stream(data)
        else:
            data = {}

    except Exception as e:
        print(f"Error retrieving data from punk API: {e}") 
        data = {}

    return data
