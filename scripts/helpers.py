import os

from brownie import accounts, config, network

LOCAL_BLOCKCHAIN_ENVIRONMENTS = [
    "hardhat",
    "development",
    "ganache",
    "ganache-ui",
    "mainnet-fork",
]

ETHEREUM_ENVIRONMENTS = ["mainnet", "ropsten", "rinkeby", "kovan", "goerli"]

POLYGON_ENVIRONMENTS = ["polygon-test", "polygon-mainnet"]


def get_deployment_accounts():
    if is_local_blockchain():
        return accounts[0], accounts[1]
    else:
        owner = accounts.add(config["wallets"]["from_owner_key"])
        client = accounts.add(config["wallets"]["from_client_key"])
    return owner, client


def is_local_blockchain():
    return network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS


def is_ethereum_blockchain():
    return network.show_active() in ETHEREUM_ENVIRONMENTS


def is_polygon_blockchain():
    return network.show_active() in POLYGON_ENVIRONMENTS


def get_block_explorer_token():
    if is_ethereum_blockchain():
        return os.getenv("ETHERSCAN_TOKEN")
    elif is_polygon_blockchain():
        return os.getenv("POLYGONSCAN_TOKEN")
    return


def setup_dev_accounts(affiliate_names):
    required_num_accounts = len(affiliate_names) + 2
    num_accounts_to_create = required_num_accounts - len(accounts)
    for i in range(num_accounts_to_create):
        accounts.add()
    return dict(zip(["zamps", "client"] + affiliate_names, accounts))


def display_affiliates(zamps_contract, names_to_addresses={}):
    addresses_to_names = {v: k for k, v in names_to_addresses.items()}
    return [
        {
            "depth": depth,
            "account": account,
            "parentAccount": parentAccount,
            "name": addresses_to_names.get(account),
            "balance": zamps_contract.balanceOf(account),
            "tokensOwned": zamps_contract.tokensOwnedBy(account),
            "tokensAffiliated": zamps_contract.tokensAffiliatedTo(account),
        }
        for depth, account, parentAccount in zamps_contract.affiliates()
    ]


def display_ancestors(zamps_contract, account, names_to_addresses={}):
    addresses_to_names = {v: k for k, v in names_to_addresses.items()}
    ancestors = zamps_contract.ancestorsOf(account)[1:]
    print_str = ""
    for ancestor in ancestors:
        print_str += (
            f"{ancestor[:3]}...{ancestor[-3:]} "
            f"({addresses_to_names.get(ancestor)})  ====>  "
        )
    print_str += (
        f"{str(account)[:3]}....{str(account)[-3:]} "
        f"({addresses_to_names.get(account)})"
    )
    return print_str
