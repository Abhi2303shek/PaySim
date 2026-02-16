# 🏦 PaySim Fraud Detection — SQL Behavioural Case Study

## 📌 Project Overview

Digital payment systems face sophisticated fraud attacks where attackers drain accounts and disappear within seconds. Traditional rule-based systems (like threshold checks) fail because fraud is behavioural, not just transactional.
This project analyses a large-scale financial transaction dataset (PaySim) using **advanced SQL analytics and window functions** to discover real fraud patterns and design a better detection strategy.
Instead of simple counting queries, the project answers a business question:

> **How do fraudsters behave — and how can a bank stop them before money leaves the system?**

---

## 🧾 Dataset Description

The PaySim dataset simulates real mobile money transactions.

Each row represents one transaction with fields such as:

* `step` → time sequence of transaction
* `type` → transaction category (TRANSFER, CASH_OUT, PAYMENT, etc.)
* `amount` → transaction value
* `nameOrig` → sender account
* `nameDest` → receiver account
* `oldbalanceOrg / newbalanceOrig` → sender balance before & after
* `oldbalanceDest / newbalanceDest` → receiver balance before & after
* `isFraud` → actual fraud label
* `isFlaggedFraud` → bank’s original detection rule

Dataset size: **Millions of transactions** (highly imbalanced fraud data)

---

## 🎯 Objectives

1. Measure the effectiveness of the bank’s current fraud detection rule
2. Identify behavioural patterns of fraudsters
3. Detect mule accounts and attack chains
4. Analyse temporal fraud activity
5. Build a rule-based fraud detection model using SQL only
6. Provide actionable business recommendations

---

## 🛠 Tools & Techniques

* MySQL
* Window Functions (LAG, LEAD, ROW_NUMBER, RUNNING SUM)
* Behavioural pattern detection
* Sequential transaction analysis
* Rule-based modelling

No machine learning was used — the focus is **analytical thinking using SQL**.

---

## 🔍 Investigation Approach

### Step 1 — Validate Current Detection System

* Compared `isFlaggedFraud` vs `isFraud`
* Measured false positives and false negatives

Result:

> The bank rule detects only a very small portion of actual frauds

Conclusion:
The existing system relies on thresholds instead of behaviour

---

### Step 2 — Transaction Type Analysis

Fraud occurs almost exclusively in:

* TRANSFER
* CASH_OUT

Safe transaction types:

* PAYMENT
* DEBIT
* CASH_IN

Conclusion:
Fraud is behavioural and targeted — not random

---

### Step 3 — Behavioural Sequence Detection (Window Functions)

Using `LEAD()`:

TRANSFER → CASH_OUT pattern discovered

Meaning:

> Fraudsters immediately withdraw transferred funds to avoid reversal

---

### Step 4 — Account Balance Behaviour

Major discovery:

* Sender balance becomes zero after fraud
* Amount ≈ full account balance
* Receiver accounts initially empty

Conclusion:
Attack pattern = account draining into mule accounts

---

### Step 5 — Mule Account Detection

Using partitioned window analysis:

* Many victims → one destination account
* Accounts receive repeated fraudulent transfers

Conclusion:
Fraud network structure exists (hub-and-spoke model)

---

### Step 6 — Temporal Behaviour

* Fraud occurs in bursts
* Multiple rapid transactions
* Accounts disappear after a few transactions

Conclusion:
Fraud attacks are planned sessions, not random activity

---

## 🧠 Key Fraud Behaviour Discovered

Fraudster workflow:

1. Compromise account
2. Transfer full balance
3. Send to the mule account
4. Immediately cash out
5. Abandon account

---

## 🧪 SQL Rule-Based Detection Model

A high-risk transaction typically satisfies:

* Transaction type = TRANSFER or CASH_OUT
* Amount equals sender balance
* Sender balance becomes zero
* Followed by a cash withdrawal

This rule detects fraud far better than the bank’s original rule.

---

## 📊 Business Recommendations

1. Monitor behaviour, not just amount thresholds
2. Flag accounts performing full-balance transfers
3. Detect transfer → withdrawal sequences in real time
4. Freeze accounts receiving funds from multiple senders
5. Implement session-based monitoring instead of single-transaction checks

---

## 💡 Key Takeaways

* Fraud detection is a behavioural problem, not a classification problem
* SQL window functions can detect fraud patterns effectively
* Simple rule-based logic can outperform naive detection rules

---

## 🚀 How to Run

1. Import dataset using `LOAD DATA INFILE`
2. Run analysis queries from `/sql_queries`
3. Review the behavioural detection section

---

## 📌 Author Note

This project demonstrates analytical thinking using SQL instead of machine learning, simulating a real-world banking fraud investigation workflow.
The focus is on reasoning, pattern detection, and business interpretation — skills expected from a data analyst in financial risk analytics.

## 🚀 Author
Abhishek Singh 
Data Analysis Portfolio Project
