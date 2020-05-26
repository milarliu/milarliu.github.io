use mavenfuzzyfactory;


#######################################
############ Final Project ############
#######################################


-- Part. 1 ----------------------------
-- volume growth: overall session and order volume, trended by quarter for the life of the business
select
	year(ws.created_at) as yr,
    quarter(ws.created_at) as qtr,
    count(distinct ws.website_session_id) as sessions,
    count(distinct order_id) as orders
from website_sessions as ws
	left join orders as o
		on ws.website_session_id = o.website_session_id
group by 1, 2;
# Result:
# dramatic growth of sessions and orders throughout the whole time.
# To handle the incomplete 1st quarter of 2015:
# due to the limit of raw data up till 4th quarter of 2014, we can project it for 1st quarter of 2015


-- Part. 2 ----------------------------
-- efficiency improvements: quarterly figures since the company launched, for session-to-order conversion rate, rev per order, rev per session
select
	year(ws.created_at) as yr,
    quarter(ws.created_at) as qtr,
    count(distinct order_id)/count(distinct ws.website_session_id) as session_to_order_cvr,
    sum(price_usd)/count(distinct order_id) as revenue_per_order,
    sum(price_usd)/count(distinct ws.website_session_id) as revenue_per_session
from website_sessions as ws
	left join orders as o
		on ws.website_session_id = o.website_session_id
group by 1, 2;
# Result:
# similar story as session and order growth in question 1, the session_to_order conversion rate improved from 3.2% to 8.4%.
# as well as revenue per order and revenue per session.
# The metric "revenue per session" indicates how our marketing should spend to acquire a traffic, higher we can bid, more traffic we can obtain.


-- Part. 3 ----------------------------
-- specific channels growth: quarterly view of orders from gsearch nonbrand, bsearch nonbrand, brand search overall, organic search, direct type-in
select
	year(ws.created_at) as yr,
    quarter(ws.created_at) as qtr,
    count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then order_id else null end) as gsearch_nonbrand_orders,
    count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then order_id else null end) as bsearch_nonbrand_orders,
    count(distinct case when utm_campaign = 'brand' then order_id else null end) as brand_search_orders,
    count(distinct case when utm_source is null and http_referer is not null then order_id else null end) as organic_search_orders,
    count(distinct case when utm_source is null and http_referer is null then order_id else null end) as direct_typein_orders
from website_sessions as ws
	left join orders as o
		on ws.website_session_id = o.website_session_id
group by 1, 2;
# Result:
# Orders from all channels picked up significantly.
# To be more specific, the percentage of other searches against nonbrand searches increased from around 1:6 to around 1:2.


-- Part. 4 ----------------------------
-- overall session-to-order conversion rate trends for same channels by quarter, noticing any periods with major improvements/optimizations
select
	year(ws.created_at) as yr,
    quarter(ws.created_at) as qtr,
    count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then order_id else null end)/
		count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then ws.website_session_id else null end) as gsearch_nonbrand_cvr,
	count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then order_id else null end)/
		count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then ws.website_session_id else null end) as bsearch_nonbrand_cvr,
	count(distinct case when utm_campaign = 'brand' then order_id else null end)/
		count(distinct case when utm_campaign = 'brand' then ws.website_session_id else null end) as brand_search_cvr,
	count(distinct case when utm_source is null and http_referer is not null then order_id else null end)/
		count(distinct case when utm_source is null and http_referer is not null then ws.website_session_id else null end) as organic_search_cvr,
	count(distinct case when utm_source is null and http_referer is null then order_id else null end)/
		count(distinct case when utm_source is null and http_referer is null then ws.website_session_id else null end) as direct_typein_cvr
from website_sessions as ws
	left join orders as o
		on ws.website_session_id = o.website_session_id
group by 1, 2;
# Result:
# all CVRs have substantially picked up, the business has improved.
# The improvements from 2012 4th quarter to 2013 1st quarter is quite significant.


