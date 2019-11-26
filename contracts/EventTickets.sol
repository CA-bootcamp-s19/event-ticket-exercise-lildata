pragma solidity ^0.5.0;

    /*
        The EventTickets contract keeps track of the details and ticket sales of one event.
     */

contract EventTickets {

    /*
        Create a public state variable called owner.
        Use the appropriate keyword to create an associated getter function.
        Use the appropriate keyword to allow ether transfers.
     */
     address payable public owner;

    uint256   TICKET_PRICE = 100 wei;

    /*
        Create a struct called "Event".
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {    //I wouldn't call a variable/struct the same as a reserved name...
      string description;
      string website;
      uint256 totalTickets;
      uint256 sales;
      mapping (address => uint) buyers;
      bool isOpen;
    }

    Event myEvent;

    /*
        Define 3 logging events.
        LogBuyTickets should provide information about the purchaser and the number of tickets purchased.
        LogGetRefund should provide information about the refund requester and the number of tickets refunded.
        LogEndSale should provide infromation about the contract owner and the balance transferred to them.
    */
    event LogBuyTickets(address purchaser, uint256 ticketsPurchased);
    event LogGetRefund(address requester, uint256 ticketsRefunded);
    event LogEndSale(address contractOwner, uint256 balanceTransfered);


    //SafeMath functions
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner() {
        require(isOwner(), "Caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /*
        Define a constructor.
        The constructor takes 3 arguments, the description, the URL and the number of tickets for sale.
        Set the owner to the creator of the contract.
        Set the appropriate myEvent details.
    */
    constructor (string memory description, string memory website, uint256 totalTickets) public {
        owner = msg.sender;

        myEvent.description = description;
        myEvent.website = website;
        myEvent.totalTickets = totalTickets;
        myEvent.sales = 0;
        myEvent.isOpen = true;
    }

    /*
        Define a function called readEvent() that returns the event details.
        This function does not modify state, add the appropriate keyword.
        The returned details should be called description, website, uint256 totalTickets, uint256 sales, bool isOpen in that order.
    */
    function readEvent()
        public
        view
        returns(string memory description, string memory website, uint256 totalTickets, uint256 sales, bool isOpen)
    {
        description = myEvent.description;
        website = myEvent.website;
        totalTickets = myEvent.totalTickets;
        sales = myEvent.sales;
        isOpen = myEvent.isOpen;
    }

    /*
        Define a function called getBuyerTicketCount().
        This function takes 1 argument, an address and
        returns the number of tickets that address has purchased.
    */
    function getBuyerTicketCount(address buyer) public view returns (uint) {
         require(buyer != address(0), "Invalid buyer address");
      return myEvent.buyers[buyer];
    }

    /*
        Define a function called buyTickets().
        This function allows someone to purchase tickets for the event.
        This function takes one argument, the number of tickets to be purchased.
        This function can accept Ether.
        Be sure to check:
            - That the event isOpen
            - That the transaction value is sufficient for the number of tickets purchased
            - That there are enough tickets in stock
        Then:
            - add the appropriate number of tickets to the purchasers count
            - account for the purchase in the remaining number of available tickets
            - refund any surplus value sent with the transaction
            - emit the appropriate event
    */
    function buyTickets(uint256 ticketsPurchased) public payable {
      require(myEvent.isOpen, "Event must be open");
      require(msg.value >= mul(ticketsPurchased, TICKET_PRICE), "Value is not sufficient for the number of tickets purchased");
      require(ticketsPurchased <= myEvent.totalTickets, "There are not enough tickets in stock");

      myEvent.totalTickets = sub(myEvent.totalTickets, ticketsPurchased);
      myEvent.buyers[msg.sender] = add(myEvent.buyers[msg.sender], ticketsPurchased);
      myEvent.sales = add(myEvent.sales, ticketsPurchased);

      if(msg.value > mul(ticketsPurchased, TICKET_PRICE)) {
        msg.sender.transfer(msg.value - mul(ticketsPurchased, TICKET_PRICE));
      }

      emit LogBuyTickets(msg.sender, ticketsPurchased);
    }

    /*
        Define a function called getRefund().
        This function allows someone to get a refund for tickets for the account they purchased from.
        TODO:
            - Check that the requester has purchased tickets.
            - Make sure the refunded tickets go back into the pool of avialable tickets.
            - Transfer the appropriate amount to the refund requester.
            - Emit the appropriate event.
    */
    function getRefund() public payable {
      require(myEvent.isOpen == true, "The event is closed");
      require(myEvent.buyers[msg.sender] > 0, "Requestor hasn't bought anything !");

      uint256 itemsToBeRefunded = myEvent.buyers[msg.sender];
      myEvent.totalTickets = add(myEvent.totalTickets, itemsToBeRefunded);
      myEvent.sales = sub(myEvent.sales, itemsToBeRefunded);
      myEvent.buyers[msg.sender] = 0;

      msg.sender.transfer(mul(itemsToBeRefunded, TICKET_PRICE));

      emit LogGetRefund(msg.sender, itemsToBeRefunded);
    }

    /*
        Define a function called endSale().
        This function will close the ticket sales.
        This function can only be called by the contract owner.
        TODO:
            - close the event
            - transfer the contract balance to the owner
            - emit the appropriate event
    */
    function endSale() public payable onlyOwner {
      require(myEvent.isOpen, "Event is already closed");
      myEvent.isOpen = false;
      uint256 balanceTransfer = address(this).balance;

      if (balanceTransfer > 0) {
        owner.transfer(balanceTransfer);
      }

      emit LogEndSale(owner, balanceTransfer);
    }

}
