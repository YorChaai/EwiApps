--
-- PostgreSQL database dump
--

\restrict HHXIAzK5gXVRSbL53XMqDMVHe9CsilgvEb6NblWJ1XzI3L2OMHDYlSYqmXXVuNC

-- Dumped from database version 16.13
-- Dumped by pg_dump version 16.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: advance_item_subcategories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advance_item_subcategories (
    advance_item_id integer NOT NULL,
    category_id integer NOT NULL
);


ALTER TABLE public.advance_item_subcategories OWNER TO postgres;

--
-- Name: advance_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advance_items (
    id integer NOT NULL,
    advance_id integer NOT NULL,
    category_id integer NOT NULL,
    description character varying(300) NOT NULL,
    estimated_amount double precision NOT NULL,
    revision_no integer,
    evidence_path character varying(500),
    evidence_filename character varying(200),
    date date,
    source character varying(50),
    currency character varying(10),
    currency_exchange double precision,
    status character varying(20),
    notes text,
    created_at timestamp without time zone
);


ALTER TABLE public.advance_items OWNER TO postgres;

--
-- Name: advance_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advance_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advance_items_id_seq OWNER TO postgres;

--
-- Name: advance_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advance_items_id_seq OWNED BY public.advance_items.id;


--
-- Name: advances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advances (
    id integer NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    advance_type character varying(10),
    user_id integer NOT NULL,
    status character varying(30),
    notes text,
    approved_revision_no integer,
    active_revision_no integer,
    report_year integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    approved_at timestamp without time zone
);


ALTER TABLE public.advances OWNER TO postgres;

--
-- Name: advances_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advances_id_seq OWNER TO postgres;

--
-- Name: advances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advances_id_seq OWNED BY public.advances.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(10) NOT NULL,
    parent_id integer,
    status character varying(20),
    created_by integer,
    sort_order integer,
    main_group character varying(50)
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_id_seq OWNER TO postgres;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: dividend_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dividend_settings (
    id integer NOT NULL,
    year integer NOT NULL,
    profit_retained double precision NOT NULL,
    opening_cash_balance double precision NOT NULL,
    accounts_receivable double precision NOT NULL,
    prepaid_tax_pph23 double precision NOT NULL,
    prepaid_expenses double precision NOT NULL,
    other_receivables double precision NOT NULL,
    office_inventory double precision NOT NULL,
    other_assets double precision NOT NULL,
    accounts_payable double precision NOT NULL,
    salary_payable double precision NOT NULL,
    shareholder_payable double precision NOT NULL,
    accrued_expenses double precision NOT NULL,
    share_capital double precision NOT NULL,
    retained_earnings_balance double precision NOT NULL,
    created_at timestamp without time zone
);


ALTER TABLE public.dividend_settings OWNER TO postgres;

--
-- Name: dividend_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dividend_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dividend_settings_id_seq OWNER TO postgres;

--
-- Name: dividend_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dividend_settings_id_seq OWNED BY public.dividend_settings.id;


--
-- Name: dividends; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dividends (
    id integer NOT NULL,
    date date NOT NULL,
    name character varying(150) NOT NULL,
    amount double precision NOT NULL,
    recipient_count integer NOT NULL,
    tax_percentage double precision NOT NULL,
    created_at timestamp without time zone
);


ALTER TABLE public.dividends OWNER TO postgres;

--
-- Name: dividends_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dividends_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dividends_id_seq OWNER TO postgres;

--
-- Name: dividends_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dividends_id_seq OWNED BY public.dividends.id;


--
-- Name: expense_subcategories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expense_subcategories (
    expense_id integer NOT NULL,
    category_id integer NOT NULL
);


ALTER TABLE public.expense_subcategories OWNER TO postgres;

--
-- Name: expenses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expenses (
    id integer NOT NULL,
    settlement_id integer NOT NULL,
    category_id integer NOT NULL,
    description character varying(300) NOT NULL,
    amount double precision NOT NULL,
    date date NOT NULL,
    source character varying(50),
    advance_item_id integer,
    revision_no integer,
    currency character varying(10),
    currency_exchange double precision,
    evidence_path character varying(500),
    evidence_filename character varying(200),
    status character varying(20),
    notes text,
    created_at timestamp without time zone
);


ALTER TABLE public.expenses OWNER TO postgres;

--
-- Name: expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.expenses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.expenses_id_seq OWNER TO postgres;

--
-- Name: expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.expenses_id_seq OWNED BY public.expenses.id;


--
-- Name: manual_combine_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.manual_combine_groups (
    id integer NOT NULL,
    table_name character varying(20) NOT NULL,
    report_year integer NOT NULL,
    group_date date NOT NULL,
    row_ids_json text NOT NULL,
    created_at timestamp without time zone
);


