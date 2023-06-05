# Addresses collection

Addresses collection is a shared space designed to share addresses between smart contract instances in the Forge scripts and tests.

1. Add address the the shared space:
    ```solidity
    /// @notice Allocates an address for the current chain id
    /// @param _key Key to allocate/resolve an address
    /// @param _value An address that should be allocated
    function setAddress(string memory _key, address _value) public

    /// @notice Allocates an address
    /// @param _chainId A chain identifier that a `_value` is related to 
    /// @param _key Key to allocate/resolve an address
    /// @param _value An address that should be allocated
    function setAddress(uint256 _chainId, string memory _key, address _value) public
    ```

1. Get address from the shared space:
    ```solidity
    /// @notice Resolves an address by specified `_key` for the current chain id
    /// @param _key The key to resolving an address
    function getAddress(string memory _key) public view returns (address)

    /// @notice Resolves an address by specified `_key` and `_chainId`
    /// @param _chainId A chain identifier for which we want to resolve an address
    /// @param _key The key to resolving an address
    function getAddress(uint256 _chainId, string memory _key) public view returns (address)
    ```

1. An example on how to use it (pseudo code):
    ```solidity
    contract A is AddressesCollection {}

    contract B is AddressesCollection {}

    A a = new A();
    B b = new B();

    string constant KEY_1 = "key 1";
    string constant KEY_2 = "key 2";

    address addr1 = address(1);
    address addr2 = address(2);

    a.setAddress(KEY_1, addr1);
    b.setAddress(KEY_2, addr2);

    // These conditions will pass. As both `a` and `b` have shared addresses space
    assertEq(addr1, b.getAddress(KEY_1));
    assertEq(addr2, a.getAddress(KEY_2));
    ```
    [See an example](./../test/addresses/AddressesCollectionTest.sol).
