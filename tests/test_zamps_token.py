from brownie import ZampsToken

from scripts.helpers import get_deployment_accounts


def test_deploy():
    # Arrange
    test_token_url = "https://ipfs.io/ipfs/XXXXXXXXXXXXXXXXXX"
    zamps_account, client_account = get_deployment_accounts()

    # Act
    zamps_token_contract = ZampsToken.deploy(
        client_account, test_token_url, {"from": zamps_account}
    )

    # Assert
    assert zamps_token_contract.balanceOf(zamps_account) == 0
    assert zamps_token_contract.balanceOf(client_account) == 10
