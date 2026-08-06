# Online Retail Analytics | Dec 2010 – Dec 2011

A comprehensive end-to-end analytics project demonstrating data pipeline design, stakeholder-focused reporting, and executive storytelling. Built on the UCI Online Retail dataset (522K transactions across 13 months), this project transforms raw e-commerce data into an 8-page Power BI dashboard and a standalone presentation deck.

---

## Project Overview

**Goal:** Build reporting for two stakeholders with distinct needs — a CEO view (revenue, growth, concentration) and a CMO view (retention, repeat behavior, expansion strategy) — from a single governed data source.

**Scope:** 522K transactions | 13 months (Dec 2010 – Dec 2011) | ~25% guest checkouts | 414 non-UK accounts

**Deliverables:**
- SQL Server star schema (Fact_sales + 3 dimensions)
- 8-page Power BI dashboard (CEO tier + CMO tier)
- 15-slide standalone presentation deck
- This documentation

---

## Architecture

```
UCI Online Retail Dataset (raw)
           ↓
    SQL Server (cleaning, deduplication, business logic)
           ↓
   Star Schema (Fact_sales + Dim_Customer/Product/Date)
           ↓
    Power BI Desktop (visualization only, minimal DAX)
           ↓
 8-Page Dashboard + Standalone Deck
```

**Philosophy:** All data transformation lives in SQL. Power BI is visualization-only. This ensures the dashboard reflects a single source of truth and every number is defensible.

---

## Key Findings

### CEO Tier: Revenue & Growth

| Finding | Stat | Implication |
|---------|------|-------------|
| **Geographic Concentration** | 85.2% UK revenue | Expansion opportunity in non-UK markets (currently untapped) |
| **Product Mix** | Top 100 SKUs = 33% revenue | Distributed catalog; breadth, not hit-dependency risk |
| **Growth Trend** | Peak £1.45M (Nov 2011) | Strong growth Aug–Nov; Dec partial-month data, not decline |
| **Customer Distribution** | 1,800+ accounts | Top customers matter, but revenue is spread; no single account dependency |

### CMO Tier: Retention & Strategy

| Finding | Stat | Implication |
|---------|------|-------------|
| **Repeat Revenue** | 93% from 65% of base | Strong lifetime value concentration in repeat segment |
| **Reorder Window** | 22-day median, 52-day P75 threshold | Lifecycle campaigns should target 45–52 day gaps, not post-churn |
| **Product-Level Loyalty** | 95–100% repeat (9/10 top products) | Retention is structural, not category-dependent |
| **Expansion Priority** | Germany/France (88–94 accounts) vs. NL/Ireland (9–14) | Acquire in Germany/France (repeat behavior exists); protect NL/Ireland (retention risk) |

**One Outlier:** MEDIUM CERAMIC JAR shows inverted pattern (95% one-time revenue). Worth monitoring; may reflect seasonal bulk orders or a data quality edge case.

---

## Data Model

### Fact_sales
- **Grain:** One row per invoice line item
- **Rows:** 522,067
- **Key Columns:**
  - `InvoiceNo`, `StockCode`, `CustomerKey` (or -1 for guest), `InvoiceDate`
  - `Quantity`, `UnitPrice`, `Revenue` (computed: Qty × Price)
  - `Country`
- **Cleaning Applied:**
  - Null `CustomerID` → `CustomerKey = -1` (guest placeholder)
  - Excluded rows: `CustomerID IN (14265, 12743, 12363, 16320, 15108)` (test/admin accounts)
  - Excluded countries: 'European Community', 'Unspecified'
  - Duplicates resolved via `ROW_NUMBER()` in SQL

### Dim_Customer
- **Grain:** One row per unique customer (including guest)
- **Rows:** ~4,330 known customers + 1 guest
- **Key Columns:**
  - `CustomerKey` (PK; includes -1 for guest)
  - `Country` (derived from most-frequent country per customer)
- **Guest Handling:** `-1` → 'Unknown' country
- **Note:** Guest transactions are included in CEO revenue totals but excluded from all CMO customer-behavior measures (repeat rate, reorder gap, segment revenue)

### Dim_Product
- **Grain:** One row per unique `StockCode`
- **Rows:** ~3,800 SKUs
- **Key Columns:**
  - `StockCode` (PK)
  - `Description` (most-frequent description per StockCode)

### Dim_Date
- Standard date dimension with `MonthYear` labels for trend analysis

---

## Power BI Measures (DAX)

All measures use the star schema above. Key measures:

```dax
Product Revenue = SUMX(Fact_sales, Fact_sales[Quantity] * Fact_sales[UnitPrice])

Product Rank = RANKX(ALL(Dim_Product[Description]), [Product Revenue], , DESC)

Cumulative % = DIVIDE([Cumulative Revenue], 
                       CALCULATE([Product Revenue], ALL(Dim_Product[Description])))

Repeat Customer = CALCULATE(COUNTROWS(Fact_sales), 
                            FILTER(ALL(Dim_Customer), 
                                   [Invoice Count] >= 2))
```

