# Brazilian E-Commerce: Exploratory Data Analysis

> **Status:** Analysis complete. Final notebook formatting (written conclusions under each section) in progress.

## Objective
Analyze ~100k real orders from Olist, a Brazilian e-commerce marketplace (2016–2018), to understand
sales volume, revenue, shipping costs, geographic differences and what drives customer satisfaction.

## Dataset
- Source: [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- 9 related tables: orders, order items, products, customers, sellers, reviews, payments, geolocation, category translation
- Period with complete data: January 2017 – August 2018

## Key findings

**Delivery time is the main driver of customer satisfaction.**
Orders delivered in 0–7 days average 4.41 stars; orders that take more than 30 days drop to 2.18.
(Pearson r = -0.33, p < 0.001)

**Price barely affects satisfaction.**
The correlation between order price and review score is close to zero (r = -0.04). Cheap and expensive
orders receive similar ratings (4.17 vs 4.00). Customers care more about how long they wait than how much they pay.

**Distant regions wait twice as long and pay twice as much for shipping.**
Average delivery time goes from 10.3 days in the Southeast to 22.1 days in the North, and average freight
from R$19.81 to R$41.29. Satisfaction is lower in the North and Northeast (4.03 and 3.97 vs 4.18 in the Southeast),
a statistically significant but moderate difference (0.22 stars, Kruskal-Wallis p < 0.001).

**Shipping weighs heavily on small purchases.**
Overall, freight is 14.2% of what customers pay. But for orders under R$46 it is 33.7% of the total,
compared to 8.9% for orders above R$150.

**Sales are highly concentrated geographically.**
São Paulo state accounts for 42% of all orders, and the top 5 states for 77%.

**Black Friday creates a clear sales peak.**
November 2017 had 7,544 orders, 63% more than October (4,631).

**Best and worst rated categories** (minimum 100 reviews):
General interest books rank highest (4.46); office furniture ranks lowest (3.62, based on 1,268 reviews).

**Other metrics**
- Average order value: R$137.75 (median R$86.90, showing a right-skewed distribution)
- Average items per order: 1.14
- São Paulo city alone accounts for 15,540 orders
- No significant trend in ratings over time (p = 0.42), with a temporary drop between December 2017 and April 2018

## Methodology notes
- Excluded months with incomplete data (Sep–Dec 2016, Sep–Oct 2018) from all time-based analysis
- Used order-level aggregation to avoid counting the same review multiple times in multi-item orders
- Used both Pearson and Spearman correlation, since prices and delivery times are highly skewed
- Filtered categories with fewer than 100 reviews to avoid unreliable averages
- Grouped the 27 states into Brazil's 5 official regions to get larger, more reliable samples
- Reported effect sizes alongside p-values: with ~100k orders, even very small differences are statistically significant

## Tools
Python, pandas, SciPy, Matplotlib, Jupyter

## Roadmap
- [x] Volume and quantity analysis
- [x] Revenue and shipping analysis
- [x] Customer satisfaction analysis
- [x] Temporal patterns and seasonality
- [x] Geographic analysis (sales, satisfaction and freight by region)
- [ ] Written conclusions for each section in the notebook

## How to run
1. Clone the repository
2. Make sure the CSV files are in `data/` (or download them from the Kaggle link above)
3. Open `proyecto_1_datasets.ipynb` and run all cells