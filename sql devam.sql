CREATE TABLE IF NOT EXISTS public.credit_risk
(
    person_age integer,
    person_income integer,
    person_home_ownership character varying(50) COLLATE pg_catalog."default",
    person_emp_length numeric(5,2),
    loan_intent character varying(50) COLLATE pg_catalog."default",
    loan_grade character varying(10) COLLATE pg_catalog."default",
    loan_amnt integer,
    loan_int_rate numeric(5,2),
    loan_status integer,
    loan_percent_income numeric(5,2),
    cb_person_default_on_file character varying(5) COLLATE pg_catalog."default",
    cb_person_cred_hist_length integer
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.credit_risk
    OWNER to postgres;
	
select * from public.credit_risk
select person_home_ownership,loan_grade from public.credit_risk
where loan_grade='A'

CREATE TABLE IF NOT EXISTS public.high_risk_users AS
SELECT
    person_age,
    person_income,
    loan_grade,
    loan_amnt,
    loan_percent_income
FROM
    public.credit_risk
WHERE
    1=2;

WITH risk_averages AS (
    SELECT
        AVG(person_age) AS avg_age,
        AVG(loan_percent_income) AS avg_loan_percent,
        AVG(loan_amnt) AS avg_loan_amount
    FROM
        public.credit_risk
    WHERE
        person_income < 50000
        AND loan_grade IN ('C', 'D', 'E', 'F', 'G')
)
INSERT INTO public.high_risk_users (
    person_age,
    person_income,
    loan_grade,
    loan_amnt,
    loan_percent_income
)
SELECT
    cr.person_age,
    cr.person_income,
    cr.loan_grade,
    cr.loan_amnt,
    cr.loan_percent_income
FROM
    public.credit_risk cr,
    risk_averages ra
WHERE
    cr.person_income < 80000
    AND cr.loan_grade IN ('B','C', 'D', 'E', 'F', 'G')
    AND cr.person_age < ra.avg_age
    AND cr.loan_percent_income > ra.avg_loan_percent;


WITH risk_averages AS (
    SELECT
        AVG(person_age) AS avg_age,
        AVG(loan_percent_income) AS avg_loan_percent,
        AVG(loan_amnt) AS avg_loan_amount
    FROM
        public.credit_risk
    WHERE
        person_income < 80000
        AND loan_grade IN ('B','C', 'D', 'E', 'F', 'G')
)
SELECT
    cr.person_age,
    cr.person_income,
    cr.loan_grade,
    cr.loan_amnt,
    cr.loan_percent_income
FROM
    public.credit_risk cr
JOIN
    risk_averages ra ON TRUE
WHERE
    cr.person_income < 80000
    AND cr.loan_grade IN ('B,''C', 'D', 'E', 'F', 'G')
    AND cr.person_age < ra.avg_age
    AND cr.loan_percent_income > ra.avg_loan_percent;

WITH long_history AS (
    SELECT
        person_age,
        loan_int_rate * 0.95 AS new_int_rate,
        loan_grade,
        'indirim' AS islem_turu
    FROM
        public.credit_risk
    WHERE
        cb_person_cred_hist_length > 8
        AND person_age >= 30
),
short_history AS (
    SELECT
        person_age,
        loan_int_rate * 1.12 AS new_int_rate,
        loan_grade,
        'zam' AS islem_turu
    FROM
        public.credit_risk
    WHERE
        cb_person_cred_hist_length <= 8
        AND person_age >= 30
)

SELECT
    person_age,
    loan_grade,
    islem_turu,
    new_int_rate
FROM
    long_history
UNION ALL
SELECT
    person_age,
    loan_grade,
    islem_turu,
    new_int_rate
FROM
    short_history
ORDER BY
    person_age, loan_grade;

WITH updated_rates AS (
    SELECT
        person_age,
        loan_grade,
        CASE 
            WHEN cb_person_cred_hist_length > 8 AND person_age >= 30 
                THEN loan_int_rate * 0.95
            WHEN cb_person_cred_hist_length <= 8 AND person_age >= 30 
                THEN loan_int_rate * 1.12
            ELSE loan_int_rate
        END AS new_int_rate,
        CASE 
            WHEN cb_person_cred_hist_length > 8 AND person_age >= 30 
                THEN 'indirim'
            WHEN cb_person_cred_hist_length <= 8 AND person_age >= 30 
                THEN 'zam'
            ELSE 'degisiklik yok'
        END AS islem_turu
    FROM public.credit_risk
    WHERE person_age >= 30
)

SELECT
    person_age,
    loan_grade,
    islem_turu,
    new_int_rate
FROM updated_rates
ORDER BY person_age, loan_grade;

	
	