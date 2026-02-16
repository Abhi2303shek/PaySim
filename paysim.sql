create database paysim_fraud;
use paysim_fraud;
SET GLOBAL local_infile = 1;
CREATE TABLE paysim (
    step INT,
    type VARCHAR(100),
    amount DOUBLE,
    nameOrig VARCHAR(100),
    oldbalanceOrg DOUBLE,
    newbalanceOrig DOUBLE,
    nameDest VARCHAR(100),
    oldbalanceDest DOUBLE,
    newbalanceDest DOUBLE,
    isFraud INT,
    isFlaggedFraud INT
);

LOAD DATA LOCAL INFILE 'C:/Desktop/PaySim.csv'
INTO TABLE paysim
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW VARIABLES LIKE 'local_infile';

select count(*) from paysim;

# 1️⃣ Dataset Overview (Understanding the problem)
## 1. What percentage of total transactions are fraudulent?
select count(*) as total, sum(isFraud) as fraud, round(sum(isFraud) * 100/count(*), 4) from paysim;

## 2. How many transactions were flagged as fraud by the system vs actually fraud?
select count(*) as total, sum(isFlaggedFraud) as fraud, round(sum(isFlaggedFraud) * 100/count(*), 4) from paysim;

## 3. How accurate is the bank’s fraud detection rule?
select sum(isFraud) as fraud_real, sum(isFlaggedFraud) as fraud, round(sum(isFraud) * 100/ sum(isFlaggedFraud), 2) from paysim;
select isFlaggedFraud, count(*) as total, sum(isFraud) as actual from paysim group by isFlaggedFraud;

## 4. Are fraudulent transactions rare events (class imbalance)?
select case when isFraud=1 then 'Fraud' else 'Normal' end category, count(*) from paysim group by category;

# 2️⃣ Transaction Type Behaviour
## 5. Which transaction types are most frequently used?
select type, count(*) from paysim group by type;

## 6. Which transaction type has the highest fraud rate?
select type, round(sum(isFraud)*100/count(*),3) as fraud_rate from paysim group by type order by fraud_rate desc;

## 7. Does fraud occur only in specific transaction types?
select distinct type from paysim where isFraud=1;

## 8. Are some transaction types completely safe?
select type from paysim group by type having sum(isFraud)=0;

## 9. Are fraudsters using a predictable transaction pattern (e.g., Transfer → Cash Out)?
select * from (select *, lead(type) over(partition by nameOrig order by step) next_txn from paysim) trans where type='Transfer' and next_txn='CASH_OUT';

# 3️⃣ Time-based Patterns
## 10. Does fraud increase over time (step progression)?
select step, sum(isFraud) from paysim group by step;

## 11. Are there peak fraud hours in a day?
select step%24 as hours, sum(isFraud) as frauds from paysim group by hours order by frauds desc limit 10;

## 12. Do fraudsters operate at night more than day?
select step%24 as hours, round(sum(isFraud) * 100/count(*),4) as frauds from paysim group by hours;

## 13. Are frauds clustered in certain time windows?
select *, step-lag(step) over(partition by nameOrig order by step) gap from paysim;

## 14. Does fraud spike after certain transaction volumes?
select step, count(*) as txn from paysim group by step having sum(isFraud)>0;

# 4️⃣ Transaction Amount Analysis
## 15. Are fraudulent transactions larger than normal transactions?
select isFraud, avg(amount) from paysim group by isFraud;

## 16. What transaction amount range is most risky?
select case 
when amount<10000 then 'Small'
when amount<100000 then 'Medium'
when amount<1000000 then 'Large'
else 'V.Large' end range_amount, sum(isFraud) frauds from paysim group by range_amount;

## 17. Is there a minimum amount below which fraud rarely occurs?
select min(amount) from paysim where isFraud=1;

## 18. Are extremely large transactions always fraud?
select count(*) from paysim where amount>1000000 and isFraud=1;

## 19. Do fraudsters empty the entire balance in one transaction?
select count(*) from paysim where amount=oldbalanceOrg and isFraud=1;

# 5️⃣ Account Balance Behaviour (Most Important Section)
## 20. Do fraudsters transfer entire account balance?
select count(*) from paysim where newbalanceOrig=0 and isFraud=1;

## 21. Do sender accounts become zero after fraud?
select count(*) from paysim where amount=oldbalanceOrg and isFraud=1;

## 22. Are receiver accounts initially empty?
select count(*) from paysim where oldbalanceDest=0 and isFraud=1;

## 23. Do fraud transactions violate normal balance logic?
select count(*) from paysim where newbalanceDest>0 and newbalanceOrig>0;

