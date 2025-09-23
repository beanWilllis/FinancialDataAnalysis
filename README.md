# Finance Project

# Overview
This is an exploratory data analysis project of stock trading which involves initial data investigation in Excel, data cleaning using Python, data analysis using SQL, and data modeling using Tableau.

# Implementation
The data used in this project is a combination of synthetically made personal financial data and real life forex data and valid stock market dates. The prices of the stocks and the personal information used are randomly generated, but the forex data is taken from available datasets of the Federal Reserve Bank of St. Louis' website, which I used to determine dates the market was open when generating trade dates. Two data files are generated out of this, one for account data and another for transactions. These are purposefully filled with errors which I then cleaned using Python in order to further analysze them in SQL. In the SQL analysis, I explore many useful and realistic questions regarding the dataset information. After exploring the data further in SQL and learning about the trends, I took 4 SQL queries and exported them to use in Tableau. Then I modeled these as graphs in order to visualize the trends and put them into a dashboard for a more holistic view of the data.

https://fred.stlouisfed.org/series/DEXUSEU
https://fred.stlouisfed.org/series/DEXCAUS
