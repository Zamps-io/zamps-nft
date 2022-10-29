import os

from brownie import ZampsToken

from scripts import helpers


def deploy_contract():
    zamps_account, client_account = helpers.get_deployment_accounts()
    if helpers.is_ethereum_blockchain():
        block_explorer_token = os.getenv("ETHERSCAN_TOKEN")
    elif helpers.is_polygon_blockchain():
        block_explorer_token = os.getenv("POLYGONSCAN_TOKEN")
    else:
        block_explorer_token = None
    should_publish = bool(block_explorer_token)
    zamps_token_contract = ZampsToken.deploy(
        client_account.address,
        {"from": zamps_account},
        publish_source=should_publish,
    )
    return zamps_token_contract


def main():
    deploy_contract()
