/*
===============================================================================================================
Create Database & Schemas
===============================================================================================================

Scripts:
    This script create a new database name 'datawarehouse' after checking if it already exists and if it exists
    it will drop the database and recreate, additionally, the script sets up three schemas within the database: 'bronze', 'silver' and 'gold'.

Warning:
    Running this script will drop the entire datawarehouse database if it exists.
    All data in the database will be permanently deleted. kinldy proceed with coution 
    and ensure that you have proper backups of data before running this scripts
*/

-- Drop the Database datawarehouse if exists

DROP DATABASE IF EXISTS datawarehouse;

-- Creating the Database 'datawarehouse'

CREATE DATABASE datawarehouse;


-- Connect to the Database 'datawarehouse' (psql terminal)

-- \c datawarehuse 

-- Create the schemas

CREATE SCHEMA bronze;

CREATE SCHEMA silver;

CREATE SCHEMA gold;




