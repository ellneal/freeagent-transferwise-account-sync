# Account Sync

Transfers transactions from a Transferwise _Borderless_ account to an associated FreeAgent bank account. You need to create a FreeAgent application to use this: dev.freeagent.com.

## Usage

The script takes two arguments: currency (for the transferwise transactions) and the ID of the FreeAgent account to sync them to (make sure you set this account to use the correct currency in FreeAgent).

```sh
ruby main.rb GBP 123456
```

There are also several required environment variables:

```sh
TRANSFERWISE_API_URL=https://api.transferwise.com/v1
TRANSFERWISE_API_KEY=
TRANSFERWISE_PROFILE_ID=
TRANSFERWISE_ACCOUNT_ID=
TRANSFERWISE_SIGNING_KEY=
FREEAGENT_API_URL=https://api.freeagent.com/v2
FREEAGENT_API_CLIENT_ID=
FREEAGENT_API_CLIENT_SECRET=
FREEAGENT_API_REFRESH_TOKEN=
```

I use a docker container:

```sh
docker run --rm  -ti \
    -e TRANSFERWISE_API_URL=https://api.transferwise.com/v1 \
    -e TRANSFERWISE_API_KEY={YOUR API KEY} \
    -e TRANSFERWISE_PROFILE_ID={YOUR PROFILE ID} \
    -e TRANSFERWISE_ACCOUNT_ID={YOUR ACCOUNT ID} \
    -e TRANSFERWISE_SIGNING_KEY={PATH TO PRIVATE KEY} \
    -e FREEAGENT_API_URL=https://api.freeagent.com/v2 \
    -e FREEAGENT_API_CLIENT_ID={YOUR FREEAGENT CLIENT ID} \
    -e FREEAGENT_API_CLIENT_SECRET={YOUR FREEAGENT CLIENT SECRET} \
    -e FREEAGENT_API_REFRESH_TOKEN={YOUR FREEAGENT REFRESH TOKEN} \
    ellneal/freeagent-transferwise-account-sync GBP 123456
```


