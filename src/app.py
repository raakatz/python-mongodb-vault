from flask import Flask, render_template, request, redirect, url_for, session
from pymongo import MongoClient
import re
import requests
import json
import base64
import time
import os

VAULT_ADDR = os.environ['VAULT_ADDR']
NAMESPACE = os.environ['NAMESPACE']

with open('/var/run/secrets/kubernetes.io/serviceaccount/token') as f:
    jwt = f.read()
request_data = {"jwt": jwt, "role": "webapp"}

while True:
    try:
        auth_res = requests.post(f'http://{VAULT_ADDR}:8200/v1/auth/kubernetes/login', data=request_data)
        token = auth_res.json()["auth"]["client_token"]
    except Exception:
        print("Could not authenticate with Vault. Retrying...\n")
        time.sleep(5)
    else:
        break
        
while True:
    try:
        db_res = requests.get(f'http://{VAULT_ADDR}:8200/v1/database/creds/webapp', headers={"X-Vault-Token": token})
        DB_USERNAME = db_res.json()["data"]["username"]
        DB_PASSWORD = db_res.json()["data"]["password"]
    except Exception:
        print("Could not get database credentials from Vault. Retrying...\n")
        time.sleep(5)
    else:
        break

print(f'''
THIS IS FOR DEMONSTRATION PURPOSES
DB username is {DB_USERNAME}
DB password is {DB_PASSWORD}
''')

app = Flask(__name__)

client = MongoClient(f'{NAMESPACE}-mongodb.{NAMESPACE}.svc', 27017, username=DB_USERNAME, password=DB_PASSWORD, authSource='my_database')
db = client.my_database
users = db.users

@app.route('/')
@app.route('/register', methods =['GET', 'POST'])
def register():
    msg = ''
    if request.method == 'POST' and 'FirstName' in request.form and 'LastName' in request.form and 'CreditCard' in request.form:
        
        FirstName = request.form['FirstName']
        LastName = request.form['LastName']
        CreditCard = request.form['CreditCard']
        
        CreditCard_bytes = CreditCard.encode("ascii")
        b64_bytes = base64.b64encode(CreditCard_bytes)
        b64_string = b64_bytes.decode("ascii")

        encryption_res = requests.post(f'http://{VAULT_ADDR}:8200/v1/transit/encrypt/my-key', headers={"X-Vault-Token": token}, data={"plaintext": b64_string})
        cipher = encryption_res.json()["data"]["ciphertext"]

        users.insert_one({"FirstName": FirstName, "LastName": LastName, "CreditCard": cipher})

        msg = 'You have successfully registered!'
        
    elif request.method == 'POST':
        msg = 'Please fill out the form'
        
    return render_template('register.html', msg = msg)

