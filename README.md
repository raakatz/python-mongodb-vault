### INITIALIZE VAULT
Run the vault setup script to install Vault and configure it the generate dynamic credentials for our database as well as configure an encryption key that can be used by the application to encrypt data

    ./install-vault.sh [ int | prod ]

### Application Deployment Steps

We will build and deploy our app with its database
    
    helm dependency update myapp-helm
    helm install myapp-int myapp-helm -n myapp-int --set vaultAddress=vault-int.vault-int.svc --create-namespace
    helm install myapp-prod myapp-helm -n myapp-prod --set vaultAddress=vault-prod.vault-prod.svc --create-namespace

We will log into our database and see that the root user exists as well as the application user (its username and password can be found in the application logs)

    oc exec -it $(oc get pods -l app.kubernetes.io/component=mongodb -o jsonpath="{.items[0].metadata.name}") -- mongosh -u root -p willBeChangedByVault
    use my_database;
    db.getUsers();

Then, we will force the rotation of the database root credentials
    
    export VAULT_ADDR=http://$(oc get route -o jsonpath="{.items[0].spec.host}")
    export VAULT_TOKEN=root
    vault write -force database/rotate-root/my_database

And we won't be able to login with the root user anymore

    oc exec -it $(oc get pods -l app.kubernetes.io/component=mongodb -o jsonpath="{.items[0].metadata.name}") -- mongosh -u root -p willBeChangedByVault

We'll use our application to send data to the database, and then login to the database with the application's user and see our data

    oc exec -it $(oc get pods -l app.kubernetes.io/component=mongodb -o jsonpath="{.items[0].metadata.name}") -- mongosh -u <user> -p <password> --authenticationDatabase my_database
    use my_database;
    db.users.find( { } );

To see our decrypted data we'll run the following:

    vault write -field=plaintext transit/decrypt/my-key ciphertext=<ciphertext> | base64 -d

