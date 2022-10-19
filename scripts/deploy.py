from brownie import ZampsToken

from scripts.helpers import get_accounts


def main():
    zamps_account, client_account = get_accounts()
    zamps_token_contract = ZampsToken.deploy(
        client_account.address, {"from": zamps_account}
    )
    return zamps_token_contract
