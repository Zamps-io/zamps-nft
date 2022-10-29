from brownie import ZampsToken

from scripts import helpers


def deploy_contract():
    zamps_account, client_account = helpers.get_deployment_accounts()
    should_publish = bool(helpers.get_block_explorer_token())
    zamps_token_contract = ZampsToken.deploy(
        client_account.address,
        {"from": zamps_account},
        publish_source=should_publish,
    )
    return zamps_token_contract


def main():
    deploy_contract()
