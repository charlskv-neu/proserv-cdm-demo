IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'proservod')
BEGIN
  CREATE DATABASE proservod;
END;
GO