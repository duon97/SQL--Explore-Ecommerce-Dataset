# Explore-Ecommerce-Dataset

# I. Introduction

This project explores an eCommerce dataset collected from Google Analytics in 2017. 
The dataset contains detailed information about user sessions on a website of an ecommerce company, and I will be using SQL on Google BigQuery to perform various analyses.
The dataset is organized in an array format to optimize storage costs and improve query performance.

## II. The Goal of Creating This Project

The primary goal of this project is to analyze and gain insights from the eCommerce dataset using SQL on Google BigQuery. The specific objectives of this project are:

- **Overview of Website Activity**: Understand overall website traffic and user engagement based on the available data.
- **Bounce Rate Analysis**: Evaluate the bounce rate by traffic source to understand how effectively the website retains visitors.
- **Revenue Analysis**: Analyze revenue generation by different traffic sources to identify high-performing channels.
- **Transactions Analysis**: Investigate transaction patterns to determine conversion rates and identify user behavior trends.
- **Products Analysis**: Perform an analysis of products viewed, added to carts, and purchased to better understand product performance and customer interest.

## III. Dataset description table 
| Field Name                         | Data Type |
|------------------------------------|-----------|
| `fullVisitorId`                    | STRING    |
| `date`                             | STRING    |
| `totals`                           | RECORD    |
| `totals.bounces`                   | INTEGER   |
| `totals.hits`                      | INTEGER   |
| `totals.pageviews`                 | INTEGER   |
| `totals.visits`                    | INTEGER   |
| `totals.transactions`              | INTEGER   |
| `trafficSource.source`             | STRING    |
| `hits`                             | RECORD    |
| `hits.eCommerceAction`             | RECORD    |
| `hits.eCommerceAction.action_type` | STRING    |
| `hits.product`                     | RECORD    |
| `hits.product.productQuantity`     | INTEGER   |
| `hits.product.productRevenue`      | INTEGER   |
| `hits.product.productSKU`          | STRING    |
| `hits.product.v2ProductName`       | STRING    |
