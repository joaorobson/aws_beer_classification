resource "aws_kinesis_stream" "data_stream" {
  name        = "data_distributor"
  shard_count = 1

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]
}