**Design Note:** Guest rows (`CustomerKey = -1`) are explicitly excluded from customer-behavior measures via filter context. This is disclosed whenever CEO and CMO tiers are discussed together.

---

## Dashboard Structure

**8 Pages, split by stakeholder:**

### CEO Tier (Q1–Q4)
1. **CEO Q1 – Revenue Concentration:** 85.2% UK; non-UK shows growth potential
2. **CEO Q2 – Product Mix:** Top 100 SKUs = 33% revenue; long tail indicates catalog breadth
3. **CEO Q3 – Trend:** Monthly revenue with Nov 2011 peak (£1.45M); Dec partial-month anomaly flagged
4. **CEO Q4 – Top Customers:** CustomerKey 16446 is a one-off outlier (£168K on 2 invoices); not a relationship dependency

### CMO Tier (Q1–Q4)
5. **CMO Q1 – Retention:** 93% revenue from repeat customers (65% of base)
6. **CMO Q2 – Reorder Behavior:** 22-day median gap; 52-day P75 threshold for re-engagement campaigns
7. **CMO Q3 – Product × Retention:** 9 of 10 top products are 95–100% repeat-driven; MEDIUM CERAMIC JAR is an outlier (95% one-time)
8. **CMO Q4 – Expansion:** NL/Ireland = high revenue, low account count (retention risk). Germany/France = broader acquisition opportunity with repeat behavior established

---


## Screenshots

<img width="1323" height="739" alt="overview" src="https://github.com/user-attachments/assets/7ecb9784-8272-469d-ad1e-9646ee465ce3" />

<img width="1323" height="743" alt="CEO_Q1" src="https://github.com/user-attachments/assets/5e6795b5-6ac1-40a4-b690-1d215e658570" />


<img width="1324" height="744" alt="CEO_Q2" src="https://github.com/user-attachments/assets/58cdbadb-9347-4710-a05a-02346e8bd757" />


<img width="1322" height="744" alt="CEO_Q3" src="https://github.com/user-attachments/assets/59fb0aee-40db-43da-a0dc-b0652dbc5890" />


<img width="1323" height="745" alt="CEO_Q4" src="https://github.com/user-attachments/assets/2bbffd28-e9a4-4457-a78d-b10c56131a7a" />


<img width="1322" height="745" alt="CMO_Q1" src="https://github.com/user-attachments/assets/e49be0bb-e18c-4437-b312-4905dd25bf60" />


<img width="1323" height="747" alt="CMO_Q2" src="https://github.com/user-attachments/assets/bf21c3a1-ff6a-4d1e-bd89-9499f00a22c1" />

<img width="1324" height="745" alt="CMO_Q3" src="https://github.com/user-attachments/assets/2c8b28ff-8d3d-43b3-a227-2aa773cbc6b3" />


<img width="1323" height="743" alt="CMO_Q4" src="https://github.com/user-attachments/assets/3726aa33-123a-4264-98a0-39cfb73cbf02" />










## Presentation Deck

**File:** `Online_Retail_Analytics.pptx` (15 slides)

**Structure:**
1. Title slide
2. Project overview (data, ask, deliverable)
3. Architecture + build principles (SQL is analyst, Power BI is storyteller)
4. CEO section divider
5–8. CEO Q1–Q4 findings (with charts pulled from Power BI)
9. CMO section divider
10–13. CMO Q1–Q4 findings
14. Synthesis & recommendations (4 strategic takeaways)
15. Closing slide

