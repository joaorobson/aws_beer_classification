import base64
import json

INTEREST_FIELDS = ["id", "name", "abv", "ibu", "target_fg", "target_og", "ebc", "srm", "ph"] 


def remove_unwanted_fields(data: dict) -> dict:
    return {key: data[key] for key in data if key in INTEREST_FIELDS}


def convert_dict_to_csv(data: dict) -> str:
    return ",".join([str(value) for value in data.values()]) + "\n"


def convert_str_to_base64(data: str) -> str:
    return base64.b64encode(data.encode("utf-8")).decode("utf-8")


def clean_data(event, context):
    print(f"Cleaning punk API data...")
    records = event.get("records") or []
    output = []
    for record in records:
        data = json.loads(base64.b64decode(record.get("data")))
        data = convert_dict_to_csv(remove_unwanted_fields(data))
        datab64 = convert_str_to_base64(data)

        output_record = {
            "recordId": record.get("recordId"),
            "result": "Ok",
            "data": datab64,
        }
        output.append(output_record)

    return {"records": output} 
