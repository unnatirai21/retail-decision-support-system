
import os
from pathlib import Path
import pandas as pd
import mysql.connector
import google.generativeai as genai

from dotenv import dotenv_values


project_root = Path(__file__).resolve().parent.parent
config = dotenv_values(project_root / ".env")

api_key = config["GEMINI_API_KEY"]
genai.configure(api_key=api_key)

model = genai.GenerativeModel("models/gemini-3.6-flash")

# Connect to MySQL database
conn = mysql.connector.connect(
    host=config["MYSQL_HOST"],
    user=config["MYSQL_USER"],
    password=config["MYSQL_PASSWORD"],
    database=config["MYSQL_DATABASE"]
)

cursor = conn.cursor(dictionary=True)


def execute_procedure(procedure_name):

    cursor.callproc(procedure_name)
    rows = []

    for result in cursor.stored_results():
        rows.extend(result.fetchall())

    return pd.DataFrame(rows)


executive_dashboard = execute_procedure("ED")
customer_lifetime = execute_procedure("CLV")
region_performance = execute_procedure("RPS")
abc_inventory = execute_procedure("ABC1")
risk_flagging = execute_procedure("RF")

executive_summary = executive_dashboard.to_string(index=False)
clv_summary = customer_lifetime.head(10).to_string(index=False)
region_summary = region_performance.to_string(index=False)
abc_summary = abc_inventory.head(10).to_string(index=False)
risk_summary = risk_flagging.to_string(index=False)
prompt = f"""
You are a Senior Strategy Consultant at McKinsey & Company.

You have received analytical outputs from a retail company's decision intelligence system.

Analyse the information and prepare an executive report suitable for the CEO.

EXECUTIVE DASHBOARD

{executive_summary}

CUSTOMER LIFETIME VALUE

{clv_summary}

REGION PERFORMANCE SCORECARD

{region_summary}

ABC INVENTORY CLASSIFICATION

{abc_summary}

RISK ASSESSMENT (SCREENING SIGNALS — NOT CONFIRMED FRAUD)

{risk_summary}

----------------------------------------------------

Prepare a professional executive report.

The report must contain:

1. Executive Summary

2. Business Performance Analysis

3. Revenue Drivers

4. Operational Risks

5. Strategic Opportunities

6. Action Plan

   • Immediate Actions

   • Medium-Term Actions

   • Long-Term Actions

Instructions

- Think like a McKinsey strategy consultant.

- Explain why every important KPI matters.

- Support every recommendation using the provided data.

- Do not invent numbers.

- Do not repeat KPI values unnecessarily.

- Identify patterns, risks and growth opportunities.

- Write in concise executive language.

- Use bullet points where appropriate.

- RISK ASSESSMENT SECTION — CRITICAL: The data provided under "RISK ASSESSMENT" 
  is a heuristic screening output, not a confirmed fraud investigation. Use the 
  exact risk_flag labels as given (e.g. "Velocity Anomaly", "Watchlist Only"). 
  Do NOT rename them, do NOT use the words "fraud", "contamination", "attack", 
  or "abuse" unless that literal word already appears in the provided label. 
  Frame these customers as candidates for manual review, not as proven bad actors.

- REGION PERFORMANCE SECTION: Treat revenue, return rate, and delivery time as 
  THREE SEPARATE metrics per region. Do not combine them into a single composite 
  score or invent a weighting formula. Compare regions on each metric independently 
  and note where a region is strong on one dimension but weak on another.

- Do not add dates, names, or attributions (e.g. "prepared by", document dates) 
  that were not provided in the data — leave any such header fields generic or omit them.
"""


print("\nGenerating AI Report...\n")

response = model.generate_content(prompt)
report = response.text
print(report)


reports_folder = project_root / "reports"
reports_folder.mkdir(exist_ok=True)
report_path = reports_folder / "executive_report.md"

with open(report_path, "w", encoding="utf-8") as file:

    file.write("# AI-Powered Executive Business Report\n\n")

    file.write(report)

    file.write("\n\n---\n")

    file.write("Generated using MySQL, Python and Google Gemini AI.")


print("\nReport saved successfully.")
cursor.close()
conn.close()
cursor=None
conn=None