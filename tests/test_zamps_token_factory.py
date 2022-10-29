from scripts.deploy_factory import deploy_factory_contract
from scripts.helpers import setup_dev_accounts

DEFAULT_BRANCHING_FACTOR = 10


def test_deploy_child_contract():
    # Arrange
    dev_accounts = setup_dev_accounts(["affiliate"])
    client = dev_accounts["client"]
    zamps_factory_contract = deploy_factory_contract()

    # Act
    tx = zamps_factory_contract.create({"from": client})

    # Assert
    assert tx.status.name == "Confirmed"
    assert tx.new_contracts[0] == zamps_factory_contract.tokens(0)
    assert tx.new_contracts[0] == zamps_factory_contract.businessOwnersContracts(
        client, 0
    )
