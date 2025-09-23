CREATE VIEW "CombinedTables" AS 

WITH "CleanerTransactions" AS (
    SELECT *
    FROM "Transactions"
    WHERE "PricePerShare(USD)" != 0.0
),

"TransactionsWithOriginalCurrencyTrade" AS (
    SELECT *, 
           "CleanerTransactions"."PricePerShare(USD)" / "Forex"."ExchangeRate" AS "PricePerShare(OriginalCurrency)"
    FROM "CleanerTransactions"
    JOIN "Forex" ON "CleanerTransactions"."OriginalCurrencyUsed" = "Forex"."Currency"
    AND "CleanerTransactions"."TradeDate" = "Forex"."Date"
)

SELECT *
FROM "Accounts"
JOIN "People" ON "Accounts"."PersonID" = "People"."PersonID"
JOIN "TransactionsWithOriginalCurrencyTrade" ON "Accounts"."AccountID" = "TransactionsWithOriginalCurrencyTrade"."AccountID";

-- What is the average trade value broken down by account type and income bracket?

SELECT ROUND(AVG("PricePerShare(USD)" *  "Quantity"), 2) AS "AverageTradeValue(USD)", 
       "AccountType"
FROM "CombinedTables"
GROUP BY "AccountType"
ORDER BY "AverageTradeValue(USD)" DESC;

SELECT ROUND(AVG("PricePerShare(USD)" *  "Quantity"), 2) AS "AverageTradeValue(USD)", 
       "IncomeBracket"
FROM "CombinedTables"
GROUP BY "IncomeBracket"
ORDER BY "AverageTradeValue(USD)" DESC;

-- Which customers have the highest total transaction volume over time, and how does that relate to their account type, age, risk, and employment status?

SELECT ROUND(SUM("PricePerShare(USD)" *  "Quantity"), 2) AS "Volume",
       "PersonID",
       "EmploymentStatus",
       "AccountType",
       "RiskTolerance",
       julianday(CURRENT_DATE) - julianday("DateOfBirth")
FROM "CombinedTables"
GROUP BY "PersonID"
ORDER BY "Volume" DESC
LIMIT 10;

-- For each account type, what is the average time between account opening and first trade

WITH "AccountTradeDateInfo" AS (
    SELECT julianday(MIN("TradeDate")) - julianday("AccountOpenedDate") AS "DateDifference", 
           "AccountID",
           "AccountType"
    FROM "CombinedTables"
    GROUP BY "AccountID"
)

SELECT ROUND(AVG("DateDifference"), 2) AS "AverageDateDiffByAccType", 
       "AccountType"
FROM "AccountTradeDateInfo"
GROUP BY "AccountType"
ORDER BY "AverageDateDiffByAccType" DESC;

-- For each month over the last two years, how many new accounts were created, 
-- and how many of them placed at least one trade in their first 30 days?

WITH "AccountsWith30DayTrade" AS (
    SELECT DISTINCT "AccountID", "AccountOpenedDate"
    FROM "CombinedTables"
    WHERE julianday("TradeDate") - julianday("AccountOpenedDate") <= 30
),

"NewAccountsLastTwoYears" AS (
    SELECT COUNT("AccountID") AS "NumberOfNewAccounts",
           strftime('%Y-%m', "AccountOpenedDate") AS "Month"
    FROM "Accounts" 
    GROUP BY strftime('%Y-%m', "AccountOpenedDate")
    HAVING strftime('%Y-%m', "AccountOpenedDate") >= DATE(CURRENT_DATE, '-2 years')
),

"AccountsWith30DayTradeLastTwoYears" AS (
    SELECT COUNT("AccountID") AS "NumberOfAccountsWith30DayTrade",
           strftime('%Y-%m', "AccountOpenedDate") AS "Month"
    FROM "AccountsWIth30DayTrade"
    GROUP BY strftime('%Y-%m', "AccountOpenedDate")
    HAVING strftime('%Y-%m', "AccountOpenedDate") >= DATE(CURRENT_DATE, '-2 years')
)

SELECT COALESCE("NewAccountsLastTwoYears"."NumberOfNewAccounts", 0) AS "NumberOfNewAccounts", 
       COALESCE("AccountsWith30DayTradeLastTwoYears"."NumberOfAccountsWith30DayTrade", 0) AS "NumberOfAccountsWith30DayTrade",
       "NewAccountsLastTwoYears"."Month"
