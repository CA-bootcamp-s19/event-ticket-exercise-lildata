pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;

    constructor () public {
        owner = msg.sender;
    }


    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
      string description;
      string website;
      uint256 totalTickets;
      uint256 sales;
      mapping (address => uint) buyers;
      bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint256 => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

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
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory description, string memory website, uint totalTicketsForSale) public onlyOwner returns(uint id) {
        id = idGenerator;
        idGenerator += 1;
        events[id] = Event({description: description, website: website, totalTickets: totalTicketsForSale, sales: 0, isOpen: true});

        emit LogEventAdded(description, website, totalTicketsForSale, id);

        return id;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint id)
    public
    view
    returns (string memory description, string memory website, uint totalTickets, uint sales, bool isOpen) {
        Event storage thisEvent = events[id];
        return (thisEvent.description, thisEvent.website, thisEvent.totalTickets, thisEvent.sales, thisEvent.isOpen);
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint eventId, uint ticketsCount) public payable {
        Event storage thisEvent = events[eventId];
        require(thisEvent.isOpen == true, "This event is closed");
        require(ticketsCount <= sub(thisEvent.totalTickets, thisEvent.sales), "Not enought available tickets");
        uint totalPrice = mul(ticketsCount, PRICE_TICKET);
        require(msg.value >= totalPrice, "Amount transfer is too low");

        thisEvent.buyers[msg.sender] = add(thisEvent.buyers[msg.sender], ticketsCount);
        thisEvent.sales = add(thisEvent.sales, ticketsCount);

        uint amountToRefund = sub(msg.value, totalPrice);
        if (amountToRefund > 0) {
          msg.sender.transfer(amountToRefund);
        }

        emit LogBuyTickets(msg.sender, eventId, ticketsCount);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint eventId) public payable {
        Event storage thisEvent = events[eventId];
        require(thisEvent.isOpen == true, "This event is closed");
        require(thisEvent.buyers[msg.sender] > 0, "Requestor hasn't bought anything for this event");

        uint ticketsRefunded = thisEvent.buyers[msg.sender];
        uint amountRefunded = mul(ticketsRefunded, PRICE_TICKET);
        thisEvent.buyers[msg.sender] = 0;
        thisEvent.sales = sub(thisEvent.sales, ticketsRefunded);
        msg.sender.transfer(amountRefunded);


        emit LogGetRefund(msg.sender, eventId, ticketsRefunded);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint eventId) public view returns(uint) {
        return events[eventId].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint eventId) public onlyOwner {
        Event storage thisEvent = events[eventId];
        require(thisEvent.isOpen == true, "Event is closed");

        thisEvent.isOpen = false;
        uint256 total = mul(PRICE_TICKET, thisEvent.sales);
        if (total > 0) {
            owner.transfer(total);
        }

        emit LogEndSale(owner, total, eventId);
    }
}
