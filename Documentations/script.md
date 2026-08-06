# Online Retail Analytics | Dec 2010 – Dec 2011

End-to-end analytics project: 522K transactions → SQL star schema → Power BI → 15-slide deck. Two stakeholder tiers (CEO: revenue growth; CMO: retention strategy).

---

## Key Findings

| Stakeholder | Finding | Stat | Action |
|-------------|---------|------|--------|
| CEO | UK concentration | 85.2% revenue | Expand non-UK markets |
| CEO | Product mix | Top 100 = 33% revenue | Distributed catalog; no hit risk |
| CEO | Growth trend | Peak £1.45M (Nov 2011) | Dec partial-month, not decline |
| CEO | Top customers | 1,800+ accounts | No single-account dependency |
| CMO | Repeat revenue | 93% from 65% base | Strong lifetime value |
| CMO | Reorder window | 22-day median, 52-day P75 | Target 45-52 day gaps |
| CMO | Product loyalty | 95-100% repeat (9/10) | Retention is structural |
| CMO | Expansion | Germany/France 88-94 accounts | Acquire here; NL/Ireland 9-14 (protect) |

**Outlier:** MEDIUM CERAMIC JAR inverts repeat pattern (95% one-time). Worth monitoring.

---

## Data Model

**Fact_sales:** 522K rows (InvoiceNo, StockCode, CustomerKey, Revenue, Country)  
**Dim_Customer:** ~4,331 rows (includes guest key -1)  
**Dim_Product:** ~3,800 rows  
**Dim_Date:** ~396 days  

**Cleaning:** Guest transactions (null CustomerID) → CustomerKey = -1; included in CEO totals, excluded from CMO customer-behavior measures. Test accounts + excluded countries removed in SQL.

---

## Files

- `Online_Retail_Analytics.pptx` — 15-slide standalone deck (no dashboard needed)
- `/sql/` — 6 scripts (schema + 5 aggregations for each finding)
- `/dax/` — DAX measures with filter context documentation
- `/screenshots/` — 8 dashboard PNGs (reference only)


## Screenshots





---

## Quick Start

1. Run `schema.sql` to create star schema
2. Run aggregation queries in `/sql/` to validate findings
3. Build Power BI model; paste measures from `measures.dax`
4. Present with the PPTX deck (standalone, no dashboard needed)

---

## Design Philosophy

**All business logic in SQL.** Power BI is visualization-only, so every number is defensible and the dashboard reflects a single source of truth.

---

## Insights :

- **Guest handling:** Real business problem, not data quality. Intentional asymmetry disclosed.
- **Outlier catch:** CustomerKey 16446 (£168K on 2 invoices) flagged by cross-checking revenue rank vs. invoice count.
- **MEDIUM CERAMIC JAR:** 95% one-time revenue (inverts pattern). Flagged, not hidden.
- **Reorder strategy:** 22-day median, 52-day churn threshold. Target 45-52 day gaps for re-engagement.
- **Expansion:** Germany/France (repeat behavior exists, customer count is gap). Protect NL/Ireland (thin base, high revenue).

---

**Project:** Online Retail Analytics Portfolio | **Author:** Mohana | **Date:** 2026