from brownie import ZampsTokenFactory

from scripts import helpers


def deploy_factory_contract():
    should_publish = bool(helpers.get_block_explorer_token())
    _, client_account = helpers.get_deployment_accounts()
    return ZampsTokenFactory.deploy(
        {"from": client_account.address}, publish_source=should_publish
    )


def main():
    deploy_factory_contract()
