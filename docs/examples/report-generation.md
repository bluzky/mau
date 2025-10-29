# Report Generation Examples

Real-world examples of generating dynamic reports, data summaries, and CSV exports with Mau.

## Overview

This guide provides copy-paste ready examples for generating reports, including summary tables, CSV data, and structured data outputs.

## Sales Report

Generate a comprehensive sales report with summaries and breakdowns.

```elixir
template = """
=== SALES REPORT ===
Period: {{ report.start_date }} to {{ report.end_date }}
Generated: {{ report.generated_date }}

EXECUTIVE SUMMARY
-----------------
Total Revenue: ${{ report.total_revenue | round(2) }}
Total Orders: {{ report.total_orders }}
Average Order Value: ${{ report.average_order_value | round(2) }}
Conversion Rate: {{ report.conversion_rate }}%

SALES BY REGION
---------------
{% for region in report.by_region %}
{{ region.name }}:
  Revenue: ${{ region.revenue | round(2) }} ({{ region.percentage }}%)
  Orders: {{ region.orders }}
  Growth: {{ region.growth }}%

{% endfor %}

TOP PRODUCTS
------------
{% for product in report.top_products %}
{{ forloop.index }}. {{ product.name }}
   Revenue: ${{ product.revenue | round(2) }}
   Units Sold: {{ product.units }}
   % of Total: {{ product.percentage }}%

{% endfor %}

CUSTOMER ANALYSIS
-----------------
New Customers: {{ report.new_customers }}
Returning Customers: {{ report.returning_customers }}
Customer Retention Rate: {{ report.retention_rate }}%
Average Customer Lifetime Value: ${{ report.avg_ltv | round(2) }}

MONTHLY BREAKDOWN
-----------------
{% for month in report.monthly %}
{{ month.name }}:
  Revenue: ${{ month.revenue | round(2) }}
  Orders: {{ month.orders }}
  Avg Order Value: ${{ month.avg_order_value | round(2) }}
{% endfor %}

NOTES
-----
{{ report.notes }}

---
Report prepared by: {{ report.prepared_by }}
"""

context = %{
  "report" => %{
    "start_date" => "2024-01-01",
    "end_date" => "2024-10-31",
    "generated_date" => "2024-10-29",
    "total_revenue" => 125000.50,
    "total_orders" => 1250,
    "average_order_value" => 100.00,
    "conversion_rate" => 3.5,
    "new_customers" => 450,
    "returning_customers" => 800,
    "retention_rate" => 64.0,
    "avg_ltv" => 450.75,
    "by_region" => [
      %{"name" => "North America", "revenue" => 75000, "percentage" => 60, "orders" => 750, "growth" => 12.5},
      %{"name" => "Europe", "revenue" => 30000, "percentage" => 24, "orders" => 300, "growth" => 8.3},
      %{"name" => "Asia Pacific", "revenue" => 20000.50, "percentage" => 16, "orders" => 200, "growth" => 25.0}
    ],
    "top_products" => [
      %{"name" => "Premium Plan", "revenue" => 45000, "units" => 450, "percentage" => 36.0},
      %{"name" => "Standard Plan", "revenue" => 50000, "units" => 1000, "percentage" => 40.0},
      %{"name" => "Add-ons", "revenue" => 30000.50, "units" => 600, "percentage" => 24.0}
    ],
    "monthly" => [
      %{"name" => "January", "revenue" => 10000, "orders" => 100, "avg_order_value" => 100},
      %{"name" => "February", "revenue" => 11000, "orders" => 110, "avg_order_value" => 100},
      %{"name" => "March", "revenue" => 12500, "orders" => 125, "avg_order_value" => 100}
    ],
    "notes" => "Strong growth in Q2 driven by new product launch. Asia Pacific region shows highest growth potential.",
    "prepared_by" => "Finance Team"
  }
}

{:ok, report} = Mau.render(template, context)
IO.puts(report)
```

---

## CSV Export

Generate CSV data for spreadsheet import.

