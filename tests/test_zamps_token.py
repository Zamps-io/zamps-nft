import pytest
from brownie import ZampsToken, accounts, exceptions

from scripts.helpers import get_deployment_accounts, setup_dev_accounts

DEFAULT_BRANCHING_FACTOR = 10
MAX_DEPTH = 5


def test_deploy():
    # Arrange
    zamps_account, client = get_deployment_accounts()

    # Act
    ZampsToken.deploy(client, {"from": zamps_account})


def test_transfer_from():
    # Arrange
    dev_accounts = setup_dev_accounts(["affiliate"])
    zamps = dev_accounts["zamps"]
    client = dev_accounts["client"]
    affiliate = dev_accounts["affiliate"]

    # Act
    zamps_contract = ZampsToken.deploy(client, {"from": zamps})
    client_token_balance = zamps_contract.balanceOf(client)
    zamps_token_balance = zamps_contract.balanceOf(zamps)

    # Assert
    assert zamps_token_balance == 0
    assert client_token_balance == DEFAULT_BRANCHING_FACTOR
    assert len(zamps_contract.affiliates()) == 1

    # Act
    client_tokens = zamps_contract.tokensOwnedBy(client)
    token_id = client_tokens[0]
    zamps_contract.safeTransferFrom(client, affiliate, token_id, {"from": client})

    # Assert
    # One more affiliate in the network
    assert len(zamps_contract.affiliates()) == 2

    # Token transferred from client to new affiliate
    assert zamps_contract.ownerOf(token_id) == affiliate

    # Balances reflects the token transferred
    # and the newly generalted affiliate tokens
    assert zamps_contract.balanceOf(client) == client_token_balance - 1
    assert zamps_contract.balanceOf(affiliate) == DEFAULT_BRANCHING_FACTOR + 1


def test_only_whitelisted_can_distribute():
    # Arrange
    dev_accounts = setup_dev_accounts(
        ["affiliate", "whitelisted_address", "unapproved_address"]
    )
    zamps = dev_accounts["zamps"]
    client = dev_accounts["client"]
    affiliate = dev_accounts["affiliate"]
    whitelisted_address = dev_accounts["whitelisted_address"]
    unapproved_address = dev_accounts["unapproved_address"]
    zamps_contract = ZampsToken.deploy(client, {"from": zamps})
    zamps_contract.safeTransferFrom(client, affiliate, 0, {"from": client})

    # Act
    tx = zamps_contract.distribute(affiliate, {"from": client, "value": 1000})

    # Assert
    assert tx.status.name == "Confirmed"  # client is whitelisted by default

    # Act
    tx = zamps_contract.distribute(
        affiliate, {"from": whitelisted_address, "value": 1000}
    )

    # Assert
    assert tx.status.name == "Confirmed"  # whitelisted address can distribute

    # Act
    tx = zamps_contract.distribute(
        affiliate, {"from": unapproved_address, "value": 1000}
    )

    # Assert
    assert tx.status.name == "Confirmed"  # non-whitelisted address cannot distribute


def test_trasnfer_to_maximum_depth():
    # Arrange
    zamps = accounts[0]
    client = accounts[1]
    zamps_contract = ZampsToken.deploy(client, {"from": zamps})
    starting_num_affiliates = len(zamps_contract.affiliates())
    from_address = client

    for depth in range(1, MAX_DEPTH + 1):

        starting_balance = zamps_contract.balanceOf(from_address)

        # Act
        token_id = zamps_contract.tokensAffiliatedTo(from_address)[0]
        to_address = accounts[depth + 1]
        zamps_contract.safeTransferFrom(
            from_address, to_address, token_id, {"from": from_address}
        )

        # Assert
        assert len(zamps_contract.affiliates()) == depth + starting_num_affiliates
        assert zamps_contract.ownerOf(token_id) == to_address
        assert zamps_contract.balanceOf(from_address) == starting_balance - 1
        assert zamps_contract.balanceOf(to_address) == DEFAULT_BRANCHING_FACTOR + 1

        # Set from address for next iteration
        from_address = to_address

    # Act
    token_id = zamps_contract.tokensAffiliatedTo(from_address)[0]
    to_address = accounts[MAX_DEPTH + 3]

    with pytest.raises(exceptions.VirtualMachineError):
        zamps_contract.safeTransferFrom(
            from_address, to_address, token_id, {"from": from_address}
        )
