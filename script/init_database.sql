/*
====================================================
Create Database and Schemas
====================================================
Script Purpose :
	This script creates a new database named 'DataWarehouse' after checking if it already exists.
	If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas within the database: 'bronze','silver', and 'gold'.

WARNING:
	Running this script will drop the entire 'DataWarehouse' database if it exists.
	All data in the database will be permanently deleted. Proceed with caution and ensure you have proper backups before running this script.
*/


--Create Database 'DataWarehouse'
Use master;
Go

--Drop and recreate the 'Datawarehouse' database
If EXISTS (Select 1 from sys.databases where name = 'DataWarehouse')
Begin
	Alter Database DataWarehouse set SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;
Go

--Create the 'DataWarehouse' database
Create Database DataWarehouse;
Go

Use DataWarehouse;
Go

Create Schema bronze;
Go

Create SCHEMA silver;
Go

Create SCHEMA gold;
Go
--Go is just separator that tell SQl that first execute the previous statemensts.