FROM "NewAccountsLastTwoYears"
LEFT JOIN "AccountsWith30DayTradeLastTwoYears" ON "NewAccountsLastTwoYears"."Month" = "AccountsWith30DayTradeLastTwoYears"."Month";


-- Which accounts have the most diverse trading history based on number of stocks traded?

WITH "DistinctStocksTradedByAccount" AS (
    SELECT DISTINCT "StockID", "AccountID", "AccountType"
    FROM "CombinedTables"
)

SELECT COUNT("StockID") AS "NumStocksTraded",
       "AccountID",
       "AccountType"
FROM "DistinctStocksTradedByAccount"
GROUP BY "AccountID"
ORDER BY "NumStocksTraded" DESC
LIMIT 10;

-- For each month, what was the total value of all trades in all currencies, and which currency contributed the most each month?

WITH "MonthlyVolumesEUR" AS (
    SELECT ROUND(SUM("PricePerShare(USD)" * "Quantity"), 2) AS "EURVolume(USD)",
           strftime('%Y-%m', "TradeDate") AS "Month"
    FROM "Transactions"
    WHERE "OriginalCurrencyUsed" = 'EUR'
    GROUP BY strftime('%Y-%m', "TradeDate")
),

"MonthlyVolumesCAD" AS (
    SELECT ROUND(SUM("PricePerShare(USD)" * "Quantity"), 2) AS "CADVolume(USD)",
           strftime('%Y-%m', "TradeDate") AS "Month"
    FROM "Transactions"
    WHERE "OriginalCurrencyUsed" = 'CAD'
    GROUP BY strftime('%Y-%m', "TradeDate")
),

"MonthlyVolumesUSD" AS (
    SELECT ROUND(SUM("PricePerShare(USD)" * "Quantity"), 2) AS "USDVolume(USD)",
           strftime('%Y-%m', "TradeDate") AS "Month"
    FROM "Transactions"
    WHERE "OriginalCurrencyUsed" = 'USD'
    GROUP BY strftime('%Y-%m', "TradeDate")
)

SELECT "MonthlyVolumesEUR"."Month" AS "Month",
       "MonthlyVolumesEUR"."EURVolume(USD)" AS "EURVolume",
       "MonthlyVolumesCAD"."CADVolume(USD)" AS "CADVolume",
       "MonthlyVolumesUSD"."USDVolume(USD)" AS "USDVolume",
       "MonthlyVolumesEUR"."EURVolume(USD)" + "MonthlyVolumesCAD"."CADVolume(USD)" + "MonthlyVolumesUSD"."USDVolume(USD)" AS "TotalVolume",
       MAX("MonthlyVolumesEUR"."EURVolume(USD)", "MonthlyVolumesCAD"."CADVolume(USD)", "MonthlyVolumesUSD"."USDVolume(USD)") AS "MaxVolume",
       CASE 
           WHEN "MonthlyVolumesEUR"."EURVolume(USD)" = MAX("MonthlyVolumesEUR"."EURVolume(USD)", "MonthlyVolumesCAD"."CADVolume(USD)", "MonthlyVolumesUSD"."USDVolume(USD)") THEN 'EUR'
           WHEN "MonthlyVolumesCAD"."CADVolume(USD)" = MAX("MonthlyVolumesEUR"."EURVolume(USD)", "MonthlyVolumesCAD"."CADVolume(USD)", "MonthlyVolumesUSD"."USDVolume(USD)") THEN 'CAD'
           WHEN "MonthlyVolumesUSD"."USDVolume(USD)" = MAX("MonthlyVolumesEUR"."EURVolume(USD)", "MonthlyVolumesCAD"."CADVolume(USD)", "MonthlyVolumesUSD"."USDVolume(USD)") THEN 'USD'
       END AS "MaxVolumeCurrency"
FROM "MonthlyVolumesEUR"
JOIN "MonthlyVolumesCAD" ON "MonthlyVolumesEUR"."Month" = "MonthlyVolumesCAD"."Month"
JOIN "MonthlyVolumesUSD" ON "MonthlyVolumesEUR"."Month" = "MonthlyVolumesUSD"."Month";

