-- MySQL Stored Procedure
DELIMITER //
CREATE PROCEDURE SplitProducts()
BEGIN
    DECLARE order_id INT;
    DECLARE customer_name VARCHAR(255);
    DECLARE products_string TEXT;
    DECLARE product VARCHAR(255);
    DECLARE i INT;
    DECLARE done INT DEFAULT 0;

    -- Declare cursor to iterate through the original table
    DECLARE product_cursor CURSOR FOR
        SELECT OrderID, CustomerName, Products FROM ProductDetail;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Create a temporary table to store the 1NF result
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_product_detail (
        OrderID INT,
        CustomerName VARCHAR(255),
        Product VARCHAR(255)
    );

    OPEN product_cursor;

    read_loop: LOOP
        FETCH product_cursor INTO order_id, customer_name, products_string;
        IF done THEN
            LEAVE read_loop;
        END IF;

        SET i = 1;
        -- Loop through each product in the comma-separated string
        WHILE i <= LENGTH(products_string) - LENGTH(REPLACE(products_string, ',', '')) + 1 DO
            SET product = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(products_string, ',', i), ',', 1));
            INSERT INTO temp_product_detail (OrderID, CustomerName, Product) VALUES (order_id, customer_name, product);
            SET i = i + 1;
        END WHILE;
    END LOOP read_loop;

    CLOSE product_cursor;

    -- Select from the temporary table (the 1NF result)
    SELECT * FROM temp_product_detail;
    DROP TEMPORARY TABLE temp_product_detail; 
END //
DELIMITER ;

-- Call the procedure to execute it



-- Create the Orders table
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerName VARCHAR(255)
);

-- Create the OrderProducts table
CREATE TABLE OrderProducts (
    OrderID INT,
    Product VARCHAR(255),
    Quantity INT,
    PRIMARY KEY (OrderID, Product), -- Composite primary key
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) -- Foreign key to Orders
);

-- Populate the Orders table
INSERT INTO Orders (OrderID, CustomerName)
SELECT DISTINCT OrderID, CustomerName
FROM OrderDetails;

-- Populate the OrderProducts table
INSERT INTO OrderProducts (OrderID, Product, Quantity)
SELECT OrderID, Product, Quantity
FROM OrderDetails;

-- Drop the original OrderDetails table (optional, if you want to remove it)
-- DROP TABLE OrderDetails;

-- Select from the new tables to show the result
SELECT * FROM Orders;
SELECT * FROM OrderProducts;