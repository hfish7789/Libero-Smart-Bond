// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract SmartBond is Ownable {
    using SafeMath for uint256;
    string name;
    address tokenToRedeem;
    uint256 totalDebt;
    uint256 parDecimals;
    uint256 bondsNumber;
    uint256 cap;
    uint256 parValue;
    uint256 couponRate;
    uint256 term;
    uint256 timesToRedeem;
    uint256 public loopLimit;
    uint256 nonce = 0;
    uint256 couponThreshold = 0;
    IERC20 token;
    mapping(uint256 => address) bonds;
    mapping(uint256 => uint256) maturities;
    mapping(uint256 => uint256) couponsRedeemed;
    mapping(address => uint256) bondsAmount;

    event MintedBond(address buyer, uint256 bondsAmount);
    event RedeemedCoupons(address indexed caller, uint256[] bonds);
    event Transferred(address indexed from, address indexed to, uint256[] bonds);
    event ChangeLoopLimit(uint256 indexed nowLoopLimit);

    constructor(
        string memory _name, 
        uint256 _par, 
        uint256 _parDecimals, 
        uint256 _coupon,
        uint256 _term, 
        uint256 _cap, 
        uint256 _timesToRedeem, 
        address _tokenToRedeem,
        uint256 _loopLimit
    ) {
        require(bytes(_name).length > 0);
        require(_coupon > 0);
        require(_par > 0);
        require(_term > 0);
        require(_loopLimit > 0);
        require(_timesToRedeem >= 1);

        name = _name;
        parValue = _par;
        cap = _cap;
        loopLimit = _loopLimit;
        parDecimals = _parDecimals;
        timesToRedeem = _timesToRedeem;
        couponRate = _coupon;
        term = _term;
        couponThreshold = term.div(timesToRedeem);

        if (_tokenToRedeem == address(0))
            tokenToRedeem = _tokenToRedeem;
        else
            token = IERC20(_tokenToRedeem);
    }

    /**
    * @notice Change the number of elements you can loop through in this contract
    * @param _loopLimit The new loop limit
    */

    function changeLoopLimit(uint256 _loopLimit) external onlyOwner {
        require(_loopLimit > 0);
        loopLimit = _loopLimit;
        emit ChangeLoopLimit(loopLimit);
    }

    /**
    * @notice Mint bonds to a new buyer
    * @param buyer The buyer of the bonds
    * @param _bondsAmount How many bonds to mint
    */

    function mintBond(address buyer, uint256 _bondsAmount) external onlyOwner {
        require(buyer != address(0));
        require(_bondsAmount >= 1);
        require(_bondsAmount <= loopLimit);

        if (cap > 0)
            require(bondsNumber.add(_bondsAmount) <= cap);

        bondsNumber = bondsNumber.add(_bondsAmount);
        nonce = nonce.add(_bondsAmount);

        for (uint256 i = 0; i < _bondsAmount; i++) {
            maturities[nonce.sub(i)] = block.timestamp.add(term);
            bonds[nonce.sub(i)] = buyer;
            couponsRedeemed[nonce.sub(i)] = 0;
            bondsAmount[buyer] = bondsAmount[buyer].add(_bondsAmount);
        }

        totalDebt = totalDebt.add(parValue.mul(_bondsAmount)).add((parValue.mul(couponRate).div(100)).mul(timesToRedeem.mul(_bondsAmount)));
        emit MintedBond(buyer, _bondsAmount);
    }

    /**
    * @notice Redeem coupons on your bonds
    * @param _bonds An array of bond ids corresponding to the bonds you want to redeem apon
    */

    function redeemCoupons(uint256[] calldata _bonds) external {

        require(_bonds.length > 0);
        require(_bonds.length <= loopLimit);
        require(_bonds.length <= getBalance(msg.sender));

        uint256 issueDate = 0;
        uint256 lastThresholdRedeemed = 0;
        uint256 toRedeem = 0;

        for (uint256 i = 0; i < _bonds.length; i++) {
            if (bonds[_bonds[i]] != msg.sender || couponsRedeemed[_bonds[i]] == timesToRedeem) continue;

            issueDate = maturities[_bonds[i]].sub(term);
            lastThresholdRedeemed = issueDate.add(couponsRedeemed[_bonds[i]].mul(couponThreshold));

            if (lastThresholdRedeemed.add(couponThreshold) >= maturities[_bonds[i]] || block.timestamp < lastThresholdRedeemed.add(couponThreshold)) continue;

            toRedeem = (block.timestamp.sub(lastThresholdRedeemed)).div(couponThreshold);

            if (toRedeem == 0) continue;

            couponsRedeemed[_bonds[i]] = couponsRedeemed[_bonds[i]].add(toRedeem);
            getMoney(toRedeem.mul(parValue.mul(couponRate).div( 10 ** (parDecimals.add(2)) ) ), msg.sender);

            if (couponsRedeemed[_bonds[i]] == timesToRedeem) {
                bonds[_bonds[i]] = address(0);
                maturities[_bonds[i]] = 0;
                bondsAmount[msg.sender]--;
                getMoney(parValue.div( (10 ** parDecimals) ), msg.sender );
            }
        }
        emit RedeemedCoupons(msg.sender, _bonds);
    }

    /**
    * @notice Transfer bonds to another address
    * @param receiver The receiver of the bonds
    * @param _bonds The ids of the bonds that you want to transfer
    */

    function transfer(address receiver, uint256[] calldata _bonds) external {
        require(_bonds.length > 0);
        require(receiver != address(0));
        require(_bonds.length <= getBalance(msg.sender));

        for (uint256 i = 0; i < _bonds.length; i++) {
            if (bonds[_bonds[i]] != msg.sender || couponsRedeemed[_bonds[i]] == timesToRedeem) continue;

            bonds[_bonds[i]] = receiver;
            bondsAmount[msg.sender] = bondsAmount[msg.sender].sub(1);
            bondsAmount[receiver] = bondsAmount[receiver].add(1);
        }

        emit Transferred(msg.sender, receiver, _bonds);
    }

    /**
    * @notice Donate money to this contract
    */

    function donate() external payable {
        require(address(token) == address(0));
    }

    // function() payable { revert(); }
    receive() external payable {}

    //PRIVATE

    /**
    * @notice Transfer coupon money to an address
    * @param amount The amount of money to be transferred
    * @param receiver The address which will receive the money
    */

    function getMoney(uint256 amount, address receiver) internal {
        if (address(token) == address(0))
            payable(receiver).transfer(amount);
        else
            token.transfer(msg.sender, amount);

        totalDebt = totalDebt.sub(amount);
    }

    //GETTERS

    /**
    * @dev Get the last time coupons for a particular bond were redeemed
    * @param bond The bond id to analyze
    */

    function getLastTimeRedeemed(uint256 bond) external view returns (uint256) {
        uint256 issueDate = maturities[bond].sub(term);
        uint256 lastThresholdRedeemed = issueDate.add(couponsRedeemed[bond].mul(couponThreshold));
        return lastThresholdRedeemed;
    }

    /**
    * @dev Get the owner of a specific bond
    * @param bond The bond id to analyze
    */

    function getBondOwner(uint256 bond) internal view returns (address) {
        return bonds[bond];
    }

    /**
    * @dev Get how many coupons remain to be redeemed for a specific bond
    * @param bond The bond id to analyze
    */

    function getRemainingCoupons(uint256 bond) external view returns (int256) {
        address owner = getBondOwner(bond);
        if (owner == address(0)) return -1;
        uint256 redeemed = getCouponsRedeemed(bond);
        return int256(timesToRedeem - redeemed);
    }

    /**
    * @dev Get how many coupons were redeemed for a specific bond
    * @param bond The bond id to analyze
    */

    function getCouponsRedeemed(uint256 bond) internal view returns (uint256) {
        return couponsRedeemed[bond];
    }

    /**
    * @dev Get the address of the token that is redeemed for coupons
    */

    function getTokenAddress() external view returns (address) {
        return (address(token));
    }

    /**
    * @dev Get how many times coupons can be redeemed for bonds
    */

    function getTimesToRedeem() external view returns (uint256) {
        return timesToRedeem;
    }

    /**
    * @dev Get how much time it takes for a bond to mature
    */

    function getTerm() external view returns (uint256) {
        return term;
    }

    /**
    * @dev Get the maturity date for a specific bond
    * @param bond The bond id to analyze
    */

    function getMaturity(uint256 bond) external view returns (uint256) {
        return maturities[bond];
    }

    /**
    * @dev Get how much money is redeemed on a coupon
    */

    function getSimpleInterest() external view returns (uint256) {
        uint256 rate = getCouponRate();
        uint256 par = getParValue();
        return par.mul(rate).div(100);
    }

    /**
    * @dev Get the yield of a bond
    */

    function getCouponRate() internal view returns (uint256) {
        return couponRate;
    }

    /**
    * @dev Get the par value for these bonds
    */

    function getParValue() internal view returns (uint256) {
        return parValue;
    }

    /**
    * @dev Get the cap amount for these bonds
    */

    function getCap() external view returns (uint256) {
        return cap;
    }

    /**
    * @dev Get amount of bonds that an address has
    * @param who The address to analyze
    */

    function getBalance(address who) public view returns (uint256) {
        return bondsAmount[who];
    }

    /**
    * @dev If the par value is a real number, it might have decimals. Get the amount of decimals the par value has
    */

    function getParDecimals() external view returns (uint256) {
        return parDecimals;
    }

    /**
    * @dev Get the address of the token redeemed for coupons
    */

    function getTokenToRedeem() external view returns (address) {
        return tokenToRedeem;
    }

    /**
    * @dev Get the name of this smart bond contract
    */

    function getName() external view returns (string memory) {
        return name;
    }

    /**
    * @dev Get the current unpaid debt
    */

    function getTotalDebt() external view returns (uint256) {
        return totalDebt;
    }

    /**
    * @dev Get the total amount of bonds issued
    */

    function getTotalBonds() external view returns (uint256) {
        return bondsNumber;
    }

    /**
    * @dev Get the latest nonce
    */

    function getNonce() external view returns (uint256) {
        return nonce;
    }

    /**
    * @dev Get the amount of time that needs to pass between the dates when you can redeem coupons
    */

    function getCouponThreshold() external view returns (uint256) {
        return couponThreshold;
    }
}