-- Which accounts, if any, have never made a trade?

SELECT "AccountID"
FROM "Accounts"
WHERE "AccountID" NOT IN (
    SELECT "AccountID"
    FROM "Transactions"
);

-- Which customers have made a trade in the last 30 days after having no activity in the 90 days prior?

WITH "AccountsWithTradeLast30Days" AS (
    SELECT "AccountID", MIN("TradeDate") AS "EarliestTradeLast30Days"
    FROM "CombinedTables"
    WHERE julianday(CURRENT_DATE) - julianday("TradeDate") <= 30 
    GROUP BY "AccountID"
),

"TradeDataForAccountsWithTradeInLast30Days" AS (
    SELECT "AccountID", "TradeDate"
    FROM "Transactions"
    WHERE "AccountID" IN (
        SELECT "AccountID"
        FROM "AccountsWithTradeLast30Days"
    )
),

"CombinedDataForAccountsWithTradeInLast30days" AS (
    SELECT "AccountsWithTradeLast30Days"."AccountID",
        "AccountsWithTradeLast30Days"."EarliestTradeLast30Days",
        "TradeDataForAccountsWithTradeInLast30Days"."TradeDate"
    FROM "AccountsWithTradeLast30Days"
    JOIN "TradeDataForAccountsWithTradeInLast30Days" ON "AccountsWithTradeLast30Days"."AccountID" = "TradeDataForAccountsWithTradeInLast30Days"."AccountID"
    ORDER BY "AccountsWithTradeLast30Days"."AccountID"
),

"AccountsWithTradeInLast30DaysAndIn90DaysPrior" AS (
    SELECT DISTINCT "AccountID"
    FROM "CombinedDataForAccountsWithTradeInLast30days"
    WHERE julianday("EarliestTradeLast30Days") - julianday("TradeDate") > 0
    AND julianday("EarliestTradeLast30Days") - julianday("TradeDate") <= 90
)

SELECT "AccountID"
FROM "AccountsWithTradeLast30Days"
WHERE "AccountID" NOT IN "AccountsWithTradeInLast30DaysAndIn90DaysPrior";

-- Identify customers whose trading volume (USD) has increased by at least 50% in the last 3 months compared to the 3 months before that

WITH "Last3MonthsVolume" AS (
    SELECT "AccountID",
           ROUND(SUM("PricePerShare(USD)" * "Quantity"), 2) AS "TotalVolume"
    FROM "CombinedTables"
    WHERE julianday("TradeDate") < julianday(CURRENT_DATE)
    AND julianday("TradeDate") > julianday(CURRENT_DATE) - 90
    GROUP BY "AccountID"
),

"Volume6To3MonthsAgo" AS (
    SELECT "AccountID",
           ROUND(SUM("PricePerShare(USD)" * "Quantity"), 2) AS "TotalVolume"
    FROM "CombinedTables"
    WHERE julianday("TradeDate") < julianday(CURRENT_DATE) - 90
    AND julianday("TradeDate") > julianday(CURRENT_DATE) - 180
    GROUP BY "AccountID"
),

"Last6MonthsVolumeInfo" AS (
    SELECT "Last3MonthsVolume"."AccountID",
           "Last3MonthsVolume"."TotalVolume" AS "RecentVolumes",
           "Volume6To3MonthsAgo"."TotalVolume" AS "OlderVolumes"
    FROM "Last3MonthsVolume"
    JOIN "Volume6To3MonthsAgo" ON "Last3MonthsVolume"."AccountID" = "Volume6To3MonthsAgo"."AccountID"
)

SELECT "AccountID",
       ROUND("OlderVolumes", 2) AS "OldVolume",
       ROUND("RecentVolumes", 2) AS "NewVolume",
       ROUND(("RecentVolumes" - "OlderVolumes") / "OlderVolumes", 2) * 100 AS "PercentVolumeIncrease"
FROM "Last6MonthsVolumeInfo"
WHERE "OlderVolumes" != 0.0
AND ("RecentVolumes" - "OlderVolumes") / "OlderVolumes" > 0.5;

-- Which stocks had the highest average daily trade volume (USD) over the past 6 months, 
-- and who are the top 3 most frequent traders for each of those stocks?

