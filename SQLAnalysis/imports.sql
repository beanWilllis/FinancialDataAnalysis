.import --csv us_currency_data.csv USCurrencyDataTemp
.import --csv eu_currency_data.csv EUCurrencyDataTemp
.import --csv ca_currency_data.csv CACurrencyDataTemp

INSERT INTO "USCurrencyData" ("Date", "ExchangeRate", "Currency")
SELECT "Date", "ExchangeRate", "Currency" FROM "USCurrencyDataTemp";

INSERT INTO "EUCurrencyData" ("Date", "ExchangeRate", "Currency")
SELECT "Date", "ExchangeRate", "Currency" FROM "EUCurrencyDataTemp";

INSERT INTO "CACurrencyData" ("Date", "ExchangeRate", "Currency")
SELECT "Date", "ExchangeRate", "Currency" FROM "CACurrencyDataTemp";

DROP TABLE "USCurrencyDataTemp";
DROP TABLE "EUCurrencyDataTemp";
DROP TABLE "CACurrencyDataTemp";

CREATE VIEW "Forex" AS 
SELECT * 
FROM "USCurrencyData"
UNION
SELECT *
FROM "EUCurrencyData"
UNION
SELECT * 
FROM "CaCurrencyData";

.import --csv cleaned_transactions.csv TempTransactions
.import --csv cleaned_accounts.csv TempAccounts

INSERT INTO "Stocks" ("StockName", 
                      "Ticker")
SELECT DISTINCT "Asset", "Ticker" 
FROM TempTransactions;

INSERT INTO "Transactions" ("AccountID",
                            "TransactionID",
                            "StockID",
                            "Quantity",
                            "TradeDate",
                            "SettlementDate",
                            "PricePerShare(USD)",
                            "OriginalCurrencyUsed",
                            "TransactionStatus",
                            "Notes")
SELECT "AccountID",
        "TransactionID",
        "StockID",
        "Quantity",
        "TradeDate",
        "SettlementDate",
        "PricePerShare(USD)",
        "OriginalCurrencyUsed",
        "TransactionStatus",
        "Notes"
FROM (
    SELECT "TempTransactions"."AccountID",
           "TempTransactions"."TransactionID",
           "Stocks"."StockID",
           "TempTransactions"."Quantity",
           "TempTransactions"."TradeDate",
           "TempTransactions"."SettlementDate",
           "TempTransactions"."PricePerShare" * "Forex"."ExchangeRate" AS "PricePerShare(USD)",
           "TempTransactions"."Currency" AS "OriginalCurrencyUsed",
           "TempTransactions"."TransactionStatus",
           "TempTransactions"."Notes"
    FROM "TempTransactions"
    JOIN "Stocks" ON "TempTransactions"."Ticker" = "Stocks"."Ticker"
    JOIN "Forex" ON "TempTransactions"."TradeDate" = "Forex"."Date" AND "TempTransactions"."Currency" = "Forex"."Currency"
);

INSERT INTO "People" ("FirstName",
                      "LastName",
                      "Email",
                      "DateOfBirth",
                      "MailingAddress",
                      "IncomeBracket",
                      "EmploymentStatus",
                      "SSN",
                      "PhoneNumber",
                      "ExtensionNumber")
SELECT "FirstName",
        "LastName",
        "Email",
        "DateOfBirth",
        "MailingAddress",
        "IncomeBracket",
        "EmploymentStatus",
        "SSN",
        "PhoneNumber",
        "ExtensionNumber"
FROM "TempAccounts";

INSERT INTO "Accounts" ("AccountID",
                        "PersonID",
                        "AccountType",
                        "RiskTolerance",
                        "AccountOpenedDate") 
SELECT "TempAccounts"."AccountID",
       "People"."PersonID",
       "TempAccounts"."AccountType",
       "TempAccounts"."RiskTolerance",
       "TempAccounts"."AccountOpenedDate"
FROM "TempAccounts"
JOIN "People" ON "TempAccounts"."SSN" = "People"."SSN";

DROP TABLE "TempTransactions";
DROP TABLE "TempAccounts";
