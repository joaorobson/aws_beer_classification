FROM public.ecr.aws/lambda/python:3.9

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY utils.py model.py main.py ./

CMD ["main.predict_ibu"]
