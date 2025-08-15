-- 1) Create Tables

-- Products Table
CREATE TABLE Products (
    Id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL
);
SELECT * FROM Products;

-- Users Table
CREATE TABLE Users (
    User_ID SERIAL PRIMARY KEY,
    Username VARCHAR(100) NOT NULL
);
SELECT * FROM Users;

-- Cart Table (updated: tied to a specific user)
CREATE TABLE Cart (
    UserID INT NOT NULL,
    ProductId INT NOT NULL,
    Qty INT NOT NULL,
    CONSTRAINT PK_Cart PRIMARY KEY (UserID, ProductId),
    CONSTRAINT FK_Cart_User FOREIGN KEY (UserID) REFERENCES Users(User_ID),
    CONSTRAINT FK_Cart_Product FOREIGN KEY (ProductId) REFERENCES Products(Id)
);
SELECT * FROM Cart;

-- OrderHeader Table
CREATE TABLE OrderHeader (
    OrderID SERIAL PRIMARY KEY,
    UserID INT NOT NULL,
    Orderdate DATE NOT NULL,
    CONSTRAINT FK_OrderHeader_User FOREIGN KEY (UserID) REFERENCES Users(User_ID)
);
SELECT * FROM OrderHeader;

-- OrderDetails Table
CREATE TABLE OrderDetails (
    OrderHeader INT NOT NULL,
    ProdID INT NOT NULL,
    Qty INT NOT NULL,
    CONSTRAINT PK_OrderDetails PRIMARY KEY (OrderHeader, ProdID),
    CONSTRAINT FK_OrderDetails_OrderHeader FOREIGN KEY (OrderHeader) REFERENCES OrderHeader(OrderID),
    CONSTRAINT FK_OrderDetails_ProdID FOREIGN KEY (ProdID) REFERENCES Products(Id)
);
SELECT * FROM OrderDetails;


-- 2) Insert Sample Data for Products and Users
INSERT INTO Products (name, price) VALUES ('Coke', 10.00);
INSERT INTO Products (name, price) VALUES ('Chips', 5.00);

INSERT INTO Users (Username) VALUES ('Tom');
INSERT INTO Users (Username) VALUES ('Jem');

SELECT * FROM Products;
SELECT * FROM Users;


-- 3) Demonstrate Adding Items to the Cart

--FOR USER 1

-- adds Coke (ProductId = 1) to their cart
INSERT INTO Cart (UserID, ProductId, Qty)
VALUES (1, 1, 1)
ON CONFLICT (UserID, ProductId)
DO UPDATE SET Qty = Cart.Qty + 1;
SELECT * FROM Cart;

-- adds Coke (ProductId = 1) again (should update qty)
INSERT INTO Cart (UserID, ProductId, Qty)
VALUES (1, 1, 1)
ON CONFLICT (UserID, ProductId)
DO UPDATE SET Qty = Cart.Qty + 1;
SELECT * FROM Cart;

-- adds Chips (ProductId = 2) to their cart
INSERT INTO Cart (UserID, ProductId, Qty)
VALUES (1, 2, 1)
ON CONFLICT (UserID, ProductId)
DO UPDATE SET Qty = Cart.Qty + 1;
SELECT * FROM Cart;


--FOR USER 2

-- adds Coke (ProductId = 1) to their cart
INSERT INTO Cart (UserID, ProductId, Qty)
VALUES (2, 1, 1)
ON CONFLICT (UserID, ProductId)
DO UPDATE SET Qty = Cart.Qty + EXCLUDED.Qty;
SELECT * FROM Cart;

-- adds Coke (ProductId = 1) again (should update qty)
INSERT INTO Cart (UserID, ProductId, Qty)
VALUES (2, 1, 1)
ON CONFLICT (UserID, ProductId)
DO UPDATE SET Qty = Cart.Qty + EXCLUDED.Qty;
SELECT * FROM Cart;

-- adds Chips (ProductId = 2) to their cart
INSERT INTO Cart (UserID, ProductId, Qty)
VALUES (2, 2, 1)
ON CONFLICT (UserID, ProductId)
DO UPDATE SET Qty = Cart.Qty + EXCLUDED.Qty;
SELECT * FROM Cart;


-- 4) Removing Items from Cart

--FOR USER 1:

DO $$
BEGIN
    -- Check product 1 for User 1
    IF EXISTS (SELECT 1 FROM Cart WHERE UserID = 1 AND ProductId = 1 AND Qty > 1) THEN
        UPDATE Cart SET Qty = Qty - 1 
        WHERE UserID = 1 AND ProductId = 1;
    ELSIF EXISTS (SELECT 1 FROM Cart WHERE UserID = 1 AND ProductId = 1 AND Qty = 1) THEN
        DELETE FROM Cart WHERE UserID = 1 AND ProductId = 1;
    END IF;

    -- Check product 2 for User 1
    IF EXISTS (SELECT 1 FROM Cart WHERE UserID = 1 AND ProductId = 2 AND Qty = 1) THEN
        DELETE FROM Cart WHERE UserID = 1 AND ProductId = 2;
    END IF;
END $$;

select * from cart;

--FOR USER 2:
DO $$
BEGIN
    -- Check product 1 for User 2
    IF EXISTS (SELECT 1 FROM Cart WHERE UserID = 2 AND ProductId = 1 AND Qty > 1) THEN
        UPDATE Cart SET Qty = Qty - 1 
        WHERE UserID = 2 AND ProductId = 1;
    ELSIF EXISTS (SELECT 1 FROM Cart WHERE UserID = 2 AND ProductId = 1 AND Qty = 1) THEN
        DELETE FROM Cart WHERE UserID = 2 AND ProductId = 1;
    END IF;

    -- Check product 2 for User 2
    IF EXISTS (SELECT 1 FROM Cart WHERE UserID = 2 AND ProductId = 2 AND Qty = 1) THEN
        DELETE FROM Cart WHERE UserID = 2 AND ProductId = 2;
    END IF;
END $$;

select * from cart;

-- 5) Checkout with Transaction

-- Checkout for User 1

-- Insert into OrderHeader
INSERT INTO OrderHeader (UserID, Orderdate)
VALUES (1, CURRENT_DATE)
RETURNING OrderID;
SELECT * FROM OrderHeader;

-- Insert into OrderDetails
INSERT INTO OrderDetails (OrderHeader, ProdID, Qty)
SELECT 1, ProductId, Qty 
FROM Cart
WHERE UserID = 1;
SELECT * FROM OrderDetails;

-- Clear the user's cart after checkout
DELETE FROM Cart WHERE UserID = 1;

SELECT * FROM OrderHeader;
SELECT * FROM OrderDetails;
SELECT * FROM Cart;


-- Checkout for User 2

INSERT INTO OrderHeader (UserID, Orderdate)
VALUES (2, CURRENT_DATE)
RETURNING OrderID;
SELECT * FROM OrderHeader;

-- Assume OrderID = 2
INSERT INTO OrderDetails (OrderHeader, ProdID, Qty)
SELECT 2, ProductId, Qty
FROM Cart
WHERE UserID = 2;
SELECT * FROM OrderDetails;

DELETE FROM Cart WHERE UserID = 2;

SELECT * FROM OrderHeader;
SELECT * FROM OrderDetails;
SELECT * FROM Cart;

--Step 6 – Queries to Print Orders (with INNER JOINs)
--1. Print a Single Order
SELECT oh.OrderID, oh.OrderDate, u.Username, p.Name AS Product, od.Qty, p.Price, (od.Qty * p.Price) AS Total
FROM OrderHeader oh
JOIN Users u ON oh.UserID = u.User_ID
JOIN OrderDetails od ON oh.OrderID = od.OrderHeader
JOIN Products p ON od.ProdID = p.Id
WHERE oh.OrderID = 2;

--2. Print All Orders for a Day’s Shopping
SELECT oh.OrderID, oh.OrderDate, u.Username, p.Name AS Product, od.Qty, p.Price, (od.Qty * p.Price) AS Total
FROM OrderHeader oh
JOIN Users u ON oh.UserID = u.User_ID
JOIN OrderDetails od ON oh.OrderID = od.OrderHeader
JOIN Products p ON od.ProdID = p.Id
WHERE oh.OrderDate = CURRENT_DATE
ORDER BY oh.OrderID, u.Username;




DROP TABLE Products;
DROP TABLE Users;
DROP TABLE Cart;
DROP TABLE OrderHeader;
DROP TABLE OrderDetails;




