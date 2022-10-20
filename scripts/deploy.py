import os

from brownie import ZampsToken

from scripts.helpers import get_deployment_accounts, is_local_blockchain


def deploy_contract():
    token_uri = os.getenv("TOKEN_URI")  # If this is not set, it will be None
    etherscan_token = os.getenv("ETHERSCAN_TOKEN")
    should_publish = bool(etherscan_token) and not is_local_blockchain()
    zamps_account, client_account = get_deployment_accounts()
    zamps_token_contract = ZampsToken.deploy(
        client_account.address,
        token_uri,
        {"from": zamps_account},
        publish_source=should_publish,
    )
    return zamps_token_contract


def main():
    deploy_contract()
