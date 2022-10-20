# zamps-nft

## Environment setup


Install python. Project was built with v3.9.7 but probably latest version is fine. [pyenv](https://github.com/pyenv/pyenv) is a nice way to manage multiple python versions on a single machine. 

Clone the repo and inside the local directory create a python virtual environment:

```
➜ python -m venv venv
```

Activate and install requirements:

```
➜ source venv/bin/activate && pip install -r requirements.txt
```

## Running tests

```
➜ brownie test

Brownie v1.19.1 - Python development framework for Ethereum

====================================================== test session starts =======================================================
platform darwin -- Python 3.9.7, pytest-6.2.5, py-1.11.0, pluggy-1.0.0
rootdir: /Users/felixeaston-smith/code/mos/web3/zamps-nft
plugins: eth-brownie-1.19.1, forked-1.4.0, web3-5.30.0, xdist-1.34.0, hypothesis-6.27.3, anyio-3.3.4, time-machine-2.4.0
collected 2 items
Attached to local RPC client listening at '127.0.0.1:8545'...

tests/test_zamps_token.py ..                                                                                               [100%]
================================================= 2 passed, 20 warnings in 0.39s =================================================


```

## Brownie console 

To test interacting with the smart contract manually use the brownie console:

```
➜ brownie console

Brownie v1.19.1 - Python development framework for Ethereum

ZampsMvpProject is the active project.

Attached to local RPC client listening at '127.0.0.1:8545'...
Brownie environment is ready.
>>> from scripts.helpers import setup_dev_accounts, display_affiliates, display_ancestors
>>> affiliate_names = ["felix", "clint", "kawika", "skyler", "david"]
>>> dev_accounts = setup_dev_accounts(affiliate_names)
>>> dev_accounts
{
    'client': 0x21b42413bA931038f35e7A5224FaDb065d297Ba3,
    'david': 0x844ec86426F076647A5362706a04570A5965473B,
    'felix': 0x0063046686E46Dc6F15918b61AE2B121458534a5,
    'kawika': 0x46C0a5326E643E4f71D3149d50B48216e174Ae84,
    'skyler': 0x807c47A89F720fe4Ee9b8343c286Fc886f43191b,
    'zamps': 0x66aB6D9362d4F35596279692F0251Db635165871
}
>>> from scripts.deploy import deploy_contract
>>> zamps_token_contract = deploy_contract()
Transaction sent: 0xd0e544382ed7273945d90cd3999c0760ae55d3484eeaacf5856927c44fb756d7
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 25
  ZampsToken.constructor confirmed   Block: 28   Gas used: 4257696 (35.48%)
  ZampsToken deployed at: 0x654f70d8442EA18904FA1AD79114f7250F7E9336
```


## Deploying

Running `scripts/deploy.py` with brownie handles setting up accounts for zamps and the client (the two accounts required to deploy) and deploying the contract to a network.

### Local

By default brownie will run a local ganache instance, deploy the contract and tear down the local instance once the deploy command has run:

```
➜ brownie run scripts/deploy.py

Brownie v1.19.2 - Python development framework for Ethereum

Attached to local RPC client listening at '127.0.0.1:8545'...

Running 'scripts/deploy_and_create.py::main'...
Transaction sent: 0xc785ea6580746d389552eaaac9fa5bc3355e3be1dd52e3eb2b198e6b645d3d05
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 1
  ZampsToken.constructor confirmed   Block: 2   Gas used: 4801733 (40.01%)
  ZampsToken deployed at: 0x602C71e4DAC47a042Ee7f46E0aee17F94A3bA0B6
```

### Testnet 

To deploy to a test net some additional configuration is required. First choose a test network. The following example uses polygon mumbai testnet.

Setup two accounts (one for zamps, one for the client) on e.g. metamask and purchase some currency of the chosen test network.

Add a .env file with the following to the root of the project directory with the following env vars:

```
ZAMPS_PRIVATE_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX # zamps private key
CLIENT_PRIVATE_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX # client private key
WEB3_INFURA_PROJECT_ID=XXXXXXXXXXXXXXXXXXXXXXXXXX # infura api key (chosen testnet must be activate for this key)
```

Run the deploy script for your chosen network:

```
brownie run scripts/deploy.py --network polygon-test
```