**Design:**
- Navy (#1E2761), ice blue (#CADCFC), coral accent (#FF6B4A)
- Cambria headings, Calibri body
- Standalone narrative — no dashboard dependency
- Charts reflect exact numbers from Power BI model

**Key Narrative Decisions:**
- CEO Q2: Reframed from Pareto/80-20 assumption to "distributed catalog" after actual data came back near-linear
- CMO Q2: Power BI reference-line feature doesn't work on categorical axes, so 52-day threshold communicated via context, not visual highlight
- CMO Q3: MEDIUM CERAMIC JAR outlier is named explicitly — one unexpected data quirk, worth monitoring
- CMO Q4: Recommendation prioritizes Germany/France for acquisition (repeat behavior exists, customer count is the gap) over NL/Ireland (retention risk)

---

## How to Use This Project

### For Portfolio/Interview Context
1. **Start with the deck** (`Online_Retail_Analytics.pptx`) — it's a standalone story
2. **Reference the dashboard** for live interactivity and detailed breakdowns
3. **Cite the data model** (README section above) when asked about pipeline decisions
4. **Walk through one finding end-to-end** (e.g., CMO Q2 reorder gap) to demonstrate SQL logic, DAX measures, and business interpretation

### For Technical Deep Dives
1. Review `schema.sql` for table creation and star schema joins
2. Review `sql_queries/` folder for aggregations powering each dashboard page
3. Examine the Power BI model for DAX measure design and filter context handling
4. Check the presentation deck narrative to see how technical findings translate to executive language

### For Replication
- Dataset: UCI Online Retail (publicly available; see References section)
- SQL Server Express: Create database `tcs_db`, run schema + queries
- Power BI: Connect to SQL Server, build measures and relationships as described above
- This README contains all business logic and data-handling decisions

---

## Known Limitations & Caveats

1. **Dec 2011 Partial Month:** Data runs through Dec 9, 2011 only. Not a full month; appears as a sharp decline in trend analysis but is expected artifact of data collection cutoff.

2. **One-Time Customer Outlier (MEDIUM CERAMIC JAR):** This product inverts the repeat-customer dominance pattern (95% one-time revenue vs. ~5% repeat). Reflects real data; not a modeling error. Worth investigating in product/customer analysis.

3. **Guest Transactions:** ~25% of rows have no CustomerID. Assigned `CustomerKey = -1` and included in CEO revenue totals (to reflect true business revenue) but excluded from all CMO customer-behavior measures (repeat rate, reorder gap, segment revenue). This asymmetry is disclosed whenever both tiers are discussed together.

4. **Negative Quantity Rows:** Cancellations/returns in the original dataset. Removal process not captured in a saved script — if asked in interview, acknowledge this as a documentation gap and describe the intended approach.

5. **Power BI Version Constraints:** Deck was built in a Power BI version without right-click sort axis, Format pane sort-by-column, or reference-line support on categorical axes. Workarounds applied where needed; not a data-quality issue.

---

## SQL Queries & DAX Measures

Full SQL scripts and DAX code are available in the `/sql` and `/dax` directories of this repository.

**Key Aggregations:**
- `CEO_Q2_ProductRevenue.sql` — Product rank + cumulative % (feeds CEO Q2 chart)
- `CEO_Q3_MonthlyRevenue.sql` — Total revenue by month (feeds CEO Q3 trend)
- `CMO_Q2_ReorderGap.sql` — Gap days between consecutive orders (feeds CMO Q2 bucketing)
- `CMO_Q3_ProductRepeatMix.sql` — Repeat % by product (feeds CMO Q3 chart)
- `CMO_Q4_CountryExpansion.sql` — Revenue + customer count by country (feeds CMO Q4)

All queries exclude guest rows where semantically appropriate and are documented inline.

---

## Screenshots

Dashboard screenshots are available in `/screenshots/`:
- `CEO_Q1.png` — UK concentration chart
- `CEO_Q2.png` — Product distribution curve
- `CEO_Q3.png` — Monthly revenue trend
- `CEO_Q4.png` — Top customer ranking
- `CMO_Q1.png` — Repeat vs. one-time donut
- `CMO_Q2.png` — Reorder gap distribution
- `CMO_Q3.png` — Product-level repeat %
- `CMO_Q4.png` — Country expansion opportunity

These are for reference only; the presentation deck is standalone.

---

## Interview Talking Points

**1. Data Cleaning Philosophy**
> "Guest transactions (~25% of rows) are a real business problem, not a data quality issue. I included them in CEO revenue totals to reflect actual business revenue, but excluded them from all customer-behavior measures. That asymmetry is intentional and disclosed."

**2. One-Off Outlier Handling (CustomerKey 16446)**
> "This customer ranks #4 by revenue but has only 2 invoices. When I cross-referenced revenue rank with invoice count, I caught it. The Dec 2011 spike is the same order. One-time bulk buyers can distort both rankings and trends — always sanity-check by a second metric."

**3. MEDIUM CERAMIC JAR Anomaly**
> "Nine of ten top products are 95–100% repeat-driven, but MEDIUM CERAMIC JAR inverts (95% one-time). I flagged it explicitly in the deck because it's worth monitoring — might be seasonal bulk orders or a product-category edge case."

**4. SQL vs. Power BI Separation**
> "All business logic lives in SQL Server. Power BI never re-cleans data — it visualizes what SQL already proved correct. If a number seems off, I go back to SQL, not Power Query."

**5. Reorder Window Strategy (CMO Q2)**
> "Median reorder gap is 22 days; customers inactive beyond 52 days (P75) are increasingly likely to churn. Lifecycle campaigns should target 45–52 day gaps, not after they've already gone quiet."

**6. Expansion Strategy (CMO Q4)**
> "Germany and France show 88–94 accounts with established repeat behavior. Netherlands and Ireland have high revenue but only 9–14 accounts — retention risk if a handful churn. Prioritize acquisition in Germany/France; protect the thin base in NL/Ireland."

---

## References

- **Dataset:** [UCI Machine Learning Repository - Online Retail](https://archive.ics.uci.edu/ml/datasets/Online+Retail)
- **Tools:** SQL Server Express, Power BI Desktop, pptxgenjs
- **Star Schema Design:** Inspired by Kimball analytics patterns

---

## Contact & Attribution

**Project:** Online Retail Analytics Portfolio  
**Author:** Mohana  
**Date:** 2024  
**License:** Open for educational and portfolio purposes

---

*Last updated: August 2026*
