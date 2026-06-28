/* ----------------------------------------------------------------------------
   Init: DataWarehouseAnalytics database + gold layer

   Purpose
     Standalone bootstrap for the analytics project. My data warehouse project
     builds the gold layer as views over silver; this script rebuilds the same
     gold star-schema as standalone tables loaded from CSV exports, so the
     analytics scripts can run without standing up the full warehouse pipeline.

   What it does
     1. Drops and recreates the DataWarehouseAnalytics database (clean slate).
     2. Creates the gold schema and three tables: dim_customers, dim_products,
        and fact_sales (the customer/product dimensions and the sales fact).
     3. Bulk-loads each table from my exported gold-layer CSVs.

   WARNING
     This DROPS the entire DataWarehouseAnalytics database if it exists — every
     table and row is permanently deleted. Back up first if that matters.

   Before running
     Update the BULK INSERT file paths to wherever your CSV exports live.
     Tested on Microsoft SQL Server (T-SQL) via SSMS.
---------------------------------------------------------------------------- */

USE master;
GO

-- Drop and recreate the 'DataWarehouseAnalytics' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics;
END;
GO

-- Create the 'DataWarehouseAnalytics' database
CREATE DATABASE DataWarehouseAnalytics;
GO

USE DataWarehouseAnalytics;
GO

-- Create Schemas

CREATE SCHEMA gold;
GO

CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);
GO

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);
GO

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);
GO

TRUNCATE TABLE gold.dim_customers;
GO

BULK INSERT gold.dim_customers
FROM 'C:\sql\dwha_project\datasets\gold.dim_customers.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.dim_products;
GO

BULK INSERT gold.dim_products
FROM 'C:\sql\dwha_project\datasets\gold.dim_products.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.fact_sales;
GO

BULK INSERT gold.fact_sales
FROM 'C:\sql\dwha_project\datasets\gold.fact_sales.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO
