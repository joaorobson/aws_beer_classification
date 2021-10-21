aws lambda invoke \
  --function-name predict_ibu \
  --payload $(cat test_beers.json | base64 -w 0) \
  response.json
