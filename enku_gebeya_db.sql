-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Jul 09, 2025 at 05:01 PM
-- Server version: 9.1.0
-- PHP Version: 8.3.14

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `nemolight_finance`
--

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `AddExpense`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `AddExpense` (IN `p_date` DATE, IN `p_category` VARCHAR(255), IN `p_description` TEXT, IN `p_amount` DECIMAL(10,2))   BEGIN
    INSERT INTO expenses (date, category, description, amount)
    VALUES (p_date, p_category, p_description, p_amount);
    SELECT LAST_INSERT_ID() AS id; -- Return the ID of the newly inserted record
END$$

DROP PROCEDURE IF EXISTS `AddSale`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `AddSale` (IN `p_TotalAmount` DECIMAL(10,2), IN `p_PaymentMethod` ENUM('Cash','Card','MobileMoney'), IN `p_Notes` TEXT)   BEGIN
    INSERT INTO Sales (TotalAmount, PaymentMethod, Notes)
    VALUES (p_TotalAmount, p_PaymentMethod, p_Notes);
END$$

DROP PROCEDURE IF EXISTS `CreateRole`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `CreateRole` (IN `p_Name` VARCHAR(50), OUT `p_Id` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Rollback on error
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error creating role';
    END;

    START TRANSACTION;
    INSERT INTO Roles (Name)
    VALUES (p_Name);
    SET p_Id = LAST_INSERT_ID();
    COMMIT;
END$$

DROP PROCEDURE IF EXISTS `CreateUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `CreateUser` (IN `p_Username` VARCHAR(255), IN `p_PasswordHash` VARCHAR(255), IN `p_RoleId` INT, IN `p_Email` VARCHAR(255), IN `p_IsAdmin` TINYINT(1), OUT `p_Id` INT)   BEGIN
    INSERT INTO Users (Username, PasswordHash, RoleId, Email, IsAdmin, CreatedAt)
    VALUES (p_Username, p_PasswordHash, p_RoleId, p_Email, p_IsAdmin, NOW());
    SET p_Id = LAST_INSERT_ID();
END$$

DROP PROCEDURE IF EXISTS `CreateUserInRole`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `CreateUserInRole` (IN `p_CurrentUserId` INT, IN `p_UserId` INT, IN `p_RoleId` INT, IN `p_RoleName` VARCHAR(50), OUT `p_Id` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Rollback on error
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error creating user-role mapping';
    END;

    -- Validate admin permission
    CALL ValidateAdminPermission(p_CurrentUserId);

    START TRANSACTION;
    INSERT INTO UserInRoles (UserId, RoleId, RoleName)
    VALUES (p_UserId, p_RoleId, p_RoleName);
    SET p_Id = LAST_INSERT_ID();
    COMMIT;
END$$

DROP PROCEDURE IF EXISTS `DeleteCashFlow`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteCashFlow` (IN `p_id` INT)   BEGIN
    DELETE FROM cash_flows WHERE id = p_id;
END$$

DROP PROCEDURE IF EXISTS `DeleteExpense`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteExpense` (IN `p_id` INT)   BEGIN
    DELETE FROM expenses
    WHERE id = p_id;
END$$

DROP PROCEDURE IF EXISTS `DeleteIncome`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteIncome` (IN `p_id` INT)   BEGIN
    DELETE FROM Income
    WHERE id = p_id;
END$$

DROP PROCEDURE IF EXISTS `DeleteRole`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteRole` (IN `p_Id` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Rollback on error
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error deleting role';
    END;

    START TRANSACTION;
    DELETE FROM Roles WHERE Id = p_Id;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Role not found';
    END IF;
    COMMIT;
END$$

DROP PROCEDURE IF EXISTS `DeleteSale`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteSale` (IN `p_SaleID` INT)   BEGIN
    DELETE FROM Sales WHERE SaleID = p_SaleID;
END$$

DROP PROCEDURE IF EXISTS `DeleteUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteUser` (IN `p_Id` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Rollback on error
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error deleting user';
    END;

    START TRANSACTION;
    DELETE FROM Users WHERE Id = p_Id;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found';
    END IF;
    COMMIT;
END$$

DROP PROCEDURE IF EXISTS `DeleteUserInRole`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteUserInRole` (IN `p_CurrentUserId` INT, IN `p_Id` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error deleting user-role mapping';
    END;

    -- Validate admin permission
    CALL ValidateAdminPermission(p_CurrentUserId);

    START TRANSACTION;
    DELETE FROM UserInRoles WHERE Id = p_Id;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User-role mapping not found';
    END IF;
    COMMIT;
END$$

DROP PROCEDURE IF EXISTS `GetAllCashFlows`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllCashFlows` ()   BEGIN
    SELECT id, date, description, amount FROM cash_flows ORDER BY date DESC, id DESC;
END$$

DROP PROCEDURE IF EXISTS `GetAllExpenses`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllExpenses` ()   BEGIN
    SELECT id, date, category, description, amount
    FROM expenses;
END$$

DROP PROCEDURE IF EXISTS `GetAllIncome`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllIncome` ()   BEGIN
    SELECT id, date, source, description, amount
    FROM Income;
END$$

DROP PROCEDURE IF EXISTS `GetCashFlow`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetCashFlow` ()   BEGIN
    SELECT * FROM CashFlow;
END$$

DROP PROCEDURE IF EXISTS `GetCashFlowById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetCashFlowById` (IN `p_id` INT)   BEGIN
    SELECT id, date, description, amount FROM cash_flows WHERE id = p_id;
END$$

DROP PROCEDURE IF EXISTS `GetExpenseById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetExpenseById` (IN `p_id` INT)   BEGIN
    SELECT id, date, category, description, amount
    FROM expenses
    WHERE id = p_id;
END$$

DROP PROCEDURE IF EXISTS `GetExpenses`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetExpenses` ()   BEGIN
    SELECT * FROM Expenses;
END$$

DROP PROCEDURE IF EXISTS `GetIncomeById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetIncomeById` (IN `p_id` INT)   BEGIN
    SELECT id, date, source, description, amount
    FROM Income
    WHERE id = p_id;
END$$

DROP PROCEDURE IF EXISTS `GetSaleByID`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetSaleByID` (IN `p_SaleID` INT)   BEGIN
    SELECT * FROM Sales WHERE SaleID = p_SaleID;
END$$

DROP PROCEDURE IF EXISTS `GetSales`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetSales` ()   BEGIN
    SELECT * FROM Sales;
END$$

DROP PROCEDURE IF EXISTS `GetSupplierByID`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetSupplierByID` (IN `p_SupplierID` INT)   BEGIN
    SELECT * FROM Suppliers WHERE SupplierID = p_SupplierID;
END$$

DROP PROCEDURE IF EXISTS `GetSuppliers`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetSuppliers` ()   BEGIN
    SELECT * FROM Suppliers;
END$$

DROP PROCEDURE IF EXISTS `InsertCashFlow`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertCashFlow` (IN `p_date` DATE, IN `p_description` VARCHAR(255), IN `p_amount` DECIMAL(10,2))   BEGIN
    INSERT INTO cash_flows (date, description, amount)
    VALUES (p_date, p_description, p_amount);
    
    SELECT LAST_INSERT_ID() AS id; -- Return the ID of the newly inserted row
END$$

DROP PROCEDURE IF EXISTS `InsertIncome`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertIncome` (IN `p_date` DATE, IN `p_source` VARCHAR(255), IN `p_description` TEXT, IN `p_amount` DECIMAL(10,2))   BEGIN
    INSERT INTO Income (date, source, description, amount)
    VALUES (p_date, p_source, p_description, p_amount);
END$$

DROP PROCEDURE IF EXISTS `ReadRole`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `ReadRole` (IN `p_Id` INT)   BEGIN
    SELECT Id, Name
    FROM Roles
    WHERE Id = p_Id;
END$$

DROP PROCEDURE IF EXISTS `ReadUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `ReadUser` (IN `p_Id` INT)   BEGIN
    SELECT u.Id, u.Username, u.PasswordHash, u.RoleId, r.Name AS RoleName, u.CreatedAt
    FROM Users u
    LEFT JOIN Roles r ON u.RoleId = r.Id
    WHERE u.Id = p_Id;
END$$

DROP PROCEDURE IF EXISTS `ReadUserInRole`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `ReadUserInRole` (IN `p_Id` INT)   BEGIN
    SELECT ur.Id, ur.UserId, u.Username, ur.RoleId, r.Name AS RoleName, ur.RoleName AS AssignedRoleName
    FROM UserInRoles ur
    LEFT JOIN Users u ON ur.UserId = u.Id
    LEFT JOIN Roles r ON ur.RoleId = r.Id
    WHERE ur.Id = p_Id;
END$$

DROP PROCEDURE IF EXISTS `sp_CreateProduct`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_CreateProduct` (IN `p_ProductName` VARCHAR(100), IN `p_SKU` VARCHAR(50), IN `p_Description` TEXT, IN `p_UnitPrice` DECIMAL(10,2), IN `p_QTY` INT, IN `p_WarehouseID` INT, IN `p_Photo` TEXT, OUT `p_ProductID` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An error occurred';
    END;

    -- Validate input parameters
    IF p_ProductName IS NULL OR p_ProductName = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ProductName cannot be empty.';
    END IF;
    IF p_SKU IS NULL OR p_SKU = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SKU cannot be empty.';
    END IF;
    IF p_UnitPrice <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UnitPrice must be greater than zero.';
    END IF;
    IF p_QTY < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity cannot be negative.';
    END IF;
    IF p_WarehouseID IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Warehouses WHERE WarehouseID = p_WarehouseID AND Status = 'Active'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Specified WarehouseID does not exist or is not active.';
    END IF;

    START TRANSACTION;

    -- Insert the product
    INSERT INTO Products (ProductName, SKU, Description, UnitPrice, QTY, Status, Photo)
    VALUES (p_ProductName, p_SKU, p_Description, p_UnitPrice, p_QTY, 'Active', p_Photo);

    SET p_ProductID = LAST_INSERT_ID();

    -- Create inventory record if WarehouseID is provided and QTY > 0
    IF p_WarehouseID IS NOT NULL AND p_QTY > 0 THEN
        INSERT INTO Inventory (ProductID, WarehouseID, Quantity, Status)
        VALUES (p_ProductID, p_WarehouseID, p_QTY, 'Active');

        -- Log the initial stock transaction
        INSERT INTO StockTransactions (ProductID, WarehouseID, Quantity, TransactionType, Status, Remarks)
        VALUES (p_ProductID, p_WarehouseID, p_QTY, 'IN', 'Active', 'Initial stock from product creation');
    END IF;

    COMMIT;
END$$

DROP PROCEDURE IF EXISTS `sp_CreateWarehouse`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_CreateWarehouse` (IN `p_WarehouseName` VARCHAR(100), IN `p_Location` VARCHAR(200), OUT `p_WarehouseID` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An error occurred';
    END;

    IF p_WarehouseName IS NULL OR p_WarehouseName = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'WarehouseName cannot be empty.';
    END IF;

    INSERT INTO Warehouses (WarehouseName, Location, Status)
    VALUES (p_WarehouseName, p_Location, 'Active');

    SET p_WarehouseID = LAST_INSERT_ID();
END$$

DROP PROCEDURE IF EXISTS `sp_DeleteSale`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_DeleteSale` (IN `p_id` INT)   BEGIN
    DELETE FROM Sales WHERE id = p_id;
END$$

DROP PROCEDURE IF EXISTS `sp_GetAllSales`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetAllSales` ()   BEGIN
    SELECT * FROM Sales ORDER BY date DESC, id DESC;
END$$

DROP PROCEDURE IF EXISTS `sp_GetInventoryStatus`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetInventoryStatus` (IN `p_WarehouseID` INT, IN `p_IncludeDeleted` BOOLEAN)   BEGIN
    SELECT 
        p.ProductID,
        p.ProductName,
        p.SKU,
        w.WarehouseID,
        w.WarehouseName,
        COALESCE(i.Quantity, 0) AS Quantity,
        i.Status,
        i.LastUpdated
    FROM Products p
    CROSS JOIN Warehouses w
    LEFT JOIN Inventory i ON p.ProductID = i.ProductID AND w.WarehouseID = i.WarehouseID
    WHERE (p_WarehouseID IS NULL OR w.WarehouseID = p_WarehouseID)
        AND (p_IncludeDeleted = 1 OR (
            p.Status = 'Active' AND 
            w.Status = 'Active' AND 
            (i.Status = 'Active' OR i.Status IS NULL)
        ))
    ORDER BY p.ProductID, w.WarehouseID;
END$$

DROP PROCEDURE IF EXISTS `sp_GetLowStock`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetLowStock` (IN `p_Threshold` INT, IN `p_WarehouseID` INT)   BEGIN
    SELECT 
        p.ProductID,
        p.ProductName,
        p.SKU,
        w.WarehouseID,
        w.WarehouseName,
        i.Quantity,
        i.Status
    FROM Inventory i
    JOIN Products p ON i.ProductID = p.ProductID
    JOIN Warehouses w ON i.WarehouseID = w.WarehouseID
    WHERE i.Quantity <= p_Threshold
        AND (p_WarehouseID IS NULL OR i.WarehouseID = p_WarehouseID)
        AND i.Status = 'Active'
        AND p.Status = 'Active'
        AND w.Status = 'Active'
    ORDER BY i.Quantity, p.ProductID;
END$$

DROP PROCEDURE IF EXISTS `sp_GetProduct`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetProduct` (IN `p_ProductID` INT, IN `p_IncludeDeleted` BOOLEAN)   BEGIN
    SELECT ProductID, ProductName, SKU, Description, UnitPrice, Status, CreatedAt, UpdatedAt, QTY, Photo
    FROM Products
    WHERE (p_ProductID IS NULL OR ProductID = p_ProductID)
        AND (p_IncludeDeleted = 1 OR Status = 'Active')
    ORDER BY ProductID;
END$$

DROP PROCEDURE IF EXISTS `sp_GetSaleById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetSaleById` (IN `p_id` INT)   BEGIN
    SELECT * FROM Sales WHERE id = p_id;
END$$

DROP PROCEDURE IF EXISTS `sp_GetTransactionHistory`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetTransactionHistory` (IN `p_ProductID` INT, IN `p_WarehouseID` INT, IN `p_StartDate` DATETIME, IN `p_EndDate` DATETIME, IN `p_IncludeDeleted` BOOLEAN)   BEGIN
    SELECT 
        t.TransactionID,
        t.ProductID,
        p.ProductName,
        p.SKU,
        t.WarehouseID,
        w.WarehouseName,
        t.Quantity,
        t.TransactionType,
        t.Status,
        t.TransactionDate,
        t.Remarks
    FROM StockTransactions t
    JOIN Products p ON t.ProductID = p.ProductID
    JOIN Warehouses w ON t.WarehouseID = w.WarehouseID
    WHERE (p_ProductID IS NULL OR t.ProductID = p_ProductID)
        AND (p_WarehouseID IS NULL OR t.WarehouseID = p_WarehouseID)
        AND (p_StartDate IS NULL OR t.TransactionDate >= p_StartDate)
        AND (p_EndDate IS NULL OR t.TransactionDate <= p_EndDate)
        AND (p_IncludeDeleted = 1 OR t.Status = 'Active')
    ORDER BY t.TransactionDate DESC;
END$$

DROP PROCEDURE IF EXISTS `sp_GetWarehouse`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_GetWarehouse` (IN `p_WarehouseID` INT, IN `p_IncludeDeleted` BOOLEAN)   BEGIN
    SELECT WarehouseID, WarehouseName, Location, Status, CreatedAt
    FROM Warehouses
    WHERE (p_WarehouseID IS NULL OR WarehouseID = p_WarehouseID)
        AND (p_IncludeDeleted = 1 OR Status = 'Active')
    ORDER BY WarehouseID;
END$$

DROP PROCEDURE IF EXISTS `sp_InsertSale`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_InsertSale` (IN `p_date` DATE, IN `p_customerName` VARCHAR(255), IN `p_itemSold` VARCHAR(255), IN `p_quantity` INT, IN `p_unitPrice` DECIMAL(10,2))   BEGIN
    DECLARE p_totalAmount DECIMAL(10, 2);
    SET p_totalAmount = p_quantity * p_unitPrice;

    INSERT INTO Sales (date, customerName, itemSold, quantity, unitPrice, totalAmount)
    VALUES (p_date, p_customerName, p_itemSold, p_quantity, p_unitPrice, p_totalAmount);

    SELECT LAST_INSERT_ID() AS id; -- Return the ID of the newly inserted row
END$$

DROP PROCEDURE IF EXISTS `sp_MarkProductDeleted`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_MarkProductDeleted` (IN `p_ProductID` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An error occurred';
    END;

    IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = p_ProductID AND Status = 'Active') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid or already deleted ProductID.';
    END IF;
    IF EXISTS (SELECT 1 FROM Inventory WHERE ProductID = p_ProductID AND Status = 'Active') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot mark product as deleted with active inventory.';
    END IF;
    IF EXISTS (SELECT 1 FROM StockTransactions WHERE ProductID = p_ProductID AND Status = 'Active') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot mark product as deleted with active transaction history.';
    END IF;

    UPDATE Products
    SET Status = 'Deleted',
        UpdatedAt = CURRENT_TIMESTAMP
    WHERE ProductID = p_ProductID AND Status = 'Active';
END$$

DROP PROCEDURE IF EXISTS `sp_MarkTransactionDeleted`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_MarkTransactionDeleted` (IN `p_TransactionID` INT)   BEGIN
    DECLARE v_ProductID INT;
    DECLARE v_WarehouseID INT;
    DECLARE v_Quantity INT;
    DECLARE v_TransactionType VARCHAR(10);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An error occurred';
    END;

    -- Get transaction details
    SELECT ProductID, WarehouseID, Quantity, TransactionType
    INTO v_ProductID, v_WarehouseID, v_Quantity, v_TransactionType
    FROM StockTransactions
    WHERE TransactionID = p_TransactionID AND Status = 'Active';

    IF v_ProductID IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid or already deleted TransactionID.';
    END IF;

    START TRANSACTION;

    -- Reverse inventory change
    IF EXISTS (
        SELECT 1 FROM Inventory 
        WHERE ProductID = v_ProductID AND WarehouseID = v_WarehouseID AND Status = 'Active'
    ) THEN
        UPDATE Inventory
        SET Quantity = CASE 
            WHEN v_TransactionType = 'IN' THEN Quantity - v_Quantity
            WHEN v_TransactionType = 'OUT' THEN Quantity + v_Quantity
            END,
            LastUpdated = CURRENT_TIMESTAMP
        WHERE ProductID = v_ProductID AND WarehouseID = v_WarehouseID AND Status = 'Active';

        IF (SELECT Quantity FROM Inventory 
            WHERE ProductID = v_ProductID AND WarehouseID = v_WarehouseID AND Status = 'Active') < 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reversing transaction would cause negative stock.';
        END IF;
    ELSE
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No active inventory record to reverse transaction.';
    END IF;

    -- Mark transaction as deleted
    UPDATE StockTransactions
    SET Status = 'Deleted'
    WHERE TransactionID = p_TransactionID AND Status = 'Active';

    COMMIT;
END$$

DROP PROCEDURE IF EXISTS `sp_MarkWarehouseDeleted`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_MarkWarehouseDeleted` (IN `p_WarehouseID` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An error occurred';
    END;

    IF NOT EXISTS (SELECT 1 FROM Warehouses WHERE WarehouseID = p_WarehouseID AND Status = 'Active') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid or already deleted WarehouseID.';
    END IF;
    IF EXISTS (SELECT 1 FROM Inventory WHERE WarehouseID = p_WarehouseID AND Status = 'Active') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot mark warehouse as deleted with active inventory.';
    END IF;
    IF EXISTS (SELECT 1 FROM StockTransactions WHERE WarehouseID = p_WarehouseID AND Status = 'Active') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot mark warehouse as deleted with active transaction history.';
    END IF;

    UPDATE Warehouses
    SET Status = 'Deleted'
    WHERE WarehouseID = p_WarehouseID AND Status = 'Active';
END$$

DROP PROCEDURE IF EXISTS `sp_UpdateInventory`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_UpdateInventory` (IN `p_ProductID` INT, IN `p_WarehouseID` INT, IN `p_Quantity` INT, IN `p_TransactionType` VARCHAR(10), IN `p_Remarks` VARCHAR(200), OUT `p_TransactionID` INT)   BEGIN
    DECLARE v_CurrentQuantity INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An error occurred';
    END;

    -- Validate input parameters
    IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = p_ProductID AND Status = 'Active') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid or deleted ProductID.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Warehouses WHERE WarehouseID = p_WarehouseID AND Status = 'Active') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid or deleted WarehouseID.';
    END IF;
    IF p_Quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be greater than zero.';
    END IF;
    IF p_TransactionType NOT IN ('IN', 'OUT') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TransactionType must be IN or OUT.';
    END IF;

    START TRANSACTION;

    -- Check existing inventory
    SELECT COALESCE(Quantity, 0) INTO v_CurrentQuantity
    FROM Inventory
    WHERE ProductID = p_ProductID AND WarehouseID = p_WarehouseID AND Status = 'Active';

    -- Validate stock for OUT transaction
    IF p_TransactionType = 'OUT' AND (v_CurrentQuantity IS NULL OR v_CurrentQuantity < p_Quantity) THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock for OUT transaction.';
    END IF;

    -- Update or insert inventory record
    IF v_CurrentQuantity IS NOT NULL THEN
        UPDATE Inventory
        SET Quantity = CASE 
            WHEN p_TransactionType = 'IN' THEN Quantity + p_Quantity
            WHEN p_TransactionType = 'OUT' THEN Quantity - p_Quantity
            END,
            LastUpdated = CURRENT_TIMESTAMP
        WHERE ProductID = p_ProductID AND WarehouseID = p_WarehouseID AND Status = 'Active';
    ELSEIF p_TransactionType = 'IN' THEN
        INSERT INTO Inventory (ProductID, WarehouseID, Quantity, Status)
        VALUES (p_ProductID, p_WarehouseID, p_Quantity, 'Active');
    ELSE
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No active inventory record for OUT transaction.';
    END IF;

    -- Update Products table with total quantity across all warehouses
    UPDATE Products
    SET QTY = (
        SELECT SUM(Quantity)
        FROM Inventory
        WHERE ProductID = p_ProductID AND Status = 'Active'
    ),
    UpdatedAt = CURRENT_TIMESTAMP
    WHERE ProductID = p_ProductID AND Status = 'Active';

    -- Record the transaction
    INSERT INTO StockTransactions (ProductID, WarehouseID, Quantity, TransactionType, Status, Remarks)
    VALUES (p_ProductID, p_WarehouseID, p_Quantity, p_TransactionType, 'Active', p_Remarks);

    SET p_TransactionID = LAST_INSERT_ID();

    COMMIT;
END$$

DROP PROCEDURE IF EXISTS `sp_UpdateProduct`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_UpdateProduct` (IN `p_ProductID` INT, IN `p_ProductName` VARCHAR(100), IN `p_SKU` VARCHAR(50), IN `p_Description` TEXT, IN `p_UnitPrice` DECIMAL(10,2), IN `p_QTY` INT, IN `p_WarehouseID` INT, IN `p_Photo` TEXT)   BEGIN
    DECLARE v_CurrentQuantity INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An error occurred';
    END;

    -- Validate input parameters
    IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = p_ProductID AND Status = 'Active') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid or deleted ProductID.';
    END IF;
    IF p_ProductName IS NULL OR p_ProductName = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ProductName cannot be empty.';
    END IF;
    IF p_SKU IS NULL OR p_SKU = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SKU cannot be empty.';
    END IF;
    IF p_UnitPrice <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UnitPrice must be greater than zero.';
    END IF;
    IF p_QTY IS NOT NULL AND p_QTY < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity cannot be negative.';
    END IF;
    IF p_WarehouseID IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Warehouses WHERE WarehouseID = p_WarehouseID AND Status = 'Active'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Specified WarehouseID does not exist or is not active.';
    END IF;

    START TRANSACTION;

    -- Update product details
    UPDATE Products
    SET ProductName = p_ProductName,
        SKU = p_SKU,
        Description = p_Description,
        UnitPrice = p_UnitPrice,
        UpdatedAt = CURRENT_TIMESTAMP,
        Photo = p_Photo
    WHERE ProductID = p_ProductID AND Status = 'Active';

    -- Update inventory if both WarehouseID and QTY are provided
    IF p_WarehouseID IS NOT NULL AND p_QTY IS NOT NULL THEN
        SELECT COALESCE(Quantity, 0) INTO v_CurrentQuantity
        FROM Inventory
        WHERE ProductID = p_ProductID AND WarehouseID = p_WarehouseID AND Status = 'Active';

        IF v_CurrentQuantity IS NOT NULL THEN
            IF p_QTY > v_CurrentQuantity THEN
                -- IN transaction for the difference
                SET @QuantityToAdd = p_QTY - v_CurrentQuantity;
                UPDATE Inventory
                SET Quantity = p_QTY,
                    LastUpdated = CURRENT_TIMESTAMP
                WHERE ProductID = p_ProductID AND WarehouseID = p_WarehouseID AND Status = 'Active';

                INSERT INTO StockTransactions (ProductID, WarehouseID, Quantity, TransactionType, Status, Remarks)
                VALUES (p_ProductID, p_WarehouseID, @QuantityToAdd, 'IN', 'Active', 'Quantity adjustment via product update');
            ELSEIF p_QTY < v_CurrentQuantity THEN
                -- OUT transaction for the difference
                SET @QuantityToRemove = v_CurrentQuantity - p_QTY;
                UPDATE Inventory
                SET Quantity = p_QTY,
                    LastUpdated = CURRENT_TIMESTAMP
                WHERE ProductID = p_ProductID AND WarehouseID = p_WarehouseID AND Status = 'Active';

                INSERT INTO StockTransactions (ProductID, WarehouseID, Quantity, TransactionType, Status, Remarks)
                VALUES (p_ProductID, p_WarehouseID, @QuantityToRemove, 'OUT', 'Active', 'Quantity adjustment via product update');
            END IF;
        ELSE
            INSERT INTO Inventory (ProductID, WarehouseID, Quantity, Status)
            VALUES (p_ProductID, p_WarehouseID, p_QTY, 'Active');

            INSERT INTO StockTransactions (ProductID, WarehouseID, Quantity, TransactionType, Status, Remarks)
            VALUES (p_ProductID, p_WarehouseID, p_QTY, 'IN', 'Active', 'Initial stock via product update');
        END IF;

        -- Update Products.QTY to reflect total inventory
        UPDATE Products
        SET QTY = (
            SELECT SUM(Quantity)
            FROM Inventory
            WHERE ProductID = p_ProductID AND Status = 'Active'
        ),
        UpdatedAt = CURRENT_TIMESTAMP
        WHERE ProductID = p_ProductID AND Status = 'Active';
    END IF;

    COMMIT;
END$$

DROP PROCEDURE IF EXISTS `sp_UpdateSale`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_UpdateSale` (IN `p_id` INT, IN `p_date` DATE, IN `p_customerName` VARCHAR(255), IN `p_itemSold` VARCHAR(255), IN `p_quantity` INT, IN `p_unitPrice` DECIMAL(10,2))   BEGIN
    DECLARE p_totalAmount DECIMAL(10, 2);
    SET p_totalAmount = p_quantity * p_unitPrice;

    UPDATE Sales
    SET
        date = p_date,
        customerName = p_customerName,
        itemSold = p_itemSold,
        quantity = p_quantity,
        unitPrice = p_unitPrice,
        totalAmount = p_totalAmount
    WHERE id = p_id;
END$$

DROP PROCEDURE IF EXISTS `sp_UpdateWarehouse`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_UpdateWarehouse` (IN `p_WarehouseID` INT, IN `p_WarehouseName` VARCHAR(100), IN `p_Location` VARCHAR(200))   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An error occurred';
    END;

    IF NOT EXISTS (SELECT 1 FROM Warehouses WHERE WarehouseID = p_WarehouseID AND Status = 'Active') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid or deleted WarehouseID.';
    END IF;
    IF p_WarehouseName IS NULL OR p_WarehouseName = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'WarehouseName cannot be empty.';
    END IF;

    UPDATE Warehouses
    SET WarehouseName = p_WarehouseName,
        Location = p_Location
    WHERE WarehouseID = p_WarehouseID AND Status = 'Active';
END$$

DROP PROCEDURE IF EXISTS `UpdateCashFlow`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateCashFlow` (IN `p_id` INT, IN `p_date` DATE, IN `p_description` VARCHAR(255), IN `p_amount` DECIMAL(10,2))   BEGIN
    UPDATE cash_flows
    SET
        date = p_date,
        description = p_description,
        amount = p_amount
    WHERE id = p_id;
END$$

DROP PROCEDURE IF EXISTS `UpdateExpense`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateExpense` (IN `p_id` INT, IN `p_date` DATE, IN `p_category` VARCHAR(255), IN `p_description` TEXT, IN `p_amount` DECIMAL(10,2))   BEGIN
    UPDATE expenses
    SET
        date = p_date,
        category = p_category,
        description = p_description,
        amount = p_amount
    WHERE id = p_id;
END$$

DROP PROCEDURE IF EXISTS `UpdateIncome`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateIncome` (IN `p_id` INT, IN `p_date` DATE, IN `p_source` VARCHAR(255), IN `p_description` TEXT, IN `p_amount` DECIMAL(10,2))   BEGIN
    UPDATE Income
    SET
        date = p_date,
        source = p_source,
        description = p_description,
        amount = p_amount
    WHERE id = p_id;
END$$

DROP PROCEDURE IF EXISTS `UpdateRole`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateRole` (IN `p_Id` INT, IN `p_Name` VARCHAR(50))   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Rollback on error
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error updating role';
    END;

    START TRANSACTION;
    UPDATE Roles
    SET Name = p_Name
    WHERE Id = p_Id;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Role not found';
    END IF;
    COMMIT;
END$$

DROP PROCEDURE IF EXISTS `UpdateSale`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateSale` (IN `p_SaleID` INT, IN `p_TotalAmount` DECIMAL(10,2), IN `p_PaymentMethod` ENUM('Cash','Card','MobileMoney'), IN `p_Notes` TEXT)   BEGIN
    UPDATE Sales 
    SET TotalAmount = p_TotalAmount, PaymentMethod = p_PaymentMethod, Notes = p_Notes
    WHERE SaleID = p_SaleID;
END$$

DROP PROCEDURE IF EXISTS `UpdateSupplier`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateSupplier` (IN `p_SupplierID` INT, IN `p_Name` VARCHAR(100), IN `p_Phone` VARCHAR(20), IN `p_Address` TEXT)   BEGIN
    UPDATE Suppliers 
    SET Name = p_Name, Phone = p_Phone, Address = p_Address
    WHERE SupplierID = p_SupplierID;
END$$

DROP PROCEDURE IF EXISTS `UpdateUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateUser` (IN `p_Id` INT, IN `p_Username` VARCHAR(50), IN `p_PasswordHash` VARCHAR(255), IN `p_RoleId` INT, IN `p_Email` VARCHAR(255), IN `p_IsAdmin` TINYINT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Rollback on error
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 @msg = MESSAGE_TEXT;
    END;

    START TRANSACTION;
    -- Validate RoleId exists
    IF NOT EXISTS (SELECT 1 FROM Roles WHERE Id = p_RoleId) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid RoleId';
        ROLLBACK;
    END IF;

    -- Validate User exists (handled by ROW_COUNT, but pre-check for clarity)
    IF NOT EXISTS (SELECT 1 FROM Users WHERE Id = p_Id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found';
        ROLLBACK;
    END IF;

    UPDATE Users
    SET Username = p_Username,
        PasswordHash = IFNULL(p_PasswordHash, (SELECT PasswordHash FROM Users WHERE Id = p_Id LIMIT 1)),
        RoleId = p_RoleId,
        Email = p_Email,
        IsAdmin = p_IsAdmin,
        CreatedAt = NOW()
    WHERE Id = p_Id;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found';
    END IF;
    COMMIT;
END$$

DROP PROCEDURE IF EXISTS `UpdateUserInRole`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateUserInRole` (IN `p_CurrentUserId` INT, IN `p_Id` INT, IN `p_UserId` INT, IN `p_RoleId` INT, IN `p_RoleName` VARCHAR(50))   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error updating user-role mapping';
    END;

    -- Validate admin permission
    CALL ValidateAdminPermission(p_CurrentUserId);

    START TRANSACTION;
    UPDATE UserInRoles
    SET UserId = p_UserId,
        RoleId = p_RoleId,
        RoleName = p_RoleName
    WHERE Id = p_Id;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User-role mapping not found';
    END IF;
    COMMIT;
END$$

DROP PROCEDURE IF EXISTS `ValidateAdminPermission`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `ValidateAdminPermission` (IN `p_CurrentUserId` INT)   BEGIN
    DECLARE v_isAdmin TINYINT;
    SELECT isAdmin INTO v_isAdmin
    FROM Users
    WHERE Id = p_CurrentUserId;

    IF v_isAdmin != 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Permission denied: Only admins can perform this action';
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `cash_flows`
--

DROP TABLE IF EXISTS `cash_flows`;
CREATE TABLE IF NOT EXISTS `cash_flows` (
  `id` int NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `description` varchar(255) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `cash_flows`
--

INSERT INTO `cash_flows` (`id`, `date`, `description`, `amount`, `created_at`) VALUES
(7, '2025-06-24', 'Salary', -600.00, '2025-06-15 14:25:39'),
(6, '2025-06-17', 'Investment Returnn', 5000.00, '2025-06-15 14:23:09'),
(8, '2025-06-17', 'RENT', 400.00, '2025-06-15 16:49:46');

-- --------------------------------------------------------

--
-- Table structure for table `expenses`
--

DROP TABLE IF EXISTS `expenses`;
CREATE TABLE IF NOT EXISTS `expenses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `category` varchar(255) NOT NULL,
  `description` text,
  `amount` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `expenses`
--

INSERT INTO `expenses` (`id`, `date`, `category`, `description`, `amount`) VALUES
(7, '2025-06-25', 'laptop', 'wy', 32.00),
(8, '2025-06-24', '12', '12', 12.00),
(10, '2025-06-18', 'laptop', '23', 120.00);

-- --------------------------------------------------------

--
-- Table structure for table `income`
--

DROP TABLE IF EXISTS `income`;
CREATE TABLE IF NOT EXISTS `income` (
  `id` int NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `source` varchar(255) NOT NULL,
  `description` text,
  `amount` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `income`
--

INSERT INTO `income` (`id`, `date`, `source`, `description`, `amount`) VALUES
(13, '2025-06-17', 'free', 'monthly', 120.00),
(11, '2025-06-18', 'free', 'monthly', 3500.00),
(5, '2025-06-19', 'free', 'free', 3500.00),
(6, '2025-06-20', 'free', '34500', 3500.00),
(7, '2025-06-17', 'free', 'monthly', 3500.00),
(12, '2025-06-18', 'free', 'monthly', 120.00),
(10, '2025-06-17', 'freedom', 'monthly', 5000.00);

-- --------------------------------------------------------

--
-- Table structure for table `inventory`
--

DROP TABLE IF EXISTS `inventory`;
CREATE TABLE IF NOT EXISTS `inventory` (
  `InventoryID` int NOT NULL AUTO_INCREMENT,
  `ProductID` int NOT NULL,
  `WarehouseID` int NOT NULL,
  `Quantity` int NOT NULL,
  `LastUpdated` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `Status` varchar(20) NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`InventoryID`),
  KEY `ProductID` (`ProductID`),
  KEY `WarehouseID` (`WarehouseID`)
) ;

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
CREATE TABLE IF NOT EXISTS `products` (
  `ProductID` int NOT NULL AUTO_INCREMENT,
  `ProductName` varchar(100) NOT NULL,
  `SKU` varchar(50) NOT NULL,
  `Description` text,
  `UnitPrice` decimal(10,2) NOT NULL,
  `CreatedAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `UpdatedAt` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `Status` varchar(20) NOT NULL DEFAULT 'Active',
  `QTY` int DEFAULT NULL,
  `Photo` text,
  PRIMARY KEY (`ProductID`),
  UNIQUE KEY `SKU` (`SKU`)
) ;

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
CREATE TABLE IF NOT EXISTS `roles` (
  `Id` int NOT NULL AUTO_INCREMENT,
  `Name` varchar(50) NOT NULL,
  `Group` varchar(50) NOT NULL DEFAULT 'Global Roles',
  `IsAutoAssigned` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`Id`),
  UNIQUE KEY `Name` (`Name`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `roles`
--

INSERT INTO `roles` (`Id`, `Name`, `Group`, `IsAutoAssigned`) VALUES
(13, 'Finance', 'Global Roles', 0),
(14, 'Infentory', 'Global Roles', 0);

-- --------------------------------------------------------

--
-- Table structure for table `sales`
--

DROP TABLE IF EXISTS `sales`;
CREATE TABLE IF NOT EXISTS `sales` (
  `id` int NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `customerName` varchar(255) NOT NULL,
  `itemSold` varchar(255) NOT NULL,
  `quantity` int NOT NULL,
  `unitPrice` decimal(10,2) NOT NULL,
  `totalAmount` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `sales`
--

INSERT INTO `sales` (`id`, `date`, `customerName`, `itemSold`, `quantity`, `unitPrice`, `totalAmount`) VALUES
(3, '2025-06-24', 'john', 'PC', 4, 200.00, 800.00),
(2, '2025-06-17', 'ABC', 'LIght', 12, 1000.00, 12000.00);

-- --------------------------------------------------------

--
-- Table structure for table `stocktransactions`
--

DROP TABLE IF EXISTS `stocktransactions`;
CREATE TABLE IF NOT EXISTS `stocktransactions` (
  `TransactionID` int NOT NULL AUTO_INCREMENT,
  `ProductID` int NOT NULL,
  `WarehouseID` int NOT NULL,
  `Quantity` int NOT NULL,
  `TransactionType` varchar(10) NOT NULL,
  `TransactionDate` datetime DEFAULT CURRENT_TIMESTAMP,
  `Remarks` varchar(200) DEFAULT NULL,
  `Status` varchar(20) NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`TransactionID`),
  KEY `ProductID` (`ProductID`),
  KEY `WarehouseID` (`WarehouseID`)
) ;

-- --------------------------------------------------------

--
-- Table structure for table `userinroles`
--

DROP TABLE IF EXISTS `userinroles`;
CREATE TABLE IF NOT EXISTS `userinroles` (
  `UserId` int NOT NULL,
  `RoleId` int NOT NULL,
  `RoleName` varchar(50) NOT NULL,
  PRIMARY KEY (`UserId`,`RoleId`),
  KEY `RoleId` (`RoleId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `Id` int NOT NULL AUTO_INCREMENT,
  `Username` varchar(255) NOT NULL,
  `passwordhash` varchar(60) NOT NULL,
  `RoleId` int NOT NULL,
  `CreatedAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `isAdmin` tinyint NOT NULL DEFAULT '0' COMMENT '1 for Admin, 0 for regular user',
  `Email` varchar(255) NOT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `Username` (`Username`),
  KEY `RoleId` (`RoleId`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`Id`, `Username`, `passwordhash`, `RoleId`, `CreatedAt`, `isAdmin`, `Email`) VALUES
(18, 'string', '$2a$11$PlzE0Vkw6HAK6eZ3.3KJ/ev6WrZVCEL/Fvw3nBXkkNuOYxNXuwiui', 14, '2025-07-03 17:42:55', 1, 'string@gmail.com'),
(22, 'string1', '$2a$11$yW22RoKg9hK/aF.m4fkyIO69Gm9uyirlc.iRMuXLn.FvWTKoR1K0O', 13, '2025-07-03 22:04:06', 1, 'string@g.com');

-- --------------------------------------------------------

--
-- Table structure for table `warehouses`
--

DROP TABLE IF EXISTS `warehouses`;
CREATE TABLE IF NOT EXISTS `warehouses` (
  `WarehouseID` int NOT NULL AUTO_INCREMENT,
  `WarehouseName` varchar(100) NOT NULL,
  `Location` varchar(200) DEFAULT NULL,
  `CreatedAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `Status` varchar(20) NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`WarehouseID`)
) ;

-- --------------------------------------------------------

--
-- Table structure for table `__efmigrationshistory`
--

DROP TABLE IF EXISTS `__efmigrationshistory`;
CREATE TABLE IF NOT EXISTS `__efmigrationshistory` (
  `MigrationId` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `ProductVersion` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  PRIMARY KEY (`MigrationId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `inventory`
--
ALTER TABLE `inventory`
  ADD CONSTRAINT `inventory_ibfk_1` FOREIGN KEY (`ProductID`) REFERENCES `products` (`ProductID`),
  ADD CONSTRAINT `inventory_ibfk_2` FOREIGN KEY (`WarehouseID`) REFERENCES `warehouses` (`WarehouseID`);

--
-- Constraints for table `stocktransactions`
--
ALTER TABLE `stocktransactions`
  ADD CONSTRAINT `stocktransactions_ibfk_1` FOREIGN KEY (`ProductID`) REFERENCES `products` (`ProductID`),
  ADD CONSTRAINT `stocktransactions_ibfk_2` FOREIGN KEY (`WarehouseID`) REFERENCES `warehouses` (`WarehouseID`);

--
-- Constraints for table `userinroles`
--
ALTER TABLE `userinroles`
  ADD CONSTRAINT `userinroles_ibfk_1` FOREIGN KEY (`UserId`) REFERENCES `users` (`Id`) ON DELETE CASCADE,
  ADD CONSTRAINT `userinroles_ibfk_2` FOREIGN KEY (`RoleId`) REFERENCES `roles` (`Id`) ON DELETE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`RoleId`) REFERENCES `roles` (`Id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
