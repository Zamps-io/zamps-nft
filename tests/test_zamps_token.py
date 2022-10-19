from brownie import ZampsToken

from scripts.helpers import get_deployment_accounts, setup_dev_accounts

DEFAULT_BRANCHING_FACTOR = 10


def test_deploy():
    # Arrange
    test_token_url = "https://ipfs.io/ipfs/XXXXXXXXXXXXXXXXXX"
    zamps_account, client = get_deployment_accounts()

    # Act
    ZampsToken.deploy(client, test_token_url, {"from": zamps_account})


def test_transfer_from():
    # Arrange
    test_token_url = "https://ipfs.io/ipfs/XXXXXXXXXXXXXXXXXX"
    dev_accounts = setup_dev_accounts(["affiliate"])
    zamps = dev_accounts["zamps"]
    client = dev_accounts["client"]
    affiliate = dev_accounts["affiliate"]

    # Act
    zamps_token_contract = ZampsToken.deploy(client, test_token_url, {"from": zamps})
    client_token_balance = zamps_token_contract.balanceOf(client)
    zamps_token_balance = zamps_token_contract.balanceOf(zamps)

    # Assert
    assert zamps_token_balance == 0
    assert client_token_balance == DEFAULT_BRANCHING_FACTOR
    assert len(zamps_token_contract.affiliates()) == 1

    # Act
    client_tokens = zamps_token_contract.tokensOwnedBy(client)
    token_id = client_tokens[0]
    zamps_token_contract.transferFrom(client, affiliate, token_id, {"from": client})

    # Assert
    # One more affiliate in the network
    assert len(zamps_token_contract.affiliates()) == 2

    # Token transferred from client to new affiliate
    assert zamps_token_contract.ownerOf(token_id) == affiliate

    # Balances reflects the token transferred
    # and the newly generalted affiliate tokens
    assert zamps_token_contract.balanceOf(client) == client_token_balance - 1
    assert zamps_token_contract.balanceOf(affiliate) == DEFAULT_BRANCHING_FACTOR + 1