ALTER TABLE public.manual_combine_groups OWNER TO postgres;

--
-- Name: manual_combine_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.manual_combine_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.manual_combine_groups_id_seq OWNER TO postgres;

--
-- Name: manual_combine_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.manual_combine_groups_id_seq OWNED BY public.manual_combine_groups.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    actor_id integer,
    action_type character varying(50) NOT NULL,
    target_type character varying(50) NOT NULL,
    target_id integer NOT NULL,
    message text NOT NULL,
    read_status boolean,
    created_at timestamp without time zone,
    link_path character varying(200)
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: revenues; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.revenues (
    id integer NOT NULL,
    invoice_date date NOT NULL,
    description character varying(300) NOT NULL,
    invoice_value double precision NOT NULL,
    currency character varying(10),
    currency_exchange double precision,
    invoice_number character varying(50),
    client character varying(150),
    receive_date date,
    amount_received double precision,
    ppn double precision,
    pph_23 double precision,
    transfer_fee double precision,
    remark text,
    revenue_type character varying(32) NOT NULL,
    created_at timestamp without time zone
);


ALTER TABLE public.revenues OWNER TO postgres;

--
-- Name: revenues_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.revenues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.revenues_id_seq OWNER TO postgres;

--
-- Name: revenues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.revenues_id_seq OWNED BY public.revenues.id;


--
-- Name: settlements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.settlements (
    id integer NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    user_id integer NOT NULL,
    settlement_type character varying(10),
    status character varying(20),
    report_year integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    completed_at timestamp without time zone,
    advance_id integer
);


ALTER TABLE public.settlements OWNER TO postgres;

--
-- Name: settlements_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.settlements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.settlements_id_seq OWNER TO postgres;

--
-- Name: settlements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.settlements_id_seq OWNED BY public.settlements.id;


--
-- Name: taxes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.taxes (
    id integer NOT NULL,
    date date NOT NULL,
    description character varying(300) NOT NULL,
    transaction_value double precision NOT NULL,
    currency character varying(10),
    currency_exchange double precision,
    ppn double precision,
    pph_21 double precision,
    pph_23 double precision,
    pph_26 double precision,
    created_at timestamp without time zone
);


ALTER TABLE public.taxes OWNER TO postgres;

--
-- Name: taxes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.taxes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.taxes_id_seq OWNER TO postgres;

--
-- Name: taxes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.taxes_id_seq OWNED BY public.taxes.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(80) NOT NULL,
    email character varying(150),
    password_hash character varying(256) NOT NULL,
    google_id character varying(200),
    reset_token character varying(100),
    reset_token_expiry timestamp without time zone,
    full_name character varying(150) NOT NULL,
    phone_number character varying(20),
    workplace character varying(100),
    role character varying(20) NOT NULL,
    profile_image character varying(500),
    last_login timestamp without time zone,
    created_at timestamp without time zone
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: advance_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advance_items ALTER COLUMN id SET DEFAULT nextval('public.advance_items_id_seq'::regclass);


