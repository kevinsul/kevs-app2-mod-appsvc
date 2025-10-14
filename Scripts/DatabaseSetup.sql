-- Kev's Inventory Management Database Setup Script
-- Run this script on your SQL Server 2014+ instance

-- Create the database
CREATE DATABASE InventoryDB;
GO

USE InventoryDB;
GO

-- Create the InventoryItems table
CREATE TABLE [dbo].[InventoryItems] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [Description] nvarchar(500) NULL,
    [Quantity] int NOT NULL,
    [SerialNumber] nvarchar(50) NOT NULL,
    CONSTRAINT [PK_InventoryItems] PRIMARY KEY ([Id])
);
GO

-- Create unique index on SerialNumber
CREATE UNIQUE NONCLUSTERED INDEX [IX_InventoryItems_SerialNumber] 
ON [dbo].[InventoryItems] ([SerialNumber]);
GO

-- Add check constraint for Quantity
ALTER TABLE [dbo].[InventoryItems]
ADD CONSTRAINT [CK_InventoryItems_Quantity] CHECK ([Quantity] >= 0);
GO

-- Insert sample data (optional)
INSERT INTO [dbo].[InventoryItems] ([Name], [Description], [Quantity], [SerialNumber])
VALUES 
    ('Laptop Computer', 'Dell Latitude 7420 Business Laptop', 15, 'LAP-001'),
    ('Wireless Mouse', 'Logitech MX Master 3 Wireless Mouse', 50, 'MSE-001'),
    ('USB-C Hub', 'Multi-port USB-C Hub with HDMI and Ethernet', 25, 'HUB-001'),
    ('Monitor', '24-inch 4K UHD Monitor', 8, 'MON-001'),
    ('Keyboard', 'Mechanical Gaming Keyboard', 30, 'KBD-001');
GO

-- Verify the setup
SELECT COUNT(*) as 'Total Items' FROM [dbo].[InventoryItems];
SELECT * FROM [dbo].[InventoryItems];
GO

PRINT 'Database setup completed successfully!';