from datetime import datetime
from distutils.command.clean import clean
from elasticsearch import Elasticsearch
import requests

es = Elasticsearch(
    ['10.132.160.222'],
#    http_auth=('user', 'password'),
    scheme="http",
    port=9200,
#    verify_certs=False
)

resp = es.info(pretty=True)
#print(resp)
health = es.cluster.health()

## a very simple code to show us the cluster health
print(f"Your node {resp['name']} in the {resp['cluster_name']} is {health['status']}")
