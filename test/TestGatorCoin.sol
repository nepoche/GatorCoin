import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/GatorCoin.sol";

contract TestGatorCoin {

	function testInitialBalance() {
		GatorCoin g = GatorCoin(DeployedAddresses.GatorCoin());

		uint expected = 100000;

		Assert.equal(g.getBalance(tx.origin), expected, "The owner should start with 100000 GatorCoin");
	}

	// owner distributes coins to members (for attendance, special events, etc)
	function testDistributeCoin() {
		GatorCoin g = GatorCoin(DeployedAddresses.GatorCoin());

		uint numCoins = 5;
		address recipient = ;

		g.distributeCoin(numCoins, recipient);

		Assert.equal(g.getBalance(tx.origin), 100000 - numCoins, "Owner should have 99995 GatorCoin");
		Assert.equal(g.getBalance(recipient), numCoins, "Recipient should have 5 GatorCoin");
	}

	


}

