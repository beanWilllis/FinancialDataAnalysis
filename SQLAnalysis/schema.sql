.headers on
.mode column

CREATE TABLE "USCurrencyData" (
    "USCurrencyDataID" INTEGER,
    "Date" NUMERIC NOT NULL,
    "ExchangeRate" INTEGER NOT NULL,
    "Currency" TEXT NOT NULL,
    PRIMARY KEY("USCurrencyDataID")
);

CREATE TABLE "EUCurrencyData" (
    "EUCurrencyDataID" INTEGER,
    "Date" NUMERIC NOT NULL,
    "ExchangeRate" REAL NOT NULL,
    "Currency" TEXT NOT NULL,
    PRIMARY KEY("EUCurrencyDataID")
);

CREATE TABLE "CACurrencyData" (
    "CACurrencyDataID" INTEGER,
    "Date" NUMERIC NOT NULL,
    "ExchangeRate" REAL NOT NULL,
    "Currency" TEXT NOT NULL,
    PRIMARY KEY("CACurrencyDataID")
);

CREATE TABLE "Transactions" (
    "AccountID" TEXT,
    "TransactionID" TEXT,
    "StockID" INTEGER,
    "Quantity" INTEGER,
    "TradeDate" NUMERIC,
    "SettlementDate" NUMERIC,
    "PricePerShare(USD)" REAL,
    "OriginalCurrencyUsed" TEXT,
    "TransactionStatus" TEXT CHECK ("TransactionStatus" IN ('COMPLETED', 'PENDING')),
    "Notes" TEXT CHECK ("Notes" IN ('PENDING', 'SHORT-TERM', 'AUTO-INVEST', 'WATCHLIST', 'DIVIDENDS REINVESTED', '')),
    PRIMARY KEY("TransactionID"),
    FOREIGN KEY("AccountID") REFERENCES "Accounts"("AccountID")
);

CREATE TABLE "Stocks" (
    "StockID" INTEGER,
    "StockName" TEXT,
    "Ticker" TEXT,
    PRIMARY KEY("StockID")
);

CREATE TABLE "Accounts" (
    "AccountID" TEXT,
    "PersonID" INTEGER,
    "AccountType" TEXT CHECK ("AccountType" IN ('JOINT', 'CUSTODIAL', '401(K)', 'BROKERAGE', 'TRUST', 'ROTH IRA', '')),
    "RiskTolerance" TEXT CHECK ("RiskTolerance" IN ('LOW', 'MEDIUM', 'HIGH', '')),
    "AccountOpenedDate" NUMERIC,
    PRIMARY KEY("AccountID"),
    FOREIGN KEY("PersonID") REFERENCES "People"("PersonID")
);

CREATE TABLE "People" (
    "PersonID" INTEGER,
    "FirstName" TEXT,
    "LastName" TEXT,
    "Email" TEXT,
    "DateOfBirth" NUMERIC,
    "MailingAddress" TEXT,
    "IncomeBracket" TEXT CHECK ("IncomeBracket" IN ('<50K', '50K-100K', '100K-250K', '250K+', '')),
    "EmploymentStatus" TEXT CHECK ("EmploymentStatus" IN ('RETIRED', 'STUDENT', 'EMPLOYED', 'SELF-EMPLOYED', 'UNEMPLOYED', '')),
    "SSN" TEXT,
    "PhoneNumber" TEXT,
    "ExtensionNumber" TEXT,
    PRIMARY KEY("PersonID")
);
