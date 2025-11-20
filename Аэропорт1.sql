IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'Airport')
BEGIN
    CREATE DATABASE Airport;
END
GO

USE Airport;
GO

IF OBJECT_ID('Tickets', 'U') IS NOT NULL
    DROP TABLE Tickets;
GO

IF OBJECT_ID('Flights', 'U') IS NOT NULL
    DROP TABLE Flights;
GO

IF OBJECT_ID('Passengers', 'U') IS NOT NULL
    DROP TABLE Passengers;
GO

CREATE TABLE Passengers
(
    PassengerID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    MiddleName NVARCHAR(50) NULL,
    PassportNumber NVARCHAR(20) NOT NULL UNIQUE,
    PhoneNumber NVARCHAR(20) NULL,
    Email NVARCHAR(100) NULL,
    DateOfBirth DATE NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT CK_Passengers_Email CHECK (Email IS NULL OR Email LIKE '%@%.%')
);
GO

CREATE TABLE Flights
(
    FlightID INT PRIMARY KEY IDENTITY(1,1),
    FlightNumber NVARCHAR(10) NOT NULL UNIQUE,
    DepartureAirport NVARCHAR(100) NOT NULL,
    ArrivalAirport NVARCHAR(100) NOT NULL,
    DepartureDateTime DATETIME NOT NULL,
    ArrivalDateTime DATETIME NOT NULL,
    AircraftType NVARCHAR(50) NULL,
    TotalSeats INT NOT NULL DEFAULT 0,
    BusinessClassSeats INT NOT NULL DEFAULT 0,
    EconomyClassSeats INT NOT NULL DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Scheduled',
    CONSTRAINT CK_Flights_ArrivalAfterDeparture CHECK (ArrivalDateTime > DepartureDateTime),
    CONSTRAINT CK_Flights_Status CHECK (Status IN ('Scheduled', 'Delayed', 'Cancelled', 'Completed', 'Boarding')),
    CONSTRAINT CK_Flights_TotalSeats CHECK (TotalSeats = BusinessClassSeats + EconomyClassSeats)
);
GO

CREATE TABLE Tickets
(
    TicketID INT PRIMARY KEY IDENTITY(1,1),
    PassengerID INT NOT NULL,
    FlightID INT NOT NULL,
    TicketNumber NVARCHAR(20) NOT NULL UNIQUE,
    ClassType NVARCHAR(20) NOT NULL,
    SeatNumber NVARCHAR(10) NULL,
    Price DECIMAL(10,2) NOT NULL,
    PurchaseDate DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Active',
    CONSTRAINT FK_Tickets_Passengers FOREIGN KEY (PassengerID) REFERENCES Passengers(PassengerID) ON DELETE CASCADE,
    CONSTRAINT FK_Tickets_Flights FOREIGN KEY (FlightID) REFERENCES Flights(FlightID) ON DELETE CASCADE,
    CONSTRAINT CK_Tickets_ClassType CHECK (ClassType IN ('Business', 'Economy')),
    CONSTRAINT CK_Tickets_Status CHECK (Status IN ('Active', 'Cancelled', 'Used', 'Refunded')),
    CONSTRAINT CK_Tickets_Price CHECK (Price > 0)
);
GO

CREATE NONCLUSTERED INDEX IX_Flights_FlightNumber ON Flights(FlightNumber);
GO

CREATE NONCLUSTERED INDEX IX_Flights_DepartureDateTime ON Flights(DepartureDateTime);
GO

CREATE NONCLUSTERED INDEX IX_Passengers_PassportNumber ON Passengers(PassportNumber);
GO

CREATE NONCLUSTERED INDEX IX_Tickets_PassengerID ON Tickets(PassengerID);
GO

CREATE NONCLUSTERED INDEX IX_Tickets_FlightID ON Tickets(FlightID);
GO

CREATE NONCLUSTERED INDEX IX_Tickets_TicketNumber ON Tickets(TicketNumber);
GO

INSERT INTO Passengers (FirstName, LastName, MiddleName, PassportNumber, PhoneNumber, Email, DateOfBirth)
VALUES
    (N'Иван', N'Иванов', N'Иванович', N'1234567890', N'+7-900-123-45-67', N'ivanov@mail.ru', CONVERT(DATE, '1990-05-15', 120)),
    (N'Мария', N'Петрова', N'Сергеевна', N'0987654321', N'+7-900-987-65-43', N'petrova@mail.ru', CONVERT(DATE, '1985-08-20', 120)),
    (N'Алексей', N'Сидоров', NULL, N'5555555555', N'+7-900-555-55-55', N'sidorov@mail.ru', CONVERT(DATE, '1992-12-10', 120));
GO

INSERT INTO Flights (FlightNumber, DepartureAirport, ArrivalAirport, DepartureDateTime, ArrivalDateTime, AircraftType, TotalSeats, BusinessClassSeats, EconomyClassSeats, Status)
VALUES
    (N'SU-100', N'Москва (Шереметьево)', N'Санкт-Петербург (Пулково)', CONVERT(DATETIME, '2024-12-20 10:00:00', 120), CONVERT(DATETIME, '2024-12-20 11:30:00', 120), N'Boeing 737', 180, 20, 160, 'Scheduled'),
    (N'SU-200', N'Москва (Домодедово)', N'Екатеринбург (Кольцово)', CONVERT(DATETIME, '2024-12-20 14:00:00', 120), CONVERT(DATETIME, '2024-12-20 17:30:00', 120), N'Airbus A320', 150, 15, 135, 'Scheduled'),
    (N'SU-300', N'Санкт-Петербург (Пулково)', N'Сочи (Адлер)', CONVERT(DATETIME, '2024-12-21 08:00:00', 120), CONVERT(DATETIME, '2024-12-21 11:00:00', 120), N'Boeing 777', 300, 40, 260, 'Scheduled');
GO

INSERT INTO Tickets (PassengerID, FlightID, TicketNumber, ClassType, SeatNumber, Price, Status)
VALUES
    (1, 1, N'TK-001', N'Business', N'1A', 15000.00, 'Active'),
    (1, 2, N'TK-002', N'Economy', N'15B', 8000.00, 'Active'),
    (2, 1, N'TK-003', N'Economy', N'20C', 7500.00, 'Active'),
    (2, 3, N'TK-004', N'Business', N'2A', 20000.00, 'Active'),
    (3, 2, N'TK-005', N'Economy', N'25D', 8500.00, 'Active');
GO

SELECT * FROM Passengers;
GO

SELECT * FROM Flights;
GO

SELECT 
    t.TicketNumber,
    p.FirstName + ' ' + p.LastName AS PassengerName,
    f.FlightNumber,
    f.DepartureAirport,
    f.ArrivalAirport,
    t.ClassType,
    t.SeatNumber,
    t.Price,
    t.Status
FROM Tickets t
INNER JOIN Passengers p ON t.PassengerID = p.PassengerID
INNER JOIN Flights f ON t.FlightID = f.FlightID;
GO

SELECT 
    f.FlightNumber,
    t.ClassType,
    COUNT(*) AS TicketCount
FROM Flights f
LEFT JOIN Tickets t ON f.FlightID = t.FlightID
GROUP BY f.FlightNumber, t.ClassType
ORDER BY f.FlightNumber, t.ClassType;
GO

