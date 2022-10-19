from scripts.helpers import get_accounts
from brownie import ZampsToken

sample_token_uri = "https://ipfs.io/ipfs/QmaLg75ne665pB2akzUMhx9DcB3mkq71yYffUowsAEWppd"


def main():
    zamps_account, client_account = get_accounts()
    zamps_token_contract = ZampsToken.deploy(
        client_account.address, {"from": zamps_account}
    )
    return zamps_token_contract
