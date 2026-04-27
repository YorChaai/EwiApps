--
-- PostgreSQL database dump
--

\restrict bHVYm1hbooZ4Me7tIoTJrjFEtCb19sIJDS3BbiL2rmbA3YY6JVb3lv5Yvg0HsbV

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
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO postgres;

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
    password_hash character varying(256) NOT NULL,
    full_name character varying(150) NOT NULL,
    phone_number character varying(20),
    workplace character varying(100),
    role character varying(20) NOT NULL,
    profile_image character varying(500),
    last_login timestamp without time zone,
    created_at timestamp without time zone,
    email character varying(150),
    google_id character varying(200),
    reset_token character varying(100),
    reset_token_expiry timestamp without time zone
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
36	19
37	2
37	3
\.


--
-- Data for Name: advance_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.advance_items (id, advance_id, category_id, description, estimated_amount, revision_no, evidence_path, evidence_filename, date, source, currency, currency_exchange, status, notes, created_at) FROM stdin;
1	5	3	diofavian	101	0	\N	\N	2026-03-13	\N	IDR	1	approved	Disetujui oleh manager	2026-03-12 18:10:21.880507
2	6	65	122	101	0	\N	\N	\N	\N	IDR	1	pending	\N	2026-03-13 15:23:51.150618
3	4	25	hgfhgf	768768676	0	\N	\N	2026-03-14	\N	IDR	1	approved	Disetujui oleh manager	2026-03-13 18:08:43.265039
4	3	19	sdfds	123123123	0	\N	\N	2026-03-16	\N	IDR	1	approved	Disetujui oleh manager	2026-03-16 01:33:45.134692
5	7	19	hari selasa	123123123123	0	\N	\N	2026-03-22	\N	IDR	1	pending	[{"text":"2234234","checked":true},{"text":"2342342","checked":true},{"text":"34234234234","checked":true},{"text":"23432432","checked":true}]	2026-03-21 20:46:29.354087
6	8	17	makanan malam 2026	111111	0	\N	\N	2026-03-22	\N	IDR	1	approved	Disetujui oleh manager	2026-03-21 20:52:05.745971
7	9	19	mercu buana	12121211	0	\N	\N	2026-03-22	\N	IDR	1	approved	Disetujui oleh manager	2026-03-21 20:58:54.891465
8	10	40	aaaaaaaaaaaaaaaaaaaa	123123123	0	\N	\N	2026-03-22	\N	IDR	1	approved	Disetujui oleh manager	2026-03-21 21:20:25.918339
9	11	52	retert3	234234	0	\N	\N	2026-03-23	\N	IDR	1	pending	\N	2026-03-22 17:56:33.878685
10	11	25	werwerwer	234234234	0	\N	\N	2026-03-23	\N	IDR	1	pending	\N	2026-03-22 17:56:53.603457
11	2	22	dsfdsf	234234234	0	\N	\N	2026-03-23	\N	IDR	1	pending	\N	2026-03-22 17:58:35.872265
12	12	45	asdasdasd	123123123	0	\N	\N	2026-03-23	\N	IDR	1	pending	\N	2026-03-22 18:04:02.9478
13	13	45	asdsadasdasd	12312312312	0	\N	\N	2026-03-23	\N	IDR	1	approved	Disetujui oleh manager	2026-03-22 18:04:37.266237
14	13	17	werwerwerwer	123123123	0	\N	\N	2026-03-23	\N	IDR	1	approved	Disetujui oleh manager	2026-03-22 18:04:59.075718
15	14	22	jdjdjdn	613161	0	\N	\N	2026-03-24	\N	IDR	1	pending	\N	2026-03-23 21:24:30.23945
16	20	19	34	3434534	0	\N	\N	2026-04-13	\N	IDR	1	pending	\N	2026-04-12 17:10:11.73682
17	22	59	asdasd	132123123	0	\N	\N	2030-12-31	\N	IDR	1	approved	Disetujui oleh manager	2026-04-12 19:21:54.752686
18	22	49	123123	123123	0	\N	\N	2030-12-31	\N	IDR	1	approved	Disetujui oleh manager	2026-04-12 19:22:06.902234
19	23	68	diofavian	12312	0	\N	\N	2030-12-31	\N	IDR	1	pending	\N	2026-04-16 08:01:44.37701
20	24	4	234234	234324324	0	\N	\N	2030-12-31	\N	IDR	1	approved	Disetujui oleh manager	2026-04-18 08:39:10.311727
21	24	49	123123	1	0	\N	\N	2030-12-31	\N	USD	101	approved	Disetujui oleh manager	2026-04-18 09:10:15.895616
22	24	19	234	4	0	\N	\N	2030-12-31	\N	USD	14444	approved	Disetujui oleh manager	2026-04-18 11:50:10.775567
23	26	2	234324	12	0	\N	\N	2030-08-09	\N	USD	11231	approved	Disetujui oleh manager	2026-04-18 13:22:14.644057
24	26	3	123123	123123	0	\N	\N	2030-12-31	\N	IDR	1	approved	Disetujui oleh manager	2026-04-18 13:22:38.502453
25	26	3	324234	234324	0	\N	\N	2030-12-31	\N	IDR	1	approved	Disetujui oleh manager	2026-04-18 13:28:23.232411
26	27	2	wqew	123123	0	\N	\N	2030-12-31	\N	IDR	1	approved	Disetujui oleh manager	2026-04-18 13:31:00.023599
28	29	59	asdasd	234234	0	\N	\N	2030-12-31	\N	IDR	1	approved	\N	2026-04-18 15:17:30.022173
29	30	19	weqwe	123123	0	\N	\N	2030-12-31	\N	IDR	1	rejected	[{"text": "123123", "checked": false}]	2026-04-20 22:35:04.560387
30	31	19	qweqwe	123123	0	\N	\N	2030-12-31	\N	IDR	1	rejected	[{"text": "qweqwe", "checked": false}]	2026-04-21 00:30:49.313197
31	32	19	wqeqwe	123123	0	\N	\N	2030-12-31	\N	IDR	1	approved	[{"text":"2123123","checked":true},{"text":"12312","checked":true}]	2026-04-21 00:58:28.044859
32	32	19	213123	22	0	\N	\N	2030-12-31	\N	USD	11233	approved	\N	2026-04-21 00:58:40.498028
33	33	2	jsj	646	0	\N	\N	2030-12-31	\N	IDR	1	approved	\N	2026-04-21 01:52:35.254869
34	34	49	12312	12312	0	\N	\N	2029-12-31	\N	IDR	1	pending	\N	2026-04-21 16:56:14.454748
35	36	69	namaeawa	123123	0	\N	\N	2030-12-31	\N	IDR	1	pending	\N	2026-04-21 20:25:50.737557
36	40	19	qweqwe	123123	0	\N	\N	2024-12-31	\N	IDR	1	approved	[{"text":"qweqwe","checked":true},{"text":"qweqw","checked":true},{"text":"qweqwe\\naweqwe","checked":true},{"text":"asdsad","checked":true},{"text":"234234","checked":true}]	2026-04-23 02:58:53.849027
27	28	2	asd	123123	0	\N	\N	2030-12-31	\N	IDR	1	pending	[{"text":"erwer","checked":true},{"text":"werewr","checked":true},{"text":"erwe","checked":true},{"text":"dfsdfsd","checked":true},{"text":"234324","checked":true},{"text":"qweqwe","checked":true}]	2026-04-18 14:28:25.377008
37	41	2	yjjh	26622	0	receipts/2026/04/f73da5ffea7c4c4685ef9aa7abdee7e2.pdf	sensors-25-04857.pdf	2024-12-31	\N	IDR	1	approved	[{"text":"jjjj","checked":true},{"text":"ujjj","checked":true}]	2026-04-26 13:46:56.88589
\.


--
-- Data for Name: advances; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.advances (id, title, description, advance_type, user_id, status, notes, approved_revision_no, active_revision_no, report_year, created_at, updated_at, approved_at) FROM stdin;
1	beli barang gowel		batch	2	draft	\N	0	\N	\N	2026-03-12 10:47:37.163415	2026-03-12 10:47:37.163415	\N
2	dsfdsf		single	1	draft	\N	0	\N	\N	2026-03-12 17:43:12.146761	2026-03-22 17:58:35.870782	\N
3	sdfds		single	1	in_settlement	Disetujui	0	\N	\N	2026-03-12 17:44:02.136913	2026-03-21 20:25:06.962451	2026-03-21 20:25:05.189189
4	hgfhgf		single	1	approved	Disetujui	0	\N	\N	2026-03-12 18:00:13.170508	2026-03-18 08:24:57.533922	2026-03-13 18:09:18.51397
5	diofavian		single	1	in_settlement	Disetujui	0	\N	\N	2026-03-12 18:09:44.414725	2026-03-13 18:13:25.065639	2026-03-13 17:42:27.908962
6	122	sdfdsf	single	1	approved	Disetujui	0	\N	\N	2026-03-13 15:23:30.275661	2026-03-18 08:25:02.944037	2026-03-13 15:27:33.497326
7	hari selasa		single	1	draft	\N	0	\N	\N	2026-03-21 20:46:13.064792	2026-03-21 20:46:48.235378	\N
8	makanan malam 2026		single	1	in_settlement	Disetujui	0	\N	\N	2026-03-21 20:51:38.964186	2026-03-23 21:18:28.622068	2026-03-23 21:18:23.518316
9	mercu buana		single	1	in_settlement	Disetujui	0	\N	\N	2026-03-21 20:58:33.88783	2026-03-21 21:00:24.923	2026-03-21 21:00:20.48027
10	aaaaaaaaaaaaaaaaaaaa		single	1	in_settlement	Disetujui	0	\N	\N	2026-03-21 21:20:09.545967	2026-03-21 21:20:56.130077	2026-03-21 21:20:53.799025
11	werwerwer		single	1	draft	\N	0	\N	\N	2026-03-22 17:56:16.804312	2026-03-22 17:56:53.600366	\N
12	asdasdasd		single	1	draft	\N	0	\N	\N	2026-03-22 18:03:51.159805	2026-03-22 18:04:02.945299	\N
13	werwerwerwer		single	1	in_settlement	Disetujui	0	1	\N	2026-03-22 18:04:18.610083	2026-03-22 18:07:43.774293	2026-03-22 18:06:09.373579
14	jdjdjdn		single	1	draft	\N	0	\N	\N	2026-03-23 21:24:15.252176	2026-03-23 21:24:30.235859	\N
15	Kasbon Mandiri		single	1	draft	\N	0	\N	\N	2026-03-24 21:55:14.896608	2026-03-24 21:55:14.896608	\N
16	jjj		batch	1	draft	\N	0	\N	\N	2026-03-24 21:55:23.530421	2026-03-24 21:55:23.530421	\N
17	Kasbon Mandiri		single	1	draft	\N	0	\N	\N	2026-03-24 21:56:06.202267	2026-03-24 21:56:06.202267	\N
18	Kasbon Mandiri		single	1	draft	\N	0	\N	\N	2026-03-24 22:05:54.637917	2026-03-24 22:05:54.637917	\N
19	Kasbon Mandiri		single	1	draft	\N	0	\N	\N	2026-04-12 16:57:18.770831	2026-04-12 16:57:18.770831	\N
20	34		single	1	draft	\N	0	\N	\N	2026-04-12 17:09:58.71897	2026-04-12 17:10:11.733805	\N
21	Kasbon Mandiri		single	1	draft	\N	0	\N	\N	2026-04-12 17:11:03.728612	2026-04-12 17:11:03.728612	\N
22	sdas		batch	1	in_settlement	Disetujui	0	\N	\N	2026-04-12 19:21:34.156639	2026-04-12 19:48:32.229867	2026-04-12 19:48:27.854202
23	diofavian		single	1	draft	\N	0	\N	\N	2026-04-16 08:01:26.752026	2026-04-16 08:01:44.376004	\N
24	sasdas		batch	1	in_settlement	Disetujui	0	\N	\N	2026-04-18 08:38:57.009268	2026-04-18 11:53:07.195803	2026-04-18 11:52:45.088407
25	Kasbon Mandiri		single	1	draft	\N	0	\N	\N	2026-04-18 12:23:53.64048	2026-04-18 12:23:53.64048	\N
26	1234567890		batch	1	in_settlement	Disetujui	0	\N	\N	2026-04-18 13:21:41.959008	2026-04-18 13:28:31.825415	2026-04-18 13:28:30.553529
27	werwer		batch	1	in_settlement	Disetujui	0	\N	\N	2026-04-18 13:30:49.112218	2026-04-18 13:32:21.669057	2026-04-18 13:32:17.345228
29	asdasd		single	1	in_settlement	\N	0	\N	\N	2026-04-18 15:17:07.873146	2026-04-18 15:18:13.656781	2026-04-18 15:17:34.227723
30	weqwe		single	1	submitted	\N	0	\N	\N	2026-04-20 22:34:50.690006	2026-04-20 22:35:05.927933	\N
31	qweqwe		single	1	submitted	\N	0	\N	\N	2026-04-21 00:30:41.912594	2026-04-21 00:30:51.274337	\N
32	asdasd		batch	1	in_settlement	\N	0	\N	\N	2026-04-21 00:57:54.30863	2026-04-21 00:59:41.246046	2026-04-21 00:59:39.908661
33	lala		batch	1	in_settlement	\N	0	\N	\N	2026-04-21 01:52:18.797635	2026-04-21 01:52:58.682299	2026-04-21 01:52:45.679316
34	12312		single	1	draft	\N	0	\N	\N	2026-04-21 16:55:57.71004	2026-04-21 16:56:14.451174	\N
35	Kasbon Mandiri		single	1	draft	\N	0	\N	\N	2026-04-21 18:55:22.626181	2026-04-21 18:55:22.626181	\N
36	namaeawa		single	1	draft	\N	0	\N	\N	2026-04-21 20:25:38.78631	2026-04-21 20:25:50.733933	\N
37	kasbon300000000000000		batch	1	draft	\N	0	\N	2029	2029-04-21 20:48:16.891505	2026-04-21 20:48:16.892505	\N
38	Kasbon Mandiri		single	1	draft	\N	0	\N	2030	2030-04-21 21:22:40.942502	2026-04-21 21:22:40.942502	\N
39	Kasbon Mandiri		single	1	draft	\N	0	\N	2030	2030-04-22 10:22:32.399859	2026-04-22 10:22:32.399859	\N
40	qweqwe		single	1	in_settlement	\N	0	\N	2024	2026-04-23 02:58:44.829138	2026-04-23 03:12:29.385215	2026-04-23 03:10:49.833344
28	asd		single	1	submitted	\N	0	\N	\N	2026-04-18 14:28:15.397651	2026-04-26 16:23:02.204087	\N
42	Kasbon Mandiri		single	1	draft	\N	0	\N	2024	2026-04-26 16:48:06.317375	2026-04-26 16:48:06.318394	\N
41	yjjh		single	1	draft	\N	0	\N	2024	2026-04-26 13:46:24.420475	2026-04-26 17:25:09.155884	\N
43	Kasbon Mandiri		single	1	draft	\N	0	\N	2024	2026-04-27 04:18:48.986139	2026-04-27 04:18:48.986654	\N
\.


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alembic_version (version_num) FROM stdin;
c1f7f67b9a12
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categories (id, name, code, parent_id, status, created_by, sort_order, main_group) FROM stdin;
1	Biaya Operasi	A	\N	approved	1	4	BEBAN LANGSUNG
2	Transportation	A1	1	approved	1	2	\N
3	Accommodation	A2	1	approved	1	3	\N
4	Allowance	A3	1	approved	1	4	\N
5	Meal	A4	1	approved	1	5	\N
6	Shipping	A5	1	approved	1	6	\N
7	Laundry	A6	1	approved	1	7	\N
8	Operation	A7	1	approved	1	8	\N
9	Trip	A8	1	approved	1	9	\N
10	Training	A9	1	approved	1	10	\N
11	Gaji	A10	1	approved	1	11	\N
12	Sales	A11	1	approved	1	12	\N
13	Project Operation	A12	1	approved	1	13	\N
14	Team Building	A13	1	approved	1	14	\N
15	Maintenance	A14	1	approved	1	15	\N
17	Pembuatan Alat	B1	16	approved	1	17	\N
19	Rental Tool	C1	18	approved	1	19	\N
20	Biaya Interpretasi Log Data	D	\N	approved	1	3	BEBAN LANGSUNG
21	Data Processing	D1	20	approved	1	21	\N
22	Software License	D2	20	approved	1	22	\N
23	Administrasi	E	\N	approved	1	6	BIAYA ADMINISTRASI DAN UMUM
24	IT Services	E1	23	approved	1	24	\N
25	Biaya Bank	E2	23	approved	1	25	\N
26	Pembelian Barang	F	\N	approved	1	7	BIAYA ADMINISTRASI DAN UMUM
27	Logistic	F1	26	approved	1	27	\N
28	Hand Tools	F2	26	approved	1	28	\N
29	Sparepart	F3	26	approved	1	29	\N
30	Sewa Kantor	G	\N	approved	1	8	BIAYA ADMINISTRASI DAN UMUM
31	Sewa Ruangan	G1	30	approved	1	31	\N
32	Kesehatan	H	\N	approved	1	9	BIAYA ADMINISTRASI DAN UMUM
33	Medical	H1	32	approved	1	33	\N
34	Bisnis Dev	I	\N	approved	1	10	BIAYA ADMINISTRASI DAN UMUM
35	Modal Kerja	I1	34	approved	1	35	\N
36	asdasd	J	\N	approved	1	11	BIAYA ADMINISTRASI DAN UMUM
37	nanas	B2	16	approved	1	37	\N
38	makanan jepang	K	\N	approved	2	12	BIAYA ADMINISTRASI DAN UMUM
39	aaaaa	L	\N	approved	1	13	BIAYA ADMINISTRASI DAN UMUM
40	aaaaaa	L1	39	approved	1	40	\N
41	bbbbbb	A15	1	approved	1	41	\N
42	bbbbb	M	\N	approved	1	14	BIAYA ADMINISTRASI DAN UMUM
43	bbbbb	M1	42	approved	1	43	\N
44	asdsad	N	\N	approved	1	15	BIAYA ADMINISTRASI DAN UMUM
45	asdasda	N1	44	approved	1	45	\N
46	dfgdfgdfgd	O	\N	approved	1	16	BIAYA ADMINISTRASI DAN UMUM
47	dfgdfgdfgdf	O1	46	approved	1	47	\N
48	12312	P	\N	approved	1	17	BIAYA ADMINISTRASI DAN UMUM
49	123123	P1	48	approved	1	49	\N
50	-	A0	1	approved	1	50	\N
51	-	B0	16	approved	1	51	\N
52	-	C0	18	approved	1	52	\N
53	-	D0	20	approved	1	53	\N
54	-	E0	23	approved	1	54	\N
55	-	F0	26	approved	1	55	\N
56	-	G0	30	approved	1	56	\N
57	-	H0	32	approved	1	57	\N
58	-	I0	34	approved	1	58	\N
59	-	J0	36	approved	1	59	\N
60	-	K0	38	approved	2	60	\N
61	-	L0	39	approved	1	61	\N
62	-	M0	42	approved	1	62	\N
63	-	N0	44	approved	1	63	\N
64	-	O0	46	approved	1	64	\N
65	-	P0	48	approved	1	65	\N
66	pepaya	B3	16	approved	1	66	\N
67	diofavian	Q	\N	approved	1	5	BEBAN LANGSUNG
68	-	Q0	67	approved	1	0	\N
69	keysha	Q1	67	approved	1	0	\N
70	nabil	Q2	67	approved	1	0	\N
71	Biaya Operasi Lain-lain	A16	1	\N	\N	\N	\N
72	ATK & Dokumentasi	E3	23	\N	\N	\N	\N
73	Elektronik & Gadget	F4	26	\N	\N	\N	\N
74	Lisensi & Legalitas	I2	34	\N	\N	\N	\N
18	Biaya Sewa Peralatan	C	\N	approved	1	1	BEBAN LANGSUNG
16	Biaya Research (R&D)	B	\N	approved	1	2	BEBAN LANGSUNG
\.


--
-- Data for Name: dividend_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dividend_settings (id, year, profit_retained, opening_cash_balance, accounts_receivable, prepaid_tax_pph23, prepaid_expenses, other_receivables, office_inventory, other_assets, accounts_payable, salary_payable, shareholder_payable, accrued_expenses, share_capital, retained_earnings_balance, created_at) FROM stdin;
1	2023	0	0	0	0	0	0	0	0	0	0	0	0	0	0	2026-03-11 02:36:04.667069
3	2026	200	0	0	0	0	0	0	0	0	0	0	0	0	0	2026-03-21 02:39:03.732724
2	2024	33654157	0	0	0	0	0	0	0	0	0	0	0	0	0	2026-03-11 02:37:31.750096
\.


--
-- Data for Name: dividends; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dividends (id, date, name, amount, recipient_count, tax_percentage, created_at) FROM stdin;
1	2024-04-23	Anevril Chairulsyah	0	1	0	2026-03-11 02:36:16.79661
2	2024-06-12	Alan Muhadjir	0	1	0	2026-03-11 02:36:32.255644
\.


--
-- Data for Name: expense_subcategories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expense_subcategories (expense_id, category_id) FROM stdin;
579	19
580	27
581	2
582	69
583	3
584	70
\.


