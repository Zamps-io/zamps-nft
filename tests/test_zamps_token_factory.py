from brownie import accounts

from scripts.deploy_factory import deploy_factory_contract
from scripts.helpers import setup_dev_accounts

DEFAULT_BRANCHING_FACTOR = 10


def test_deploy_child_contract():
    # Arrange
    dev_accounts = setup_dev_accounts(["affiliate"])
    client = dev_accounts["client"]
    zamps_factory_contract = deploy_factory_contract()
    origin_address = accounts.add()

    # Act
    tx = zamps_factory_contract.create(origin_address, {"from": client})

    # Assert
    assert tx.status.name == "Confirmed"
    assert tx.new_contracts[0] == zamps_factory_contract.tokens(0)
    assert tx.new_contracts[0] == zamps_factory_contract.businessOwnersContracts(
        origin_address, 0
    )
