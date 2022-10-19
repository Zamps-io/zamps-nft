from brownie import ZampsToken, config

from scripts.helpers import get_accounts

sample_token_uri = config["token_uri"]["default"]


def main():
    zamps_account, client_account = get_accounts()
    zamps_token_contract = ZampsToken.deploy(
        client_account.address, {"from": zamps_account}
    )
    return zamps_token_contract
