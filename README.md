test-trivy
### INITIALIZE VAULT
Run the vault setup script to install Vault and configure it the generate dynamic credentials for our database as well as configure an encryption key that can be used by the application to encrypt data

    ./install-vault.sh [ int | prod ]

### Application Deployment Steps
We will first prepare our environment

    oc create ns images
    oc policy add-role-to-group system:image-puller system:serviceaccounts:myapp-int --namespace=images
    oc policy add-role-to-group system:image-puller system:serviceaccounts:myapp-prod --namespace=images
    oc registry login
    helm dependency update myapp-helm

Then we will build and deploy our app with its database
    
    podman build -t default-route-openshift-image-registry.apps-crc.testing/images/webapp:1.0 .
    podman push default-route-openshift-image-registry.apps-crc.testing/images/webapp:1.0
    helm install myapp-int myapp-helm -n myapp-int --set vaultAddress=vault-int.vault-int.svc --create-namespace
    helm install myapp-prod myapp-helm -n myapp-prod --set vaultAddress=vault-prod.vault-prod.svc --create-namespace

We will log into our database and see that the root user exists as well as the application user (its username and password can be found in the application logs)

    CHANGE TO MONGO
    oc -n myapp exec -it myapp-mysql-0 -- mysql -h myapp-mysql.myapp.svc.cluster.local -uroot -pwillBeChangedByVault
    SELECT user FROM mysql.user;

Then, we will force the rotation of the database root credentials
    
    export VAULT_ADDR=http://<route>
    export VAULT_TOKEN=root
    vault write -force database/rotate-root/my_database

And we won't be able to login with the root user anymore

    CHANGE TO MONGO
    oc -n myapp exec -it myapp-mysql-0 -- mysql -h myapp-mysql.myapp.svc.cluster.local -uroot -pwillBeChangedByVault

We'll use our application to send data to the database, and then login to the database with the application's user and see our data

    CHANGE TO MONGO
    oc -n myapp exec -it myapp-mysql-0 -- mysql -h myapp-mysql.myapp.svc.cluster.local -u<user> -p<password>
    USE my_database;
    SELECT * FROM users;

To see our decrypted data we'll run the following:

    vault write -field=plaintext transit/decrypt/my-key ciphertext=<ciphertext> | base64 -d