```elixir
template = """
Customer ID,Name,Email,Company,Phone,Total Spent,Last Purchase,Status
{% for customer in customers %}
{{ customer.id }},{{ customer.name }},{{ customer.email }},{{ customer.company }},{{ customer.phone }},${{ customer.total_spent | round(2) }},{{ customer.last_purchase }},{{ customer.status | capitalize }}
{% endfor %}
"""

context = %{
  "customers" => [
    %{
      "id" => 1001,
      "name" => "Alice Johnson",
      "email" => "alice@example.com",
      "company" => "Tech Innovations",
      "phone" => "555-0001",
      "total_spent" => 5250.00,
      "last_purchase" => "2024-10-28",
      "status" => "active"
    },
    %{
      "id" => 1002,
      "name" => "Bob Smith",
      "email" => "bob@example.com",
      "company" => "Digital Solutions",
      "phone" => "555-0002",
      "total_spent" => 2100.50,
      "last_purchase" => "2024-10-15",
      "status" => "active"
    },
    %{
      "id" => 1003,
      "name" => "Charlie Wilson",
      "email" => "charlie@example.com",
      "company" => "Creative Labs",
      "phone" => "555-0003",
      "total_spent" => 750.00,
      "last_purchase" => "2024-09-20",
      "status" => "inactive"
    }
  ]
}

{:ok, csv} = Mau.render(template, context)
# Save to file or return to user for download
File.write("customers_export.csv", csv)
```

---

## JSON Data Report

Generate structured JSON data.

```elixir
template = """
{
  "report": {
    "title": "{{ report.title }}",
    "generated_at": "{{ report.generated_at }}",
    "period": {
      "start": "{{ report.period.start }}",
      "end": "{{ report.period.end }}"
    },
    "summary": {
      "total_items": {{ report.summary.total_items }},
      "total_value": {{ report.summary.total_value | round(2) }},
      "average_value": {{ report.summary.average_value | round(2) }}
    },
    "items": [
      {% for item in report.items %}
      {
        "id": {{ item.id }},
        "name": "{{ item.name }}",
        "category": "{{ item.category }}",
        "value": {{ item.value | round(2) }},
        "quantity": {{ item.quantity }},
        "status": "{{ item.status }}"
      }{% if forloop.last == false %},{% endif %}
      {% endfor %}
    ],
    "metadata": {
      "prepared_by": "{{ report.prepared_by }}",
      "version": "{{ report.version }}"
    }
  }
}
"""

context = %{
  "report" => %{
    "title" => "Inventory Report",
    "generated_at" => "2024-10-29T14:30:00Z",
    "period" => %{
      "start" => "2024-01-01",
      "end" => "2024-10-31"
    },
    "summary" => %{
      "total_items" => 1250,
      "total_value" => 125000,
      "average_value" => 100.0
    },
    "items" => [
      %{"id" => 1, "name" => "Widget A", "category" => "Hardware", "value" => 50.0, "quantity" => 100, "status" => "in_stock"},
      %{"id" => 2, "name" => "Widget B", "category" => "Hardware", "value" => 75.0, "quantity" => 50, "status" => "in_stock"},
      %{"id" => 3, "name" => "Service Plan", "category" => "Service", "value" => 250.0, "quantity" => 10, "status" => "active"}
    ],
    "prepared_by" => "Inventory Team",
    "version" => "1.0"
  }
}

{:ok, json} = Mau.render(template, context)
```

---

## Performance Analytics Report

Detailed performance metrics and trends.