WITH "StockVolumeData" AS (
    SELECT "StockID",
        ROUND(SUM("PricePerShare(USD)" * "Quantity") / 180, 2) AS "AvgVolumeLast6Months"
    FROM "Transactions"
    WHERE julianday("TradeDate") <= julianday(CURRENT_DATE)
    AND julianday("TradeDate") >= julianday(CURRENT_DATE) - 180
    GROUP BY "StockID"
    ORDER BY "AvgVolumeLast6Months" DESC
)

SELECT "Stocks"."StockName",
       "StockVolumeData"."AvgVolumeLast6Months"
FROM "StockVolumeData"
JOIN "Stocks" ON "StockVolumeData"."StockID" = "Stocks"."StockID"
LIMIT 3;

-- Which customers have made trades in multiple currencies, and how has their average daily trade value since account creation
-- (in USD) differed across those currencies?

WITH "AccountCurrencyData" AS (
    SELECT DISTINCT "AccountID", "OriginalCurrencyUsed"
    FROM "Transactions"
    ORDER BY "AccountID"
),

"NumberOfCurrenciesUsedPerAccount" AS (
    SELECT "AccountID",
           COUNT("OriginalCurrencyUsed") AS "NumberOfCurrencies"
    FROM "AccountCurrencyData"
    GROUP BY "AccountID"
),

"MultipleCurrencyAccounts" AS (
    SELECT "AccountID"
    FROM "NumberOfCurrenciesUsedPerAccount"
    WHERE "NumberOfCurrencies" > 1
),

"VolumeEURPerAccount" AS (
    SELECT ROUND(SUM("PricePerShare(USD)" * "Quantity") / (julianday(CURRENT_DATE) - julianday("AccountOpenedDate")), 2) AS "DailyEURVolumeByAccount(USD)",
           "AccountID"
    FROM "CombinedTables"
    WHERE "OriginalCurrencyUsed" = 'EUR'
    GROUP BY "AccountID"
),

"VolumeCADPerAccount" AS (
    SELECT ROUND(SUM("PricePerShare(USD)" * "Quantity") / (julianday(CURRENT_DATE) - julianday("AccountOpenedDate")), 2) AS "DailyCADVolumeByAccount(USD)",
           "AccountID"
    FROM "CombinedTables"
    WHERE "OriginalCurrencyUsed" = 'CAD'
    GROUP BY "AccountID"
),

"VolumeUSDPerAccount" AS (
    SELECT ROUND(SUM("PricePerShare(USD)" * "Quantity") / (julianday(CURRENT_DATE) - julianday("AccountOpenedDate")), 2) AS "DailyUSDVolumeByAccount(USD)",
           "AccountID"
    FROM "CombinedTables"
    WHERE "OriginalCurrencyUsed" = 'USD'
    GROUP BY "AccountID"
)

SELECT "MultipleCurrencyAccounts"."AccountID",
       "VolumeEURPerAccount"."DailyEURVolumeByAccount(USD)",
       "VolumeCADPerAccount"."DailyCADVolumeByAccount(USD)",
       "VolumeUSDPerAccount"."DailyUSDVolumeByAccount(USD)"
FROM "MultipleCurrencyAccounts"
JOIN "VolumeEURPerAccount" ON "MultipleCurrencyAccounts"."AccountID" = "VolumeEURPerAccount"."AccountID"
JOIN "VolumeCADPerAccount" ON "MultipleCurrencyAccounts"."AccountID" = "VolumeCADPerAccount"."AccountID"
JOIN "VolumeUSDPerAccount" ON "MultipleCurrencyAccounts"."AccountID" = "VolumeUSDPerAccount"."AccountID";

-- Which customers, if any, consistently trade just below round-number thresholds (e.g., 10,000), 

WITH "SuspiciousTradeData" AS (
    SELECT COUNT("TradeDate") AS "NumberOfSuspiciousTrades",
        "AccountID"
    FROM "CombinedTables"
    WHERE "PricePerShare(OriginalCurrency)" * "Quantity" < 10000
    AND "PricePerShare(OriginalCurrency)" * "Quantity" > 9950
    GROUP BY "AccountID"
)

SELECT "AccountID"
FROM "SuspiciousTradeData"
WHERE "NumberOfSuspiciousTrades" > 5;
