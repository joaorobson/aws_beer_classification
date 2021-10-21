import boto3
import pandas as pd
import pickle
import os

from utils import load_object_from_s3

session = boto3.Session()
s3_client = session.client("s3")

BUCKET_NAME = "beers-linear-regressor" 
FILENAME = "pipeline.pkl"
FILE_PATH = os.path.join("/tmp/", FILENAME) 
X_COLUMNS = ["abv", "ebc", "ph", "srm", "target_fg", "target_og"]

class Model:
    def __init__(self) -> None:
        self.pipeline = load_object_from_s3(BUCKET_NAME, FILENAME, FILE_PATH)

    def predict(self, data: list) -> list:
        df = pd.DataFrame(data)
        df = df[X_COLUMNS]

        return self.pipeline.predict(df)
