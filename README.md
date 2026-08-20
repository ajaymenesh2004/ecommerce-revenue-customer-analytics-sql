# E-Commerce Revenue & Customer Analytics (SQL)

End-to-end SQL analysis of an e-commerce dataset — from schema design through
revenue trends, customer lifetime value, product revenue leakage, retention,
and cohort analysis. Built to answer the kind of questions a business/data
analyst would be asked to investigate: *Is revenue growing? Which customers
and products drive it? Where are we losing money, and are we retaining
customers over time?*

## Overview

This project models a relational e-commerce database (customers, products,
orders, reviews) in MySQL and layers a set of analytical SQL queries on top
to surface business insights. It's structured to mirror a real ETL +
analysis workflow: schema first, then load, then query.

## Dataset & Schema

Four related tables:

| Table       | Description                                    |
|-------------|-------------------------------------------------|
| `customers` | Customer demographics (gender, age group, country, signup date) |
| `products`  | Product catalog (name, category, unit price)   |
| `orders`    | Order-level transactions (quantity, amount, status, payment method) |
| `reviews`   | Post-order product reviews (rating, text)      |

**Load order:** `customers`, `products` → `orders` → `reviews`
(Orders references Customers and Products; Reviews references all three.)

```
customers ─┐
           ├─→ orders ─→ reviews
products  ─┘
```

## Tech Stack

- MySQL 8.x (window functions, CTEs)
- PyCharm (development environment)

## Key Analyses

- **Revenue trends** — Month-over-month, quarter-over-quarter, and
  year-over-year revenue growth using `LAG()` window functions
- **Customer Lifetime Value (CLV)** — Ranks customers by total spend and
  average order value
- **Revenue leakage** — Breaks down gross vs. net revenue by product,
  isolating cancellation and return impact
- **Retention** — New vs. repeat customer revenue split by month, and a
  churn flag based on days since last order
- **Demographics** — Revenue by country, gender, and age group
- **Cohort analysis** — Customer retention rate and revenue by signup
  cohort, tracked across subsequent months

## Sample Insight Structure *(replace with your actual findings once run)*

- Revenue grew X% QoQ in [quarter], driven primarily by [category/segment]
- Top 10% of customers by CLV account for X% of total delivered revenue
- [Product/category] shows the highest revenue leakage at X%, mostly from
  returns rather than cancellations
- Month-1 cohort retention averages X%, dropping to X% by month 3

## How to Run

1. Run `sql/01_schema_setup.sql` to create the database and tables
2. Load your data into `customers`, `products`, `orders`, `reviews`
   (in that order, to satisfy foreign key constraints)
3. Run `sql/02_analysis_queries.sql` — each query is self-contained and
   commented by section

## Repository Structure

```
├── sql/
│   ├── 01_schema_setup.sql       -- database, tables, constraints
│   └── 02_analysis_queries.sql   -- revenue, CLV, leakage, retention, cohorts
└── README.md
```

## Author

Ajay — MBA (Business Analytics), aspiring Data/Financial Analyst.
[Add LinkedIn / portfolio link here]
