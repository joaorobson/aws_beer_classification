# Punk API infrasctructure

This project uses [Terraform](https://www.terraform.io/) to construct a architecture that consumes,
cleans and stoesdata from the [Punk API](https://punkapi.com/documentation/v2), cl. Besides that, it
provides a machine learning  model that could be accessed remotely to predict the IBU (*International
Bitterness Units*) of a beer via an AWS Lambda.

## Setup

To build this project, you must have [terraform installed](https://learn.hashicorp.com/tutorials/terraform/install-cli)
 and an [AWS account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/).

Once you have both configured, it is possible to run the project. First of all, clone the repo and open it:

```
git clone https://github.com/joaorobson/aws_beer_classification.git
cd aws_beer_classification
```

Create a Python env to install some dependencies:

```
python3.9 -m venv env
source env/bin/activate
pip install -r notebooks/requirements.txt
```

### Prediction setup

Before building the main architeture, it is necessary to create a Lambda that will be responsible to
load a pre-trained model from a S3 bucket and make predictions remotely. This step was done using
container images, given the [memory limitations](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html)
 imposed by AWS regarding *.zip* deployment packages.

This can be done with the folowing steps:

1. Set some env variables:

```
export AWS_REGION=us-west-2
export BUCKET_NAME="beers-linear-regressor"
export IMAGE_NAME="ibu_prediction_image"
export IMAGE_TAG="latest"
```

2. Create the ECR repository to store the generated image:

```
terraform apply -target=aws_ecr_repository.ibu_prediction_repository
```

3. Set the REGISTRY_ID AND IMAGE_URI env variables:

```
export REGISTRY_ID=$(aws ecr \
  describe-repositories \
  --query 'repositories[?repositoryName == `'$IMAGE_NAME'`].registryId' \
  --output text)
export IMAGE_URI=${REGISTRY_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}
```

4. Authenticate the docker client to the ECR registry using you AWS account id:
```
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin [aws_account_id].dkr.ecr.$AWS_REGION.amazonaws.com
```

5. Build and push the docker image:

```
cd code/model/
docker build -t $IMAGE_URI .
docker push $IMAGE_URI:$IMAGE_TAG
```

> NOTE: Currently, the lambda function will not work properly, because it depends of a model version stored
at the S3 bucket. To make it work, follow the commands in the next sections.


### Main architecture setup

After that, to build the architeture in AWS, in the root directoryof the project, run:

```
terraform apply
```

This command create all the resources used by the project. The comportament is rather basic:
every 5 minutes, a new beer record is retrieved and store in S3 buckets, one with the raw data and
another with a cleaned version. With that, the cleaned data bucket can be used to train a machine learning
model locally, which is exemplified by [this notebook](notebooks/Predição%20do%20IBU%20de%20cervejas.ipynb).


### Model training

Now, it is possible to train a model given the data collected and stored by the architecture.
To do that, run the notebook located [here](notebooks/Predição%20do%20IBU%20de%20cervejas.ipynb):

```
 ./env/bin/jupyter notebook
```

After run it, it will be possible to make a prediction via the Lambda created early using the notebook
itself or via CLI:

```
cd notebooks
./invoke_predict_ibu.sh
```

# References

* [Terraform Docs - AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* [The most minimal AWS Lambda + Python + Terraform setup](https://www.davidbegin.com/the-most-minimal-aws-lambda-function-with-python-terraform/)
* [DEPLOYING AWS LAMBDA FUNCTIONS WITH TERRAFORM](https://jeremievallee.com/2017/03/26/aws-lambda-terraform.html)
* [Building Lambda Functions with Terraform](https://aws-blog.de/2019/05/building-lambda-with-terraform.html)
* [Building a serverless, containerized machine learning model API using AWS Lambda & API Gateway and Terraform](https://blog.telsemeyer.com/2021/01/10/building-a-serverless-containerized-machine-learning-model-api-using-terraform-aws-lambda-api-gateway-and/)
* [Amazon ECR - Pushing a Docker image](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html)
* [Setting Crawler Configuration Options](https://docs.aws.amazon.com/glue/latest/dg/crawler-configuration.html)
