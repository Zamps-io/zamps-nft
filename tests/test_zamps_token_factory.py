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
    assert len(zamps_factory_contract.getTokens()) == 1
    assert len(zamps_factory_contract.getBusinessOwnersContracts(client)) == 1