-- Part. 5 ----------------------------
-- monthly revenue and margin by product, with total sales and revenue, noticing the seasonality
select
	year(created_at) as yr,
    month(created_at) as mon,
    sum(case when product_id = 1 then price_usd else null end) as prod1_rev,
    sum(case when product_id = 1 then price_usd-cogs_usd else null end) as prod1_marg,
    sum(case when product_id = 2 then price_usd else null end) as prod2_rev,
    sum(case when product_id = 2 then price_usd-cogs_usd else null end) as prod2_marg,
    sum(case when product_id = 3 then price_usd else null end) as prod3_rev,
    sum(case when product_id = 3 then price_usd-cogs_usd else null end) as prod3_marg,
    sum(case when product_id = 4 then price_usd else null end) as prod4_rev,
    sum(case when product_id = 4 then price_usd-cogs_usd else null end) as prod4_marg,
	sum(price_usd) as total_rev,
    sum(price_usd-cogs_usd) as total_marg
from order_items
group by 1, 2;
# Result:
# For prod1, mrfuzzy, sales revenue in Nov and Dec are extremely high for every year, may be due to most US students recognizing holidays during then.
# For prod2, lovebear, the rev and margin are especially high in Feb, which makes sense, since it's targeting couples.
# For prod3, birthdaybear, the rev and margin seem higher at the end of the year, but lack of data to identify seasonality.
# Same for prod4, minibear.


-- Part. 6 ----------------------------
-- impact of introducing new products: monthly session to /products page, % of these sessions that clicked through another page and how it changes,
-- a view of how conversion from /products to placing an order has improved
drop temporary table if exists products_pvs;
create temporary table products_pvs
select 
	website_session_id,
    website_pageview_id,
    created_at as saw_products_at
from website_pageviews
where pageview_url = '/products';

select
	year(saw_products_at) as yr,
    month(saw_products_at) as mon,
    count(distinct pp.website_session_id) as sessions_to_products,
    count(distinct wp.website_session_id) as clicked_to_next_page,
    count(distinct wp.website_session_id)/count(distinct pp.website_session_id) as clickthrough_rate,
    count(distinct order_id) as orders,
    count(distinct order_id)/count(distinct pp.website_session_id) as products_to_order_cvr
from products_pvs as pp
	left join website_pageviews as wp
		on pp.website_session_id = wp.website_session_id
		and wp.website_pageview_id > pp.website_pageview_id
	left join orders as o
		on pp.website_session_id = o.website_session_id
group by 1, 2;
# Result:
# clickthrough_rate improved from 71.39% to 85.60% throughout the business life, so as products_to_order CVR from 8.10% to 13.90%.


-- Part. 7 ----------------------------
-- 4th product became a primary product on Dec 05, 2014. Pull sales data since then, show how well each product cross-sells from one another
drop temporary table if exists pri_products;
create temporary table pri_products
select
	order_id,
    primary_product_id,
    created_at as ordered_at
from orders
where created_at > '2014-12-05';

select
	primary_product_id,
    count(distinct order_id) as total_orders,
    count(distinct case when x_sell_prod_id = 1 then order_id else null end) as x_sold_w_p1,
    count(distinct case when x_sell_prod_id = 1 then order_id else null end)/count(distinct order_id) as x_sold_w_p1_rt,
    count(distinct case when x_sell_prod_id = 2 then order_id else null end) as x_sold_w_p2,
    count(distinct case when x_sell_prod_id = 2 then order_id else null end)/count(distinct order_id) as x_sold_w_p2_rt,
    count(distinct case when x_sell_prod_id = 3 then order_id else null end) as x_sold_w_p3,
    count(distinct case when x_sell_prod_id = 3 then order_id else null end)/count(distinct order_id) as x_sold_w_p3_rt,
    count(distinct case when x_sell_prod_id = 4 then order_id else null end) as x_sold_w_p4,
    count(distinct case when x_sell_prod_id = 4 then order_id else null end)/count(distinct order_id) as x_sold_w_p4_rt
from (
	select 
		pp.*,
        oi.product_id as x_sell_prod_id
	from pri_products as pp
		left join order_items oi
			on pp.order_id = oi.order_id
            and oi.is_primary_item = 0
	) as pri_w_x_sell
group by 1;
# Result:
# likelihood to be the primary product: p1 > p2 > p3 > p4
# Prod4 is sold best with all three existing products, with x_sold_rt around 20%.
# Prod1 and prod3 cross-sell well with each other.














