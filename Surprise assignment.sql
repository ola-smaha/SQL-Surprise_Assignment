DROP TABLE IF EXISTS reporting_schema.dim_customer;
CREATE TABLE reporting_schema.dim_customer
(
	customer_id SERIAL PRIMARY KEY,
	first_name TEXT,
	last_name TEXT
);
WITH CTE_CUSTOMER_DESCRIPTION AS
(
	SELECT
		customer_id,
		first_name,
		last_name
	FROM public.customer
)
INSERT INTO reporting_schema.dim_customer(customer_id, first_name, last_name)
SELECT * FROM CTE_CUSTOMER_DESCRIPTION;
----------------------------------------------------------
DROP TABLE IF EXISTS reporting_schema.fact_customer;
CREATE TABLE reporting_schema.fact_customer
(
	cust_transaction SERIAL PRIMARY KEY,
	rental_id INT REFERENCES public.rental(rental_id),
	customer_id INT REFERENCES public.customer(customer_id),
	rental_date TIMESTAMP,
	return_date TIMESTAMP,
	rental_fee NUMERIC
);
WITH CTE_CUSTOMER_TRANSACTION AS
(
	SELECT DISTINCT
		se_rental.rental_id,
		se_rental.customer_id,
		se_rental.rental_date,
		se_rental.return_date,
		se_payment.amount
	FROM public.rental se_rental
	INNER JOIN public.payment se_payment
		ON se_rental.rental_id = se_payment.rental_id
)
INSERT INTO reporting_schema.fact_customer(rental_id, customer_id, rental_date, return_date, rental_fee)
SELECT * FROM CTE_CUSTOMER_TRANSACTION;
----------------------------------------------------------
DROP TABLE IF EXISTS reporting_schema.agg_customer;
CREATE TABLE reporting_schema.agg_customer
(
	customer_id SERIAL PRIMARY KEY,
	total_movies_rented INT,
	total_paid NUMERIC,
	average_rental_duration NUMERIC
);
WITH CTE_AGG_CUSTOMER AS
(
	SELECT
		se_rental.customer_id,
		COUNT(se_inventory.film_id) AS total_films_rented,
		ROUND(AVG(EXTRACT(DAY FROM (return_date - rental_date))*24 + EXTRACT(HOUR FROM (return_date - rental_date))),2) AS avg_rental_duration,
		SUM(se_payment.amount) AS total_paid
	FROM public.rental se_rental 
	INNER JOIN public.inventory se_inventory
		ON se_rental.inventory_id = se_inventory.inventory_id
	INNER JOIN public.payment se_payment
		ON se_payment.rental_id = se_rental.rental_id
	GROUP BY
		se_rental.customer_id
)
INSERT INTO reporting_schema.agg_customer(customer_id, total_movies_rented, total_paid, average_rental_duration)
SELECT * FROM CTE_AGG_CUSTOMER;