--
-- Name: advances id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advances ALTER COLUMN id SET DEFAULT nextval('public.advances_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: dividend_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dividend_settings ALTER COLUMN id SET DEFAULT nextval('public.dividend_settings_id_seq'::regclass);


--
-- Name: dividends id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dividends ALTER COLUMN id SET DEFAULT nextval('public.dividends_id_seq'::regclass);


--
-- Name: expenses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expenses ALTER COLUMN id SET DEFAULT nextval('public.expenses_id_seq'::regclass);


--
-- Name: manual_combine_groups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manual_combine_groups ALTER COLUMN id SET DEFAULT nextval('public.manual_combine_groups_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: revenues id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.revenues ALTER COLUMN id SET DEFAULT nextval('public.revenues_id_seq'::regclass);


--
-- Name: settlements id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settlements ALTER COLUMN id SET DEFAULT nextval('public.settlements_id_seq'::regclass);


--
-- Name: taxes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.taxes ALTER COLUMN id SET DEFAULT nextval('public.taxes_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: advance_item_subcategories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.advance_item_subcategories (advance_item_id, category_id) FROM stdin;
\.


--
-- Data for Name: advance_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.advance_items (id, advance_id, category_id, description, estimated_amount, revision_no, evidence_path, evidence_filename, date, source, currency, currency_exchange, status, notes, created_at) FROM stdin;
\.


--
-- Data for Name: advances; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.advances (id, title, description, advance_type, user_id, status, notes, approved_revision_no, active_revision_no, report_year, created_at, updated_at, approved_at) FROM stdin;
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categories (id, name, code, parent_id, status, created_by, sort_order, main_group) FROM stdin;
1	Biaya Operasi	A	\N	approved	1	0	BEBAN LANGSUNG
2	Transportation	A1	1	approved	1	0	\N
3	Accommodation	A2	1	approved	1	0	\N
4	Allowance	A3	1	approved	1	0	\N
5	Meal	A4	1	approved	1	0	\N
6	Biaya Research (R&D)	B	\N	approved	1	0	BEBAN LANGSUNG
7	Administrasi	C	\N	approved	1	0	BIAYA ADMINISTRASI DAN UMUM
8	Biaya Bank	C1	7	approved	1	0	\N
\.


--
-- Data for Name: dividend_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dividend_settings (id, year, profit_retained, opening_cash_balance, accounts_receivable, prepaid_tax_pph23, prepaid_expenses, other_receivables, office_inventory, other_assets, accounts_payable, salary_payable, shareholder_payable, accrued_expenses, share_capital, retained_earnings_balance, created_at) FROM stdin;
\.


--
-- Data for Name: dividends; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dividends (id, date, name, amount, recipient_count, tax_percentage, created_at) FROM stdin;
\.


--
-- Data for Name: expense_subcategories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expense_subcategories (expense_id, category_id) FROM stdin;
\.


--
-- Data for Name: expenses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expenses (id, settlement_id, category_id, description, amount, date, source, advance_item_id, revision_no, currency, currency_exchange, evidence_path, evidence_filename, status, notes, created_at) FROM stdin;
\.


--
-- Data for Name: manual_combine_groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.manual_combine_groups (id, table_name, report_year, group_date, row_ids_json, created_at) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, user_id, actor_id, action_type, target_type, target_id, message, read_status, created_at, link_path) FROM stdin;
\.


--
-- Data for Name: revenues; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.revenues (id, invoice_date, description, invoice_value, currency, currency_exchange, invoice_number, client, receive_date, amount_received, ppn, pph_23, transfer_fee, remark, revenue_type, created_at) FROM stdin;
\.


--
-- Data for Name: settlements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.settlements (id, title, description, user_id, settlement_type, status, report_year, created_at, updated_at, completed_at, advance_id) FROM stdin;
\.


--
-- Data for Name: taxes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.taxes (id, date, description, transaction_value, currency, currency_exchange, ppn, pph_21, pph_23, pph_26, created_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, email, password_hash, google_id, reset_token, reset_token_expiry, full_name, phone_number, workplace, role, profile_image, last_login, created_at) FROM stdin;
2	staff1	\N	scrypt:32768:8:1$3JSmpfQ0eQIbvZCq$8dc399754b5cb6d0f4138f55c90f3a6573e5b1efe2d7386678e201d55d1a28702dd8b12a2fe191ec66d24816e384e44cafeb68803d3a200bfa028435ecb85dca	\N	\N	\N	Staff 1	-	-	staff	\N	\N	2026-04-25 01:34:31.765559
1	manager1	\N	scrypt:32768:8:1$2fzSYqGDUXJGfJZw$e6fd13483f9c562e240ce9db3d6babfc28fec71d2fff19154e00adf1c1f2f20b3a99f63d977e5a5306424a3208d88e6a1bbd64d6bce58c8dfed916146227952f	\N	\N	\N	Manager	-	-	manager	\N	2026-04-25 01:34:40.758843	2026-04-25 01:34:31.765559
\.


--
-- Name: advance_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.advance_items_id_seq', 1, false);


--
-- Name: advances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.advances_id_seq', 1, false);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_id_seq', 8, true);


--
-- Name: dividend_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dividend_settings_id_seq', 1, false);


--
-- Name: dividends_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dividends_id_seq', 1, false);


--
-- Name: expenses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expenses_id_seq', 1, false);


--
-- Name: manual_combine_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.manual_combine_groups_id_seq', 1, false);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_id_seq', 1, false);


--
-- Name: revenues_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.revenues_id_seq', 1, false);


--
-- Name: settlements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.settlements_id_seq', 1, false);


--
-- Name: taxes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.taxes_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- Name: advance_item_subcategories advance_item_subcategories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advance_item_subcategories
    ADD CONSTRAINT advance_item_subcategories_pkey PRIMARY KEY (advance_item_id, category_id);


--
-- Name: advance_items advance_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advance_items
    ADD CONSTRAINT advance_items_pkey PRIMARY KEY (id);


--
-- Name: advances advances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advances
    ADD CONSTRAINT advances_pkey PRIMARY KEY (id);