```elixir
template = """
PERFORMANCE ANALYTICS REPORT
============================
Report Period: {{ period.start }} to {{ period.end }}

WEBSITE PERFORMANCE
-------------------
Metric                          Value           Change
Page Load Time (avg)            {{ metrics.page_load_time }}ms         {{ metrics.page_load_change }}%
Bounce Rate                     {{ metrics.bounce_rate }}%             {{ metrics.bounce_change }}%
Time on Page (avg)              {{ metrics.time_on_page }}s            {{ metrics.time_change }}%
Conversion Rate                 {{ metrics.conversion_rate }}%         {{ metrics.conversion_change }}%

TOP PAGES
---------
{% for page in metrics.top_pages %}
{{ forloop.index }}. {{ page.title }}
   Path: {{ page.path }}
   Visitors: {{ page.visitors }}
   Bounce Rate: {{ page.bounce_rate }}%
   Avg Time: {{ page.avg_time }}s

{% endfor %}

TRAFFIC SOURCES
---------------
{% for source in metrics.traffic_sources %}
{{ source.name }}
  Visitors: {{ source.visitors }} ({{ source.percentage }}%)
  Conversion: {{ source.conversion }}%
  Avg Session Duration: {{ source.avg_session }}s

{% endfor %}

USER ENGAGEMENT
---------------
Total Users: {{ metrics.total_users }}
New Users: {{ metrics.new_users }} ({{ metrics.new_user_percentage }}%)
Returning Users: {{ metrics.returning_users }}
Active Users (30d): {{ metrics.active_users_30d }}

GOALS & CONVERSIONS
-------------------
{% for goal in metrics.goals %}
{{ goal.name }}: {{ goal.completions }} completions ({{ goal.conversion_rate }}%)
{% endfor %}

TOP DEVICES
-----------
{% for device in metrics.devices %}
{{ device.name }}: {{ device.sessions }} sessions ({{ device.percentage }}%)
{% endfor %}

RECOMMENDATIONS
---------------
1. Focus on improving page load time - currently {{ metrics.page_load_time }}ms
2. Optimize top pages for conversion
3. Expand traffic from high-converting sources
4. Implement A/B testing on key pages

---
Generated: {{ report.generated_date }}
Analyst: {{ report.analyst }}
"""

context = %{
  "period" => %{
    "start" => "2024-10-01",
    "end" => "2024-10-31"
  },
  "metrics" => %{
    "page_load_time" => 2.5,
    "page_load_change" => -12.5,
    "bounce_rate" => 42.3,
    "bounce_change" => -5.2,
    "time_on_page" => 3.45,
    "time_change" => 8.5,
    "conversion_rate" => 3.8,
    "conversion_change" => 15.3,
    "total_users" => 125000,
    "new_users" => 45000,
    "new_user_percentage" => 36,
    "returning_users" => 80000,
    "active_users_30d" => 95000,
    "top_pages" => [
      %{"title" => "Homepage", "path" => "/", "visitors" => 35000, "bounce_rate" => 35.2, "avg_time" => 4.5},
      %{"title" => "Product Page", "path" => "/products", "visitors" => 28000, "bounce_rate" => 45.1, "avg_time" => 3.2},
      %{"title" => "Pricing", "path" => "/pricing", "visitors" => 22000, "bounce_rate" => 38.5, "avg_time" => 5.1}
    ],
    "traffic_sources" => [
      %{"name" => "Organic Search", "visitors" => 60000, "percentage" => 48, "conversion" => 4.2, "avg_session" => 4.5},
      %{"name" => "Direct", "visitors" => 35000, "percentage" => 28, "conversion" => 3.5, "avg_session" => 3.8},
      %{"name" => "Social Media", "visitors" => 20000, "percentage" => 16, "conversion" => 2.8, "avg_session" => 2.2},
      %{"name" => "Referral", "visitors" => 10000, "percentage" => 8, "conversion" => 5.1, "avg_session" => 5.9}
    ],
    "goals" => [
      %{"name" => "Sign Up", "completions" => 4750, "conversion_rate" => 3.8},
      %{"name" => "Contact Form", "completions" => 1250, "conversion_rate" => 1.0},
      %{"name" => "Download", "completions" => 2500, "conversion_rate" => 2.0}
    ],
    "devices" => [
      %{"name" => "Desktop", "sessions" => 75000, "percentage" => 60},
      %{"name" => "Mobile", "sessions" => 40000, "percentage" => 32},
      %{"name" => "Tablet", "sessions" => 10000, "percentage" => 8}
    ]
  },
  "report" => %{
    "generated_date" => "2024-10-29",
    "analyst" => "Analytics Team"
  }
}

{:ok, report} = Mau.render(template, context)
```

---

## Financial Summary

Generate financial statements and summaries.

