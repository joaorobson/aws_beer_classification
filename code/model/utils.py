import boto3
import pickle


session = boto3.Session()
s3_client = session.client("s3")

def load_object_from_s3(bucket_name, filename, file_path):
    try:
        s3_client.download_file(bucket_name, filename, file_path)
    except Exception as e:
        print(f"Model is not available yet: {e}")
    else:
        with open(file_path, "rb") as f:
            obj = pickle.load(f)
        return obj
