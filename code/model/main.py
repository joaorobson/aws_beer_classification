import json
import os

from model import Model


model = Model()

def predict_ibu(event, context):
    print("Event received:", event)

    data = event["data"]
    if isinstance(data, str):
        data = json.loads(data)

    print("Data received:", data)

    ibus = model.predict(data)

    body = [{sample["id"]: ibu} for sample, ibu in zip(data, ibus)]

    response = {
        "statusCode": 200,
        "predictions": json.dumps(body),
    }
    return response