```elixir
template = """
FINANCIAL SUMMARY REPORT
========================
Fiscal Year: {{ fiscal_year }}
As of: {{ report_date }}

INCOME STATEMENT ($ thousands)
------------------------------
                                  This Month    YTD        Growth
Revenue                            ${{ income.revenue_month }}    ${{ income.revenue_ytd }}    {{ income.revenue_growth }}%
Cost of Revenue                    ${{ income.cost_month }}      ${{ income.cost_ytd }}       {{ income.cost_growth }}%
Gross Profit                       ${{ income.gross_profit_month }}    ${{ income.gross_profit_ytd }}     {{ income.gp_growth }}%

Operating Expenses
  Sales & Marketing                ${{ income.sales_marketing_month }}    ${{ income.sales_marketing_ytd }}     -
  R&D                              ${{ income.rd_month }}      ${{ income.rd_ytd }}        -
  General & Admin                  ${{ income.ga_month }}      ${{ income.ga_ytd }}        -
Total Operating Expenses           ${{ income.op_expenses_month }}    ${{ income.op_expenses_ytd }}     {{ income.op_growth }}%

Operating Income                   ${{ income.operating_income_month }}     ${{ income.operating_income_ytd }}      {{ income.oi_growth }}%
Net Income                         ${{ income.net_income_month }}      ${{ income.net_income_ytd }}       {{ income.net_growth }}%

BALANCE SHEET ($ thousands)
---------------------------
Assets
  Current Assets                   ${{ balance.current_assets }}
  Fixed Assets                     ${{ balance.fixed_assets }}
  Intangible Assets                ${{ balance.intangible_assets }}
Total Assets                       ${{ balance.total_assets }}

Liabilities
  Current Liabilities              ${{ balance.current_liabilities }}
  Long-term Debt                   ${{ balance.long_term_debt }}
Total Liabilities                  ${{ balance.total_liabilities }}

Equity
  Common Stock                     ${{ balance.common_stock }}
  Retained Earnings                ${{ balance.retained_earnings }}
Total Equity                       ${{ balance.total_equity }}

Total Liabilities & Equity         ${{ balance.total_liab_equity }}

KEY METRICS
-----------
Gross Margin                       {{ metrics.gross_margin }}%
Operating Margin                   {{ metrics.operating_margin }}%
Net Margin                         {{ metrics.net_margin }}%
Current Ratio                      {{ metrics.current_ratio }}
Debt-to-Equity                     {{ metrics.debt_to_equity }}

YEAR-TO-DATE SUMMARY
--------------------
Revenue Growth                     {{ ytd.revenue_growth }}% YoY
Expense Ratio                      {{ ytd.expense_ratio }}%
Profitability                      {{ ytd.profitability }}%

---
Prepared by: Finance Department
Verified by: CFO
"""

context = %{
  "fiscal_year" => 2024,
  "report_date" => "2024-10-31",
  "income" => %{
    "revenue_month" => 1250.0,
    "revenue_ytd" => 10500.0,
    "revenue_growth" => 15.5,
    "cost_month" => 750.0,
    "cost_ytd" => 6300.0,
    "cost_growth" => 12.3,
    "gross_profit_month" => 500.0,
    "gross_profit_ytd" => 4200.0,
    "gp_growth" => 22.5,
    "sales_marketing_month" => 150.0,
    "sales_marketing_ytd" => 1200.0,
    "rd_month" => 100.0,
    "rd_ytd" => 800.0,
    "ga_month" => 75.0,
    "ga_ytd" => 600.0,
    "op_expenses_month" => 325.0,
    "op_expenses_ytd" => 2600.0,
    "op_growth" => 18.0,
    "operating_income_month" => 175.0,
    "operating_income_ytd" => 1600.0,
    "oi_growth" => 28.5,
    "net_income_month" => 140.0,
    "net_income_ytd" => 1280.0,
    "net_growth" => 32.0
  },
  "balance" => %{
    "current_assets" => 5000.0,
    "fixed_assets" => 8000.0,
    "intangible_assets" => 2000.0,
    "total_assets" => 15000.0,
    "current_liabilities" => 3000.0,
    "long_term_debt" => 2000.0,
    "total_liabilities" => 5000.0,
    "common_stock" => 5000.0,
    "retained_earnings" => 5000.0,
    "total_equity" => 10000.0,
    "total_liab_equity" => 15000.0
  },
  "metrics" => %{
    "gross_margin" => 40.0,
    "operating_margin" => 15.2,
    "net_margin" => 12.2,
    "current_ratio" => 1.67,
    "debt_to_equity" => 0.5
  },
  "ytd" => %{
    "revenue_growth" => 15.5,
    "expense_ratio" => 0.75,
    "profitability" => 12.2
  }
}

{:ok, report} = Mau.render(template, context)
```

---

## See Also

- [Data Transformation](data-transformation.md) - Using map directives
- [Email Templates](email-templates.md) - Email template examples
- [Filters Guide](../guides/filters.md) - Formatting data with filters
- [Template Syntax Guide](../guides/template-syntax.md) - Template language reference