## 24. Are balances manipulated to bypass detection?
select *, amount-lag(step) over(partition by nameOrig order by step) jump from paysim;

## 25. Is there a pattern in old vs new balance difference?
select *,(oldbalanceOrg - newbalanceOrig) diff from paysim where isFraud=1;

# 6️⃣ Sender & Receiver Behaviour
## 26. Are certain sender accounts repeatedly committing fraud?
select nameOrig, sum(isFraud) frauds from paysim group by nameOrig order by frauds desc limit 10;

## 27. Are there mule accounts receiving multiple fraud transactions?
select *, count(nameOrig) over(partition by nameDest) as senders from paysim;

## 28. Do fraudsters use new accounts or old accounts?
select * from (select *, row_number() over (partition by nameorig order by step) rn from paysim) tr where rn=1 and isFraud=1;

## 29. Do fraudsters transact only once and disappear?
select nameOrig, count(*) tran from paysim where isFraud=1 group by nameOrig having tran<=2;

## 30. Are there hub accounts connected to many fraud cases?
select nameDest, count(*) fraud_received from paysim where isFraud=1 group by nameDest order by fraud_received desc limit 10;

# 7️⃣ Detection System Evaluation (Very Important for Portfolio)
## 31. What % of actual frauds were detected by the system?
select sum(isFlaggedFraud and isFraud)/sum(isFraud) fraud_rate from paysim;

## 32. What % of flagged transactions were actually fraud?
select sum(isFraud and isFlaggedFraud)/sum(isFlaggedFraud) real_fraud_rate from paysim;

## 33. False positive rate of the bank rule?
select sum(isFlaggedFraud and isFraud=0)/count(*) as false_positive from paysim;

## 34. False negative rate (dangerous misses)?
select sum(isFraud=1 and isFlaggedFraud=0)/count(*) as false_negative from paysim;

## 35. Can a better rule be designed using simple conditions?
select count(*) from paysim where type in ('TRANSFER', 'CASH_OUT') and amount=oldbalanceOrg and newbalanceOrig=0;

# 8️⃣ Behavioural Fraud Patterns
## 36. Does fraud mostly occur as TRANSFER followed by CASH_OUT?
select * from (select *, lead(type) over(partition by nameOrig order by step) next_txn from paysim) trans where type='Transfer' and next_txn='CASH_OUT';

## 37. Do fraudsters avoid deposit/payments?
select distinct type from paysim where isFraud=1;

## 38. Do fraudsters always drain money immediately?
select count(*) from paysim where isFraud=1 and newbalanceOrig=0;

## 39. Are fraud transactions faster than normal users?
select *, step-lag(step) over(partition by nameOrig order by step) rapid_time from paysim;

## 40. Is fraud associated with zero-balance receivers?
select count(*) from paysim where isFraud=1 and oldbalanceDest=0;

# 9️⃣ Risk Rule Creation (Business Insight)
## 41. Can high-risk transactions be identified using amount + type?
select type, avg(amount), sum(isFraud) from paysim group by type;

## 42. Can balance change detect fraud reliably?
select count(*) from paysim where (oldbalanceOrg - newbalanceOrig)=amount and isFraud=1;

## 43. Can time-of-day improve fraud detection?
select step%24 hour, sum(isFraud) from paysim group by hour;

## 44. What 3 conditions best predict fraud?
select count(*) from paysim where type in ('TRANSFER', 'CASH_OUT') and amount>200000 and newbalanceOrig=0;

## 45. Can we design a simple rule-based fraud detection model?
select *, case when type in ('TRANSFER', 'CASH_OUT') and amount=oldbalanceOrg and newbalanceOrig=0 then 1 else 0 end predict_fraud from paysim;

# 🔟 Advanced Analytical Thinking (Recruiter-level)
## 46. What is the strongest indicator of fraud in the dataset?
select type, sum(isFraud) frauds from paysim group by type order by frauds desc limit 10;

## 47. What behaviour distinguishes fraudsters from genuine users?
select isFraud, avg(amount), avg(oldbalanceOrg) from paysim group by isFraud;

## 48. Can fraud be predicted without using the `isFraud` column?
select count(*) from paysim where type in ('TRANSFER', 'CASH_OUT') and amount=oldbalanceOrg and newbalanceOrig=0;

## 49. What variables are useless for fraud detection?
select count(distinct nameOrig), count(distinct nameDest) from paysim;

## 50. What business policy would you recommend to the bank?
select type, sum(isFraud) frauds from paysim group by type;