--
-- Name: categories categories_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_code_key UNIQUE (code);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: dividend_settings dividend_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dividend_settings
    ADD CONSTRAINT dividend_settings_pkey PRIMARY KEY (id);


--
-- Name: dividend_settings dividend_settings_year_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dividend_settings
    ADD CONSTRAINT dividend_settings_year_key UNIQUE (year);


--
-- Name: dividends dividends_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dividends
    ADD CONSTRAINT dividends_pkey PRIMARY KEY (id);


--
-- Name: expense_subcategories expense_subcategories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense_subcategories
    ADD CONSTRAINT expense_subcategories_pkey PRIMARY KEY (expense_id, category_id);


--
-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (id);


--
-- Name: manual_combine_groups manual_combine_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manual_combine_groups
    ADD CONSTRAINT manual_combine_groups_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: revenues revenues_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.revenues
    ADD CONSTRAINT revenues_pkey PRIMARY KEY (id);


--
-- Name: settlements settlements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_pkey PRIMARY KEY (id);


--
-- Name: taxes taxes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.taxes
    ADD CONSTRAINT taxes_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_google_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_google_id_key UNIQUE (google_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: ix_advances_report_year; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_advances_report_year ON public.advances USING btree (report_year);


--
-- Name: ix_advances_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_advances_status ON public.advances USING btree (status);


--
-- Name: ix_advances_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_advances_user_id ON public.advances USING btree (user_id);


--
-- Name: ix_categories_parent_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_categories_parent_id ON public.categories USING btree (parent_id);


--
-- Name: ix_categories_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_categories_status ON public.categories USING btree (status);


--
-- Name: ix_dividends_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_dividends_date ON public.dividends USING btree (date);


--
-- Name: ix_expenses_category_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_expenses_category_id ON public.expenses USING btree (category_id);


--
-- Name: ix_expenses_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_expenses_date ON public.expenses USING btree (date);


--
-- Name: ix_expenses_settlement_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_expenses_settlement_id ON public.expenses USING btree (settlement_id);


--
-- Name: ix_revenues_invoice_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_revenues_invoice_date ON public.revenues USING btree (invoice_date);


--
-- Name: ix_revenues_revenue_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_revenues_revenue_type ON public.revenues USING btree (revenue_type);


--
-- Name: ix_settlements_advance_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_settlements_advance_id ON public.settlements USING btree (advance_id);


--
-- Name: ix_settlements_report_year; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_settlements_report_year ON public.settlements USING btree (report_year);


--
-- Name: ix_settlements_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_settlements_status ON public.settlements USING btree (status);


--
-- Name: ix_settlements_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_settlements_user_id ON public.settlements USING btree (user_id);


--
-- Name: ix_taxes_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_taxes_date ON public.taxes USING btree (date);


--
-- Name: advance_item_subcategories advance_item_subcategories_advance_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advance_item_subcategories
    ADD CONSTRAINT advance_item_subcategories_advance_item_id_fkey FOREIGN KEY (advance_item_id) REFERENCES public.advance_items(id);


--
-- Name: advance_item_subcategories advance_item_subcategories_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advance_item_subcategories
    ADD CONSTRAINT advance_item_subcategories_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: advance_items advance_items_advance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advance_items
    ADD CONSTRAINT advance_items_advance_id_fkey FOREIGN KEY (advance_id) REFERENCES public.advances(id);


--
-- Name: advance_items advance_items_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advance_items
    ADD CONSTRAINT advance_items_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: advances advances_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advances
    ADD CONSTRAINT advances_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: categories categories_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: categories categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.categories(id);


--
-- Name: expense_subcategories expense_subcategories_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense_subcategories
    ADD CONSTRAINT expense_subcategories_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: expense_subcategories expense_subcategories_expense_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense_subcategories
    ADD CONSTRAINT expense_subcategories_expense_id_fkey FOREIGN KEY (expense_id) REFERENCES public.expenses(id);


--
-- Name: expenses expenses_advance_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_advance_item_id_fkey FOREIGN KEY (advance_item_id) REFERENCES public.advance_items(id);


--
-- Name: expenses expenses_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: expenses expenses_settlement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_settlement_id_fkey FOREIGN KEY (settlement_id) REFERENCES public.settlements(id);


--
-- Name: notifications notifications_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id);


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: settlements settlements_advance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_advance_id_fkey FOREIGN KEY (advance_id) REFERENCES public.advances(id);


--
-- Name: settlements settlements_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict HHXIAzK5gXVRSbL53XMqDMVHe9CsilgvEb6NblWJ1XzI3L2OMHDYlSYqmXXVuNC

