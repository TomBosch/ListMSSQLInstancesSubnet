USE [master]
GO

/****** Object:  Database [Inventory]    Script Date: 13/06/2018 13:27:00 ******/
CREATE DATABASE [Inventory]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Inventory', FILENAME = N'D:\MSSQL\DATA\Inventory.mdf' , SIZE = 5120KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Inventory_log', FILENAME = N'L:\MSSQL\Log\Inventory_log.ldf' , SIZE = 2048KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

USE [Inventory]
GO

/****** Object:  Table [dbo].[Instances]    Script Date: 13/06/2018 13:26:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Instances](
	[ID] [uniqueidentifier] NOT NULL,
	[InstanceName] [nvarchar](200) NULL,
	[Port] [int] NULL,
	[IPAddress] [nvarchar](50) NULL,
	[Version] [nvarchar](50) NULL,
	[ComputerName] [nvarchar](150) NULL
) ON [PRIMARY]

GO
