import os

from brownie import ZampsToken

from scripts.helpers import get_deployment_accounts


def main():
    token_uri = os.getenv("TOKEN_URI")  # If this is not set, it will be None
    zamps_account, client_account = get_deployment_accounts()
    zamps_token_contract = ZampsToken.deploy(
        client_account.address, token_uri, {"from": zamps_account}
    )
    return zamps_token_contract