--
-- Data for Name: expenses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expenses (id, settlement_id, category_id, description, amount, date, source, advance_item_id, revision_no, currency, currency_exchange, evidence_path, evidence_filename, status, notes, created_at) FROM stdin;
1	1	19	ALFA Service PDP-075 Pertamina Zona#4 - Rental Tool	29640916	2024-01-11	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 41	2026-03-11 12:39:59
2	2	19	ALFA Service PDS-01ST Pertamina Zona#4 - Rental Tool	29640916	2024-01-11	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 42	2026-03-11 12:39:59
3	3	19	ALFA Service JRK-254 Pertamina Zona#4 - Rental Tool	29640916	2024-01-11	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 43	2026-03-11 12:39:59
5	5	11	Gaji Januari 2024 _Yufitri	2500000	2024-02-01	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 45	2026-03-11 12:39:59
582	242	69	234	234	2024-12-31	BRI	\N	0	USD	1111	\N	\N	pending	\N	2026-04-26 16:38:11.363537
6	6	11	Gaji Februari 2024 + raple gaji Januari 2024_Yufitri	3500000	2024-03-05	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 46	2026-03-11 12:39:59
8	8	11	Gaji Maret 2024_Yufitri	3000000	2024-03-28	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 48	2026-03-11 12:39:59
10	10	21	Data proccesing MTD 4 well, project Tomori-Alan	122625000	2024-05-01	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 50	2026-03-11 12:39:59
11	11	11	Gaji April_Yufitri	3000000	2024-05-04	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 51	2026-03-11 12:39:59
14	14	19	ALFA Service TLJ-58 Pertamina Zona#4 - Rental Tool	29640916	2024-06-03	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 54	2026-03-11 12:39:59
16	16	11	Gaji Mei_Yufitri	3000000	2024-06-03	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 56	2026-03-11 12:39:59
17	17	19	ALFA Service JRK-193 Pertamina Zona#4 - Rental Tool	29640916	2024-06-04	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 57	2026-03-11 12:39:59
18	18	11	Gaji Juni 2024_Yufitri	3000000	2024-06-30	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 58	2026-03-11 12:39:59
19	19	28	Downhole Sampling tool #1-1 GARINDO SARANA BARU	39800000	2024-06-30	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 59	2026-03-11 12:39:59
20	20	29	Kekurangan (PPN ) ke PT Garindo sarana Baru (Downhole Sampling)	3582000	2024-07-03	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 60	2026-03-11 12:39:59
23	23	35	Pembelian Lisence Sonoechometer to PT Weebz Mandiri	16650000	2024-07-10	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 63	2026-03-11 12:39:59
26	26	11	Gaji Juli 2024_Yufitri	3000000	2024-07-28	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 66	2026-03-11 12:39:59
29	29	35	MUTRI | Sewa ruangan kantor BBC 2 bulan	11270000	2024-08-15	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 69	2026-03-11 12:39:59
33	33	19	ALFA Service JRK-163 Pertamina Zona#4 - Rental Tool	29640916	2024-09-02	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 73	2026-03-11 12:39:59
30	30	28	Downhole Sampling tool #1-2 GARINDO SARANA BARU	53835000	2024-08-15	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 70	2026-03-11 12:39:59
39	39	19	PLT Service TGB-033 Pertamina Cirebon - Rental Tool	16165271	2024-10-04	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 79	2026-03-11 12:39:59
40	40	19	ALFA Service TGB-033 Pertamina Cirebon - Rental Tool	25967616	2024-10-04	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 80	2026-03-11 12:39:59
41	41	19	MFC Service TGB-033 Pertamina Cirebon - Rental Tool	32101247	2024-10-04	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 81	2026-03-11 12:39:59
42	42	19	ALFA Service JRK-095 Pertamina Zona#4 - Rental Tool	29640916	2024-10-07	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 82	2026-03-11 12:39:59
43	43	19	MPLT/GR-CCL/ALFA TIS - Rental Tool	74291457	2024-10-11	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 83	2026-03-11 12:39:59
31	31	21	Data proccesing TGB-33 DAN TIS (RBG-3b)-Alan	101120000	2024-08-21	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 71	2026-03-11 12:39:59
32	32	11	Gaji Agustus 2024_Yufitri	3000000	2024-08-31	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 72	2026-03-11 12:39:59
34	34	35	MUTRI | Penambahan modal biaya kerja	100000000	2024-09-04	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 74	2026-03-11 12:39:59
36	36	28	Downhole Sampling tool #2 GARINDO SARANA BARU	34299000	2024-09-21	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 76	2026-03-11 12:39:59
37	37	11	Gaji fitri bulan september 2024	3000000	2024-10-03	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 77	2026-03-11 12:39:59
38	38	11	Gaji fitri bulan October 2024	3000000	2024-10-03	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 78	2026-03-11 12:39:59
47	47	35	MUTRI | Penambahan modal biaya kerja 3rd	75000000	2024-11-29	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 87	2026-03-11 12:39:59
583	243	3	34324	234234	2024-12-31	Mandiri	\N	0	IDR	1	receipts/2026/04/9cc42acbad3547a59ad6026b78b5450e.pdf	sensors-25-04857.pdf	pending	\N	2026-04-26 16:56:45.445491
48	48	11	Gaji fitri bulan November 2024	3000000	2024-11-29	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 88	2026-03-11 12:39:59
55	55	25	Total Biaya Transaksi Bank selama 1 tahun	1998587	2024-12-31	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 96	2026-03-11 12:39:59
52	52	5	Team building EWI dengan team Well Intervention PEP Reg. 2	39201350	2024-12-18	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 92	2026-03-11 12:39:59
53	53	11	Gaji Desember 2024 + Bomnus akhir tahun - 4 bulan_Yufitri	15000000	2024-12-25	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 93	2026-03-11 12:39:59
71	56	29	White Marker	19000	2024-02-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 119 | Subcategory: Logistic	2026-03-11 12:39:59
72	56	29	Internet Data	87000	2024-02-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 120 | Subcategory: Logistic	2026-03-11 12:39:59
83	57	29	Internet Data	70000	2024-03-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 139 | Subcategory: Logistic	2026-03-11 12:39:59
92	59	73	Buy Cable type C to A	69009	2024-03-18	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 156	2026-03-11 12:39:59
93	59	73	Buy Cable type C to C	145800	2024-03-18	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 157	2026-03-11 12:39:59
94	59	73	Buy Jack 3 Pin Socket	20891	2024-03-18	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 158	2026-03-11 12:39:59
480	100	24	Google Workspace PT. EWI	306982	2023-10-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 730 | Subcategory: IT Services	2026-03-11 12:39:59
481	100	24	Google Workspace PT. EWI	306982	2023-11-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 731 | Subcategory: IT Services	2026-03-11 12:39:59
482	100	24	Google Workspace PT. EWI	306982	2023-12-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 732 | Subcategory: IT Services	2026-03-11 12:39:59
483	100	24	Google Workspace PT. EWI	306982	2024-01-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 733 | Subcategory: IT Services	2026-03-11 12:39:59
484	100	24	Google Workspace PT. EWI	306982	2024-02-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 734 | Subcategory: IT Services	2026-03-11 12:39:59
485	100	24	Google Workspace PT. EWI	306982	2024-03-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 735 | Subcategory: IT Services	2026-03-11 12:39:59
486	100	24	Google Workspace PT. EWI	306982	2024-04-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 736 | Subcategory: IT Services	2026-03-11 12:39:59
487	100	24	Google Workspace PT. EWI	306982	2024-05-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 737 | Subcategory: IT Services	2026-03-11 12:39:59
97	59	73	Buy SANWA YX360TRF	455600	2024-03-18	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 161	2026-03-11 12:39:59
98	59	28	Send Tool from Gowell to TGE	168732	2024-03-19	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 162	2026-03-11 12:39:59
99	59	28	Send Tool from Bintaro to Gowell	168732	2024-03-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 163	2026-03-11 12:39:59
105	61	71	Send DTR Bintaro - Gowell	38121	2024-04-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 175 | Subcategory: Shipping	2026-03-11 12:39:59
106	61	71	Send QPS Gowell - TGE	105879	2024-04-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 176 | Subcategory: Shipping	2026-03-11 12:39:59
107	61	71	Send ALFA Bintaro - Andara	39654	2024-04-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 177 | Subcategory: Shipping	2026-03-11 12:39:59
108	61	71	Send HPTC Bintaro - Andara	39654	2024-04-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 178 | Subcategory: Shipping	2026-03-11 12:39:59
584	244	70	234	234	2024-12-31	Mandiri	\N	0	IDR	1	receipts/2026/04/c81e2e76e4a14c9fbd41de90b7b5e701.pdf	Sistem_Absensi_Pengenalan_Wajah_Bermasker_Masked_F.pdf	pending	\N	2026-04-26 17:09:57.269635
580	240	27	jfjdj	61616	2024-12-31	Cash	\N	0	IDR	1	receipts/2026/04/0f832ff703eb4a60a3b463542319df45.pdf	Sistem_Absensi_Pengenalan_Wajah_Bermasker_Masked_F.pdf	pending	[{"text":"kfkrnrnrjk","checked":true},{"text":"rkrkr","checked":true},{"text":"rkrkr","checked":true},{"text":"jdndj","checked":true},{"text":"iijj","checked":true},{"text":"2234","checked":true}]	2026-04-26 13:14:55.939882
109	61	71	Send BA Bintaro - TGE	18000	2024-04-23	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 179 | Subcategory: Shipping	2026-03-11 12:39:59
110	61	71	Send MPLT TGE - Gowell	167297	2024-04-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 180 | Subcategory: Shipping	2026-03-11 12:39:59
111	61	71	Crews' Food	160000	2024-04-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 182 | Subcategory: Meal	2026-03-11 12:39:59
118	63	71	Jakarta - Palembang - Jakarta	1387800	2024-05-06	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 198 | Subcategory: Transportation	2026-03-11 12:39:59
122	63	2	Tol Indralaya	27000	2024-05-08	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 203 | Subcategory: Transportation	2026-03-11 12:39:59
127	64	2	Taksi	150000	2024-04-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 212 | Subcategory: Transportation	2026-03-11 12:39:59
130	64	4	Tunajngan lapangan for 3 days (19-21 apr24) Anevril	300	2024-04-21	\N	\N	0	USD	16051	\N	\N	approved	Imported from row 218 | Subcategory: Allowance	2026-03-11 12:39:59
135	65	71	Internet Data	75000	2024-04-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 226 | Subcategory: Logistic	2026-03-11 12:39:59
136	65	71	Crew's Operational	657000	2024-04-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 228 | Subcategory: Meal	2026-03-11 12:39:59
138	65	4	Field Bonus for 7 days (25$/Day)	75	2024-04-25	\N	\N	0	USD	16050.85	\N	\N	approved	Imported from row 232 | Subcategory: Allowance	2026-03-11 12:39:59
100	60	33	MCU RS PP	5407000	2024-04-02	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 165	2026-03-11 12:39:59
142	66	71	Battery A2	101800	2024-04-19	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 239 | Subcategory: Logistic	2026-03-11 12:39:59
143	66	71	Crew's Operational	481900	2024-04-19	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 241 | Subcategory: Meal	2026-03-11 12:39:59
158	71	29	Allen key, pliers, screwdrivers	268000	2024-05-31	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 270 | Subcategory: Hand Tools	2026-03-11 12:39:59
169	72	71	Rent Car 6 Days	2900000	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 288 | Subcategory: Transportation	2026-03-11 12:39:59
170	72	2	Gasoline	400000	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 289 | Subcategory: Transportation	2026-03-11 12:39:59
177	73	71	Personal Car from Home to PT. LTJ (converted) DAY-1	233000	2024-06-05	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 302 | Subcategory: Transportation	2026-03-11 12:39:59
185	74	71	Rent Car 4 Days	2000000	2024-05-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 313 | Subcategory: Transportation	2026-03-11 12:39:59
186	74	2	Gasoline	330000	2024-05-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 314 | Subcategory: Transportation	2026-03-11 12:39:59
581	241	2	hhjh	2533	2025-12-31	BCA	\N	0	IDR	1	\N	\N	pending	[{"text":"hhjmnv","checked":true},{"text":"hjjjyt","checked":true}]	2026-04-26 13:44:52.86338
192	75	2	Lalamove Gowell-Bogor-Gowell	594804	2024-07-05	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 325 | Subcategory: Transportation	2026-03-11 12:39:59
193	75	29	Pin Punch	381960	2024-07-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 327 | Subcategory: Logistic	2026-03-11 12:39:59
194	75	29	Hardcase Custom	3595000	2024-07-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 328 | Subcategory: Logistic	2026-03-11 12:39:59
204	76	73	OTG Type C	163100	2024-07-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 342 | Subcategory: Logistic	2026-03-11 12:39:59
206	77	33	Unit Labolatorium	1474000	2024-06-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 346 | Subcategory: Medical	2026-03-11 12:39:59
208	77	33	Farmasi	109000	2024-06-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 348 | Subcategory: Medical	2026-03-11 12:39:59
209	78	71	Jakarta - Palembang	985367	2024-07-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 351 | Subcategory: Transportation	2026-03-11 12:39:59
210	78	2	Palembang - Jakarta + Extra Bagage	1175717	2024-07-27	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 352 | Subcategory: Transportation	2026-03-11 12:39:59
217	78	71	Jakarta - Palembang	400000	2024-07-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 361 | Subcategory: Transportation	2026-03-11 12:39:59
221	78	4	Tunajngan Lapangan JRK-163 (21-27 Juli 2024). 1US$=16.200	700	2024-07-27	\N	\N	0	IDR	16200	\N	\N	approved	Imported from row 369 | Subcategory: Allowance	2026-03-11 12:39:59
223	78	29	Snacks	195000	2024-07-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 372 | Subcategory: Operation	2026-03-11 12:39:59
277	83	29	Buy WD 40	65000	2024-08-01	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 451 | Subcategory: Logistic	2026-03-11 12:39:59
233	80	29	Pelican Long Case 1770	15166600	2024-08-12	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 389 | Subcategory: Logistic	2026-03-11 12:39:59
235	81	71	Jakarta - Semarang	673500	2024-08-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 394 | Subcategory: Transportation	2026-03-11 12:39:59
246	82	33	Biaya Echo_ kardio non Invasif	2108000	2024-07-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 412 | Subcategory: Medical	2026-03-11 12:39:59
251	82	2	Pengiriman dokumen ke Rachmansyah-Sijak	106000	2023-07-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 418 | Subcategory: Shipping	2026-03-11 12:39:59
257	82	28	Buy Tang Bnegkok (Tekiro)	75000	2024-07-24	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 426 | Subcategory: Logistic	2026-03-11 12:39:59
258	82	29	Buy Hose 1/4"	133000	2024-07-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 427 | Subcategory: Logistic	2026-03-11 12:39:59
259	82	29	Buy Needle Neple	700000	2024-07-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 428 | Subcategory: Logistic	2026-03-11 12:39:59
260	82	73	buy Adapter	20000	2024-07-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 429 | Subcategory: Logistic	2026-03-11 12:39:59
261	82	29	Buy Hose 1/4"	155000	2024-07-27	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 430 | Subcategory: Logistic	2026-03-11 12:39:59
262	82	29	Buy Needle Neple	660000	2024-07-27	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 431 | Subcategory: Logistic	2026-03-11 12:39:59
263	82	29	Buy Connection 1/4"	1760000	2024-07-27	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 432 | Subcategory: Logistic	2026-03-11 12:39:59
273	83	33	buy Zirolic	34200	2024-07-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 447 | Subcategory: Logistic	2026-03-11 12:39:59
281	83	29	Buy connection T dan nipple	72500	2024-08-05	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 455 | Subcategory: Logistic	2026-03-11 12:39:59
282	83	29	Buy Quick connection	400000	2024-08-05	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 456 | Subcategory: Logistic	2026-03-11 12:39:59
283	83	29	Buy Paint nippon	60000	2024-08-06	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 457 | Subcategory: Logistic	2026-03-11 12:39:59
285	83	71	w/ Crew Barekin	275000	2024-07-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 460 | Subcategory: Meal	2026-03-11 12:39:59
286	83	71	W/ TIS Petroleum personnel	157000	2024-08-01	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 461 | Subcategory: Meal	2026-03-11 12:39:59
287	83	5	w/ Crew Barekin (buy ice sirop) No reciept	80000	2024-08-02	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 462 | Subcategory: Meal	2026-03-11 12:39:59
288	83	71	w/ TIS Lemigas Personnel	270350	2024-08-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 463 | Subcategory: Meal	2026-03-11 12:39:59
289	83	71	w/ TIS Petroleum Personnel	401000	2024-08-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 464 | Subcategory: Meal	2026-03-11 12:39:59
294	84	2	Lalamove Base to Barikin	276500	2024-07-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 474 | Subcategory: Transportation	2026-03-11 12:39:59
295	84	2	Lalamove Pak Subi to Base	63568	2024-07-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 475 | Subcategory: Transportation	2026-03-11 12:39:59
296	84	2	Lalamove Barikin to Base	161885	2024-08-13	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 476 | Subcategory: Transportation	2026-03-11 12:39:59
297	84	29	TOP 1 High Temp Grease	144900	2024-07-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 478 | Subcategory: Operation	2026-03-11 12:39:59
309	86	71	Rent Car 6 Days	3000000	2024-09-06	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 499 | Subcategory: Transportation	2026-03-11 12:39:59
310	86	2	Gasoline	400000	2024-09-06	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 500 | Subcategory: Transportation	2026-03-11 12:39:59
323	88	2	Gasoline	200000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 522 | Subcategory: Transportation	2026-03-11 12:39:59
324	88	2	Gasoline	215000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 523 | Subcategory: Transportation	2026-03-11 12:39:59
325	88	2	Gasoline	197000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 524 | Subcategory: Transportation	2026-03-11 12:39:59
326	88	2	Gasoline	200000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 525 | Subcategory: Transportation	2026-03-11 12:39:59
327	88	2	Gasoline	220000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 526 | Subcategory: Transportation	2026-03-11 12:39:59
330	88	15	Car Wash	40000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 529 | Subcategory: Transportation	2026-03-11 12:39:59
341	88	5	Black Coffe	47000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 541 | Subcategory: Operation	2026-03-11 12:39:59
351	89	4	Tunjangan lapaangan for 8 days- (job at JRK-095)	800	2024-09-30	\N	\N	0	USD	15200	\N	\N	approved	Imported from row 559 | Subcategory: Allowance	2026-03-11 12:39:59
357	90	2	Tol ( trip Bintaro - Instrutek solusindo) No reciept	64500	2024-09-09	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 567 | Subcategory: Transportation	2026-03-11 12:39:59
358	90	2	Tol ( trip Instrutek solusindo - Bintaro) No Reciept	64500	2024-09-09	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 568 | Subcategory: Transportation	2026-03-11 12:39:59
359	90	2	tol (Bintaro - Cikarang)	112500	2024-09-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 569 | Subcategory: Transportation	2026-03-11 12:39:59
360	90	2	tol (Cikarang - Bekasi -Bintaro)	50500	2024-09-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 570 | Subcategory: Transportation	2026-03-11 12:39:59
361	90	2	tol (Bintaro - Cinere)	59000	2024-09-11	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 571 | Subcategory: Transportation	2026-03-11 12:39:59
362	90	2	Tol  Jakarta - Cirebon	245000	2024-09-17	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 573 | Subcategory: Trip	2026-03-11 12:39:59
364	90	2	Tol  Cirebon - Jakarta	166000	2024-09-18	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 575 | Subcategory: Trip	2026-03-11 12:39:59
367	90	7	Loundry 2 days @Rp. 50.000	100000	2024-09-18	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 579 | Subcategory: Accommodation	2026-03-11 12:39:59
414	95	2	POS courier	15000	2024-10-09	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 647 | Subcategory: Shipping	2026-03-11 12:39:59
375	91	33	Medicine	36000	2024-08-24	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 590 | Subcategory: Medical	2026-03-11 12:39:59
376	91	33	medicine	45000	2024-09-01	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 591 | Subcategory: Medical	2026-03-11 12:39:59
377	91	33	Medicine	241100	2024-09-12	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 592 | Subcategory: Medical	2026-03-11 12:39:59
379	91	2	Pengiriman dokumen ke Yufitri	10000	2024-09-02	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 595 | Subcategory: Shipping	2026-03-11 12:39:59
380	91	2	Pengiriman dokumen ke Yulia - LBU	18000	2024-08-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 596 | Subcategory: Shipping	2026-03-11 12:39:59
381	91	2	Pengiriman dokumen ke Rachmansyah-Sijak	18000	2024-09-02	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 597 | Subcategory: Shipping	2026-03-11 12:39:59
382	91	71	Buy lag ban 2 ea	25000	2024-05-24	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 598 | Subcategory: Shipping	2026-03-11 12:39:59
383	91	71	printing di snappy	31000	2024-08-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 599 | Subcategory: Shipping	2026-03-11 12:39:59
388	92	2	Demob Tools (Kalog)	280400	2024-09-23	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 607 | Subcategory: Transportation	2026-03-11 12:39:59
391	92	2	Lalamove Kalog-Gowell	73584	2024-09-23	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 610 | Subcategory: Transportation	2026-03-11 12:39:59
404	94	2	MRT ( Lebak Bulus - Duku Atas )	14000	2024-11-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 634 | Subcategory: Transportation	2026-03-11 12:39:59
405	94	2	KRL ( Duku Atas - Sudimara )	3000	2024-11-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 635 | Subcategory: Transportation	2026-03-11 12:39:59
407	95	24	Plastic folder 3 pcs	35000	2023-06-08	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 639 | Subcategory: Shipping	2026-03-11 12:39:59
408	95	2	Lala Move courier	100000	2023-05-30	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 641 | Subcategory: Shipping	2026-03-11 12:39:59
409	95	24	Anvelope, Plastic map	12000	2023-07-14	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 642 | Subcategory: Shipping	2026-03-11 12:39:59
410	95	2	JNE courier	44000	2023-12-01	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 643 | Subcategory: Shipping	2026-03-11 12:39:59
412	95	2	JNE courier	18000	2024-09-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 645 | Subcategory: Shipping	2026-03-11 12:39:59
413	95	2	POS courier	8000	2024-09-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 646 | Subcategory: Shipping	2026-03-11 12:39:59
415	95	2	JNE courier	10000	2024-10-14	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 648 | Subcategory: Shipping	2026-03-11 12:39:59
428	97	29	Pelican Case 1650	8156000	2024-12-14	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 664	2026-03-11 12:39:59
429	98	33	Medicine lanjutan	604000	2024-10-31	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 667 | Subcategory: Medical	2026-03-11 12:39:59
433	98	33	Medicine lanjutan	157000	2024-12-01	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 671 | Subcategory: Medical	2026-03-11 12:39:59
434	98	33	Medicine lanjutan	152000	2024-12-01	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 672 | Subcategory: Medical	2026-03-11 12:39:59
441	98	2	Taksi,take Document from Loket Graha Elnusa	155680	2024-12-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 680 | Subcategory: Transportation	2026-03-11 12:39:59
443	99	71	Traveling Jakarta - Bandung	160000	2024-12-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 684 | Subcategory: Transportation	2026-03-11 12:39:59
444	99	2	Taksi around the Bandung city for 2 days	200000	2024-12-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 685 | Subcategory: Transportation	2026-03-11 12:39:59
445	99	71	Traveling Bandung - Jakarta	160000	2024-12-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 686 | Subcategory: Transportation	2026-03-11 12:39:59
448	99	24	payment for hotel Grand Dafam and	4913283	2024-12-24	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 691 | Subcategory: Accommodation	2026-03-11 12:39:59
449	100	71	Shipment Benchmark DTR to Malaysia	3629.8	2024-02-13	\N	\N	0	MYR	3636.89	\N	\N	approved	Imported from row 695 | Subcategory: Trip	2026-03-11 12:39:59
453	100	2	Flight KUL- CGK	1897983	2024-03-12	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 699 | Subcategory: Trip	2026-03-11 12:39:59
466	100	24	Domain PT. Exspan Wireline Indonesia	184182	2022-08-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 716 | Subcategory: IT Services	2026-03-11 12:39:59
467	100	24	Google Workspace PT. EWI	107437	2022-09-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 717 | Subcategory: IT Services	2026-03-11 12:39:59
468	100	24	Google Workspace PT. EWI	177258	2022-10-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 718 | Subcategory: IT Services	2026-03-11 12:39:59
469	100	24	Google Workspace PT. EWI	214896	2022-11-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 719 | Subcategory: IT Services	2026-03-11 12:39:59
470	100	24	Google Workspace PT. EWI	214896	2022-12-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 720 | Subcategory: IT Services	2026-03-11 12:39:59
471	100	24	Google Workspace PT. EWI	214896	2023-01-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 721 | Subcategory: IT Services	2026-03-11 12:39:59
472	100	24	Google Workspace PT. EWI	214896	2023-02-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 722 | Subcategory: IT Services	2026-03-11 12:39:59
473	100	24	Google Workspace PT. EWI	214896	2023-03-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 723 | Subcategory: IT Services	2026-03-11 12:39:59
474	100	24	Google Workspace PT. EWI	214896	2023-04-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 724 | Subcategory: IT Services	2026-03-11 12:39:59
475	100	24	Google Workspace PT. EWI	214896	2023-05-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 725 | Subcategory: IT Services	2026-03-11 12:39:59
476	100	24	Google Workspace PT. EWI	214896	2023-06-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 726 | Subcategory: IT Services	2026-03-11 12:39:59
477	100	24	Google Workspace PT. EWI	214896	2023-07-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 727 | Subcategory: IT Services	2026-03-11 12:39:59
478	100	24	Domain + Google Workspace PT. EWI	399078	2023-08-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 728 | Subcategory: IT Services	2026-03-11 12:39:59
479	100	24	Google Workspace PT. EWI	214896	2023-09-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 729 | Subcategory: IT Services	2026-03-11 12:39:59
498	103	11	Gaji mael	234234234	2026-03-12	Mandiri	\N	0	IDR	1	receipts/2026/03/5c5772a42cd24d75ab069a6a937ee788.pdf	receipt_2.pdf	approved	Disetujui oleh manager.	2026-03-12 09:55:52.246776
499	106	17	123123	34	2026-03-12	Cash	\N	0	USD	16000	receipts/2026/03/a8ef1a9c0ae640948ad9e3a697728b95.pdf	sensors-25-04857.pdf	approved	Disetujui melalui approve settlement	2026-03-12 10:10:06.456386
500	106	25	23000	200000	2026-03-12	BRI	\N	0	IDR	1	\N	\N	approved	Disetujui melalui approve settlement	2026-03-12 10:10:59.263027
501	107	17	sdasd	50000	2026-03-12	BNI	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-12 10:17:02.465824
502	108	19	blejar party	12312312	2026-03-12	BRI	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-12 10:38:09.706122
507	115	17	gaji diofavian	300000	2026-03-12	BRI	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-12 13:33:34.07737
510	119	37	12312	123123	2026-03-12	BRI	\N	0	IDR	1	\N	\N	approved	Disetujui melalui approve settlement	2026-03-12 13:45:07.133216
511	119	17	123123	12312312	2026-03-12	\N	\N	0	IDR	1	\N	\N	approved	Disetujui melalui approve settlement	2026-03-12 13:45:12.969764
513	121	17	12	121	2026-03-12	BRI	\N	0	IDR	1	\N	\N	approved	Disetujui melalui approve settlement	2026-03-12 15:51:05.223431
515	123	17	sfdsf	234234	2026-03-12	BRI	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-12 16:19:10.346996
523	133	19	coba maka	123123123112	2026-03-14	BRI	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-13 17:26:39.81384
525	135	3	diofavian	101	2026-03-13	BCA	1	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-13 18:13:25.065639
527	137	31	aaaaaaaaaaaaaaaa	1111111	2026-03-16	Mandiri	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-16 04:03:55.668891
528	140	28	asdasd11	1231231	2026-03-18	BRI	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-18 08:40:20.032252
529	141	66	pepaya panas	111111	2026-03-19	BRI	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-18 18:26:09.936976
530	142	45	asdasda	123123123	2026-03-19	BCA	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-18 18:27:52.990969
532	144	17	qweqwe1	1111231	2026-03-22	BNI	\N	0	IDR	1	\N	\N	pending	[{"text":"udjdjdjdd","checked":true},{"text":"rudidiej","checked":true},{"text":"diidei","checked":true}]	2026-03-21 20:28:50.9613
534	146	17	hari senin	1112121	2026-03-22	BRI	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-21 20:44:50.316044
535	147	19	mercu buana	12121211	2026-03-21	Advance	7	0	IDR	1	\N	\N	pending	\N	2026-03-21 21:00:24.923983
536	148	40	aaaaaaaaaaaaaaaaaaaa	123123123	2026-03-21	Advance	8	0	IDR	1	\N	\N	pending	\N	2026-03-21 21:20:56.131061
537	149	25	21231	111111	2026-03-22	BRI	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-22 14:22:05.549404
538	150	19	qwwer	123123123	2026-03-23	BRI	\N	0	IDR	1	\N	\N	pending	\N	2026-03-22 18:03:41.632333
539	151	45	asdsadasdasd	12312312312	2026-03-22	BCA	13	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-22 18:06:12.075926
540	151	17	werwerwerwer	123123123	2026-03-22	BCA	14	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-22 18:06:12.075926
541	152	19	jdjdjdj	131313	2026-03-24	BRI	\N	0	IDR	1	\N	\N	pending	\N	2026-03-23 20:59:48.728924
542	153	17	makanan malam 2026	111111	2026-03-23	Advance	6	0	IDR	1	\N	\N	pending	[{"text":"jdjdjkdjdjdj","checked":true},{"text":"djdjjd","checked":true}]	2026-03-23 21:18:28.622068
543	113	22	jajsj	13131	2026-03-25	BCA	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-03-24 18:16:01.132553
544	156	4	sd	40000	2026-04-13	Cash	\N	0	IDR	1	\N	\N	pending	\N	2026-04-12 17:07:06.853958
545	157	19	sd	2131231	2026-04-13	BRI	\N	0	IDR	1	\N	\N	pending	\N	2026-04-12 17:07:45.050939
546	158	4	87987000	98098000	2030-12-31	BNI	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-04-12 17:43:06.809424
547	159	70	reza	30000	2030-12-31	BCA	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-04-12 19:15:23.098626
548	159	5	werw	123123	2030-12-31	BRI	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-04-12 19:15:47.342315
549	159	49	123123	123123	2030-12-31	BCA	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-04-12 19:16:05.20326
550	160	59	asdasd	132123123	2026-04-12	Advance	17	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-04-12 19:48:32.230873
551	160	49	123123	123123	2026-04-12	Advance	18	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-04-12 19:48:32.230873
552	164	4	234234	234324324	2030-12-31	Advance	20	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-04-18 11:53:07.196788
553	164	49	123123	1	2030-12-31	Advance	21	0	USD	101	\N	\N	approved	Disetujui oleh manager.	2026-04-18 11:53:07.196788
554	164	19	234	4	2030-12-31	Advance	22	0	USD	14444	\N	\N	approved	Disetujui oleh manager.	2026-04-18 11:53:07.196788
555	165	2	werwerwer	23	2030-12-31	Mandiri	\N	0	EUR	12222	\N	\N	approved	Disetujui oleh manager.	2026-04-18 12:18:36.586319
556	165	5	we	12	2030-12-31	BRI	\N	0	EUR	12222	\N	\N	approved	Disetujui oleh manager.	2026-04-18 12:19:13.15738
557	165	3	23423423	234	2030-12-31	BCA	\N	0	USD	12343	\N	\N	approved	Disetujui oleh manager.	2026-04-18 12:19:33.711105
558	165	6	23434	2342	2030-12-31	BRI	\N	0	EUR	12	\N	\N	approved	Disetujui oleh manager.	2026-04-18 12:20:28.721129
559	169	69	23434	22	2030-12-13	BRI	\N	0	USD	10000	\N	\N	approved	Disetujui oleh manager.	2026-04-18 12:42:31.548674
560	170	69	sdasd	12	2030-10-01	Mandiri	\N	0	USD	1222	\N	\N	approved	Disetujui oleh manager.	2026-04-18 13:01:18.54823
561	171	2	234324	12	2030-08-09	BCA	23	0	USD	11231	\N	\N	approved	Disetujui oleh manager.	2026-04-18 13:28:31.825415
562	171	3	123123	123123	2030-12-31	Advance	24	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-04-18 13:28:31.825415
563	171	3	324234	234324	2030-12-31	Advance	25	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-04-18 13:28:31.825415
564	172	2	wqew	123123	2030-12-31	Advance	26	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-04-18 13:32:21.669057
565	173	69	3234234	234234	2030-12-31	Mandiri	\N	0	IDR	1	\N	\N	approved	Disetujui oleh manager.	2026-04-18 13:32:55.080886
566	174	69	23	12323	2030-12-31	Mandiri	\N	0	EUR	1123	\N	\N	approved	[{"text":"asd","checked":true},{"text":"234324","checked":true},{"text":"asdas","checked":true},{"text":"324324","checked":true},{"text":"erwer","checked":true},{"text":"werwer","checked":true}]	2026-04-18 14:27:21.823513
567	175	59	asdasd	234234	2030-12-31	Advance	28	0	IDR	1	\N	\N	approved	\N	2026-04-18 15:18:13.656781
568	176	3	qweqw	123123	2030-12-31	BRI	\N	0	GBP	1123123	\N	\N	approved	[{"text":"qweqwe","checked":true}]	2026-04-21 00:32:25.139803
569	185	19	qwe	123	2030-12-31	Mandiri	\N	0	IDR	1	\N	\N	pending	\N	2026-04-21 00:46:47.126406
570	186	19	wqeqwe	123123	2030-12-31	Advance	31	0	IDR	1	\N	\N	approved	\N	2026-04-21 00:59:41.248557
571	186	19	213123	22	2030-12-31	Advance	32	0	USD	11233	\N	\N	approved	[{"text":"qqweqwe","checked":true},{"text":"qweqwe","checked":true},{"text":"234324","checked":true}]	2026-04-21 00:59:41.248557
572	187	2	jsj	646	2030-12-31	Advance	33	0	IDR	1	\N	\N	approved	\N	2026-04-21 01:52:58.682299
573	188	49	123123	12313	2029-12-31	BRI	\N	0	IDR	1	\N	\N	pending	\N	2026-04-21 16:55:41.057664
574	230	70	qwe	123123	2030-12-31	BNI	\N	0	IDR	1	\N	\N	pending	\N	2026-04-21 20:30:18.616465
575	231	49	123123	12323	2029-12-31	Mandiri	\N	0	IDR	1	\N	\N	pending	\N	2026-04-21 20:30:56.083413
576	233	49	123123	123123	2030-12-31	BNI	\N	0	IDR	1	\N	\N	pending	\N	2026-04-21 21:21:23.564899
577	235	21	hshs	31616	2030-12-31	BRI	\N	0	IDR	1	\N	\N	pending	\N	2026-04-21 22:30:43.223589
578	232	2	qweqwq	123123	2030-12-31	BNI	\N	0	JPY	11231	\N	\N	pending	\N	2026-04-22 09:53:21.620612
579	239	19	qweqwe	123123	2024-12-31	Advance	36	0	IDR	1	\N	\N	approved	[{"text":"234234","checked":true},{"text":"234234","checked":true}]	2026-04-23 03:12:29.388751
531	143	19	sdfds	123123123	2026-03-21	Advance	4	0	IDR	1	\N	\N	pending	[{"text":"asdasdasd","checked":true},{"text":"asdasdasd","checked":true}]	2026-03-21 20:25:06.96345
533	145	19	sdfsdf	234234	2026-03-22	BRI	\N	0	IDR	1	\N	\N	approved	\N	2026-03-21 20:43:50.470819
4	4	12	Sales cost 4 Well Integrity Pertamina Z.4	77672400	2024-01-13	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 44	2026-03-11 12:39:59
7	7	17	Ralika Jaya Utama | Permbuatan alat Downhole Wireless Telemetry	100000000	2024-03-13	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 47	2026-03-11 12:39:59
9	9	4	THR 2024_Yufitri	3000000	2024-04-06	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 49	2026-03-11 12:39:59
12	12	17	Ralika Jaya Utama | Permbuatan alat Downhole Wireless Telemetry	100000000	2024-05-06	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 52	2026-03-11 12:39:59
13	13	2	Aro Energy | Moving slickline dari Duri (Toni Supriadi) ke Sungai lilin	18000000	2024-05-10	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 53	2026-03-11 12:39:59
15	15	13	PT Laka Indonesia |  Wastafel for WIKA Anantara Ubud Bali	300000000	2024-06-03	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 55	2026-03-11 12:39:59
21	21	13	Repair ESOR panel & Fabricate dummy test load, Payment#2	25000000	2024-07-05	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 61	2026-03-11 12:39:59
22	22	13	PT Laka Indonesia |  Wastafel for WIKA Anantara Ubud Bali	25000000	2024-07-07	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 62	2026-03-11 12:39:59
24	24	13	PT Laka Indonesia |  Wastafel for WIKA Anantara Ubud Bali	25000000	2024-07-19	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 64	2026-03-11 12:39:59
25	25	13	Repair ESOR panel & Fabricate dummy test load, Payment#1	20000000	2024-07-20	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 65	2026-03-11 12:39:59
27	27	73	Handphone Operational untuk Secretary (Yufitri)	2600000	2024-07-28	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 67	2026-03-11 12:39:59
28	28	17	Ralika Jaya Utama | Permbuatan alat injeksi listrik (EAS)	100000000	2024-07-29	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 68	2026-03-11 12:39:59
35	35	17	Ralika Jaya Utama | Permbuatan alat EMR	150000000	2024-09-13	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 75	2026-03-11 12:39:59
44	44	13	PT Laka Indonesia | Project Lampu Taman Istana Negara Jakarta	100000000	2024-10-16	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 84	2026-03-11 12:39:59
45	45	21	Data Processing 8 Well Alan Project SIJAK	144000000	2024-10-24	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 85	2026-03-11 12:39:59
46	46	2	Sales fee 2 Well Integrity Pertamina Z.4	38838700	2024-11-05	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 86	2026-03-11 12:39:59
49	49	29	Payment ke UPS Biaya Import pembelian sparepart dari Pei-Genesis	777246	2024-12-04	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 89	2026-03-11 12:39:59
50	50	17	Ralika Jaya Utama | Permbuatan alat injeksi listrik (EAS)	400000000	2024-12-05	BRI	\N	0	IDR	1	\N	\N	approved	Imported from row 90	2026-03-11 12:39:59
51	51	31	Sewa Virtual Office 1th, 1jan25 - 31des25_BBC_ Ganesha Dwipaya B	4995000	2024-12-06	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 91	2026-03-11 12:39:59
54	54	17	KUPA | Pembelian Mesin Retort Horizontal 500 Lt Automatic Control	141500000	2024-12-27	BCA	\N	0	IDR	1	\N	\N	approved	Imported from row 94	2026-03-11 12:39:59
56	56	2	Airplane Ticket CGK-PLM	1608000	2024-02-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 101 | Subcategory: Transportation	2026-03-11 12:39:59
57	56	2	Airplane Ticket PLM-CGK	1119500	2024-03-04	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 102 | Subcategory: Transportation	2026-03-11 12:39:59
58	56	2	Taxi Bintaro-CGK	250000	2024-02-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 104 | Subcategory: Transportation	2026-03-11 12:39:59
59	56	2	Rental Mobil Pajero 1 Hari	900000	2024-02-08	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 105 | Subcategory: Transportation	2026-03-11 12:39:59
60	56	2	Rental Mobil Pajero Sebulan	18000000	2024-02-08	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 106 | Subcategory: Transportation	2026-03-11 12:39:59
61	56	2	Taxi CGK-Bintaro	250000	2024-03-04	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 107 | Subcategory: Transportation	2026-03-11 12:39:59
62	56	2	Fuel	1498484	2024-03-04	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 108 | Subcategory: Transportation	2026-03-11 12:39:59
63	56	2	Toll Fee	378000	2024-03-04	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 109 | Subcategory: Transportation	2026-03-11 12:39:59
64	56	3	Hotel 7 Feb-8 Feb 2024 (1 days)	200000	2024-02-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 111 | Subcategory: Accommodation	2026-03-11 12:39:59
65	56	3	Hotel Prabumulih 8 Feb- 7 Mar 2024 (1 Month)	3300000	2024-02-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 112 | Subcategory: Accommodation	2026-03-11 12:39:59
66	56	7	Laundry 27 days 1 Persons @ 50K IDR/day	1350000	2024-03-04	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 113 | Subcategory: Accommodation	2026-03-11 12:39:59
67	56	28	Gloves	58500	2024-02-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 115 | Subcategory: Logistic	2026-03-11 12:39:59
68	56	29	Battery A3	82100	2024-02-19	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 116 | Subcategory: Logistic	2026-03-11 12:39:59
69	56	28	Steker	14000	2024-02-19	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 117 | Subcategory: Logistic	2026-03-11 12:39:59
70	56	28	Gloves	65000	2024-02-22	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 118 | Subcategory: Logistic	2026-03-11 12:39:59
73	56	5	Meal Crew's Operational	1966300	2024-03-04	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 122 | Subcategory: Meal	2026-03-11 12:39:59
74	56	5	Meals 27 days 1 Persons @ 150K IDR/day	4050000	2024-03-04	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 124 | Subcategory: Meal	2026-03-11 12:39:59
75	56	4	Tunjangan Lapangan for 27 days	2700	2024-03-04	\N	\N	0	USD	15774	\N	\N	approved	Imported from row 126 | Subcategory: Allowance	2026-03-11 12:39:59
76	57	2	Airplane Ticket PLM-CGK	1000106	2024-03-06	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 129 | Subcategory: Transportation	2026-03-11 12:39:59
77	57	2	Taxi Pondok Cabe-CGK	250000	2024-02-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 131 | Subcategory: Transportation	2026-03-11 12:39:59
78	57	2	Taxi CGK-Pondok Cabe	250000	2024-03-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 132 | Subcategory: Transportation	2026-03-11 12:39:59
79	57	2	Fuel	200000	2024-03-04	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 133 | Subcategory: Transportation	2026-03-11 12:39:59
80	57	2	Toll Fee	105000	2024-03-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 134 | Subcategory: Transportation	2026-03-11 12:39:59
81	57	7	Laundry 30 days 1 Persons @ 50K IDR/day	1500000	2024-03-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 136 | Subcategory: Accommodation	2026-03-11 12:39:59
82	57	28	Safety Shoes	499940	2024-02-02	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 138 | Subcategory: Logistic	2026-03-11 12:39:59
84	57	27	Extra Baggage	540000	2024-03-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 140 | Subcategory: Logistic	2026-03-11 12:39:59
85	57	5	Meals 30 days 1 Persons @ 150K IDR/day	4500000	2024-03-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 142 | Subcategory: Meal	2026-03-11 12:39:59
86	57	2	Tunjangan Lapangan (Training) untuk 27 days	750	2024-03-07	\N	\N	0	USD	15607	\N	\N	approved	Imported from row 144 | Subcategory: Allowance	2026-03-11 12:39:59
87	58	2	Taxi Bintaro-CGK	250000	2024-03-19	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 147 | Subcategory: Transportation	2026-03-11 12:39:59
88	58	2	Taxi CGK-Bintaro	250000	2024-03-24	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 148 | Subcategory: Transportation	2026-03-11 12:39:59
89	58	7	Laundry 6 days 1 Persons @ 50K IDR/day	300000	2024-03-24	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 150 | Subcategory: Accommodation	2026-03-11 12:39:59
90	58	5	Meals 6 days 1 Persons @ 150K IDR/day	900000	2024-03-24	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 152 | Subcategory: Meal	2026-03-11 12:39:59
91	58	4	Tunjangan Lapangan untuk 6 days	600	2024-03-24	\N	\N	0	USD	15835	\N	\N	approved	Imported from row 154 | Subcategory: Allowance	2026-03-11 12:39:59
95	59	73	Buy Powerbank 2 ea 27kmah & 52kmah	3325760	2024-03-18	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 159	2026-03-11 12:39:59
96	59	73	Buy Fluke-117	4332000	2024-03-18	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 160	2026-03-11 12:39:59
101	61	2	Taxi Bintaro-CGK	250000	2024-04-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 168 | Subcategory: Transportation	2026-03-11 12:39:59
102	61	2	Taxi CGK-Bintaro	250000	2024-04-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 169 | Subcategory: Transportation	2026-03-11 12:39:59
103	61	7	Laundry 5 days 1 Persons @ 50K IDR/day	250000	2024-04-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 171 | Subcategory: Accommodation	2026-03-11 12:39:59
104	61	5	Meals 5 days 1 Persons @ 150K IDR/day	750000	2024-04-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 173 | Subcategory: Meal	2026-03-11 12:39:59
112	62	2	Fuels	284308	2024-04-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 187 | Subcategory: Transportation	2026-03-11 12:39:59
113	62	2	Toll	298000	2024-04-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 188 | Subcategory: Transportation	2026-03-11 12:39:59
114	62	3	Hotel 2 days	1357481	2024-04-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 190 | Subcategory: Accommodation	2026-03-11 12:39:59
115	62	7	Laundry 2 days	100000	2024-04-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 191 | Subcategory: Accommodation	2026-03-11 12:39:59
116	62	5	Meals 2 days 1 Persons @ 150K IDR/day	300000	2024-04-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 193 | Subcategory: Meal	2026-03-11 12:39:59
117	62	4	Tunjangan Lapangan for 2 days	200	2024-04-28	\N	\N	0	USD	16257	\N	\N	approved	Imported from row 195 | Subcategory: Allowance	2026-03-11 12:39:59
119	63	2	Taxi + Tol to Airport Jakarta	234140	2024-05-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 200 | Subcategory: Transportation	2026-03-11 12:39:59
120	63	2	Airport park + fuel + tol Indralaya	232000	2024-05-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 201 | Subcategory: Transportation	2026-03-11 12:39:59
121	63	2	Car Rental	600000	2024-05-08	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 202 | Subcategory: Transportation	2026-03-11 12:39:59
123	63	2	Tol + Taxi From Airport Jakarta	276900	2024-05-09	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 204 | Subcategory: Transportation	2026-03-11 12:39:59
124	63	3	Hotel	360000	2024-05-08	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 206 | Subcategory: Accommodation	2026-03-11 12:39:59
125	63	5	Dinner (Dwi, Febri, Ilham)	103400	2024-05-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 208 | Subcategory: Meal	2026-03-11 12:39:59
126	64	2	Train (Jati barang - Jati Negara)	255500	2024-04-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 211 | Subcategory: Transportation	2026-03-11 12:39:59
128	64	7	Laundry 3 days @ Rp. 50.000	150000	2024-04-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 214 | Subcategory: Accommodation	2026-03-11 12:39:59
129	64	5	Uang makan utk 3 hari (19-21 apr-24) @150.000	450000	2024-04-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 216 | Subcategory: Allowance	2026-03-11 12:39:59
131	64	5	Dinner (Dwi, Febri, Ilham)	128000	2024-05-08	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 219 | Subcategory: Allowance	2026-03-11 12:39:59
132	65	3	Hotel 25 Apr - 27 Apr & 29 Apr- 2 May 2024 (6 days)	3292802	2024-04-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 222 | Subcategory: Accommodation	2026-03-11 12:39:59
133	65	7	Laundry 7 days 1 Persons @ 50K IDR/day	350000	2024-04-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 223 | Subcategory: Accommodation	2026-03-11 12:39:59
134	65	28	Tekiro Kunci L, Tekiro Tang, Obeng Set	349000	2024-04-19	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 225 | Subcategory: Logistic	2026-03-11 12:39:59
137	65	5	Meals 7 days 1 Persons @ 150K IDR/day	1050000	2024-04-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 230 | Subcategory: Meal	2026-03-11 12:39:59
139	65	4	Field Bonus for 4 days 29 April-2 May 2024 (100$/Day	400	2024-04-25	\N	\N	0	USD	16050.85	\N	\N	approved	Imported from row 233 | Subcategory: Allowance	2026-03-11 12:39:59
140	66	3	Hotel 19 Apr-22 Apr 2024 (3 days)	1950000	2024-04-19	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 236 | Subcategory: Accommodation	2026-03-11 12:39:59
141	66	7	Laundry 4 days 1 Persons @ 50K IDR/day	200000	2024-04-19	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 237 | Subcategory: Accommodation	2026-03-11 12:39:59
144	66	5	Meals 4 days 1 Persons @ 150K IDR/day	600000	2024-04-19	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 243 | Subcategory: Meal	2026-03-11 12:39:59
145	66	2	Taxi Bintaro-Wisma Mas	78500	2024-04-22	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 245 | Subcategory: Transportation	2026-03-11 12:39:59
146	66	4	Field Bonus for 4 days (25$/Day)	100	2024-04-19	\N	\N	0	USD	16050.85	\N	\N	approved	Imported from row 247 | Subcategory: Allowance	2026-03-11 12:39:59
147	67	2	BOSIET Training	9693878	2024-05-17	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 249	2026-03-11 12:39:59
148	68	33	MCU Paket Umum Basic 1	5322000	2024-05-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 251	2026-03-11 12:39:59
149	68	28	Safety shoes	2402000	2024-05-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 252	2026-03-11 12:39:59
150	69	33	Biaya MCU	5407000	2024-05-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 254	2026-03-11 12:39:59
151	70	2	Tiket Pesawat Citilink (CGK-PLM 25 Mei 2024)	773238	2024-05-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 256	2026-03-11 12:39:59
152	70	2	Reschedule Tiket Pesawat dari Citilink ke Super Air Jet (CGK-PLg)	296853	2024-05-24	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 257	2026-03-11 12:39:59
153	70	2	Taxi + Tol To Airport CGK	250000	2024-05-24	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 258	2026-03-11 12:39:59
154	70	5	Uang makan (25 - 30 May 2024)	900000	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 260 | Subcategory: Allowance	2026-03-11 12:39:59
155	70	4	Tunjangan Lapangan JRK-193 (25 - 30 May 2024)	150	2024-05-25	\N	\N	0	$	16200	\N	\N	approved	Imported from row 263 | Subcategory: Allowance	2026-03-11 12:39:59
156	71	2	Taxi + Tol to Airport Jakarta	232520	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 266 | Subcategory: Transportation	2026-03-11 12:39:59
157	71	2	fuel + tol PLM-Prabu	312000	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 267 | Subcategory: Transportation	2026-03-11 12:39:59
159	71	27	Wrapping Alfa Box	80000	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 272 | Subcategory: Logistic	2026-03-11 12:39:59
160	71	28	Hand gloves	21900	2024-05-27	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 273 | Subcategory: Logistic	2026-03-11 12:39:59
161	71	5	Uang Makan (25 - 30 May 2024)	900000	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 275 | Subcategory: Allowance	2026-03-11 12:39:59
162	71	7	Laundry (25 - 30 May 2024)	300000	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 277 | Subcategory: Laundry	2026-03-11 12:39:59
163	71	4	Tunjangan Lapangan JRK-193 (25 - 30 May 2024). 1US$=16.200	150	2024-05-25	\N	\N	0	IDR	16200	\N	\N	approved	Imported from row 279 | Subcategory: Allowance	2026-03-11 12:39:59
164	72	3	Hotel 24 May - 30 May (6 days)	1650000	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 282 | Subcategory: Accommodation	2026-03-11 12:39:59
165	72	7	Laundry 6 days 1 Persons @ 50K IDR/day	300000	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 283 | Subcategory: Accommodation	2026-03-11 12:39:59
166	72	2	Airplane Ticket CGK-PLM (2 Person)	1418800	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 285 | Subcategory: Transportation	2026-03-11 12:39:59
167	72	2	Taxi Pondok Cabe-CGK	166000	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 286 | Subcategory: Transportation	2026-03-11 12:39:59
168	72	2	Toll (Pondok Cabe-CGK)	60000	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 287 | Subcategory: Transportation	2026-03-11 12:39:59
171	72	2	Taxi CGK-Pondok Cabe (inc Toll+Parking)	300000	2024-05-30	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 290 | Subcategory: Transportation	2026-03-11 12:39:59
172	72	2	Airplane Ticket PLM-CGK (2 Person)	1326410	2024-05-30	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 291 | Subcategory: Transportation	2026-03-11 12:39:59
173	72	5	Meal Crew's Operational	709300	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 293 | Subcategory: Meal	2026-03-11 12:39:59
174	72	5	Meals 7 days 1 Persons @ 150K IDR/day	900000	2024-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 295 | Subcategory: Meal	2026-03-11 12:39:59
175	72	4	Tunjangan Lapangan for 6 days	600	2024-05-25	\N	\N	0	USD	16196	\N	\N	approved	Imported from row 297 | Subcategory: Allowance	2026-03-11 12:39:59
176	73	10	BOSIET 5 - 7 June 2024	9693878	2024-06-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 300 | Subcategory: Training	2026-03-11 12:39:59
178	73	2	Transport DAY - 2 BOSIET	73000	2024-06-06	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 303 | Subcategory: Transportation	2026-03-11 12:39:59
179	73	2	Transport DAY - 3 BOSIET	59000	2024-06-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 304 | Subcategory: Transportation	2026-03-11 12:39:59
180	74	3	Hotel 16 June - 19 June (3 days)	720000	2024-05-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 307 | Subcategory: Accommodation	2026-03-11 12:39:59
181	74	7	Laundry 4 days 1 Persons @ 50K IDR/day	200000	2024-05-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 308 | Subcategory: Accommodation	2026-03-11 12:39:59
182	74	2	Airplane Ticket CGK-PLM	995500	2024-05-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 310 | Subcategory: Transportation	2026-03-11 12:39:59
183	74	2	Taxi Pondok Cabe-CGK	273500	2024-05-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 311 | Subcategory: Transportation	2026-03-11 12:39:59
184	74	2	Toll Prabumulih (PP)	224000	2024-05-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 312 | Subcategory: Transportation	2026-03-11 12:39:59
187	74	2	Taxi HLP-Pondok Cabe (inc Toll+Parking)	270000	2024-05-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 315 | Subcategory: Transportation	2026-03-11 12:39:59
188	74	2	Airplane Ticket PLM-HLP	1004000	2024-05-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 316 | Subcategory: Transportation	2026-03-11 12:39:59
189	74	73	Uneed Power Station	2371000	2024-05-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 318 | Subcategory: Logistic	2026-03-11 12:39:59
190	74	5	Meals 4 days 1 Persons @ 150K IDR/day	600000	2024-05-16	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 320 | Subcategory: Meal	2026-03-11 12:39:59
191	74	4	Tunjangan Lapangan for 4 days	400	2024-05-16	\N	\N	0	USD	16378	\N	\N	approved	Imported from row 322 | Subcategory: Allowance	2026-03-11 12:39:59
195	76	3	Hotel	344305	2024-07-08	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 331 | Subcategory: Accommodation	2026-03-11 12:39:59
196	76	3	Hotel Tax Foreigner	10	2024-07-08	\N	\N	0	MYR	3462	\N	\N	approved	Imported from row 332 | Subcategory: Accommodation	2026-03-11 12:39:59
197	76	2	Airplane Ticket CGK-KLIA	4912100	2024-07-08	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 334 | Subcategory: Transportation	2026-03-11 12:39:59
198	76	2	Taxi Home - CGK	250000	2024-07-08	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 335 | Subcategory: Transportation	2026-03-11 12:39:59
199	76	2	Taxi KLIA - Hotel	72	2024-07-08	\N	\N	0	MYR	3462	\N	\N	approved	Imported from row 336 | Subcategory: Transportation	2026-03-11 12:39:59
200	76	2	Taxi Hyperseal - Hotel	8	2024-07-09	\N	\N	0	MYR	3462	\N	\N	approved	Imported from row 337 | Subcategory: Transportation	2026-03-11 12:39:59
201	76	2	Taxi Hotel - KLIA	82.03	2024-07-09	\N	\N	0	MYR	3462	\N	\N	approved	Imported from row 338 | Subcategory: Transportation	2026-03-11 12:39:59
202	76	2	Taxi CGK - Home	259120	2024-07-09	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 339 | Subcategory: Transportation	2026-03-11 12:39:59
203	76	73	Asus Slate 13 (tablet asus)	9778400	2024-07-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 341 | Subcategory: Logistic	2026-03-11 12:39:59
205	77	33	Konsultasi Spesialis Penyakit Dalam	206000	2024-06-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 345 | Subcategory: Medical	2026-03-11 12:39:59
207	77	33	Konsultasi Spesialis Penyakit Dalam	206000	2024-06-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 347 | Subcategory: Medical	2026-03-11 12:39:59
211	78	2	Taxi + Tol to Airport Jakarta	225520	2024-07-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 354 | Subcategory: Transportation	2026-03-11 12:39:59
212	78	2	fuel + tol PLM-Prabu	292060	2024-07-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 355 | Subcategory: Transportation	2026-03-11 12:39:59
213	78	2	fuel	190430	2024-07-24	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 356 | Subcategory: Transportation	2026-03-11 12:39:59
214	78	2	Tol Prabu - PLM + Fuel	262000	2024-07-27	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 357 | Subcategory: Transportation	2026-03-11 12:39:59
215	78	2	Tol + Taxi From Airport Jakarta	235000	2024-07-27	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 358 | Subcategory: Transportation	2026-03-11 12:39:59
216	78	2	Car rental 21 - 27 Jul 2024	3500000	2024-07-27	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 359 | Subcategory: Transportation	2026-03-11 12:39:59
218	78	3	Lodge 21-27 Jul 2024 (3 rooms)	2160000	2024-07-27	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 363 | Subcategory: Accommodation	2026-03-11 12:39:59
219	78	5	Uang Makan (21 - 27 Juli 2024)	1050000	2024-07-27	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 365 | Subcategory: Allowance	2026-03-11 12:39:59
220	78	7	Laundry (21 - 27 Juli 2024)	350000	2024-07-27	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 367 | Subcategory: Laundry	2026-03-11 12:39:59
222	78	28	Rags - Gloves	70000	2024-07-22	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 371 | Subcategory: Operation	2026-03-11 12:39:59
224	78	29	Battery for DTR (Spare)	38900	2024-07-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 373 | Subcategory: Operation	2026-03-11 12:39:59
225	79	5	Uang makan (16 - 19 June 2024) pending job /Job Postponed	600000	2024-06-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 376 | Subcategory: Allowance	2026-03-11 12:39:59
226	79	7	Laundry (16 - 19 June 2024) pending job /Job Postponed	200000	2024-06-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 377 | Subcategory: Allowance	2026-03-11 12:39:59
227	79	5	Uang makan (21 - 27 Juli 2024)	1050000	2024-07-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 378 | Subcategory: Allowance	2026-03-11 12:39:59
228	79	7	Laundry (21 - 27 Juli 2024)	350000	2024-07-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 379 | Subcategory: Allowance	2026-03-11 12:39:59
229	79	4	Tunjangan LapanganJRK-163 (16 - 19 Juni 2024) pending job	100	2024-06-20	\N	\N	0	$	16300	\N	\N	approved	Imported from row 381 | Subcategory: Allowance	2026-03-11 12:39:59
230	79	4	Tunjangan Lapangan JRK-163 (21 - 27 Juli 2024)	175	2024-07-28	\N	\N	0	$	16300	\N	\N	approved	Imported from row 382 | Subcategory: Allowance	2026-03-11 12:39:59
231	80	7	Laundry 10 days 1 Persons @ 50K IDR/day	500000	2024-08-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 385 | Subcategory: Laundry	2026-03-11 12:39:59
232	80	5	Meals 10 days 1 Persons @ 150K IDR/day	1500000	2024-08-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 387 | Subcategory: Meal	2026-03-11 12:39:59
234	80	4	Tunjangan Lapangan for 10 days	1000	2024-08-08	\N	\N	0	USD	16100	\N	\N	approved	Imported from row 391 | Subcategory: Allowance	2026-03-11 12:39:59
236	81	2	Taxi+Tol Serpong - Gambir	154000	2024-08-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 396 | Subcategory: Transportation	2026-03-11 12:39:59
237	81	2	Gocar St. Tawang - PT. TIS	129000	2024-08-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 397 | Subcategory: Transportation	2026-03-11 12:39:59
238	81	2	Gocar Hotel to Tawang	45000	2024-08-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 398 | Subcategory: Transportation	2026-03-11 12:39:59
239	81	3	Hotel 3 Aug - 6 Aug 2024 (2 rooms)	1591200	2024-08-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 400 | Subcategory: Accommodation	2026-03-11 12:39:59
240	81	3	Hotel 6 Aug - 7 Aug 2024 (2 rooms)	795600	2024-08-05	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 401 | Subcategory: Accommodation	2026-03-11 12:39:59
241	81	5	Uang Makan (3 - 7 Aug 2024)	750000	2024-08-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 403 | Subcategory: Allowance	2026-03-11 12:39:59
242	81	7	Laundry (3 - 7 Aug 2024)	250000	2024-08-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 405 | Subcategory: Laundry	2026-03-11 12:39:59
243	81	4	Tunjangan LapanganRBG-3B PT. TIS (3-7 Aug 2024)	500	2024-08-07	\N	\N	0	IDR	15900	\N	\N	approved	Imported from row 407 | Subcategory: Allowance	2026-03-11 12:39:59
244	82	33	Biaya MCU di RSPP	5630000	2024-07-01	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 410 | Subcategory: Medical	2026-03-11 12:39:59
245	82	33	Biaya Konsul Dokter Jantung	460000	2024-07-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 411 | Subcategory: Medical	2026-03-11 12:39:59
247	82	33	Biaya Obat Candesartan	149850	2024-07-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 413 | Subcategory: Medical	2026-03-11 12:39:59
248	82	33	Fisioterapi 1st	285000	2024-07-09	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 414 | Subcategory: Medical	2026-03-11 12:39:59
249	82	33	Fisioterapi 2nd	285000	2024-07-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 415 | Subcategory: Medical	2026-03-11 12:39:59
250	82	33	Fisioterapi 3rd	285000	2024-07-11	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 416 | Subcategory: Medical	2026-03-11 12:39:59
252	82	2	Fuel ( trip ambil tool Sampler and to Andara )	164100	2024-07-11	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 420 | Subcategory: Transportation	2026-03-11 12:39:59
253	82	2	Fuel ( trip ke Lemigas and Workshop sampler)	291000	2024-07-11	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 421 | Subcategory: Transportation	2026-03-11 12:39:59
254	82	2	Fuel ( trip ke Lemigas and Workshop sampler)	177350	2024-07-17	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 422 | Subcategory: Transportation	2026-03-11 12:39:59
255	82	2	Fuel ( trip ke Barekin Bogor, inspeksi tool)	319700	2024-07-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 423 | Subcategory: Transportation	2026-03-11 12:39:59
256	82	2	Fuel trip ke Glodok buy Hydralic pump assesories	217350	2024-07-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 424 | Subcategory: Transportation	2026-03-11 12:39:59
264	82	28	Buy Case for tools box dan hydraulic pump	2636800	2024-07-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 433 | Subcategory: Logistic	2026-03-11 12:39:59
265	82	5	Coffe drink visit to MEPI Jakarta ( Bondan)	144100	2024-07-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 435 | Subcategory: Meal	2026-03-11 12:39:59
266	82	5	Meal lunch when inspect Sample tool	157000	2024-07-04	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 436 | Subcategory: Meal	2026-03-11 12:39:59
267	82	5	Meal lunch when visit to Lemigas (Sample Botol)	81000	2024-07-11	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 437 | Subcategory: Meal	2026-03-11 12:39:59
268	83	2	Rental car (include Fuel ) 10 days, @Rp1.100.000	11000000	2024-08-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 440 | Subcategory: Transportation	2026-03-11 12:39:59
269	83	2	Toll (Jkt Blora - PP)	483000	2024-07-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 441 | Subcategory: Transportation	2026-03-11 12:39:59
270	83	2	Toll (Gubug - Jakarta)	496000	2024-08-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 442 | Subcategory: Transportation	2026-03-11 12:39:59
271	83	7	Laundry dor 10 days @Rp.50.000.	500000	2024-08-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 444 | Subcategory: Accommodation	2026-03-11 12:39:59
272	83	3	Hotel for 6 days ( 29 Jul - 3 aug 24)	2700000	2024-08-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 445 | Subcategory: Accommodation	2026-03-11 12:39:59
274	83	5	buy Soft drink	199900	2024-07-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 448 | Subcategory: Logistic	2026-03-11 12:39:59
275	83	5	buy Soft drink	69000	2024-07-31	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 449 | Subcategory: Logistic	2026-03-11 12:39:59
276	83	5	buy Soft drink	98000	2024-07-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 450 | Subcategory: Logistic	2026-03-11 12:39:59
278	83	5	buy Soft drink	109800	2024-08-01	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 452 | Subcategory: Logistic	2026-03-11 12:39:59
279	83	5	buy Soft drink	96600	2024-08-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 453 | Subcategory: Logistic	2026-03-11 12:39:59
280	83	5	buy Soft drink	56600	2024-08-04	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 454 | Subcategory: Logistic	2026-03-11 12:39:59
284	83	5	buy Soft drink	118100	2024-08-06	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 458 | Subcategory: Logistic	2026-03-11 12:39:59
290	83	5	Meal utk 10 hari (29 Jul -7Aug-24) @Rp. 150.000	1500000	2024-08-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 466 | Subcategory: Allowance	2026-03-11 12:39:59
291	83	4	Tunjangan lapangan for 10 days (29Jul - 07Aug24) Anevril	1000	2024-08-07	\N	\N	0	USD	16100	\N	\N	approved	Imported from row 468 | Subcategory: Allowance	2026-03-11 12:39:59
292	84	71	Electrical Bill	159682	2024-07-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 471 | Subcategory: Accommodation	2026-03-11 12:39:59
293	84	7	Laundry 10 days 1 Persons @ 50K IDR/day	500000	2024-07-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 472 | Subcategory: Accommodation	2026-03-11 12:39:59
298	84	5	Meal Crew's Operational	263200	2024-07-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 480 | Subcategory: Meal	2026-03-11 12:39:59
299	84	5	Meals 10 days 1 Persons @ 150K IDR/day	1500000	2024-07-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 482 | Subcategory: Meal	2026-03-11 12:39:59
300	84	4	Tunjangan Lapangan for 10 days	1000	2024-07-29	\N	\N	0	USD	15513	\N	\N	approved	Imported from row 484 | Subcategory: Allowance	2026-03-11 12:39:59
301	85	5	Uang makan (6 - 11 September 2024) 6 days	900000	2024-09-13	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 487 | Subcategory: Allowance	2026-03-11 12:39:59
302	85	7	Laundry (6 - 11 September 2024) 6 days	300000	2024-09-13	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 488 | Subcategory: Allowance	2026-03-11 12:39:59
303	85	4	Tunjangan Lapangan PBM - 009 (6 - 11 September 2024)	150	2024-09-13	\N	\N	0	$	15450	\N	\N	approved	Imported from row 490 | Subcategory: Allowance	2026-03-11 12:39:59
304	86	3	Hotel 6 Sept - 11 Sept (5 days)	1800000	2024-09-06	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 493 | Subcategory: Accommodation	2026-03-11 12:39:59
305	86	7	Laundry 6 days 1 Persons @ 50K IDR/day	300000	2024-09-06	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 494 | Subcategory: Accommodation	2026-03-11 12:39:59
306	86	2	Airplane Ticket CGK-PLM	904682	2024-09-06	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 496 | Subcategory: Transportation	2026-03-11 12:39:59
307	86	2	Taxi Pondok Cabe-Vania-CGK (inc Toll)	256500	2024-09-06	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 497 | Subcategory: Transportation	2026-03-11 12:39:59
308	86	2	Toll (PLM-Prabumulih-PLM)	224000	2024-09-06	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 498 | Subcategory: Transportation	2026-03-11 12:39:59
311	86	2	Taxi CGK-Pondok Cabe (inc Toll+Parking)	310660	2024-09-06	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 501 | Subcategory: Transportation	2026-03-11 12:39:59
312	86	2	Airplane Ticket PLM-CGK	836100	2024-09-08	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 502 | Subcategory: Transportation	2026-03-11 12:39:59
313	86	4	Field Allowance	600	2024-09-06	\N	\N	0	USD	15438	\N	\N	approved	Imported from row 504 | Subcategory: Allowance	2026-03-11 12:39:59
314	86	5	Meals	900000	2024-09-06	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 505 | Subcategory: Allowance	2026-03-11 12:39:59
315	87	2	Taxi+Tol Serpong - Gambir	241280	2024-09-22	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 508 | Subcategory: Transportation	2026-03-11 12:39:59
316	87	2	Gocar St. Cepu, Kalog - Bojonegoro	250000	2024-09-23	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 509 | Subcategory: Transportation	2026-03-11 12:39:59
317	87	2	Taxi+Tol Gambir - Serpong	240000	2024-09-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 510 | Subcategory: Transportation	2026-03-11 12:39:59
318	87	5	Uang Makan (22 - 26 Sept 2024)	750000	2024-09-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 512 | Subcategory: Allowance	2026-03-11 12:39:59
319	87	7	Laundry (22 - 26 Sept 2024)	250000	2024-09-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 514 | Subcategory: Laundry	2026-03-11 12:39:59
320	87	4	Field Bonus SKW#26 (22 - 26 Sept 2024). 1US$=15.100	500	2024-09-26	\N	\N	0	IDR	15100	\N	\N	approved	Imported from row 516 | Subcategory: Allowance	2026-03-11 12:39:59
321	88	3	Hotel 21 Sept - 27 Sept 2024 (6 days)	1680000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 519 | Subcategory: Accommodation	2026-03-11 12:39:59
322	88	7	Laundry 20 Sept - 27 Sept 2024 (7days) @ Rp. 50000	350000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 520 | Subcategory: Accommodation	2026-03-11 12:39:59
328	88	2	Toll (PLM-Prabumulih)	112000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 527 | Subcategory: Transportation	2026-03-11 12:39:59
329	88	2	Toll (Prabumulih-PLM)	117000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 528 | Subcategory: Transportation	2026-03-11 12:39:59
331	88	5	Aqua 600 ML + Sunlight	65000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 531 | Subcategory: Operation	2026-03-11 12:39:59
332	88	5	Fried Food + Soft Drink	150000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 532 | Subcategory: Operation	2026-03-11 12:39:59
333	88	5	Meal's Crew	120000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 533 | Subcategory: Operation	2026-03-11 12:39:59
334	88	5	Snack's Crew	172000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 534 | Subcategory: Operation	2026-03-11 12:39:59
335	88	5	Meal's + Soft Drink Crew	300000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 535 | Subcategory: Operation	2026-03-11 12:39:59
336	88	5	Aqua 600 ML	65000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 536 | Subcategory: Operation	2026-03-11 12:39:59
337	88	5	Meal's Crws + Ice Tea	200000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 537 | Subcategory: Operation	2026-03-11 12:39:59
338	88	5	Snack's Crew	240000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 538 | Subcategory: Operation	2026-03-11 12:39:59
339	88	5	Meal's + Soft Drink Crew	230000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 539 | Subcategory: Operation	2026-03-11 12:39:59
340	88	5	Soft Drink	110000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 540 | Subcategory: Operation	2026-03-11 12:39:59
342	88	4	Field Allowance 20 Sept - 27 Sept 2024	175	2024-09-28	\N	\N	0	USD	15250	\N	\N	approved	Imported from row 543 | Subcategory: Allowance	2026-03-11 12:39:59
343	88	5	Meals 20 Sept - 27 Sept 2024 7 days	1050000	2024-09-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 544 | Subcategory: Allowance	2026-03-11 12:39:59
344	89	2	Air ticket Anevril JKT-Palembang	796800	2024-09-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 547 | Subcategory: Transportation	2026-03-11 12:39:59
345	89	2	Air ticket Anevril Palembang-JKT	804500	2024-09-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 548 | Subcategory: Transportation	2026-03-11 12:39:59
346	89	2	Taxi Anevril Home - CGK Airport	250000	2024-09-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 550 | Subcategory: Transportation	2026-03-11 12:39:59
347	89	2	Taxi Anevril CGK Airport - Home	250000	2024-09-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 551 | Subcategory: Transportation	2026-03-11 12:39:59
348	89	2	Sewa mobil 8 hari (21/09/24 - 29/09/24)	4000000	2024-09-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 552 | Subcategory: Transportation	2026-03-11 12:39:59
349	89	7	Laundry 8 days @ 50K IDR/day	400000	2024-09-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 555 | Subcategory: Accommodation	2026-03-11 12:39:59
350	89	5	Meals 8 days @ 150K IDR/day	900000	2024-09-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 557 | Subcategory: Allowance	2026-03-11 12:39:59
352	90	2	Fuel ( trip modified tool Sampler to Mr suby)	274000	2024-08-22	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 562 | Subcategory: Transportation	2026-03-11 12:39:59
353	90	2	Gocar ( trip Bintaro - Instrutek solusindo)	144500	2024-09-09	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 563 | Subcategory: Transportation	2026-03-11 12:39:59
354	90	2	Gocar ( trip Instrutek solusindo - Bintaro)	160000	2024-09-09	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 564 | Subcategory: Transportation	2026-03-11 12:39:59
355	90	2	Fuel ( trip to Sclumberger Cikaranga,SIT seeting tool )	232500	2024-09-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 565 | Subcategory: Transportation	2026-03-11 12:39:59
356	90	2	Fuel ( trip to workshop Gowell & ktr Pajak)	256800	2024-09-13	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 566 | Subcategory: Transportation	2026-03-11 12:39:59
363	90	2	Fuel	180000	2024-09-17	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 574 | Subcategory: Trip	2026-03-11 12:39:59
365	90	2	Fuel	222650	2024-09-18	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 576 | Subcategory: Trip	2026-03-11 12:39:59
366	90	3	Hotel	700000	2024-09-17	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 578 | Subcategory: Accommodation	2026-03-11 12:39:59
368	90	5	lunch when check MTD tool at workshop Gowell	171000	2024-09-11	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 581 | Subcategory: Meal	2026-03-11 12:39:59
369	90	5	Uang makan utk 3 hari (17-18 Sept-24) @150.000	300000	2024-09-18	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 582 | Subcategory: Meal	2026-03-11 12:39:59
370	91	33	Biaya Konsul Dokter Penyakit dalam	854100	2024-08-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 585 | Subcategory: Medical	2026-03-11 12:39:59
371	91	33	Fisioterapi 1st	285000	2024-08-28	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 586 | Subcategory: Medical	2026-03-11 12:39:59
372	91	33	Fisioterapi 2nd	285000	2024-08-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 587 | Subcategory: Medical	2026-03-11 12:39:59
373	91	33	Fisioterapi 3rd	285000	2024-08-30	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 588 | Subcategory: Medical	2026-03-11 12:39:59
374	91	33	Biaya Konsul Dokter Syaraf	2906650	2024-09-02	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 589 | Subcategory: Medical	2026-03-11 12:39:59
378	91	33	Biaya Konsul ke 2, Dokter Jantung	1370000	2024-10-01	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 593 | Subcategory: Medical	2026-03-11 12:39:59
384	92	3	Hotel 23 Sept - 26 Sept (3 days)	1584184	2024-09-23	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 602 | Subcategory: Accommodation	2026-03-11 12:39:59
385	92	7	Laundry 6 days 1 Persons @ 50K IDR/day	250000	2024-09-23	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 603 | Subcategory: Accommodation	2026-03-11 12:39:59
386	92	2	Train Ticket Gambir-Cepu (2 pax)	1213500	2024-09-23	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 605 | Subcategory: Transportation	2026-03-11 12:39:59
387	92	2	Taxi Pondok Cabe-Gambir	132500	2024-09-23	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 606 | Subcategory: Transportation	2026-03-11 12:39:59
389	92	2	Taxi Gambir-Pondok Cabe (inc Toll+Parking)	326600	2024-09-23	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 608 | Subcategory: Transportation	2026-03-11 12:39:59
390	92	2	Train Ticket Bojonegoro-Gambir (2 pax)	1653500	2024-09-23	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 609 | Subcategory: Transportation	2026-03-11 12:39:59
392	92	4	Field Allowance	500	2024-09-23	\N	\N	0	USD	15231	\N	\N	approved	Imported from row 612 | Subcategory: Allowance	2026-03-11 12:39:59
393	92	5	Meals	750000	2024-09-23	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 613 | Subcategory: Allowance	2026-03-11 12:39:59
394	93	2	Taxi Anevril Home - CGK Airport	250000	2024-10-03	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 616 | Subcategory: Transportation	2026-03-11 12:39:59
395	93	2	Taxi Anevril CGK Airport - Home	250000	2024-10-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 617 | Subcategory: Transportation	2026-03-11 12:39:59
396	93	7	Laundry 18 days @ 50K IDR/day	900000	2024-10-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 619 | Subcategory: Accommodation	2026-03-11 12:39:59
397	93	5	operation meal with BHI person	1102050	2024-10-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 622 | Subcategory: Meal	2026-03-11 12:39:59
398	93	5	Meal 18 days @ 150K IDR/day	2700000	2024-10-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 624 | Subcategory: Allowance	2026-03-11 12:39:59
399	93	4	Field Allowance for 18 days	1800	2024-10-20	\N	\N	0	USD	15849	\N	\N	approved	Imported from row 626 | Subcategory: Allowance	2026-03-11 12:39:59
400	94	10	Basic Sea Survival	2700000	2024-11-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 629 | Subcategory: Training	2026-03-11 12:39:59
401	94	2	Gojek ( Damn Coffe - PT Lautan Tenang Jaya )	15000	2024-11-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 631 | Subcategory: Transportation	2026-03-11 12:39:59
402	94	2	Gojek ( PT Lautan Tenang Jaya - Stasiun MRT )	15000	2024-11-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 632 | Subcategory: Transportation	2026-03-11 12:39:59
403	94	2	Gojek ( Stasiun Sudimara - Home )	15000	2024-11-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 633 | Subcategory: Transportation	2026-03-11 12:39:59
406	95	72	Materai 15 pcs	150000	2023-05-25	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 638 | Subcategory: Shipping	2026-03-11 12:39:59
411	95	72	Materai 6 pcs	62000	2024-10-07	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 644 | Subcategory: Shipping	2026-03-11 12:39:59
416	95	72	Materai 10 pcs	103000	2024-10-14	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 649 | Subcategory: Shipping	2026-03-11 12:39:59
417	95	72	Materai 5 pcs	55000	2024-10-17	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 650 | Subcategory: Shipping	2026-03-11 12:39:59
418	95	72	Materai 10 pcs	103000	2024-11-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 651 | Subcategory: Shipping	2026-03-11 12:39:59
419	95	2	GoCar to Elnusa PP	275000	2024-10-14	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 653 | Subcategory: Transportation	2026-03-11 12:39:59
420	95	2	Tol & parking fee	31500	2024-10-14	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 654 | Subcategory: Transportation	2026-03-11 12:39:59
421	95	2	GoCar to Elnusa PP	266000	2024-10-17	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 655 | Subcategory: Transportation	2026-03-11 12:39:59
422	95	2	Tol & parking fee	53500	2024-10-17	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 656 | Subcategory: Transportation	2026-03-11 12:39:59
423	95	2	GoCar to Elnusa PP	269000	2024-11-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 657 | Subcategory: Transportation	2026-03-11 12:39:59
424	95	2	Tol & parking fee	43450	2024-11-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 658 | Subcategory: Transportation	2026-03-11 12:39:59
425	95	2	GoCar to Elnusa PP	290000	2024-12-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 659 | Subcategory: Transportation	2026-03-11 12:39:59
426	95	2	Tol & parking fee	48500	2024-12-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 660 | Subcategory: Transportation	2026-03-11 12:39:59
427	96	73	Starlink Kit	5583200	2024-11-11	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 662	2026-03-11 12:39:59
430	98	33	Biaya Konsul Dokter Jantung 3rdPenyakit dalam	799000	2024-12-02	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 668 | Subcategory: Medical	2026-03-11 12:39:59
431	98	33	Biaya Konsul dokter Kulit a/n Diofavian	1582141	2024-12-01	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 669 | Subcategory: Medical	2026-03-11 12:39:59
432	98	33	Biaya Konsul Dokter mata a/n Eva linda	970767	2024-12-01	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 670 | Subcategory: Medical	2026-03-11 12:39:59
435	98	33	Medicine after konsul jantung 3rd	190309.5	2024-12-02	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 673 | Subcategory: Medical	2026-03-11 12:39:59
436	98	33	Medicine after konsul jantung 3rd	417600	2024-12-11	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 674 | Subcategory: Medical	2026-03-11 12:39:59
437	98	2	Fuel diesel visit consul to KPP pajak	276216	2024-11-11	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 676 | Subcategory: Transportation	2026-03-11 12:39:59
438	98	2	toll gate	79500	2024-11-11	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 677 | Subcategory: Transportation	2026-03-11 12:39:59
439	98	2	Parkir Graha Elnusa (HSE tool hall meeting) at Elnusa (graha Elnusa)	29000	2024-11-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 678 | Subcategory: Transportation	2026-03-11 12:39:59
440	98	2	toll gate	17000	2024-11-26	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 679 | Subcategory: Transportation	2026-03-11 12:39:59
442	98	2	Parkir Graha Elnusa (antar dokemen invoice)	17000	2024-12-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 681 | Subcategory: Transportation	2026-03-11 12:39:59
446	99	5	Meal	195585	2024-12-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 688 | Subcategory: Meal	2026-03-11 12:39:59
447	99	5	Meal	299900	2024-12-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 689 | Subcategory: Meal	2026-03-11 12:39:59
450	100	2	Taxi Home - CGK Airport	200000	2024-03-11	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 696 | Subcategory: Trip	2026-03-11 12:39:59
451	100	3	Flight CGK-KUL + Hotel 1 night	1803353	2024-03-11	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 697 | Subcategory: Trip	2026-03-11 12:39:59
452	100	2	Train KLIA Airport to Hyperseal	50	2024-03-11	\N	\N	0	MYR	3636.89	\N	\N	approved	Imported from row 698 | Subcategory: Trip	2026-03-11 12:39:59
454	100	2	Train Hyperseal to KLIA Airport	50	2024-03-12	\N	\N	0	MYR	3636.89	\N	\N	approved	Imported from row 700 | Subcategory: Trip	2026-03-11 12:39:59
455	100	2	Taxi CGK Airport to Home	200000	2024-03-12	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 701 | Subcategory: Trip	2026-03-11 12:39:59
456	100	5	Meals 2 days @ 300,000/day	600000	2024-03-12	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 702 | Subcategory: Trip	2026-03-11 12:39:59
457	100	2	Car 22-23 Apr 2024 (2 days) incl. Fuel & Tol	3000000	2024-04-22	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 704 | Subcategory: Trip	2026-03-11 12:39:59
458	100	4	Tunjangan Lapangan @ 1.5 juta/day x 2 days	3000000	2024-04-23	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 705 | Subcategory: Trip	2026-03-11 12:39:59
459	100	5	Meals 2 days @ 150,000/day	300000	2024-04-23	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 706 | Subcategory: Trip	2026-03-11 12:39:59
460	100	2	Car 30 Apr-01 May 2024 (2 days) incl. Fuel & Tol	3000000	2024-04-30	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 708 | Subcategory: Trip	2026-03-11 12:39:59
461	100	2	Taxi Home to KCIC Train station	100000	2024-12-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 710 | Subcategory: Training	2026-03-11 12:39:59
462	100	2	Train Round trip Jakarta - Bandung @200K/trip	400000	2024-12-20	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 711 | Subcategory: Training	2026-03-11 12:39:59
463	100	3	Hotel 1 night 20 - 21 Dec 2024	784000	2024-12-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 712 | Subcategory: Training	2026-03-11 12:39:59
464	100	2	Taxi from KCIC Stationa Halim to Home	100000	2024-12-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 713 | Subcategory: Training	2026-03-11 12:39:59
465	100	5	Meals 2 days @ 150,000/day	300000	2024-12-21	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 714 | Subcategory: Training	2026-03-11 12:39:59
488	101	10	Traning Basic Sea Survival (BSS)	2700000	2024-12-10	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 739	2026-03-11 12:39:59
489	102	2	Transport Train, (Jakarta to Cirebon)	200000	2024-12-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 741	2026-03-11 12:39:59
490	102	2	Gojek (Cirendeu to Gambir Station)	61500	2024-12-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 742	2026-03-11 12:39:59
491	102	2	Gojek (Cirebon Station to Hotel)	12500	2024-12-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 743	2026-03-11 12:39:59
492	102	3	Accomodation Hotel (Pia Hotel 29 - 30 des, 1 Night)	224000	2024-12-29	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 744	2026-03-11 12:39:59
493	102	2	Transport Train (Cirebon to Jakarta)	140000	2024-12-30	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 745	2026-03-11 12:39:59
494	102	2	Gojek (Hotel to HSSE Training Center PEP Zone 7)	11000	2024-12-30	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 746	2026-03-11 12:39:59
495	102	2	Gojek (CSB to Cirebon Train Station)	11000	2024-12-30	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 747	2026-03-11 12:39:59
496	102	2	Gojek (Gambir Station to Cirendeu)	66000	2024-12-30	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 748	2026-03-11 12:39:59
497	102	4	Meal Allowance 2 Days (29 - 30 December 2024)@ 150 rb	300000	2024-12-30	\N	\N	0	IDR	1	\N	\N	approved	Imported from row 749	2026-03-11 12:39:59
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
1	1	1	submit	settlement	134	Manager melakukan submit settlement: hgfhgf	\N	2026-03-16 04:00:59.386864	/settlements/134
2	1	1	submit_confirmation	settlement	134	Settlement "hgfhgf" Anda telah disubmit	\N	2026-03-16 04:00:59.391549	/settlements/134
3	1	2	submit	settlement	137	Staff 1 melakukan submit settlement: asdasd	\N	2026-03-16 04:04:02.506149	/settlements/137
4	2	2	submit_confirmation	settlement	137	Settlement "asdasd" Anda telah disubmit	\N	2026-03-16 04:04:02.51041	/settlements/137
5	2	1	approve	settlement	137	Settlement Anda telah disetujui: asdasd	\N	2026-03-16 04:04:57.00239	/settlements/137
6	1	2	submit	settlement	138	Staff 1 melakukan submit settlement: Pengeluaran Sendiri	\N	2026-03-16 04:12:29.050459	/settlements/138
7	2	2	submit_confirmation	settlement	138	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-03-16 04:12:29.05449	/settlements/138
8	1	2	submit	settlement	138	Staff 1 melakukan submit settlement: Pengeluaran Sendiri	\N	2026-03-16 04:23:14.23852	/settlements/138
9	2	2	submit_confirmation	settlement	138	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-03-16 04:23:14.244045	/settlements/138
10	1	2	submit	settlement	140	Staff 1 melakukan submit settlement: Beli barang gowel	\N	2026-03-17 04:46:55.59101	/settlements/140
11	2	2	submit_confirmation	settlement	140	Settlement "Beli barang gowel" Anda telah disubmit	\N	2026-03-17 04:46:55.601028	/settlements/140
12	1	2	submit	settlement	138	Staff 1 melakukan submit settlement: Pengeluaran Sendiri	\N	2026-03-17 05:38:03.442672	/settlements/138
13	2	2	submit_confirmation	settlement	138	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-03-17 05:38:03.448886	/settlements/138
14	1	1	submit	settlement	132	Manager melakukan submit settlement: dsfds	\N	2026-03-17 06:01:06.930123	/settlements/132
15	1	1	submit_confirmation	settlement	132	Settlement "dsfds" Anda telah disubmit	\N	2026-03-17 06:01:06.933797	/settlements/132
16	1	1	submit	settlement	141	Manager melakukan submit settlement: beljar kdoing	\N	2026-03-17 06:02:03.887341	/settlements/141
17	1	1	submit_confirmation	settlement	141	Settlement "beljar kdoing" Anda telah disubmit	\N	2026-03-17 06:02:03.890813	/settlements/141
18	1	1	submit	settlement	142	Manager melakukan submit settlement: hgjhgj	\N	2026-03-17 07:06:53.073937	/settlements/142
19	1	1	submit_confirmation	settlement	142	Settlement "hgjhgj" Anda telah disubmit	\N	2026-03-17 07:06:53.078038	/settlements/142
20	1	1	submit	settlement	140	Manager melakukan submit settlement: kerja sampingan	\N	2026-03-18 08:40:23.493561	/settlements/140
21	1	1	submit_confirmation	settlement	140	Settlement "kerja sampingan" Anda telah disubmit	\N	2026-03-18 08:40:23.497697	/settlements/140
22	1	1	submit	settlement	140	Manager melakukan submit settlement: kerja sampingan	\N	2026-03-18 09:15:43.160148	/settlements/140
23	1	1	submit_confirmation	settlement	140	Settlement "kerja sampingan" Anda telah disubmit	\N	2026-03-18 09:15:43.165681	/settlements/140
24	1	1	submit	settlement	140	Manager melakukan submit settlement: kerja sampingan	\N	2026-03-18 09:51:48.347257	/settlements/140
25	1	1	submit_confirmation	settlement	140	Settlement "kerja sampingan" Anda telah disubmit	\N	2026-03-18 09:51:48.351439	/settlements/140
26	1	1	submit	settlement	140	Manager melakukan submit settlement: kerja sampingan	\N	2026-03-18 18:04:50.596923	/settlements/140
27	1	1	submit_confirmation	settlement	140	Settlement "kerja sampingan" Anda telah disubmit	\N	2026-03-18 18:04:50.599918	/settlements/140
28	1	1	submit	settlement	140	Manager melakukan submit settlement: kerja sampingan	\N	2026-03-18 18:05:30.462312	/settlements/140
29	1	1	submit_confirmation	settlement	140	Settlement "kerja sampingan" Anda telah disubmit	\N	2026-03-18 18:05:30.464828	/settlements/140
30	1	1	submit	settlement	140	Manager melakukan submit settlement: kerja sampingan	\N	2026-03-18 18:05:50.133717	/settlements/140
31	1	1	submit_confirmation	settlement	140	Settlement "kerja sampingan" Anda telah disubmit	\N	2026-03-18 18:05:50.136719	/settlements/140
32	1	1	approve	settlement	140	Settlement Anda telah disetujui: kerja sampingan	\N	2026-03-18 18:05:56.766926	/settlements/140
33	1	1	create	category	66	Manager membuat kategori baru: pepaya	\N	2026-03-18 18:26:01.152212	/categories
34	1	1	submit	settlement	141	Manager melakukan submit settlement: Pengeluaran Batch	\N	2026-03-18 18:26:11.755541	/settlements/141
35	1	1	submit_confirmation	settlement	141	Settlement "Pengeluaran Batch" Anda telah disubmit	\N	2026-03-18 18:26:11.759524	/settlements/141
36	1	1	approve	category	66	Kategori 'pepaya' Anda telah disetujui	\N	2026-03-18 18:26:24.359474	/categories
37	1	1	approve	settlement	141	Settlement Anda telah disetujui: Pengeluaran Batch	\N	2026-03-18 18:26:35.670485	/settlements/141
38	1	1	submit	settlement	142	Manager melakukan submit settlement: asdasd	\N	2026-03-18 18:27:55.367188	/settlements/142
39	1	1	submit_confirmation	settlement	142	Settlement "asdasd" Anda telah disubmit	\N	2026-03-18 18:27:55.371182	/settlements/142
40	1	1	submit	settlement	142	Manager melakukan submit settlement: asdasd	\N	2026-03-18 18:28:27.132716	/settlements/142
41	1	1	submit_confirmation	settlement	142	Settlement "asdasd" Anda telah disubmit	\N	2026-03-18 18:28:27.13674	/settlements/142
42	1	1	approve	settlement	142	Settlement Anda telah disetujui: asdasd	\N	2026-03-18 18:28:34.820284	/settlements/142
43	1	1	submit	advance	3	Manager melakukan submit kasbon: sdfds	\N	2026-03-21 20:24:25.008605	/advances/3
44	1	1	submit_confirmation	advance	3	Kasbon "sdfds" Anda telah disubmit	\N	2026-03-21 20:24:25.012605	/advances/3
45	1	1	submit	advance	3	Manager melakukan submit kasbon: sdfds	\N	2026-03-21 20:25:01.44043	/advances/3
46	1	1	submit_confirmation	advance	3	Kasbon "sdfds" Anda telah disubmit	\N	2026-03-21 20:25:01.443429	/advances/3
47	1	1	approve	advance	3	Kasbon Anda telah disetujui: sdfds	\N	2026-03-21 20:25:05.194288	/advances/3
48	1	1	submit	settlement	143	Manager melakukan submit settlement: sdfds	\N	2026-03-21 20:25:12.232576	/settlements/143
49	1	1	submit_confirmation	settlement	143	Settlement "sdfds" Anda telah disubmit	\N	2026-03-21 20:25:12.235609	/settlements/143
50	1	1	submit	settlement	144	Manager melakukan submit settlement: asdasd	\N	2026-03-21 20:28:52.928914	/settlements/144
51	1	1	submit_confirmation	settlement	144	Settlement "asdasd" Anda telah disubmit	\N	2026-03-21 20:28:52.932915	/settlements/144
52	1	1	submit	settlement	145	Manager melakukan submit settlement: sdfsdf	\N	2026-03-21 20:43:53.247442	/settlements/145
53	1	1	submit_confirmation	settlement	145	Settlement "sdfsdf" Anda telah disubmit	\N	2026-03-21 20:43:53.251444	/settlements/145
54	1	1	submit	settlement	146	Manager melakukan submit settlement: hari senin	\N	2026-03-21 20:44:53.75763	/settlements/146
55	1	1	submit_confirmation	settlement	146	Settlement "hari senin" Anda telah disubmit	\N	2026-03-21 20:44:53.761797	/settlements/146
56	1	1	submit	settlement	146	Manager melakukan submit settlement: hari senin	\N	2026-03-21 20:45:43.893906	/settlements/146
57	1	1	submit_confirmation	settlement	146	Settlement "hari senin" Anda telah disubmit	\N	2026-03-21 20:45:43.897527	/settlements/146
58	1	1	approve	settlement	146	Settlement Anda telah disetujui: hari senin	\N	2026-03-21 20:45:55.375622	/settlements/146
59	1	1	submit	advance	7	Manager melakukan submit kasbon: hari selasa	\N	2026-03-21 20:46:32.136903	/advances/7
60	1	1	submit_confirmation	advance	7	Kasbon "hari selasa" Anda telah disubmit	\N	2026-03-21 20:46:32.139903	/advances/7
61	1	1	submit	advance	8	Manager melakukan submit kasbon: makanan malam 2026	\N	2026-03-21 20:52:09.438813	/advances/8
62	1	1	submit_confirmation	advance	8	Kasbon "makanan malam 2026" Anda telah disubmit	\N	2026-03-21 20:52:09.441799	/advances/8
63	1	1	submit	advance	9	Manager melakukan submit kasbon: mercu buana	\N	2026-03-21 20:58:57.727631	/advances/9
64	1	1	submit_confirmation	advance	9	Kasbon "mercu buana" Anda telah disubmit	\N	2026-03-21 20:58:57.73161	/advances/9
65	1	1	submit	advance	9	Manager melakukan submit kasbon: mercu buana	\N	2026-03-21 20:59:36.007715	/advances/9
66	1	1	submit_confirmation	advance	9	Kasbon "mercu buana" Anda telah disubmit	\N	2026-03-21 20:59:36.009716	/advances/9
67	1	1	submit	advance	9	Manager melakukan submit kasbon: mercu buana	\N	2026-03-21 20:59:59.614314	/advances/9
68	1	1	submit_confirmation	advance	9	Kasbon "mercu buana" Anda telah disubmit	\N	2026-03-21 20:59:59.617281	/advances/9
69	1	1	submit	advance	9	Manager melakukan submit kasbon: mercu buana	\N	2026-03-21 21:00:14.681162	/advances/9
70	1	1	submit_confirmation	advance	9	Kasbon "mercu buana" Anda telah disubmit	\N	2026-03-21 21:00:14.684122	/advances/9
71	1	1	approve	advance	9	Kasbon Anda telah disetujui: mercu buana	\N	2026-03-21 21:00:20.485156	/advances/9
72	1	1	submit	settlement	147	Manager melakukan submit settlement: mercu buana	\N	2026-03-21 21:00:28.66699	/settlements/147
73	1	1	submit_confirmation	settlement	147	Settlement "mercu buana" Anda telah disubmit	\N	2026-03-21 21:00:28.670016	/settlements/147
74	1	1	submit	advance	10	Manager melakukan submit kasbon: aaaaaaaaaaaaaaaaaaaa	\N	2026-03-21 21:20:29.591386	/advances/10
75	1	1	submit_confirmation	advance	10	Kasbon "aaaaaaaaaaaaaaaaaaaa" Anda telah disubmit	\N	2026-03-21 21:20:29.596386	/advances/10
76	1	1	submit	advance	10	Manager melakukan submit kasbon: aaaaaaaaaaaaaaaaaaaa	\N	2026-03-21 21:20:49.79753	/advances/10
77	1	1	submit_confirmation	advance	10	Kasbon "aaaaaaaaaaaaaaaaaaaa" Anda telah disubmit	\N	2026-03-21 21:20:49.800543	/advances/10
78	1	1	approve	advance	10	Kasbon Anda telah disetujui: aaaaaaaaaaaaaaaaaaaa	\N	2026-03-21 21:20:53.806733	/advances/10
79	1	1	submit	settlement	149	Manager melakukan submit settlement: Pengeluaran Sendiri	\N	2026-03-22 14:22:07.977799	/settlements/149
80	1	1	submit_confirmation	settlement	149	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-03-22 14:22:07.984361	/settlements/149
81	1	1	submit	settlement	149	Manager melakukan submit settlement: Pengeluaran Sendiri	\N	2026-03-22 14:22:41.266669	/settlements/149
82	1	1	submit_confirmation	settlement	149	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-03-22 14:22:41.271719	/settlements/149
83	1	1	submit	settlement	149	Manager melakukan submit settlement: Pengeluaran Sendiri	\N	2026-03-22 14:22:54.187882	/settlements/149
84	1	1	submit_confirmation	settlement	149	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-03-22 14:22:54.195052	/settlements/149
85	1	1	submit	settlement	149	Manager melakukan submit settlement: Pengeluaran Sendiri	\N	2026-03-22 14:27:19.380454	/settlements/149
86	1	1	submit_confirmation	settlement	149	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-03-22 14:27:19.385634	/settlements/149
87	1	1	approve	settlement	149	Settlement Anda telah disetujui: Pengeluaran Sendiri	\N	2026-03-22 15:02:33.385032	/settlements/149
88	1	1	submit	advance	13	Manager melakukan submit kasbon: werwerwerwer	\N	2026-03-22 18:05:07.477301	/advances/13
89	1	1	submit_confirmation	advance	13	Kasbon "werwerwerwer" Anda telah disubmit	\N	2026-03-22 18:05:07.483108	/advances/13
90	1	1	submit	advance	13	Manager melakukan submit kasbon: werwerwerwer	\N	2026-03-22 18:05:47.377347	/advances/13
91	1	1	submit_confirmation	advance	13	Kasbon "werwerwerwer" Anda telah disubmit	\N	2026-03-22 18:05:47.381352	/advances/13
92	1	1	submit	advance	13	Manager melakukan submit kasbon: werwerwerwer	\N	2026-03-22 18:06:04.759832	/advances/13
93	1	1	submit_confirmation	advance	13	Kasbon "werwerwerwer" Anda telah disubmit	\N	2026-03-22 18:06:04.763339	/advances/13
94	1	1	approve	advance	13	Kasbon Anda telah disetujui: werwerwerwer	\N	2026-03-22 18:06:09.381023	/advances/13
95	1	1	submit	settlement	151	Manager melakukan submit settlement: werwerwerwer	\N	2026-03-22 18:07:43.778749	/settlements/151
96	1	1	submit_confirmation	settlement	151	Settlement "werwerwerwer" Anda telah disubmit	\N	2026-03-22 18:07:43.782282	/settlements/151
97	1	1	submit	settlement	151	Manager melakukan submit settlement: werwerwerwer	\N	2026-03-22 18:08:34.095531	/settlements/151
98	1	1	submit_confirmation	settlement	151	Settlement "werwerwerwer" Anda telah disubmit	\N	2026-03-22 18:08:34.10104	/settlements/151
99	1	1	submit	settlement	151	Manager melakukan submit settlement: werwerwerwer	\N	2026-03-22 18:08:49.912239	/settlements/151
100	1	1	submit_confirmation	settlement	151	Settlement "werwerwerwer" Anda telah disubmit	\N	2026-03-22 18:08:49.917295	/settlements/151
101	1	1	approve	settlement	151	Settlement Anda telah disetujui: werwerwerwer	\N	2026-03-22 18:08:54.500709	/settlements/151
102	1	1	submit	advance	8	Manager melakukan submit kasbon: makanan malam 2026	\N	2026-03-23 21:18:15.882322	/advances/8
103	1	1	submit_confirmation	advance	8	Kasbon "makanan malam 2026" Anda telah disubmit	\N	2026-03-23 21:18:15.883479	/advances/8
104	1	1	approve	advance	8	Kasbon Anda telah disetujui: makanan malam 2026	\N	2026-03-23 21:18:23.524453	/advances/8
105	1	1	submit	settlement	153	Manager melakukan submit settlement: makanan malam 2026	\N	2026-03-24 19:44:28.905499	/settlements/153
106	1	1	submit_confirmation	settlement	153	Settlement "makanan malam 2026" Anda telah disubmit	\N	2026-03-24 19:44:28.905499	/settlements/153
107	1	1	submit	settlement	153	Manager melakukan submit settlement: makanan malam 2026	\N	2026-03-24 19:45:18.770905	/settlements/153
108	1	1	submit_confirmation	settlement	153	Settlement "makanan malam 2026" Anda telah disubmit	\N	2026-03-24 19:45:18.777704	/settlements/153
109	1	1	submit	settlement	113	Manager melakukan submit settlement: Pengeluaran Sendiri	\N	2026-03-24 19:47:07.573203	/settlements/113
110	1	1	submit_confirmation	settlement	113	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-03-24 19:47:07.578351	/settlements/113
111	1	1	submit	settlement	113	Manager melakukan submit settlement: Pengeluaran Sendiri	\N	2026-03-24 19:47:39.756391	/settlements/113
112	1	1	submit_confirmation	settlement	113	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-03-24 19:47:39.762682	/settlements/113
113	1	1	approve	settlement	113	Settlement Anda telah disetujui: Pengeluaran Sendiri	\N	2026-03-24 19:47:50.326604	/settlements/113
114	1	1	create	category	67	Anevril Chairu membuat kategori baru: diofavian	\N	2026-04-12 19:14:40.24719	/categories
115	1	1	create	category	69	Anevril Chairu membuat kategori baru: keysha	\N	2026-04-12 19:14:49.704214	/categories
116	1	1	create	category	70	Anevril Chairu membuat kategori baru: nabil	\N	2026-04-12 19:14:55.394591	/categories
117	1	1	submit	settlement	159	Anevril Chairu melakukan submit settlement: Gudang	\N	2026-04-12 19:16:09.830411	/settlements/159
118	1	1	submit_confirmation	settlement	159	Settlement "Gudang" Anda telah disubmit	\N	2026-04-12 19:16:09.836712	/settlements/159
119	1	1	approve	category	67	Kategori 'diofavian' Anda telah disetujui	\N	2026-04-12 19:16:38.587021	/categories
120	1	1	approve	category	69	Kategori 'keysha' Anda telah disetujui	\N	2026-04-12 19:16:41.49913	/categories
121	1	1	approve	category	70	Kategori 'nabil' Anda telah disetujui	\N	2026-04-12 19:16:42.906672	/categories
122	1	1	approve_expense	expense	547	Expense disetujui: reza	\N	2026-04-12 19:16:55.932197	/settlements/159
123	1	1	reject_expense	expense	548	Expense ditolak: werw	\N	2026-04-12 19:17:38.489795	/settlements/159
124	1	1	submit	advance	22	Anevril Chairu melakukan submit kasbon: sdas	\N	2026-04-12 19:22:08.744734	/advances/22
125	1	1	submit_confirmation	advance	22	Kasbon "sdas" Anda telah disubmit	\N	2026-04-12 19:22:08.749578	/advances/22
126	1	1	reject_item	advance_item	17	Item kasbon ditolak: asdasd	\N	2026-04-12 19:22:15.331019	/advances/22
127	1	1	submit	advance	22	Anevril Chairu melakukan submit kasbon: sdas	\N	2026-04-12 19:24:24.682762	/advances/22
128	1	1	submit_confirmation	advance	22	Kasbon "sdas" Anda telah disubmit	\N	2026-04-12 19:24:24.687652	/advances/22
129	1	1	submit	settlement	159	Anevril Chairu melakukan submit settlement: Gudang	\N	2026-04-12 19:36:22.197214	/settlements/159
130	1	1	submit_confirmation	settlement	159	Settlement "Gudang" Anda telah disubmit	\N	2026-04-12 19:36:22.201846	/settlements/159
131	1	1	reject_expense	expense	548	Expense ditolak: werw	\N	2026-04-12 19:36:31.609883	/settlements/159
132	1	1	approve_expense	expense	549	Expense disetujui: 123123	\N	2026-04-12 19:36:35.32188	/settlements/159
133	1	1	submit	settlement	159	Anevril Chairu melakukan submit settlement: Gudang	\N	2026-04-12 19:38:18.257528	/settlements/159
134	1	1	submit_confirmation	settlement	159	Settlement "Gudang" Anda telah disubmit	\N	2026-04-12 19:38:18.262477	/settlements/159
135	1	1	approve_expense	expense	548	Expense disetujui: werw	\N	2026-04-12 19:38:22.74251	/settlements/159
136	1	1	approve	settlement	159	Settlement Anda telah disetujui: Gudang	\N	2026-04-12 19:38:27.080191	/settlements/159
137	1	1	submit	settlement	158	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-12 19:46:00.856095	/settlements/158
138	1	1	submit_confirmation	settlement	158	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-12 19:46:00.860817	/settlements/158
139	1	1	reject_expense	expense	546	Expense ditolak: 87987000	\N	2026-04-12 19:46:25.505461	/settlements/158
140	1	1	submit	settlement	158	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-12 19:47:20.61139	/settlements/158
141	1	1	submit_confirmation	settlement	158	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-12 19:47:20.61699	/settlements/158
142	1	1	reject_expense	expense	546	Expense ditolak: 87987000	\N	2026-04-12 19:47:29.311304	/settlements/158
143	1	1	submit	settlement	158	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-12 19:48:07.717361	/settlements/158
144	1	1	submit_confirmation	settlement	158	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-12 19:48:07.722092	/settlements/158
145	1	1	approve_expense	expense	546	Expense disetujui: 87987000	\N	2026-04-12 19:48:14.595595	/settlements/158
146	1	1	approve	settlement	158	Settlement Anda telah disetujui: Pengeluaran Sendiri	\N	2026-04-12 19:48:16.241616	/settlements/158
147	1	1	approve_item	advance_item	17	Item kasbon disetujui: asdasd	\N	2026-04-12 19:48:25.25663	/advances/22
148	1	1	approve_item	advance_item	18	Item kasbon disetujui: 123123	\N	2026-04-12 19:48:26.478445	/advances/22
149	1	1	approve	advance	22	Kasbon Anda telah disetujui: sdas	\N	2026-04-12 19:48:27.862384	/advances/22
150	1	1	submit	settlement	160	Anevril Chairu melakukan submit settlement: sdas	\N	2026-04-12 19:48:50.008843	/settlements/160
151	1	1	submit_confirmation	settlement	160	Settlement "sdas" Anda telah disubmit	\N	2026-04-12 19:48:50.01429	/settlements/160
152	1	1	approve_expense	expense	550	Expense disetujui: asdasd	\N	2026-04-12 19:49:01.270496	/settlements/160
153	1	1	reject_expense	expense	551	Expense ditolak: 123123	\N	2026-04-12 19:49:19.474651	/settlements/160
154	1	1	submit	settlement	160	Anevril Chairu melakukan submit settlement: sdas	\N	2026-04-12 19:49:50.3702	/settlements/160
155	1	1	submit_confirmation	settlement	160	Settlement "sdas" Anda telah disubmit	\N	2026-04-12 19:49:50.374805	/settlements/160
156	1	1	approve_expense	expense	551	Expense disetujui: 123123	\N	2026-04-12 19:51:31.599397	/settlements/160
157	1	1	approve	settlement	160	Settlement Anda telah disetujui: sdas	\N	2026-04-12 19:51:33.203709	/settlements/160
158	1	1	submit	advance	24	Anevril Chairu melakukan submit kasbon: sadasd	\N	2026-04-17 07:11:37.069729	/advances/24
159	1	1	submit_confirmation	advance	24	Kasbon "sadasd" Anda telah disubmit	\N	2026-04-17 07:11:37.072721	/advances/24
160	1	1	approve_item	advance_item	20	Item kasbon disetujui: 123123	\N	2026-04-17 07:11:38.176717	/advances/24
161	1	1	approve_item	advance_item	21	Item kasbon disetujui: 3123123	\N	2026-04-17 07:11:39.098966	/advances/24
162	1	1	approve	advance	24	Kasbon Anda telah disetujui: sadasd	\N	2026-04-17 07:11:39.948841	/advances/24
163	1	1	submit	advance	24	Anevril Chairu melakukan submit kasbon: sasdas	\N	2026-04-18 11:50:13.004987	/advances/24
164	1	1	submit_confirmation	advance	24	Kasbon "sasdas" Anda telah disubmit	\N	2026-04-18 11:50:13.009018	/advances/24
165	1	1	approve_item	advance_item	20	Item kasbon disetujui: 234234	\N	2026-04-18 11:50:15.709058	/advances/24
166	1	1	reject_item	advance_item	21	Item kasbon ditolak: 123123	\N	2026-04-18 11:51:00.054417	/advances/24
167	1	1	reject_item	advance_item	22	Item kasbon ditolak: 234	\N	2026-04-18 11:51:07.893307	/advances/24
168	1	1	submit	advance	24	Anevril Chairu melakukan submit kasbon: sasdas	\N	2026-04-18 11:52:03.281008	/advances/24
169	1	1	submit_confirmation	advance	24	Kasbon "sasdas" Anda telah disubmit	\N	2026-04-18 11:52:03.283522	/advances/24
170	1	1	reject_item	advance_item	21	Item kasbon ditolak: 123123	\N	2026-04-18 11:52:10.615737	/advances/24
171	1	1	approve_item	advance_item	22	Item kasbon disetujui: 234	\N	2026-04-18 11:52:12.262342	/advances/24
172	1	1	submit	advance	24	Anevril Chairu melakukan submit kasbon: sasdas	\N	2026-04-18 11:52:37.925605	/advances/24
173	1	1	submit_confirmation	advance	24	Kasbon "sasdas" Anda telah disubmit	\N	2026-04-18 11:52:37.929172	/advances/24
174	1	1	approve_item	advance_item	21	Item kasbon disetujui: 123123	\N	2026-04-18 11:52:39.223957	/advances/24
175	1	1	approve	advance	24	Kasbon Anda telah disetujui: sasdas	\N	2026-04-18 11:52:45.093526	/advances/24
176	1	1	submit	settlement	164	Anevril Chairu melakukan submit settlement: sasdas	\N	2026-04-18 11:53:48.30403	/settlements/164
177	1	1	submit_confirmation	settlement	164	Settlement "sasdas" Anda telah disubmit	\N	2026-04-18 11:53:48.30807	/settlements/164
178	1	1	approve_expense	expense	552	Expense disetujui: 234234	\N	2026-04-18 11:53:57.911099	/settlements/164
179	1	1	reject_expense	expense	553	Expense ditolak: 123123	\N	2026-04-18 11:55:03.907101	/settlements/164
180	1	1	approve_expense	expense	554	Expense disetujui: 234	\N	2026-04-18 11:55:05.702091	/settlements/164
181	1	1	submit	settlement	164	Anevril Chairu melakukan submit settlement: sasdas	\N	2026-04-18 11:55:28.299596	/settlements/164
182	1	1	submit_confirmation	settlement	164	Settlement "sasdas" Anda telah disubmit	\N	2026-04-18 11:55:28.303127	/settlements/164
183	1	1	reject_expense	expense	553	Expense ditolak: 123123	\N	2026-04-18 11:55:34.345819	/settlements/164
184	1	1	submit	settlement	164	Anevril Chairu melakukan submit settlement: sasdas	\N	2026-04-18 11:55:55.028119	/settlements/164
185	1	1	submit_confirmation	settlement	164	Settlement "sasdas" Anda telah disubmit	\N	2026-04-18 11:55:55.031702	/settlements/164
186	1	1	approve_expense	expense	553	Expense disetujui: 123123	\N	2026-04-18 11:55:58.58496	/settlements/164
187	1	1	approve	settlement	164	Settlement Anda telah disetujui: sasdas	\N	2026-04-18 11:55:59.853295	/settlements/164
188	1	1	submit	settlement	165	Anevril Chairu melakukan submit settlement: werwerewr	\N	2026-04-18 12:20:30.469639	/settlements/165
189	1	1	submit_confirmation	settlement	165	Settlement "werwerewr" Anda telah disubmit	\N	2026-04-18 12:20:30.472692	/settlements/165
190	1	1	approve_expense	expense	555	Expense disetujui: werwerwer	\N	2026-04-18 12:20:32.976794	/settlements/165
191	1	1	approve_expense	expense	556	Expense disetujui: we	\N	2026-04-18 12:20:33.303557	/settlements/165
192	1	1	approve_expense	expense	557	Expense disetujui: 23423423	\N	2026-04-18 12:20:33.838217	/settlements/165
193	1	1	approve_expense	expense	558	Expense disetujui: 23434	\N	2026-04-18 12:20:34.209192	/settlements/165
194	1	1	approve	settlement	165	Settlement Anda telah disetujui: werwerewr	\N	2026-04-18 12:20:35.394666	/settlements/165
195	1	1	submit	settlement	169	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-18 12:42:34.34835	/settlements/169
196	1	1	submit_confirmation	settlement	169	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-18 12:42:34.350458	/settlements/169
197	1	1	approve_expense	expense	559	Expense disetujui: 23434	\N	2026-04-18 12:42:39.513972	/settlements/169
198	1	1	approve	settlement	169	Settlement Anda telah disetujui: Pengeluaran Sendiri	\N	2026-04-18 12:42:40.489507	/settlements/169
199	1	1	submit	settlement	170	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-18 13:01:20.534465	/settlements/170
200	1	1	submit_confirmation	settlement	170	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-18 13:01:20.53698	/settlements/170
201	1	1	approve_expense	expense	560	Expense disetujui: sdasd	\N	2026-04-18 13:01:26.380692	/settlements/170
202	1	1	approve	settlement	170	Settlement Anda telah disetujui: Pengeluaran Sendiri	\N	2026-04-18 13:01:27.398121	/settlements/170
203	1	1	submit	advance	26	Anevril Chairu melakukan submit kasbon: 1234567890	\N	2026-04-18 13:22:46.777795	/advances/26
204	1	1	submit_confirmation	advance	26	Kasbon "1234567890" Anda telah disubmit	\N	2026-04-18 13:22:46.781343	/advances/26
205	1	1	reject_item	advance_item	23	Item kasbon ditolak: 234324	\N	2026-04-18 13:22:59.78507	/advances/26
206	1	1	approve_item	advance_item	24	Item kasbon disetujui: 123123	\N	2026-04-18 13:23:01.429048	/advances/26
207	1	1	submit	advance	26	Anevril Chairu melakukan submit kasbon: 1234567890	\N	2026-04-18 13:23:26.773927	/advances/26
208	1	1	submit_confirmation	advance	26	Kasbon "1234567890" Anda telah disubmit	\N	2026-04-18 13:23:26.777942	/advances/26
209	1	1	reject_item	advance_item	23	Item kasbon ditolak: 234324	\N	2026-04-18 13:23:29.752154	/advances/26
210	1	1	submit	advance	26	Anevril Chairu melakukan submit kasbon: 1234567890	\N	2026-04-18 13:23:43.267069	/advances/26
211	1	1	submit_confirmation	advance	26	Kasbon "1234567890" Anda telah disubmit	\N	2026-04-18 13:23:43.270082	/advances/26
212	1	1	approve_item	advance_item	23	Item kasbon disetujui: 234324	\N	2026-04-18 13:23:46.762398	/advances/26
213	1	1	reject_item	advance_item	24	Item kasbon ditolak: 123123	\N	2026-04-18 13:23:50.537424	/advances/26
214	1	1	submit	advance	26	Anevril Chairu melakukan submit kasbon: 1234567890	\N	2026-04-18 13:24:12.609282	/advances/26
215	1	1	submit_confirmation	advance	26	Kasbon "1234567890" Anda telah disubmit	\N	2026-04-18 13:24:12.612512	/advances/26
216	1	1	approve_item	advance_item	24	Item kasbon disetujui: 123123	\N	2026-04-18 13:24:16.02238	/advances/26
217	1	1	reject_item	advance_item	23	Item kasbon ditolak: 234324	\N	2026-04-18 13:24:18.72188	/advances/26
218	1	1	submit	advance	26	Anevril Chairu melakukan submit kasbon: 1234567890	\N	2026-04-18 13:27:26.767421	/advances/26
219	1	1	submit_confirmation	advance	26	Kasbon "1234567890" Anda telah disubmit	\N	2026-04-18 13:27:26.770421	/advances/26
220	1	1	approve_item	advance_item	23	Item kasbon disetujui: 234324	\N	2026-04-18 13:27:28.328242	/advances/26
221	1	1	submit	advance	26	Anevril Chairu melakukan submit kasbon: 1234567890	\N	2026-04-18 13:28:24.43794	/advances/26
222	1	1	submit_confirmation	advance	26	Kasbon "1234567890" Anda telah disubmit	\N	2026-04-18 13:28:24.441445	/advances/26
223	1	1	approve_item	advance_item	25	Item kasbon disetujui: 324234	\N	2026-04-18 13:28:25.494207	/advances/26
224	1	1	approve	advance	26	Kasbon Anda telah disetujui: 1234567890	\N	2026-04-18 13:28:30.560908	/advances/26
225	1	1	submit	settlement	171	Anevril Chairu melakukan submit settlement: 1234567890	\N	2026-04-18 13:28:50.350581	/settlements/171
226	1	1	submit_confirmation	settlement	171	Settlement "1234567890" Anda telah disubmit	\N	2026-04-18 13:28:50.354126	/settlements/171
227	1	1	reject_expense	expense	561	Expense ditolak: 234324	\N	2026-04-18 13:28:59.984771	/settlements/171
228	1	1	approve_expense	expense	562	Expense disetujui: 123123	\N	2026-04-18 13:29:06.565563	/settlements/171
229	1	1	approve_expense	expense	563	Expense disetujui: 324234	\N	2026-04-18 13:29:07.576544	/settlements/171
230	1	1	submit	settlement	171	Anevril Chairu melakukan submit settlement: 1234567890	\N	2026-04-18 13:29:13.953474	/settlements/171
231	1	1	submit_confirmation	settlement	171	Settlement "1234567890" Anda telah disubmit	\N	2026-04-18 13:29:13.956489	/settlements/171
232	1	1	reject_expense	expense	561	Expense ditolak: 234324	\N	2026-04-18 13:29:21.085005	/settlements/171
233	1	1	submit	settlement	171	Anevril Chairu melakukan submit settlement: 1234567890	\N	2026-04-18 13:29:34.496775	/settlements/171
234	1	1	submit_confirmation	settlement	171	Settlement "1234567890" Anda telah disubmit	\N	2026-04-18 13:29:34.499472	/settlements/171
235	1	1	approve_expense	expense	561	Expense disetujui: 234324	\N	2026-04-18 13:29:38.108036	/settlements/171
236	1	1	approve	settlement	171	Settlement Anda telah disetujui: 1234567890	\N	2026-04-18 13:30:41.568543	/settlements/171
237	1	1	submit	advance	27	Anevril Chairu melakukan submit kasbon: werwer	\N	2026-04-18 13:31:01.690678	/advances/27
238	1	1	submit_confirmation	advance	27	Kasbon "werwer" Anda telah disubmit	\N	2026-04-18 13:31:01.693863	/advances/27
239	1	1	approve_item	advance_item	26	Item kasbon disetujui: wqew	\N	2026-04-18 13:31:03.947142	/advances/27
240	1	1	reject_item	advance_item	26	Item kasbon ditolak: wqew	\N	2026-04-18 13:32:03.329512	/advances/27
241	1	1	submit	advance	27	Anevril Chairu melakukan submit kasbon: werwer	\N	2026-04-18 13:32:11.176529	/advances/27
242	1	1	submit_confirmation	advance	27	Kasbon "werwer" Anda telah disubmit	\N	2026-04-18 13:32:11.180053	/advances/27
243	1	1	approve_item	advance_item	26	Item kasbon disetujui: wqew	\N	2026-04-18 13:32:16.379763	/advances/27
244	1	1	approve	advance	27	Kasbon Anda telah disetujui: werwer	\N	2026-04-18 13:32:17.351926	/advances/27
245	1	1	submit	settlement	172	Anevril Chairu melakukan submit settlement: werwer	\N	2026-04-18 13:32:28.071897	/settlements/172
246	1	1	submit_confirmation	settlement	172	Settlement "werwer" Anda telah disubmit	\N	2026-04-18 13:32:28.075622	/settlements/172
247	1	1	approve_expense	expense	564	Expense disetujui: wqew	\N	2026-04-18 13:32:33.350756	/settlements/172
248	1	1	approve	settlement	172	Settlement Anda telah disetujui: werwer	\N	2026-04-18 13:32:37.39213	/settlements/172
249	1	1	submit	settlement	173	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-18 13:32:56.469546	/settlements/173
250	1	1	submit_confirmation	settlement	173	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-18 13:32:56.473148	/settlements/173
251	1	1	approve_expense	expense	565	Expense disetujui: 3234234	\N	2026-04-18 13:32:59.29814	/settlements/173
252	1	1	approve	settlement	173	Settlement Anda telah disetujui: Pengeluaran Sendiri	\N	2026-04-18 13:33:34.791338	/settlements/173
253	1	1	submit	settlement	174	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-18 14:27:23.588749	/settlements/174
254	1	1	submit_confirmation	settlement	174	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-18 14:27:23.593789	/settlements/174
255	1	1	reject_expense	expense	566	Expense ditolak: 23	\N	2026-04-18 14:27:31.550327	/settlements/174
256	1	1	submit	settlement	174	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-18 14:27:59.85126	/settlements/174
257	1	1	submit_confirmation	settlement	174	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-18 14:27:59.854249	/settlements/174
258	1	1	approve_expense	expense	566	Expense disetujui: 23	\N	2026-04-18 14:28:03.065953	/settlements/174
259	1	1	submit	advance	28	Anevril Chairu melakukan submit kasbon: asd	\N	2026-04-18 14:28:27.659748	/advances/28
260	1	1	submit_confirmation	advance	28	Kasbon "asd" Anda telah disubmit	\N	2026-04-18 14:28:27.663651	/advances/28
261	1	1	reject_item	advance_item	27	Item kasbon ditolak: asd	\N	2026-04-18 14:28:38.354143	/advances/28
262	1	1	approve_item	advance_item	27	Item kasbon disetujui: asd	\N	2026-04-18 14:28:49.689825	/advances/28
263	1	1	reject_item	advance_item	27	Item kasbon ditolak: asd	\N	2026-04-18 14:28:54.476858	/advances/28
264	1	1	submit	advance	28	Anevril Chairu melakukan submit kasbon: asd	\N	2026-04-18 14:29:21.734222	/advances/28
265	1	1	submit_confirmation	advance	28	Kasbon "asd" Anda telah disubmit	\N	2026-04-18 14:29:21.738224	/advances/28
266	1	1	approve_item	advance_item	27	Item kasbon disetujui: asd	\N	2026-04-18 14:29:23.83929	/advances/28
267	1	1	reject_item	advance_item	27	Item kasbon ditolak: asd	\N	2026-04-18 14:29:27.067184	/advances/28
268	1	1	reject_expense	expense	566	Expense ditolak: 23	\N	2026-04-18 14:55:35.179714	/settlements/174
269	1	1	submit	settlement	174	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-18 15:01:46.670472	/settlements/174
270	1	1	submit_confirmation	settlement	174	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-18 15:01:46.674494	/settlements/174
271	1	1	approve_expense	expense	566	Expense disetujui: 23	\N	2026-04-18 15:01:50.554638	/settlements/174
272	1	1	reject_expense	expense	566	Expense ditolak: 23	\N	2026-04-18 15:01:53.760712	/settlements/174
273	1	1	submit	settlement	174	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-18 15:02:17.931336	/settlements/174
274	1	1	submit_confirmation	settlement	174	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-18 15:02:17.935316	/settlements/174
275	1	1	approve_expense	expense	566	Expense disetujui: 23	\N	2026-04-18 15:02:21.0272	/settlements/174
276	1	1	submit	advance	29	Anevril Chairu melakukan submit kasbon: wfsedf	\N	2026-04-18 15:02:37.498101	/advances/29
277	1	1	submit_confirmation	advance	29	Kasbon "wfsedf" Anda telah disubmit	\N	2026-04-18 15:02:37.503226	/advances/29
278	1	1	reject_item	advance_item	28	Item kasbon ditolak: wfsedf	\N	2026-04-18 15:02:40.824121	/advances/29
279	1	1	submit	advance	29	Anevril Chairu melakukan submit kasbon: wfsedf	\N	2026-04-18 15:02:52.660315	/advances/29
280	1	1	submit_confirmation	advance	29	Kasbon "wfsedf" Anda telah disubmit	\N	2026-04-18 15:02:52.664716	/advances/29
281	1	1	approve_item	advance_item	28	Item kasbon disetujui: wfsedf	\N	2026-04-18 15:02:56.242632	/advances/29
282	1	1	reject_item	advance_item	28	Item kasbon ditolak: wfsedf	\N	2026-04-18 15:02:59.141824	/advances/29
283	1	1	submit	advance	29	Anevril Chairu melakukan submit kasbon: wfsedf	\N	2026-04-18 15:03:26.567362	/advances/29
284	1	1	submit_confirmation	advance	29	Kasbon "wfsedf" Anda telah disubmit	\N	2026-04-18 15:03:26.570931	/advances/29
285	1	1	approve_item	advance_item	28	Item kasbon disetujui: wfsedf	\N	2026-04-18 15:03:28.676876	/advances/29
286	1	1	reject_item	advance_item	28	Item kasbon ditolak: wfsedf	\N	2026-04-18 15:03:32.070603	/advances/29
287	1	1	approve_item	advance_item	28	Item kasbon disetujui: wfsedf	\N	2026-04-18 15:04:09.196693	/advances/29
288	1	1	reject_item	advance_item	28	Item kasbon ditolak: wfsedf	\N	2026-04-18 15:05:13.308315	/advances/29
289	1	1	reject_item	advance_item	28	Item kasbon ditolak: wfsedf	\N	2026-04-18 15:05:17.150042	/advances/29
290	1	1	reject_item	advance_item	28	Item kasbon ditolak: wfsedf	\N	2026-04-18 15:05:20.246895	/advances/29
291	1	1	submit	advance	29	Anevril Chairu melakukan submit kasbon: wfsedf	\N	2026-04-18 15:06:50.914326	/advances/29
292	1	1	submit_confirmation	advance	29	Kasbon "wfsedf" Anda telah disubmit	\N	2026-04-18 15:06:50.918219	/advances/29
293	1	1	approve_item	advance_item	28	Item kasbon disetujui: wfsedf	\N	2026-04-18 15:06:53.883598	/advances/29
294	1	1	reject_item	advance_item	28	Item kasbon ditolak: wfsedf	\N	2026-04-18 15:06:59.445472	/advances/29
295	1	1	submit	advance	29	Anevril Chairu melakukan submit kasbon: wfsedf	\N	2026-04-18 15:07:06.612827	/advances/29
296	1	1	submit_confirmation	advance	29	Kasbon "wfsedf" Anda telah disubmit	\N	2026-04-18 15:07:06.618872	/advances/29
297	1	1	approve_item	advance_item	28	Item kasbon disetujui: wfsedf	\N	2026-04-18 15:07:07.387244	/advances/29
298	1	1	approve	advance	29	Kasbon Anda telah disetujui: wfsedf	\N	2026-04-18 15:07:09.32491	/advances/29
299	1	1	submit	settlement	175	Anevril Chairu melakukan submit settlement: wfsedf	\N	2026-04-18 15:07:20.093664	/settlements/175
300	1	1	submit_confirmation	settlement	175	Settlement "wfsedf" Anda telah disubmit	\N	2026-04-18 15:07:20.098224	/settlements/175
301	1	1	approve_expense	expense	567	Expense disetujui: wfsedf	\N	2026-04-18 15:09:03.53555	/settlements/175
302	1	1	reject_expense	expense	567	Expense ditolak: wfsedf	\N	2026-04-18 15:09:07.82688	/settlements/175
303	1	1	submit	settlement	175	Anevril Chairu melakukan submit settlement: wfsedf	\N	2026-04-18 15:09:16.615072	/settlements/175
304	1	1	submit_confirmation	settlement	175	Settlement "wfsedf" Anda telah disubmit	\N	2026-04-18 15:09:16.619105	/settlements/175
305	1	1	approve_expense	expense	567	Expense disetujui: wfsedf	\N	2026-04-18 15:09:20.068538	/settlements/175
306	1	1	approve	settlement	175	Settlement Anda telah disetujui: wfsedf	\N	2026-04-18 15:09:21.117608	/settlements/175
307	1	1	submit	advance	29	Anevril Chairu melakukan submit kasbon: asdasd	\N	2026-04-18 15:17:31.804272	/advances/29
308	1	1	submit_confirmation	advance	29	Kasbon "asdasd" Anda telah disubmit	\N	2026-04-18 15:17:31.818823	/advances/29
309	1	1	approve_item	advance_item	28	Item kasbon disetujui: asdasd	\N	2026-04-18 15:17:32.686825	/advances/29
310	1	1	approve	advance	29	Kasbon Anda telah disetujui: asdasd	\N	2026-04-18 15:17:34.24522	/advances/29
311	1	1	submit	settlement	175	Anevril Chairu melakukan submit settlement: asdasd	\N	2026-04-18 15:17:41.04824	/settlements/175
312	1	1	submit_confirmation	settlement	175	Settlement "asdasd" Anda telah disubmit	\N	2026-04-18 15:17:41.061072	/settlements/175
313	1	1	approve_expense	expense	567	Expense disetujui: asdasd	\N	2026-04-18 15:17:46.256877	/settlements/175
314	1	1	approve	settlement	175	Settlement Anda telah disetujui: asdasd	\N	2026-04-18 15:17:48.005871	/settlements/175
315	1	1	submit	settlement	175	Anevril Chairu melakukan submit settlement: asdasd	\N	2026-04-18 15:18:21.556663	/settlements/175
316	1	1	submit_confirmation	settlement	175	Settlement "asdasd" Anda telah disubmit	\N	2026-04-18 15:18:21.560791	/settlements/175
317	1	1	approve_expense	expense	567	Expense disetujui: asdasd	\N	2026-04-18 15:18:25.256578	/settlements/175
318	1	1	approve	settlement	175	Settlement Anda telah disetujui: asdasd	\N	2026-04-18 15:18:26.123051	/settlements/175
319	1	1	submit	advance	30	Anevril Chairu melakukan submit kasbon: weqwe	\N	2026-04-20 22:35:05.93812	/advances/30
320	1	1	submit_confirmation	advance	30	Kasbon "weqwe" Anda telah disubmit	\N	2026-04-20 22:35:05.94324	/advances/30
321	1	1	reject_item	advance_item	29	Item kasbon ditolak: weqwe	\N	2026-04-20 22:35:24.966853	/advances/30
322	1	1	submit	advance	31	Anevril Chairu melakukan submit kasbon: qweqwe	\N	2026-04-21 00:30:51.282295	/advances/31
323	1	1	submit_confirmation	advance	31	Kasbon "qweqwe" Anda telah disubmit	\N	2026-04-21 00:30:51.285872	/advances/31
324	1	1	reject_item	advance_item	30	Item kasbon ditolak: qweqwe	\N	2026-04-21 00:30:54.813062	/advances/31
325	1	1	submit	advance	28	Anevril Chairu melakukan submit kasbon: asd	\N	2026-04-21 00:31:31.593206	/advances/28
326	1	1	submit_confirmation	advance	28	Kasbon "asd" Anda telah disubmit	\N	2026-04-21 00:31:31.597719	/advances/28
327	1	1	reject_item	advance_item	27	Item kasbon ditolak: asd	\N	2026-04-21 00:31:48.410751	/advances/28
328	1	1	submit	settlement	176	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-21 00:32:30.731972	/settlements/176
329	1	1	submit_confirmation	settlement	176	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-21 00:32:30.736213	/settlements/176
330	1	1	reject_expense	expense	568	Expense ditolak: qweqw	\N	2026-04-21 00:32:49.867661	/settlements/176
331	1	1	submit	settlement	176	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-21 00:34:25.47407	/settlements/176
332	1	1	submit_confirmation	settlement	176	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-21 00:34:25.477806	/settlements/176
333	1	1	approve_expense	expense	568	Expense disetujui: qweqw	\N	2026-04-21 00:34:48.82647	/settlements/176
334	1	1	approve	settlement	176	Settlement Anda telah disetujui: Pengeluaran Sendiri	\N	2026-04-21 00:34:53.153524	/settlements/176
335	1	1	submit	advance	32	Anevril Chairu melakukan submit kasbon: asdasd	\N	2026-04-21 00:58:42.82273	/advances/32
336	1	1	submit_confirmation	advance	32	Kasbon "asdasd" Anda telah disubmit	\N	2026-04-21 00:58:42.827782	/advances/32
337	1	1	reject_item	advance_item	31	Item kasbon ditolak: wqeqwe	\N	2026-04-21 00:58:46.352254	/advances/32
338	1	1	approve_item	advance_item	32	Item kasbon disetujui: 213123	\N	2026-04-21 00:58:49.075532	/advances/32
339	1	1	submit	advance	32	Anevril Chairu melakukan submit kasbon: asdasd	\N	2026-04-21 00:59:11.721726	/advances/32
340	1	1	submit_confirmation	advance	32	Kasbon "asdasd" Anda telah disubmit	\N	2026-04-21 00:59:11.726242	/advances/32
341	1	1	approve_item	advance_item	31	Item kasbon disetujui: wqeqwe	\N	2026-04-21 00:59:13.075089	/advances/32
342	1	1	reject_item	advance_item	31	Item kasbon ditolak: wqeqwe	\N	2026-04-21 00:59:15.656186	/advances/32
343	1	1	submit	advance	32	Anevril Chairu melakukan submit kasbon: asdasd	\N	2026-04-21 00:59:37.565584	/advances/32
344	1	1	submit_confirmation	advance	32	Kasbon "asdasd" Anda telah disubmit	\N	2026-04-21 00:59:37.570137	/advances/32
345	1	1	approve_item	advance_item	31	Item kasbon disetujui: wqeqwe	\N	2026-04-21 00:59:38.442215	/advances/32
346	1	1	approve	advance	32	Kasbon Anda telah disetujui: asdasd	\N	2026-04-21 00:59:39.914712	/advances/32
347	1	1	submit	settlement	186	Anevril Chairu melakukan submit settlement: asdasd	\N	2026-04-21 00:59:53.153084	/settlements/186
348	1	1	submit_confirmation	settlement	186	Settlement "asdasd" Anda telah disubmit	\N	2026-04-21 00:59:53.15627	/settlements/186
349	1	1	approve_expense	expense	570	Expense disetujui: wqeqwe	\N	2026-04-21 01:00:01.580446	/settlements/186
350	1	1	reject_expense	expense	571	Expense ditolak: 213123	\N	2026-04-21 01:00:21.993059	/settlements/186
351	1	1	submit	settlement	186	Anevril Chairu melakukan submit settlement: asdasd	\N	2026-04-21 01:00:57.244935	/settlements/186
352	1	1	submit_confirmation	settlement	186	Settlement "asdasd" Anda telah disubmit	\N	2026-04-21 01:00:57.247446	/settlements/186
353	1	1	approve_expense	expense	571	Expense disetujui: 213123	\N	2026-04-21 01:02:03.644942	/settlements/186
354	1	1	reject_expense	expense	571	Expense ditolak: 213123	\N	2026-04-21 01:02:06.496042	/settlements/186
355	1	1	submit	settlement	186	Anevril Chairu melakukan submit settlement: asdasd	\N	2026-04-21 01:02:14.206637	/settlements/186
356	1	1	submit_confirmation	settlement	186	Settlement "asdasd" Anda telah disubmit	\N	2026-04-21 01:02:14.210186	/settlements/186
357	1	1	approve_expense	expense	571	Expense disetujui: 213123	\N	2026-04-21 01:02:17.497361	/settlements/186
358	1	1	approve	settlement	186	Settlement Anda telah disetujui: asdasd	\N	2026-04-21 01:02:18.759331	/settlements/186
359	1	1	reject_expense	expense	566	Expense ditolak: 23	\N	2026-04-21 01:02:30.015719	/settlements/174
360	1	1	submit	settlement	174	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-21 01:02:45.955167	/settlements/174
361	1	1	submit_confirmation	settlement	174	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-21 01:02:45.958847	/settlements/174
362	1	1	submit	advance	33	Anevril Chairu melakukan submit kasbon: lala	\N	2026-04-21 01:52:39.432686	/advances/33
363	1	1	submit_confirmation	advance	33	Kasbon "lala" Anda telah disubmit	\N	2026-04-21 01:52:39.434984	/advances/33
364	1	1	approve_item	advance_item	33	Item kasbon disetujui: jsj	\N	2026-04-21 01:52:43.357787	/advances/33
365	1	1	approve	advance	33	Kasbon Anda telah disetujui: lala	\N	2026-04-21 01:52:45.681858	/advances/33
366	1	1	submit	settlement	187	Anevril Chairu melakukan submit settlement: lala	\N	2026-04-21 01:53:17.845158	/settlements/187
367	1	1	submit_confirmation	settlement	187	Settlement "lala" Anda telah disubmit	\N	2026-04-21 01:53:17.847666	/settlements/187
368	1	1	approve_expense	expense	572	Expense disetujui: jsj	\N	2026-04-21 01:53:35.653442	/settlements/187
369	1	1	approve	settlement	187	Settlement Anda telah disetujui: lala	\N	2026-04-21 01:53:38.416682	/settlements/187
370	1	1	submit	settlement	231	Anevril Chairu melakukan submit settlement: 2029diooooooooooooo	\N	2026-04-21 21:14:07.404283	/settlements/231
371	1	1	submit_confirmation	settlement	231	Settlement "2029diooooooooooooo" Anda telah disubmit	\N	2026-04-21 21:14:07.408299	/settlements/231
372	1	1	reject_expense	expense	566	Expense ditolak: 23	\N	2026-04-21 21:14:51.158273	/settlements/174
373	1	1	submit	settlement	174	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-21 21:15:05.656676	/settlements/174
374	1	1	submit_confirmation	settlement	174	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-21 21:15:05.661714	/settlements/174
375	1	1	submit	settlement	233	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-21 21:21:26.156833	/settlements/233
376	1	1	submit_confirmation	settlement	233	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-21 21:21:26.160703	/settlements/233
377	1	1	submit	settlement	174	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	\N	2026-04-21 21:58:58.905922	/settlements/174
378	1	1	submit_confirmation	settlement	174	Settlement "Pengeluaran Sendiri" Anda telah disubmit	\N	2026-04-21 21:58:58.909446	/settlements/174
379	1	1	approve_expense	expense	566	Expense disetujui: 23	\N	2026-04-21 21:59:04.299379	/settlements/174
380	1	1	approve	settlement	174	Settlement Anda telah disetujui: Pengeluaran Sendiri	\N	2026-04-21 21:59:08.952122	/settlements/174
381	5	1	submit	advance	40	Anevril Chairu melakukan submit kasbon: qweqwe	f	2026-04-23 02:58:59.453852	/advances/40
382	1	1	submit	advance	40	Anevril Chairu melakukan submit kasbon: qweqwe	f	2026-04-23 02:58:59.460463	/advances/40
383	1	1	submit_confirmation	advance	40	Kasbon "qweqwe" Anda telah disubmit	f	2026-04-23 02:58:59.463465	/advances/40
384	1	1	reject_item	advance_item	36	Item kasbon ditolak: qweqwe	f	2026-04-23 02:59:07.235146	/advances/40
385	5	1	submit	advance	40	Anevril Chairu melakukan submit kasbon: qweqwe	f	2026-04-23 03:09:48.168912	/advances/40
386	1	1	submit	advance	40	Anevril Chairu melakukan submit kasbon: qweqwe	f	2026-04-23 03:09:48.175184	/advances/40
387	1	1	submit_confirmation	advance	40	Kasbon "qweqwe" Anda telah disubmit	f	2026-04-23 03:09:48.177184	/advances/40
388	1	1	reject_item	advance_item	36	Item kasbon ditolak: qweqwe	f	2026-04-23 03:09:53.786907	/advances/40
389	5	1	submit	advance	40	Anevril Chairu melakukan submit kasbon: qweqwe	f	2026-04-23 03:10:27.751146	/advances/40
390	1	1	submit	advance	40	Anevril Chairu melakukan submit kasbon: qweqwe	f	2026-04-23 03:10:27.752673	/advances/40
391	1	1	submit_confirmation	advance	40	Kasbon "qweqwe" Anda telah disubmit	f	2026-04-23 03:10:27.753769	/advances/40
392	1	1	approve_item	advance_item	36	Item kasbon disetujui: qweqwe	f	2026-04-23 03:10:29.336934	/advances/40
393	1	1	reject_item	advance_item	36	Item kasbon ditolak: qweqwe	f	2026-04-23 03:10:33.094056	/advances/40
394	5	1	submit	advance	40	Anevril Chairu melakukan submit kasbon: qweqwe	f	2026-04-23 03:10:45.281397	/advances/40
395	1	1	submit	advance	40	Anevril Chairu melakukan submit kasbon: qweqwe	f	2026-04-23 03:10:45.28204	/advances/40
396	1	1	submit_confirmation	advance	40	Kasbon "qweqwe" Anda telah disubmit	f	2026-04-23 03:10:45.284615	/advances/40
397	1	1	approve_item	advance_item	36	Item kasbon disetujui: qweqwe	f	2026-04-23 03:10:48.845281	/advances/40
398	1	1	approve	advance	40	Kasbon Anda telah disetujui: qweqwe	f	2026-04-23 03:10:49.837911	/advances/40
399	5	1	submit	settlement	239	Anevril Chairu melakukan submit settlement: qweqwe	f	2026-04-23 03:39:29.798744	/settlements/239
400	1	1	submit	settlement	239	Anevril Chairu melakukan submit settlement: qweqwe	f	2026-04-23 03:39:29.799761	/settlements/239
401	1	1	submit_confirmation	settlement	239	Settlement "qweqwe" Anda telah disubmit	f	2026-04-23 03:39:29.807117	/settlements/239
402	1	1	reject_expense	expense	579	Expense ditolak: qweqwe	f	2026-04-23 03:39:38.649852	/settlements/239
403	5	1	submit	settlement	239	Anevril Chairu melakukan submit settlement: qweqwe	f	2026-04-23 03:54:37.997066	/settlements/239
404	1	1	submit	settlement	239	Anevril Chairu melakukan submit settlement: qweqwe	f	2026-04-23 03:54:37.998842	/settlements/239
405	1	1	submit_confirmation	settlement	239	Settlement "qweqwe" Anda telah disubmit	f	2026-04-23 03:54:38.000939	/settlements/239
406	1	1	approve_expense	expense	579	Expense disetujui: qweqwe	f	2026-04-23 03:54:42.210543	/settlements/239
407	1	1	reject_expense	expense	579	Expense ditolak: qweqwe	f	2026-04-23 03:54:46.948632	/settlements/239
408	5	1	submit	settlement	239	Anevril Chairu melakukan submit settlement: qweqwe	f	2026-04-23 03:55:30.320426	/settlements/239
409	1	1	submit	settlement	239	Anevril Chairu melakukan submit settlement: qweqwe	f	2026-04-23 03:55:30.322482	/settlements/239
410	1	1	submit_confirmation	settlement	239	Settlement "qweqwe" Anda telah disubmit	f	2026-04-23 03:55:30.323307	/settlements/239
411	1	1	approve_expense	expense	579	Expense disetujui: qweqwe	f	2026-04-23 03:55:33.192021	/settlements/239
412	1	1	approve	settlement	239	Settlement Anda telah disetujui: qweqwe	f	2026-04-23 03:55:37.561298	/settlements/239
413	5	1	submit	settlement	143	Anevril Chairu melakukan submit settlement: sdfds	f	2026-04-26 11:42:01.189096	/settlements/143
414	1	1	submit	settlement	143	Anevril Chairu melakukan submit settlement: sdfds	f	2026-04-26 11:42:01.204415	/settlements/143
415	1	1	submit_confirmation	settlement	143	Settlement "sdfds" Anda telah disubmit	f	2026-04-26 11:42:01.208968	/settlements/143
416	5	1	submit	settlement	240	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	f	2026-04-26 13:15:04.37902	/settlements/240
417	1	1	submit	settlement	240	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	f	2026-04-26 13:15:04.380678	/settlements/240
418	1	1	submit_confirmation	settlement	240	Settlement "Pengeluaran Sendiri" Anda telah disubmit	f	2026-04-26 13:15:04.382787	/settlements/240
419	1	1	reject_expense	expense	580	Expense ditolak: jfjdj	f	2026-04-26 13:15:37.509362	/settlements/240
420	1	1	approve_expense	expense	533	Expense disetujui: sdfsdf	f	2026-04-26 13:16:28.744863	/settlements/145
421	1	1	approve	settlement	145	Settlement Anda telah disetujui: sdfsdf	f	2026-04-26 13:16:31.327758	/settlements/145
422	5	1	submit	settlement	241	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	f	2026-04-26 13:44:57.53677	/settlements/241
423	1	1	submit	settlement	241	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	f	2026-04-26 13:44:57.538979	/settlements/241
424	1	1	submit_confirmation	settlement	241	Settlement "Pengeluaran Sendiri" Anda telah disubmit	f	2026-04-26 13:44:57.540484	/settlements/241
425	1	1	reject_expense	expense	581	Expense ditolak: hhjh	f	2026-04-26 13:45:08.842116	/settlements/241
426	5	1	submit	settlement	241	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	f	2026-04-26 13:46:02.572263	/settlements/241
427	1	1	submit	settlement	241	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	f	2026-04-26 13:46:02.573719	/settlements/241
428	1	1	submit_confirmation	settlement	241	Settlement "Pengeluaran Sendiri" Anda telah disubmit	f	2026-04-26 13:46:02.573719	/settlements/241
429	5	1	submit	advance	41	Anevril Chairu melakukan submit kasbon: yjjh	f	2026-04-26 13:47:01.995781	/advances/41
430	1	1	submit	advance	41	Anevril Chairu melakukan submit kasbon: yjjh	f	2026-04-26 13:47:01.997624	/advances/41
431	1	1	submit_confirmation	advance	41	Kasbon "yjjh" Anda telah disubmit	f	2026-04-26 13:47:01.998623	/advances/41
432	1	1	reject_item	advance_item	37	Item kasbon ditolak: yjjh	f	2026-04-26 13:47:07.514059	/advances/41
433	5	1	submit	settlement	240	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	f	2026-04-26 14:06:42.744405	/settlements/240
434	1	1	submit	settlement	240	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	f	2026-04-26 14:06:42.744405	/settlements/240
435	1	1	submit_confirmation	settlement	240	Settlement "Pengeluaran Sendiri" Anda telah disubmit	f	2026-04-26 14:06:42.751264	/settlements/240
436	1	1	reject_expense	expense	580	Expense ditolak: jfjdj	f	2026-04-26 14:06:49.899551	/settlements/240
437	5	1	submit	settlement	240	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	f	2026-04-26 14:09:13.951273	/settlements/240
443	1	1	submit_confirmation	advance	41	Kasbon "yjjh" Anda telah disubmit	f	2026-04-26 14:12:03.053834	/advances/41
438	1	1	submit	settlement	240	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	f	2026-04-26 14:09:13.951273	/settlements/240
439	1	1	submit_confirmation	settlement	240	Settlement "Pengeluaran Sendiri" Anda telah disubmit	f	2026-04-26 14:09:13.951273	/settlements/240
440	1	1	reject_expense	expense	580	Expense ditolak: jfjdj	f	2026-04-26 14:09:22.751737	/settlements/240
441	5	1	submit	advance	41	Anevril Chairu melakukan submit kasbon: yjjh	f	2026-04-26 14:12:03.049564	/advances/41
442	1	1	submit	advance	41	Anevril Chairu melakukan submit kasbon: yjjh	f	2026-04-26 14:12:03.05162	/advances/41
445	5	1	submit	advance	41	Anevril Chairu melakukan submit kasbon: yjjh	f	2026-04-26 14:12:24.06009	/advances/41
446	1	1	submit	advance	41	Anevril Chairu melakukan submit kasbon: yjjh	f	2026-04-26 14:12:24.063404	/advances/41
444	1	1	reject_item	advance_item	37	Item kasbon ditolak: yjjh	f	2026-04-26 14:12:08.749761	/advances/41
447	1	1	submit_confirmation	advance	41	Kasbon "yjjh" Anda telah disubmit	f	2026-04-26 14:12:24.064458	/advances/41
448	1	1	approve_item	advance_item	37	Item kasbon disetujui: yjjh	f	2026-04-26 14:12:26.038633	/advances/41
449	5	1	submit	settlement	240	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	f	2026-04-26 15:14:22.269816	/settlements/240
450	1	1	submit	settlement	240	Anevril Chairu melakukan submit settlement: Pengeluaran Sendiri	f	2026-04-26 15:14:22.280182	/settlements/240
451	1	1	submit_confirmation	settlement	240	Settlement "Pengeluaran Sendiri" Anda telah disubmit	f	2026-04-26 15:14:22.283239	/settlements/240
452	1	1	approve_expense	expense	580	Expense disetujui: jfjdj	f	2026-04-26 15:14:24.076735	/settlements/240
453	1	1	reject_expense	expense	580	Expense ditolak: jfjdj	f	2026-04-26 15:26:53.857061	/settlements/240
454	5	1	submit	advance	28	Anevril Chairu melakukan submit kasbon: asd	f	2026-04-26 16:23:02.210255	/advances/28
455	1	1	submit	advance	28	Anevril Chairu melakukan submit kasbon: asd	f	2026-04-26 16:23:02.217779	/advances/28
456	1	1	submit_confirmation	advance	28	Kasbon "asd" Anda telah disubmit	f	2026-04-26 16:23:02.222092	/advances/28
\.


--
-- Data for Name: revenues; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.revenues (id, invoice_date, description, invoice_value, currency, currency_exchange, invoice_number, client, receive_date, amount_received, ppn, pph_23, transfer_fee, remark, revenue_type, created_at) FROM stdin;
1	2025-02-01	Invoice untuk project bulan Jan 2025	11100000	IDR	\N	INV-2025-001	PT Maju Jaya	\N	10000000	1100000	200000	\N	\N	pendapatan_langsung	2026-03-10 14:58:17.746608
2	2024-01-11	ALFA Service PDP-075 Pertamina Zona#4	354210000	IDR	1	INV017	SI Jak	2024-02-28	347125800	38963100	7084200	0	Pemungut	pendapatan_langsung	2026-03-11 12:39:59
3	2024-01-10	Revenue data procesing MTD_Tomori	150000000	IDR	1	INV015	TGE	2024-04-17	166500000	16500000	3000000	0	\N	pendapatan_langsung	2026-03-11 12:39:59
4	2024-01-11	ALFA Service PDS-01ST Pertamina Zona#4	354210000	IDR	1	INV019	SI Jak	2024-05-13	347125800	38963100	7084200	0	Pemungut	pendapatan_langsung	2026-03-11 12:39:59
5	2024-01-11	ALFA Service JRK-254 Pertamina Zona#4	354210000	IDR	1	INV018	SI Jak	2024-06-10	347125800	38963100	7084200	0	Pemungut	pendapatan_langsung	2026-03-11 12:39:59
6	2024-06-03	ALFA Service TLJ-58 Pertamina Zona#4	354210000	IDR	1	INV020	SI Jak	2024-07-24	347125800	38963100	7084200	0	Pemungut	pendapatan_langsung	2026-03-11 12:39:59
7	2024-06-04	ALFA Service JRK-193 Pertamina Zona#4	354210000	IDR	1	INV021	SI Jak	2024-08-12	347125800	38963100	7084200	0	Pemungut	pendapatan_langsung	2026-03-11 12:39:59
8	2024-09-04	Revenue Repair Electric Assisted Stimulation Machine (no 23)	89000000	IDR	1	INV023	LBU	2024-09-18	96920000	9790000	1780000	0	\N	pendapatan_langsung	2026-03-11 12:39:59
9	2024-09-02	ALFA Service JRK-163 Pertamina Zona#4	354210000	IDR	1	INV022	SI Jak	2024-10-10	347125800	38963100	7084200	0	Pemungut	pendapatan_langsung	2026-03-11 12:39:59
10	2024-10-11	Revenue Project TIS (no 28 )	819200000	IDR	1	INV028	Barikin Sakti	2024-10-14	892928000	90112000	16384000	0	\N	pendapatan_langsung	2026-03-11 12:39:59
11	2024-10-07	ALFA Service JRK-095 Pertamina Zona#4	354210000	IDR	1	INV027	SI Jak	2024-11-11	347125800	38963100	7084200	0	Pemungut	pendapatan_langsung	2026-03-11 12:39:59
12	2024-10-04	ALFA Service TGB-033 Pertamina Cirebon	290000000	IDR	1	INV024	Elnusa	2024-12-20	284197100	31900000	5800000	2900	Pemungut	pendapatan_langsung	2026-03-11 12:39:59
13	2024-10-04	MFC Service TGB-033 Pertamina Cirebon	280000000	IDR	1	INV025	Elnusa	2024-12-27	412577100	30800000	5600000	2900	Pemungut	pendapatan_langsung	2026-03-11 12:39:59
14	2024-10-04	PLT Service TGB-033 Pertamina Cirebon	141000000	IDR	\N	INV026	Elnusa	2024-12-27	0	15510000	2820000	0		pendapatan_langsung	\N
15	2024-12-31	Bunga Bank 2024	6925425	IDR	1			\N	6925425	\N	\N	\N		pendapatan_lain_lain	2026-03-11 12:39:59
16	2026-04-02	as123123	123123	idr	123123	asdas	123123	\N	12312	31231	123123	123123123	asdas	pendapatan_lain_lain	2026-04-02 08:42:01.56833
17	2026-04-03	32342342	234234	IDR234234	423	23432	423423	2024-01-04	23432	23423	23423	234234	234324	pendapatan_lain_lain	2026-04-02 17:02:28.560209
\.


--
-- Data for Name: settlements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.settlements (id, title, description, user_id, settlement_type, status, report_year, created_at, updated_at, completed_at, advance_id) FROM stdin;
1	ALFA Service PDP-075 Pertamina Zona#4 - Rental Tool	Imported from Sheet1 row 41	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
2	ALFA Service PDS-01ST Pertamina Zona#4 - Rental Tool	Imported from Sheet1 row 42	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
3	ALFA Service JRK-254 Pertamina Zona#4 - Rental Tool	Imported from Sheet1 row 43	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
4	Sales cost 4 Well Integrity Pertamina Z.4	Imported from Sheet1 row 44	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
5	Gaji Januari 2024 _Yufitri	Imported from Sheet1 row 45	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
6	Gaji Februari 2024 + raple gaji Januari 2024_Yufitri	Imported from Sheet1 row 46	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
7	Ralika Jaya Utama | Permbuatan alat Downhole Wireless Telemetry	Imported from Sheet1 row 47	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
8	Gaji Maret 2024_Yufitri	Imported from Sheet1 row 48	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
9	THR 2024_Yufitri	Imported from Sheet1 row 49	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
10	Data proccesing MTD 4 well, project Tomori-Alan	Imported from Sheet1 row 50	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
11	Gaji April_Yufitri	Imported from Sheet1 row 51	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
12	Ralika Jaya Utama | Permbuatan alat Downhole Wireless Telemetry	Imported from Sheet1 row 52	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
13	Aro Energy | Moving slickline dari Duri (Toni Supriadi) ke Sungai lilin	Imported from Sheet1 row 53	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
14	ALFA Service TLJ-58 Pertamina Zona#4 - Rental Tool	Imported from Sheet1 row 54	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
15	PT Laka Indonesia |  Wastafel for WIKA Anantara Ubud Bali	Imported from Sheet1 row 55	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
16	Gaji Mei_Yufitri	Imported from Sheet1 row 56	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
17	ALFA Service JRK-193 Pertamina Zona#4 - Rental Tool	Imported from Sheet1 row 57	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
18	Gaji Juni 2024_Yufitri	Imported from Sheet1 row 58	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
19	Downhole Sampling tool #1-1 GARINDO SARANA BARU	Imported from Sheet1 row 59	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
20	Kekurangan (PPN ) ke PT Garindo sarana Baru (Downhole Sampling)	Imported from Sheet1 row 60	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
21	Repair ESOR panel & Fabricate dummy test load, Payment#2	Imported from Sheet1 row 61	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
22	PT Laka Indonesia |  Wastafel for WIKA Anantara Ubud Bali	Imported from Sheet1 row 62	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
23	Pembelian Lisence Sonoechometer to PT Weebz Mandiri	Imported from Sheet1 row 63	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
24	PT Laka Indonesia |  Wastafel for WIKA Anantara Ubud Bali	Imported from Sheet1 row 64	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
25	Repair ESOR panel & Fabricate dummy test load, Payment#1	Imported from Sheet1 row 65	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
26	Gaji Juli 2024_Yufitri	Imported from Sheet1 row 66	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
27	Handphone Operational untuk Secretary (Yufitri)	Imported from Sheet1 row 67	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
28	Ralika Jaya Utama | Permbuatan alat injeksi listrik (EAS)	Imported from Sheet1 row 68	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
29	MUTRI | Sewa ruangan kantor BBC 2 bulan	Imported from Sheet1 row 69	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
30	Downhole Sampling tool #1-2 GARINDO SARANA BARU	Imported from Sheet1 row 70	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
31	Data proccesing TGB-33 DAN TIS (RBG-3b)-Alan	Imported from Sheet1 row 71	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
32	Gaji Agustus 2024_Yufitri	Imported from Sheet1 row 72	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
33	ALFA Service JRK-163 Pertamina Zona#4 - Rental Tool	Imported from Sheet1 row 73	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
34	MUTRI | Penambahan modal biaya kerja	Imported from Sheet1 row 74	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
35	Ralika Jaya Utama | Permbuatan alat EMR	Imported from Sheet1 row 75	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
36	Downhole Sampling tool #2 GARINDO SARANA BARU	Imported from Sheet1 row 76	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
37	Gaji fitri bulan september 2024	Imported from Sheet1 row 77	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
38	Gaji fitri bulan October 2024	Imported from Sheet1 row 78	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
39	PLT Service TGB-033 Pertamina Cirebon - Rental Tool	Imported from Sheet1 row 79	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
40	ALFA Service TGB-033 Pertamina Cirebon - Rental Tool	Imported from Sheet1 row 80	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
41	MFC Service TGB-033 Pertamina Cirebon - Rental Tool	Imported from Sheet1 row 81	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
42	ALFA Service JRK-095 Pertamina Zona#4 - Rental Tool	Imported from Sheet1 row 82	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
43	MPLT/GR-CCL/ALFA TIS - Rental Tool	Imported from Sheet1 row 83	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
44	PT Laka Indonesia | Project Lampu Taman Istana Negara Jakarta	Imported from Sheet1 row 84	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
45	Data Processing 8 Well Alan Project SIJAK	Imported from Sheet1 row 85	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
46	Sales fee 2 Well Integrity Pertamina Z.4	Imported from Sheet1 row 86	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
47	MUTRI | Penambahan modal biaya kerja 3rd	Imported from Sheet1 row 87	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
48	Gaji fitri bulan November 2024	Imported from Sheet1 row 88	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
49	Payment ke UPS Biaya Import pembelian sparepart dari Pei-Genesis	Imported from Sheet1 row 89	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
50	Ralika Jaya Utama | Permbuatan alat injeksi listrik (EAS)	Imported from Sheet1 row 90	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
199	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:39:20.11055	2026-04-21 17:39:20.11055	\N	\N
51	Sewa Virtual Office 1th, 1jan25 - 31des25_BBC_ Ganesha Dwipaya B	Imported from Sheet1 row 91	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
52	Team building EWI dengan team Well Intervention PEP Reg. 2	Imported from Sheet1 row 92	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
53	Gaji Desember 2024 + Bomnus akhir tahun - 4 bulan_Yufitri	Imported from Sheet1 row 93	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
54	KUPA | Pembelian Mesin Retort Horizontal 500 Lt Automatic Control	Imported from Sheet1 row 94	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
55	Total Biaya Transaksi Bank selama 1 tahun	Imported from Sheet1 row 96	2	single	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
56	ALFA_ TLJ-58 (PEPZ4-Prabumulih field) SIJak- IC	Imported from Sheet1 row 98	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
57	Training ALFA _TLJ-58 (PEPZ4-Prabumulih field_ Titis Maulana	Imported from Sheet1 row 127	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
58	MPLT (SAKA-UjungPangkah field) GOWell - TGE _IC	Imported from Sheet1 row 145	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
59	Non project (3rd) _ Ivan Chairulsyah	Imported from Sheet1 row 155	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
60	MCU RS PP _Titis Maulana	Imported from Sheet1 row 164	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
61	MPLT (SAKA-UjungPangkah field) by TGE - GOWell project_IC	Imported from Sheet1 row 166	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
62	PLT SRO_ TGB-33 (Jatibarang Field) Elnusa _ IC	Imported from Sheet1 row 185	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
63	Training BST_ PHR-zona 4 (Dwiyanto) (Dwi_Febri dan Ilham)	Imported from Sheet1 row 196	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
64	MFC and ALFA Memory (Jatibarang Field) TGB-033_Elnusa_ AC	Imported from Sheet1 row 209	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
65	ALFA+PLT (TGB-033 Zona 7) Elnusa_TMA	Imported from Sheet1 row 220	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
66	ALFA+MFC (TGB-033 Zona 7) Elnusa_TMA	Imported from Sheet1 row 234	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
67	BOSIET Training -_TMA	Imported from Sheet1 row 248	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
68	Non Trip MCU Dwiyanto	Imported from Sheet1 row 250	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
69	Non project _ MCU - Ilham BR	Imported from Sheet1 row 253	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
70	ALFA Job - Jrk-193 _ OJT_ Ilham BR	Imported from Sheet1 row 255	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
71	ALFA job - JRK-193 OJT - Dwiyanto S	Imported from Sheet1 row 264	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
72	ALFA JRK-193 - project SI_ TMA	Imported from Sheet1 row 280	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
73	Non Trip - BOSIET Training - DS	Imported from Sheet1 row 298	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
74	ALFA JRK-163 (Pending job) - TMA	Imported from Sheet1 row 305	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
75	Preparation TIS Petroleum - TMA	Imported from Sheet1 row 323	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
76	Delivery Tools Sonoecho (KL) - TMA	Imported from Sheet1 row 329	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
77	Non project ( MCU ulang )_ IBR	Imported from Sheet1 row 343	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
78	ALFA job - JRK-163 (Job)_undr Sijak_ DS	Imported from Sheet1 row 349	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
79	ALFA JOB - JRK 163 (training 2nd_ IBR)	Imported from Sheet1 row 374	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
80	TIS-Blora Field-PLT ALFA BHS by BARIKIN - IC	Imported from Sheet1 row 383	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
81	ALFA-MPLT-BHS_ RBG 3B PT. TIS under Barikin sakti _DS	Imported from Sheet1 row 392	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
82	Non tripo 1st -- MCU + Pembelian barang kelengkapan pump AC	Imported from Sheet1 row 408	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
83	ALFA-MPLT-Sampler project TIS Energy Blora_well RBG-3B by Barekin Sakti- AC	Imported from Sheet1 row 438	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
84	ALFA-MPLT-BHS_ RBG 3B PT. TIS under Barikin sakti _TMA	Imported from Sheet1 row 469	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
85	ALFA JOB - PMB 009 (cancel job) - IBR	Imported from Sheet1 row 485	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
86	ALFA PMB-009 (Cancel)_ TMA	Imported from Sheet1 row 491	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
87	ALFA PMB-009 (Cancel)_ TMA	Imported from Sheet1 row 506	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
88	ALFA Job JRK-095 (Jirak) - IBR	Imported from Sheet1 row 517	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
89	ALFA_JRK-095 well (PEPZ4-PEndopo field) SI jakarta _ AC	Imported from Sheet1 row 545	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
90	Trip to Cirebon Meeting MTD job X-ray field with PEP Zona 7 Region2_AC	Imported from Sheet1 row 560	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
91	Non project (follow up MCU concul & inspection tool)_AC_ 2 nd	Imported from Sheet1 row 583	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
92	MTD SKW-26_sukowati_TMA	Imported from Sheet1 row 600	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
93	MTD_STM_HDP 01 s/d 03 well (BHI project ndr Gowell) Sumbawa	Imported from Sheet1 row 614	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
94	Training Basic Sea Survival_IBR	Imported from Sheet1 row 627	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
95	Non trip 1st - project _ Pety cash 1st - YY	Imported from Sheet1 row 636	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
96	Starlink Kit_DS	Imported from Sheet1 row 661	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
97	Pelican Case 1650 TMA	Imported from Sheet1 row 663	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
98	Non trip 3rd (follow up MCU concul & visit KPP and Graha Elnusa)_AC	Imported from Sheet1 row 665	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
99	Meeting presentasi With Elnusa - Bandung &Pembelian Sparepart dari Pei-Genesis.	Imported from Sheet1 row 682	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
100	General Operation_Year 2024 - AM	Imported from Sheet1 row 693	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
200	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:43:33.910878	2026-04-21 17:43:33.910878	\N	\N
101	Non trip - Training BSS - AC	Imported from Sheet1 row 738	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
102	Trip Rakan : BSTTraining at HSSE Training Center PT Pertamina EP Zone 7 Cirebon	Imported from Sheet1 row 740	2	batch	approved	\N	2026-03-11 12:39:59	2026-03-11 12:39:59	2026-03-11 12:39:59	\N
103	Pengeluaran Sendiri		1	single	approved	\N	2026-03-12 09:55:17.939045	2026-03-12 10:31:04.585006	\N	\N
104	belajar bermain bola		1	batch	draft	\N	2026-03-12 10:01:52.034505	2026-03-12 10:01:52.034505	\N	\N
105	gaji	belajar goreng	1	batch	draft	\N	2026-03-12 10:04:42.040042	2026-03-12 10:04:42.040042	\N	\N
106	kerja ke goweel	sdasad	1	batch	approved	\N	2026-03-12 10:05:10.688921	2026-03-12 10:31:16.929507	\N	\N
107	Pengeluaran Sendiri		1	single	approved	\N	2026-03-12 10:11:40.083268	2026-03-12 10:30:48.816712	\N	\N
108	gowel party	asdas	1	batch	approved	\N	2026-03-12 10:35:12.329697	2026-03-12 10:40:03.435192	\N	\N
110	asda	asd	2	batch	draft	\N	2026-03-12 10:50:30.3536	2026-03-12 10:50:30.3536	\N	\N
111	gaji buta		2	batch	draft	\N	2026-03-12 10:54:51.801815	2026-03-12 10:54:51.801815	\N	\N
113	Pengeluaran Sendiri		1	single	approved	\N	2026-03-12 13:29:21.595321	2026-03-24 19:47:50.31821	\N	\N
115	Pengeluaran Sendiri		1	single	approved	\N	2026-03-12 13:33:13.946871	2026-03-12 17:23:50.671238	\N	\N
118	Pengeluaran Sendiri		2	single	draft	\N	2026-03-12 13:44:50.885771	2026-03-12 13:44:50.885771	\N	\N
119	Pengeluaran Batch		2	batch	approved	\N	2026-03-12 13:44:56.022613	2026-03-12 13:46:13.267811	\N	\N
121	Pengeluaran Sendiri		1	single	approved	\N	2026-03-12 15:40:56.396568	2026-03-12 15:51:18.506448	\N	\N
123	Pengeluaran Sendiri		1	single	approved	\N	2026-03-12 16:18:56.023436	2026-03-12 16:19:58.972835	\N	\N
128	Pengeluaran Sendiri		1	single	draft	\N	2026-03-12 17:17:43.54344	2026-03-12 17:17:43.54344	\N	\N
129	Pengeluaran Sendiri		1	single	draft	\N	2026-03-12 18:00:54.746694	2026-03-12 18:00:54.746694	\N	\N
130	11	11	1	single	draft	\N	2026-03-13 15:22:38.553866	2026-03-13 15:22:38.553866	\N	\N
133	Pengeluaran Sendiri		1	single	approved	\N	2026-03-13 17:26:23.967893	2026-03-13 18:08:11.481814	\N	\N
135	diofavian		1	single	approved	\N	2026-03-13 18:13:25.062624	2026-03-13 18:14:52.274649	\N	5
137	asdasd	asdasd	2	single	approved	\N	2026-03-16 04:03:39.696248	2026-03-16 04:04:56.996868	\N	\N
139	Pengeluaran Sendiri		2	single	draft	\N	2026-03-17 04:45:18.735386	2026-03-17 04:45:18.735386	\N	\N
140	kerja sampingan		1	batch	approved	\N	2026-03-18 08:39:44.347182	2026-03-18 18:05:56.743939	\N	\N
141	Pengeluaran Batch		1	batch	approved	\N	2026-03-18 18:25:45.510808	2026-03-18 18:26:35.665438	\N	\N
142	asdasd		1	batch	approved	\N	2026-03-18 18:27:41.954447	2026-03-18 18:28:34.81373	\N	\N
144	asdasd		1	batch	draft	\N	2026-03-21 20:28:30.306022	2026-03-23 21:03:21.849932	\N	\N
146	hari senin	hari senin	1	single	approved	\N	2026-03-21 20:44:30.25579	2026-03-21 20:45:55.37062	\N	\N
147	mercu buana		1	single	submitted	\N	2026-03-21 21:00:24.920992	2026-03-21 21:00:28.662992	\N	9
148	aaaaaaaaaaaaaaaaaaaa		1	single	draft	\N	2026-03-21 21:20:56.127078	2026-03-21 21:20:56.127078	\N	10
149	Pengeluaran Sendiri		1	single	approved	\N	2026-03-22 14:21:41.796887	2026-03-22 15:02:33.376779	\N	\N
150	Pengeluaran Sendiri		1	single	draft	\N	2026-03-22 18:03:26.30204	2026-03-22 18:03:26.30204	\N	\N
151	werwerwerwer		1	single	approved	\N	2026-03-22 18:06:12.070892	2026-03-22 18:08:54.494203	\N	13
152	Pengeluaran Sendiri		1	single	draft	\N	2026-03-23 20:59:33.46799	2026-03-23 20:59:33.46799	\N	\N
153	makanan malam 2026		1	single	submitted	\N	2026-03-23 21:18:28.621294	2026-03-24 19:45:18.770905	\N	8
154	Pengeluaran Sendiri		1	single	draft	\N	2026-03-24 21:55:48.745235	2026-03-24 21:55:48.745235	\N	\N
155	Pengeluaran Sendiri		1	single	draft	\N	2026-04-12 16:56:55.486625	2026-04-12 16:56:55.486625	\N	\N
156	Pengeluaran Sendiri		1	single	draft	\N	2026-04-12 17:06:33.946918	2026-04-12 17:06:33.946918	\N	\N
157	Pengeluaran Sendiri		1	single	draft	\N	2026-04-12 17:07:30.718978	2026-04-12 17:07:30.718978	\N	\N
158	Pengeluaran Sendiri		1	single	approved	\N	2026-04-12 17:42:44.34503	2026-04-12 19:48:16.233203	\N	\N
159	Gudang		1	batch	approved	\N	2026-04-12 19:14:23.049359	2026-04-12 19:38:27.073045	\N	\N
160	sdas		1	batch	approved	\N	2026-04-12 19:48:32.227352	2026-04-12 19:51:33.198303	\N	22
161	asdfs		1	batch	draft	\N	2026-04-18 08:46:14.329195	2026-04-18 08:46:14.329195	\N	\N
162	dfgdfg		1	batch	draft	\N	2026-04-18 08:48:14.950838	2026-04-18 08:48:14.950838	\N	\N
163	wsds		1	batch	draft	\N	2026-04-18 08:54:35.486961	2026-04-18 08:54:35.486961	\N	\N
164	sasdas		1	batch	approved	\N	2026-04-18 11:53:07.190214	2026-04-18 11:55:59.846908	\N	24
165	werwerewr		1	batch	approved	\N	2026-04-18 12:18:22.549736	2026-04-18 12:20:35.389647	\N	\N
166	Pengeluaran Sendiri		1	single	draft	\N	2026-04-18 12:22:13.798218	2026-04-18 12:22:13.798218	\N	\N
167	Pengeluaran Sendiri		1	single	draft	\N	2026-04-18 12:22:50.30664	2026-04-18 12:22:50.30664	\N	\N
168	Pengeluaran Sendiri		1	single	draft	\N	2026-04-18 12:33:55.303614	2026-04-18 12:33:55.303614	\N	\N
169	Pengeluaran Sendiri		1	single	approved	\N	2026-04-18 12:41:32.934665	2026-04-18 12:42:40.484733	\N	\N
170	Pengeluaran Sendiri		1	single	approved	\N	2026-04-18 13:00:27.656744	2026-04-18 13:01:27.394539	\N	\N
171	1234567890		1	batch	approved	\N	2026-04-18 13:28:31.82029	2026-04-18 13:30:41.562379	\N	26
172	werwer		1	batch	approved	\N	2026-04-18 13:32:21.666049	2026-04-18 13:32:37.387409	\N	27
173	Pengeluaran Sendiri		1	single	approved	\N	2026-04-18 13:32:46.439978	2026-04-18 13:33:34.787036	\N	\N
174	Pengeluaran Sendiri		1	single	approved	\N	2026-04-18 14:27:08.817725	2026-04-21 21:59:08.94694	\N	\N
175	asdasd		1	single	approved	\N	2026-04-18 15:18:13.654272	2026-04-18 15:18:26.114928	\N	29
176	Pengeluaran Sendiri		1	single	approved	\N	2026-04-21 00:32:13.351081	2026-04-21 00:34:53.149526	\N	\N
177	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 00:34:56.15964	2026-04-21 00:34:56.15964	\N	\N
178	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 00:35:00.259998	2026-04-21 00:35:00.259998	\N	\N
179	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 00:35:08.776028	2026-04-21 00:35:08.776028	\N	\N
180	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 00:35:17.635038	2026-04-21 00:35:17.636036	\N	\N
181	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 00:35:24.149982	2026-04-21 00:35:24.149982	\N	\N
182	dsds		1	batch	draft	\N	2026-04-21 00:37:19.80155	2026-04-21 00:37:19.80155	\N	\N
183	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 00:45:04.83598	2026-04-21 00:45:04.83598	\N	\N
184	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 00:45:07.289135	2026-04-21 00:45:07.289135	\N	\N
185	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 00:46:36.233956	2026-04-21 00:46:36.233956	\N	\N
186	asdasd		1	batch	approved	\N	2026-04-21 00:59:41.242523	2026-04-21 01:02:18.753484	\N	32
187	lala		1	batch	approved	\N	2026-04-21 01:52:58.682299	2026-04-21 01:53:38.412111	\N	33
188	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 16:55:20.76522	2026-04-21 16:55:20.76522	\N	\N
189	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:18:35.29623	2026-04-21 17:18:35.29623	\N	\N
190	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:18:39.366615	2026-04-21 17:18:39.366615	\N	\N
191	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:22:13.061782	2026-04-21 17:22:13.061782	\N	\N
192	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:24:38.835628	2026-04-21 17:24:38.835628	\N	\N
193	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:24:42.675558	2026-04-21 17:24:42.675558	\N	\N
194	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:26:50.119829	2026-04-21 17:26:50.119829	\N	\N
195	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:27:10.213598	2026-04-21 17:27:10.213598	\N	\N
196	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:28:18.522134	2026-04-21 17:28:18.522134	\N	\N
197	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:29:38.197212	2026-04-21 17:29:38.197212	\N	\N
198	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:32:16.023227	2026-04-21 17:32:16.023227	\N	\N
145	sdfsdf	sdfsdf	1	single	approved	\N	2026-03-21 20:43:32.635695	2026-04-26 13:16:31.323079	\N	\N
201	asd		1	batch	draft	\N	2026-04-21 17:43:38.616701	2026-04-21 17:43:38.616701	\N	\N
202	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:51:23.161127	2026-04-21 17:51:23.161127	\N	\N
203	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:52:29.296736	2026-04-21 17:52:29.296736	\N	\N
204	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:56:14.607891	2026-04-21 17:56:14.607891	\N	\N
205	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:56:48.161273	2026-04-21 17:56:48.161273	\N	\N
206	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:57:48.888426	2026-04-21 17:57:48.888426	\N	\N
207	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:57:58.625644	2026-04-21 17:57:58.625644	\N	\N
208	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 17:58:54.364793	2026-04-21 17:58:54.364793	\N	\N
209	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 18:02:53.657941	2026-04-21 18:02:53.657941	\N	\N
210	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 18:14:16.504654	2026-04-21 18:14:16.504654	\N	\N
211	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 18:15:54.467369	2026-04-21 18:15:54.467369	\N	\N
212	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 18:16:44.790406	2026-04-21 18:16:44.790406	\N	\N
213	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 18:17:11.18916	2026-04-21 18:17:11.18916	\N	\N
215	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 19:16:20.17909	2026-04-21 19:16:20.17909	\N	\N
216	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 19:18:35.449979	2026-04-21 19:18:35.449979	\N	\N
217	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 19:21:01.273126	2026-04-21 19:21:01.273126	\N	\N
218	Pengeluaran Sendiri		1	single	draft	\N	2029-04-22 00:00:00	2026-04-21 19:30:15.270392	\N	\N
219	Pengeluaran Sendiri		1	single	draft	\N	2027-04-22 00:00:00	2026-04-21 19:31:48.008339	\N	\N
220	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 19:50:04.025965	2026-04-21 19:50:04.025965	\N	\N
221	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 19:50:37.576111	2026-04-21 19:50:37.576111	\N	\N
222	1111111111111111111111		1	batch	draft	\N	2026-04-21 19:50:44.117939	2026-04-21 19:50:44.117939	\N	\N
223	Pengeluaran Sendiri		1	single	draft	\N	2026-04-21 19:59:36.1193	2026-04-21 19:59:36.1193	\N	\N
224	22 maret 1		1	batch	draft	\N	2026-04-21 20:00:04.246873	2026-04-21 20:00:04.246873	\N	\N
225	Pengeluaran Sendiri		1	single	draft	2030	2026-04-21 20:05:35.023384	2026-04-21 20:05:35.023384	\N	\N
226	namasaydiofavian		1	batch	draft	2030	2026-04-21 20:05:54.077069	2026-04-21 20:05:54.077069	\N	\N
227	222222222222222222222222222222222		1	batch	draft	2030	2026-04-21 20:09:47.516545	2026-04-21 20:09:47.516545	\N	\N
228	Pengeluaran Sendiri		1	single	draft	2030	2026-04-21 20:16:56.16472	2026-04-21 20:16:56.16472	\N	\N
229	diofavian 3333333333333333333333333		1	batch	draft	2030	2026-04-21 20:24:03.318336	2026-04-21 20:24:03.318336	\N	\N
230	dio00000000000000000000000000000000		1	batch	draft	2030	2030-04-21 20:30:10.827225	2026-04-21 20:30:10.829343	\N	\N
231	2029diooooooooooooo		1	batch	submitted	2029	2029-04-21 20:30:48.643493	2026-04-21 21:14:07.394832	\N	\N
232	Pengeluaran Sendiri		1	single	draft	2030	2030-04-21 21:15:43.58849	2026-04-21 21:15:43.58849	\N	\N
233	Pengeluaran Sendiri		1	single	submitted	2030	2030-04-21 21:21:13.669308	2026-04-21 21:21:26.149403	\N	\N
234	eqwe		1	batch	draft	2030	2030-04-21 21:51:33.223855	2026-04-21 21:51:33.224859	\N	\N
235	Pengeluaran Sendiri		5	single	draft	2030	2030-04-21 22:30:18.88658	2026-04-21 22:30:18.88658	\N	\N
236	Pengeluaran Sendiri		5	single	draft	2030	2030-04-21 22:33:09.592518	2026-04-21 22:33:09.592518	\N	\N
237	Pengeluaran Sendiri		1	single	draft	2030	2030-04-22 09:50:53.234004	2026-04-22 09:50:53.236009	\N	\N
238	Pengeluaran Sendiri		1	single	draft	2030	2030-04-22 10:22:42.171901	2026-04-22 10:22:42.171901	\N	\N
239	qweqwe		1	single	approved	2024	2026-04-23 03:12:29.380088	2026-04-23 03:55:37.559283	\N	40
143	sdfds		1	single	submitted	\N	2026-03-21 20:25:06.960442	2026-04-26 11:42:01.172169	\N	3
241	Pengeluaran Sendiri		1	single	submitted	2025	2025-04-26 13:44:29.886868	2026-04-26 13:46:02.567551	\N	\N
240	Pengeluaran Sendiri		1	single	draft	2024	2024-04-26 13:13:46.117448	2026-04-26 15:26:57.193818	\N	\N
242	Pengeluaran Sendiri		1	single	draft	2024	2024-04-26 16:37:56.347285	2026-04-26 16:37:56.348284	\N	\N
243	Pengeluaran Sendiri		1	single	draft	2024	2024-04-26 16:56:29.645302	2026-04-26 16:56:29.646886	\N	\N
244	Pengeluaran Sendiri		1	single	draft	2024	2024-04-26 17:09:43.088583	2026-04-26 17:09:43.088583	\N	\N
\.


--
-- Data for Name: taxes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.taxes (id, date, description, transaction_value, currency, currency_exchange, ppn, pph_21, pph_23, pph_26, created_at) FROM stdin;
1	2025-02-05	Pembayaran Pajak Jan 2025	11100000	IDR	\N	1100000	500000	200000	0	2026-03-10 14:58:17.750254
2	2023-12-29	Tax PPN 11% (Project TGE MEPI Rimau Pembayaran Ke-2)	33836000	IDR	1	33836000	0	0	0	2026-03-11 12:39:59
3	2024-01-11	Tax PPN 11% (Project TGE MEPI Rimau Pembayaran Ke-2)	33836000	IDR	1	33836000	0	0	0	2026-03-11 12:39:59
4	2024-02-29	Tax PPN 11% (Project TGE MEPI Tomori)	16500000	IDR	1	16500000	0	0	0	2026-03-11 12:39:59
5	2024-10-02	Tax PPN 11% (Perbaikan Repair Electric Assisted Stimulation Machine)	9790000	IDR	1	9790000	0	0	0	2026-03-11 12:39:59
6	2024-09-11	Pinalty Telat bayar pajak PP21 Sewa tool ALFA 2023	25439666	IDR	1	0	25439666	0	0	2026-03-11 12:39:59
7	2024-09-11	Tax PPN 11% pajak Inv-007 tahun 2023 sarulla project - Sibat	96126126	IDR	1	97126126	0	0	0	2026-03-11 12:39:59
8	2024-10-24	Penalty telat bayar pajak PPN project sarulla_INV-007_under Sibat	17716045	IDR	1	0	0	0	0	2026-03-11 12:39:59
9	2024-10-28	Pemindahbukan dari double bayar (29 des 2023) utk PPN Inv-028	33836000	IDR	1	33836000	0	0	0	2026-03-11 12:39:59
10	2024-11-11	Kekurangan pajak PPn Inv-028 (barikikn Sakti)(1/3 nya dari PBK pajak)	56276000	IDR	1	56276000	0	0	0	2026-03-11 12:39:59
11	2024-11-11	Kekurangan pajak final PPH 23 keuntungan perusahaan tahun 2023	1726469	IDR	1	0	0	1726469	0	2026-03-11 12:39:59
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, password_hash, full_name, phone_number, workplace, role, profile_image, last_login, created_at, email, google_id, reset_token, reset_token_expiry) FROM stdin;
2	staff1	scrypt:32768:8:1$gMN52BRIsJ8k3ISE$fe9241f8c684790485dc8d300ea9ea4b0b8bd07bcbfe5c7d38ba53f8a2a692278763103187cd6abafa890e9c591edeccc7ff6b7e92ee89de4e69be177dd69d90	Staff 1	\N	\N	staff	\N	2026-04-22 08:08:08.427414	2026-03-10 00:08:17	\N	\N	\N	\N
3	staff2	scrypt:32768:8:1$xsS3Vuh1BDH6l4Hd$58861ca43f2100f08591394c124929006b361850a6e93d7a9e09d5d38923bae09c7456e8f90892cb86bdcbad4a20fad7cac91aab0ba26ea4789294b19b7f27b7	Staff 2	\N	\N	staff	\N	\N	2026-03-10 00:08:17	\N	\N	\N	\N
4	mitra1	scrypt:32768:8:1$sc64BNMxiGvJfBNo$82326ae1bfec1a185c126cbf947f1dd440248ceac9462852a5b2a49a0e3da84d6283ed93343e90e77afc75a44e0fa6516ba0a39e605540c5168dcb92d0fa8207	Mitra Eksternal 1	\N	\N	mitra_eks	\N	2026-03-25 16:26:55.468741	2026-03-10 00:08:17	\N	\N	\N	\N
5	manager2	scrypt:32768:8:1$KtXwCucapDy16Ivx$f8bae66c12973c8c100c413d1471d0cb48b232d38ef4ce9e7f6b2578742937469fe7e7c52d644a975ee86c225bb9d11681c0871fd497ac064841d30022d88e3a	erlangga2	-	-	manager	\N	2026-04-24 20:16:34.44627	2026-04-21 22:29:53.524451	\N	\N	\N	\N
1	manager1	scrypt:32768:8:1$SzgU1uvuA5jmLWBa$bb70f431bc5ec8b3a21ff46695090a635325c26561c47668f68058a71094b353fef7a33b702443eac6d92e3c3cdc5b8af65bdd5c67773c9607fcb31777c992b7	Anevril Chairu	8118861201	Mercu Buana	manager	profiles/profile_1_363bed42.png	2026-04-27 04:18:27.781508	2026-03-10 00:08:17	diofavianrch@gmail.com	105989317658539505910	434731	2026-04-26 18:44:51.65886
\.


--
-- Name: advance_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.advance_items_id_seq', 37, true);


--
-- Name: advances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.advances_id_seq', 45, true);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_id_seq', 74, true);


--
-- Name: dividend_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dividend_settings_id_seq', 3, true);


--
-- Name: dividends_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dividends_id_seq', 2, true);


--
-- Name: expenses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expenses_id_seq', 584, true);


--
-- Name: manual_combine_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.manual_combine_groups_id_seq', 1, false);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_id_seq', 456, true);


--
-- Name: revenues_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.revenues_id_seq', 18, true);


--
-- Name: settlements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.settlements_id_seq', 244, true);


--
-- Name: taxes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.taxes_id_seq', 12, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 5, true);


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
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


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

\unrestrict bHVYm1hbooZ4Me7tIoTJrjFEtCb19sIJDS3BbiL2rmbA3YY6JVb3lv5Yvg0HsbV

