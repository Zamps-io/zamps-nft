import os

from brownie import ZampsTokenFactory

from scripts.helpers import get_deployment_accounts, is_local_blockchain


def deploy_factory_contract():
    etherscan_token = os.getenv("ETHERSCAN_TOKEN")
    should_publish = bool(etherscan_token) and not is_local_blockchain()
    _, client_account = get_deployment_accounts()
    return ZampsTokenFactory.deploy(
        {"from": client_account.address}, publish_source=should_publish
    )


def main():
    deploy_factory_contract()
