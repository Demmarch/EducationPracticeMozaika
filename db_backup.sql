--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

-- Started on 2025-11-27 14:33:18

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 5013 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 296 (class 1255 OID 33775)
-- Name: trg_product_log_cost_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_product_log_cost_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Проверяем, изменилась ли цена
    IF (OLD.min_cost_for_partner IS DISTINCT FROM NEW.min_cost_for_partner) THEN
        INSERT INTO product_cost_history (
            product_id, 
            new_cost, 
            change_date
        )
        VALUES (
            NEW.id, 
            NEW.min_cost_for_partner, 
            NOW()
        );
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_product_log_cost_change() OWNER TO postgres;

--
-- TOC entry 297 (class 1255 OID 33777)
-- Name: trg_update_material_stock(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_update_material_stock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material
    SET current_quantity = current_quantity + NEW.quantity_changed
    WHERE id = NEW.material_id;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_update_material_stock() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 248 (class 1259 OID 33972)
-- Name: access_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.access_log (
    id integer NOT NULL,
    staff_id integer,
    entry_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entry_type character varying(10),
    CONSTRAINT access_log_entry_type_check CHECK (((entry_type)::text = ANY ((ARRAY['Вход'::character varying, 'Выход'::character varying])::text[])))
);


ALTER TABLE public.access_log OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 33971)
-- Name: access_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.access_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.access_log_id_seq OWNER TO postgres;

--
-- TOC entry 5014 (class 0 OID 0)
-- Dependencies: 247
-- Name: access_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.access_log_id_seq OWNED BY public.access_log.id;


--
-- TOC entry 235 (class 1259 OID 33858)
-- Name: material; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.material (
    id integer NOT NULL,
    material_type_id integer,
    material_name character varying(100) NOT NULL,
    unit character varying(10) NOT NULL,
    count_in_pack integer,
    min_count integer,
    cost numeric(10,2) NOT NULL,
    description text,
    image text,
    current_quantity integer DEFAULT 0
);


ALTER TABLE public.material OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 33857)
-- Name: material_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.material_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.material_id_seq OWNER TO postgres;

--
-- TOC entry 5015 (class 0 OID 0)
-- Dependencies: 234
-- Name: material_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.material_id_seq OWNED BY public.material.id;


--
-- TOC entry 242 (class 1259 OID 33917)
-- Name: material_supply_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.material_supply_history (
    id integer NOT NULL,
    material_id integer,
    supplier_id integer,
    operation_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    quantity_changed integer NOT NULL
);


ALTER TABLE public.material_supply_history OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 33916)
-- Name: material_supply_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.material_supply_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.material_supply_history_id_seq OWNER TO postgres;

--
-- TOC entry 5016 (class 0 OID 0)
-- Dependencies: 241
-- Name: material_supply_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.material_supply_history_id_seq OWNED BY public.material_supply_history.id;


--
-- TOC entry 225 (class 1259 OID 33798)
-- Name: material_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.material_type (
    id integer NOT NULL,
    type_name character varying(50) NOT NULL
);


ALTER TABLE public.material_type OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 33797)
-- Name: material_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.material_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.material_type_id_seq OWNER TO postgres;

--
-- TOC entry 5017 (class 0 OID 0)
-- Dependencies: 224
-- Name: material_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.material_type_id_seq OWNED BY public.material_type.id;


--
-- TOC entry 233 (class 1259 OID 33841)
-- Name: partner; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partner (
    id integer NOT NULL,
    partner_type_id integer,
    partner_name character varying(100) NOT NULL,
    director_name character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    phone character varying(20) NOT NULL,
    legal_address text NOT NULL,
    inn bytea NOT NULL,
    rating integer DEFAULT 0,
    logo text,
    sales_locations text,
    login character varying(50),
    password character varying(100)
);


ALTER TABLE public.partner OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 33840)
-- Name: partner_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.partner_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.partner_id_seq OWNER TO postgres;

--
-- TOC entry 5018 (class 0 OID 0)
-- Dependencies: 232
-- Name: partner_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.partner_id_seq OWNED BY public.partner.id;


--
-- TOC entry 221 (class 1259 OID 33780)
-- Name: partner_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partner_type (
    id integer NOT NULL,
    type_name character varying(50) NOT NULL
);


ALTER TABLE public.partner_type OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 33779)
-- Name: partner_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.partner_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.partner_type_id_seq OWNER TO postgres;

--
-- TOC entry 5019 (class 0 OID 0)
-- Dependencies: 220
-- Name: partner_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.partner_type_id_seq OWNED BY public.partner_type.id;


--
-- TOC entry 237 (class 1259 OID 33873)
-- Name: product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product (
    id integer NOT NULL,
    article character varying(50) NOT NULL,
    product_type_id integer,
    product_name character varying(100) NOT NULL,
    description text,
    image text,
    min_cost_for_partner numeric(10,2) NOT NULL,
    package_size character varying(50),
    net_weight numeric(10,3),
    gross_weight numeric(10,3),
    certificate_scan text,
    standard_number character varying(50),
    production_time integer,
    cost_price numeric(10,2),
    workshop_number integer,
    production_people_count integer
);


ALTER TABLE public.product OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 33889)
-- Name: product_cost_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_cost_history (
    id integer NOT NULL,
    product_id integer,
    change_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    new_cost numeric(10,2) NOT NULL
);


ALTER TABLE public.product_cost_history OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 33888)
-- Name: product_cost_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_cost_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_cost_history_id_seq OWNER TO postgres;

--
-- TOC entry 5020 (class 0 OID 0)
-- Dependencies: 238
-- Name: product_cost_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_cost_history_id_seq OWNED BY public.product_cost_history.id;


--
-- TOC entry 236 (class 1259 OID 33872)
-- Name: product_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_id_seq OWNER TO postgres;

--
-- TOC entry 5021 (class 0 OID 0)
-- Dependencies: 236
-- Name: product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_id_seq OWNED BY public.product.id;


--
-- TOC entry 240 (class 1259 OID 33901)
-- Name: product_material; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_material (
    product_id integer NOT NULL,
    material_id integer NOT NULL,
    required_quantity numeric(10,3) NOT NULL
);


ALTER TABLE public.product_material OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 33789)
-- Name: product_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_type (
    id integer NOT NULL,
    type_name character varying(50) NOT NULL
);


ALTER TABLE public.product_type OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 33788)
-- Name: product_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_type_id_seq OWNER TO postgres;

--
-- TOC entry 5022 (class 0 OID 0)
-- Dependencies: 222
-- Name: product_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_type_id_seq OWNED BY public.product_type.id;


--
-- TOC entry 244 (class 1259 OID 33935)
-- Name: request; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.request (
    id integer NOT NULL,
    partner_id integer,
    manager_id integer,
    date_created timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(50) DEFAULT 'Новая'::character varying NOT NULL,
    payment_date timestamp without time zone
);


ALTER TABLE public.request OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 33934)
-- Name: request_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.request_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.request_id_seq OWNER TO postgres;

--
-- TOC entry 5023 (class 0 OID 0)
-- Dependencies: 243
-- Name: request_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.request_id_seq OWNED BY public.request.id;


--
-- TOC entry 246 (class 1259 OID 33954)
-- Name: request_product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.request_product (
    id integer NOT NULL,
    request_id integer,
    product_id integer,
    quantity integer NOT NULL,
    actual_price numeric(10,2) NOT NULL,
    planned_production_date date,
    CONSTRAINT request_product_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE public.request_product OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 33953)
-- Name: request_product_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.request_product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.request_product_id_seq OWNER TO postgres;

--
-- TOC entry 5024 (class 0 OID 0)
-- Dependencies: 245
-- Name: request_product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.request_product_id_seq OWNED BY public.request_product.id;


--
-- TOC entry 231 (class 1259 OID 33825)
-- Name: staff; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff (
    id integer NOT NULL,
    surname character varying(50) NOT NULL,
    name character varying(50) NOT NULL,
    patronymic character varying(50),
    position_id integer,
    birth_date date NOT NULL,
    passport_details bytea NOT NULL,
    bank_account character varying(25) NOT NULL,
    family_status character varying(50),
    health_info text,
    phone character varying(20) NOT NULL,
    login character varying(50) NOT NULL,
    password character varying(100) NOT NULL
);


ALTER TABLE public.staff OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 33824)
-- Name: staff_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.staff_id_seq OWNER TO postgres;

--
-- TOC entry 5025 (class 0 OID 0)
-- Dependencies: 230
-- Name: staff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.staff_id_seq OWNED BY public.staff.id;


--
-- TOC entry 227 (class 1259 OID 33807)
-- Name: staff_position; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff_position (
    id integer NOT NULL,
    position_name character varying(50) NOT NULL
);


ALTER TABLE public.staff_position OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 33806)
-- Name: staff_position_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.staff_position_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.staff_position_id_seq OWNER TO postgres;

--
-- TOC entry 5026 (class 0 OID 0)
-- Dependencies: 226
-- Name: staff_position_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.staff_position_id_seq OWNED BY public.staff_position.id;


--
-- TOC entry 229 (class 1259 OID 33816)
-- Name: supplier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.supplier (
    id integer NOT NULL,
    supplier_name character varying(100) NOT NULL,
    inn bytea NOT NULL,
    supplier_type character varying(50)
);


ALTER TABLE public.supplier OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 33815)
-- Name: supplier_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.supplier_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.supplier_id_seq OWNER TO postgres;

--
-- TOC entry 5027 (class 0 OID 0)
-- Dependencies: 228
-- Name: supplier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.supplier_id_seq OWNED BY public.supplier.id;


--
-- TOC entry 4770 (class 2604 OID 33975)
-- Name: access_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_log ALTER COLUMN id SET DEFAULT nextval('public.access_log_id_seq'::regclass);


--
-- TOC entry 4759 (class 2604 OID 33861)
-- Name: material id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material ALTER COLUMN id SET DEFAULT nextval('public.material_id_seq'::regclass);


--
-- TOC entry 4764 (class 2604 OID 33920)
-- Name: material_supply_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_supply_history ALTER COLUMN id SET DEFAULT nextval('public.material_supply_history_id_seq'::regclass);


--
-- TOC entry 4753 (class 2604 OID 33801)
-- Name: material_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_type ALTER COLUMN id SET DEFAULT nextval('public.material_type_id_seq'::regclass);


--
-- TOC entry 4757 (class 2604 OID 33844)
-- Name: partner id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner ALTER COLUMN id SET DEFAULT nextval('public.partner_id_seq'::regclass);


--
-- TOC entry 4751 (class 2604 OID 33783)
-- Name: partner_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_type ALTER COLUMN id SET DEFAULT nextval('public.partner_type_id_seq'::regclass);


--
-- TOC entry 4761 (class 2604 OID 33876)
-- Name: product id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product ALTER COLUMN id SET DEFAULT nextval('public.product_id_seq'::regclass);


--
-- TOC entry 4762 (class 2604 OID 33892)
-- Name: product_cost_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_cost_history ALTER COLUMN id SET DEFAULT nextval('public.product_cost_history_id_seq'::regclass);


--
-- TOC entry 4752 (class 2604 OID 33792)
-- Name: product_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_type ALTER COLUMN id SET DEFAULT nextval('public.product_type_id_seq'::regclass);


--
-- TOC entry 4766 (class 2604 OID 33938)
-- Name: request id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.request ALTER COLUMN id SET DEFAULT nextval('public.request_id_seq'::regclass);


--
-- TOC entry 4769 (class 2604 OID 33957)
-- Name: request_product id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.request_product ALTER COLUMN id SET DEFAULT nextval('public.request_product_id_seq'::regclass);


--
-- TOC entry 4756 (class 2604 OID 33828)
-- Name: staff id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff ALTER COLUMN id SET DEFAULT nextval('public.staff_id_seq'::regclass);


--
-- TOC entry 4754 (class 2604 OID 33810)
-- Name: staff_position id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_position ALTER COLUMN id SET DEFAULT nextval('public.staff_position_id_seq'::regclass);


--
-- TOC entry 4755 (class 2604 OID 33819)
-- Name: supplier id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supplier ALTER COLUMN id SET DEFAULT nextval('public.supplier_id_seq'::regclass);


--
-- TOC entry 5007 (class 0 OID 33972)
-- Dependencies: 248
-- Data for Name: access_log; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4994 (class 0 OID 33858)
-- Dependencies: 235
-- Data for Name: material; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.material VALUES (1, 1, 'Белая глина', 'кг', 50, 100, 500.00, 'Высококачественная глина', 'clay.jpg', 5000);
INSERT INTO public.material VALUES (2, 3, 'Красный пигмент', 'л', 5, 10, 1200.50, 'Стойкий краситель', 'red_pig.jpg', 50);
INSERT INTO public.material VALUES (3, 4, 'Коробка картонная', 'шт', 100, 200, 15.00, 'Для плитки 30х30', 'box.jpg', 1000);


--
-- TOC entry 5001 (class 0 OID 33917)
-- Dependencies: 242
-- Data for Name: material_supply_history; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4984 (class 0 OID 33798)
-- Dependencies: 225
-- Data for Name: material_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.material_type VALUES (1, 'Глина');
INSERT INTO public.material_type VALUES (2, 'Глазурь');
INSERT INTO public.material_type VALUES (3, 'Пигмент');
INSERT INTO public.material_type VALUES (4, 'Упаковка');


--
-- TOC entry 4992 (class 0 OID 33841)
-- Dependencies: 233
-- Data for Name: partner; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.partner VALUES (1, 1, 'Строительный Двор', 'Кузнецов А.В.', 'contact@stroy.ru', '+78123334455', 'г. Москва ул. Ленина 1', '\xc30d040703024286937dd9f7067377d23b019987f86dfe6bc742bff01c7e391c01d76cdbd0772221ff2b140fafa0f3c8bfc293b2339ed58e7b04dc1c3ac23e24f18cb77325455483627c416a', 10, 'logo1.png', 'Москва и область', 'partner1', '$2a$06$ze2h02AnRVulZrI3dUsx4.kX6fmuWGX8sP2QAXnU5Ahog0hQAIR/W');
INSERT INTO public.partner VALUES (2, 3, 'ИП Васильев', 'Васильев В.В.', 'vasil@mail.ru', '+79110001122', 'г. С-Петербург Невский 25', '\xc30d0407030218d31d3cc24e1fd26ad23b01cbe4c4d48428fe95b4609922d476516fc68eed399ecc0b82aad7b5bdc2e622c930f06243ac1ee3d8e73b1a407fcd03b64f5d59634c5bd7eef94d', 5, 'logo2.png', 'Санкт-Петербург', 'partner2', '$2a$06$NXzRx5ZAEOFa0E7eiTglT.BEsUWrM9FVWg6eah/zFK/czZREF3w3C');


--
-- TOC entry 4980 (class 0 OID 33780)
-- Dependencies: 221
-- Data for Name: partner_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.partner_type VALUES (1, 'ООО');
INSERT INTO public.partner_type VALUES (2, 'ЗАО');
INSERT INTO public.partner_type VALUES (3, 'ИП');
INSERT INTO public.partner_type VALUES (4, 'ПАО');


--
-- TOC entry 4996 (class 0 OID 33873)
-- Dependencies: 237
-- Data for Name: product; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.product VALUES (1, 'ART-001', 1, 'Белый мрамор', 'Плитка под мрамор', 'marble.jpg', 1500.00, '30x30x10', 12.500, 13.000, 'cert1.pdf', 'GOST-123', 24, 800.00, 1, 5);
INSERT INTO public.product VALUES (2, 'ART-002', 4, 'Мозаика Синяя', 'Декоративная вставка', 'mosaic.jpg', 2500.00, '10x10x5', 2.000, 2.100, 'cert2.pdf', 'GOST-456', 48, 1200.00, 2, 3);


--
-- TOC entry 4998 (class 0 OID 33889)
-- Dependencies: 239
-- Data for Name: product_cost_history; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4999 (class 0 OID 33901)
-- Dependencies: 240
-- Data for Name: product_material; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.product_material VALUES (1, 1, 2.500);
INSERT INTO public.product_material VALUES (1, 3, 0.100);
INSERT INTO public.product_material VALUES (2, 1, 0.500);
INSERT INTO public.product_material VALUES (2, 2, 0.050);


--
-- TOC entry 4982 (class 0 OID 33789)
-- Dependencies: 223
-- Data for Name: product_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.product_type VALUES (1, 'Плитка настенная');
INSERT INTO public.product_type VALUES (2, 'Плитка напольная');
INSERT INTO public.product_type VALUES (3, 'Керамогранит');
INSERT INTO public.product_type VALUES (4, 'Декор');


--
-- TOC entry 5003 (class 0 OID 33935)
-- Dependencies: 244
-- Data for Name: request; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.request VALUES (1, 2, 2, '2025-01-11 12:30:00', 'Выполнена', '2025-01-12 10:00:00');


--
-- TOC entry 5005 (class 0 OID 33954)
-- Dependencies: 246
-- Data for Name: request_product; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.request_product VALUES (1, 1, 1, 100, 1450.00, '2025-01-20');
INSERT INTO public.request_product VALUES (2, 1, 2, 50, 2400.00, '2025-01-22');


--
-- TOC entry 4990 (class 0 OID 33825)
-- Dependencies: 231
-- Data for Name: staff; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.staff VALUES (1, 'Иванов', 'Иван', 'Иванович', 1, '1980-05-15', '\xc30d04070302785d86be84ff2d1175d2c003014f2a5deb86ca6d4e75b4e36205d6a6235e88d38c4bd7126e0ecb7a5a2432db7e6c9b648aee151477c9d953d7c940f0b42c5a14ebdc592983fdb087af8bc03e086aedd306e3846e694dc94653bdcbb6ea5e07b601d7233bb6f8cec05e44bf9e71fc653754893792d05cb2ee9dcb829485bee12ad4d24e2899bb4e66c79d116c91470ffada210307036e033d012c3d99265589adbbbfdf86a6be8ca53f492b2b41a086386dfa4f09da330d55b453cbc1856086ab5691e7694bb5051dd3f612063c74b3', '40817810099910004312', 'Женат', 'Здоров', '+79001112233', 'admin', '$2a$06$bFdCrk0D68VnTc/D00s4k.vv4ntpRQ.L1LMuxZgtFzPsqBsdMXf86');
INSERT INTO public.staff VALUES (2, 'Смирнова', 'Анна', 'Петровна', 2, '1995-03-20', '\xc30d040703026bb8278be0dbb48c6fd2b601edd27a7c0f3b7c3c5228b107b03529c251e0a4881737fcc3d4d33dedb653af473d5408b8eaed7158e761aba1c17a11aa47a815308b6c8ceab7bb22a5ac12c7809edc02ee6034135e2b3c06f1a6e2fb8a4d96dfd760577b20eb61479f0a834bdc5ff0cd4491fa5bb5aa3e93b488d074b9b6057fe9ff1e63f65a824b903cbc0ec129f6c564aeda37a085e779137b17b29e1a10e6c2370ae60980b4efab62669b2cc29d9aa77cb31b39a3ba06336e27705c32d7eb1737', '40817810099910005555', 'Не замужем', 'Здорова', '+79005556677', 'manager', '$2a$06$PSdBMt3vgQC6yIkr8WwrIuHwPGikgqLNAfJ3K8fXmTEF7/Ogbn28e');
INSERT INTO public.staff VALUES (3, 'Сидоров', 'Петр', 'Сергеевич', 3, '1975-11-10', '\xc30d04070302456907782489ddac6ad2ae01915cd35207d0928c9e67c39c3adfce0c56baf0ae6025a2c0c2b7b3f74fad5b072b46324eaa1adcf27904d835619e0b6a1d98508a853ddb81ed15737673689121c17c72210a059a1188a792120284e94c62fe2149f4091ee55be060b643c1d8733158fd3f738bb5e3530e8a8b77f6b3c48c1471ee9d6c39078d457d87a6585c980690b5d8218daf02e41d77ab074ae51ea31b6972de55fff5e8a0f1a924e2a041ef7ca5b356691725425331334d', '40817810099910008888', 'Женат', 'Здоров', '+79009998877', 'master', '$2a$06$Y4Arpvh/tDB1juUcdXxqXOQWrqOu8RvtPbX3NxbmNjw8hF8uLzy/.');


--
-- TOC entry 4986 (class 0 OID 33807)
-- Dependencies: 227
-- Data for Name: staff_position; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.staff_position VALUES (1, 'Директор');
INSERT INTO public.staff_position VALUES (2, 'Менеджер продаж');
INSERT INTO public.staff_position VALUES (3, 'Мастер цеха');
INSERT INTO public.staff_position VALUES (4, 'Кладовщик');


--
-- TOC entry 4988 (class 0 OID 33816)
-- Dependencies: 229
-- Data for Name: supplier; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.supplier VALUES (1, 'ООО СтройСнаб', '\xc30d0407030296f5009fe8cc74bf7bd23b010e25be020dce187f5efde2fa34285e6050b2af434fe8bc71d9e1465b8663adf0625c66ec48952a7f8d44b8798502c4dce1109cbac940fd39a7a4', 'Оптовый');
INSERT INTO public.supplier VALUES (2, 'ИП Петров А.А.', '\xc30d04070302152ce32a95159fc06ad23b01d1a1f1cc7647e9b1a61ab7a25262104c66b656c86d4a1509d69b0840c8acdf6411d6179583c483c05fcacd0dc2360154706a958f2fd22eb18037', 'Розничный');
INSERT INTO public.supplier VALUES (3, 'АО ХимПром', '\xc30d04070302e01f554f9333cbf163d23b01e7b21f90ef8afebb00b5643c5a29052a04935e81b78767ae531403b3e1b6439ef983ea0f965ed28d37d8330d8a31589b1e1e2bd1c39b85c97709', 'Производитель');


--
-- TOC entry 5028 (class 0 OID 0)
-- Dependencies: 247
-- Name: access_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.access_log_id_seq', 1, false);


--
-- TOC entry 5029 (class 0 OID 0)
-- Dependencies: 234
-- Name: material_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.material_id_seq', 3, true);


--
-- TOC entry 5030 (class 0 OID 0)
-- Dependencies: 241
-- Name: material_supply_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.material_supply_history_id_seq', 1, false);


--
-- TOC entry 5031 (class 0 OID 0)
-- Dependencies: 224
-- Name: material_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.material_type_id_seq', 4, true);


--
-- TOC entry 5032 (class 0 OID 0)
-- Dependencies: 232
-- Name: partner_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.partner_id_seq', 2, true);


--
-- TOC entry 5033 (class 0 OID 0)
-- Dependencies: 220
-- Name: partner_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.partner_type_id_seq', 4, true);


--
-- TOC entry 5034 (class 0 OID 0)
-- Dependencies: 238
-- Name: product_cost_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_cost_history_id_seq', 1, false);


--
-- TOC entry 5035 (class 0 OID 0)
-- Dependencies: 236
-- Name: product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_id_seq', 2, true);


--
-- TOC entry 5036 (class 0 OID 0)
-- Dependencies: 222
-- Name: product_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_type_id_seq', 4, true);


--
-- TOC entry 5037 (class 0 OID 0)
-- Dependencies: 243
-- Name: request_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.request_id_seq', 1, true);


--
-- TOC entry 5038 (class 0 OID 0)
-- Dependencies: 245
-- Name: request_product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.request_product_id_seq', 2, true);


--
-- TOC entry 5039 (class 0 OID 0)
-- Dependencies: 230
-- Name: staff_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.staff_id_seq', 3, true);


--
-- TOC entry 5040 (class 0 OID 0)
-- Dependencies: 226
-- Name: staff_position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.staff_position_id_seq', 4, true);


--
-- TOC entry 5041 (class 0 OID 0)
-- Dependencies: 228
-- Name: supplier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.supplier_id_seq', 3, true);


--
-- TOC entry 4817 (class 2606 OID 33979)
-- Name: access_log access_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_log
    ADD CONSTRAINT access_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4801 (class 2606 OID 33866)
-- Name: material material_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material
    ADD CONSTRAINT material_pkey PRIMARY KEY (id);


--
-- TOC entry 4811 (class 2606 OID 33923)
-- Name: material_supply_history material_supply_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_supply_history
    ADD CONSTRAINT material_supply_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4783 (class 2606 OID 33803)
-- Name: material_type material_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_type
    ADD CONSTRAINT material_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4785 (class 2606 OID 33805)
-- Name: material_type material_type_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_type
    ADD CONSTRAINT material_type_type_name_key UNIQUE (type_name);


--
-- TOC entry 4797 (class 2606 OID 33851)
-- Name: partner partner_login_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner
    ADD CONSTRAINT partner_login_key UNIQUE (login);


--
-- TOC entry 4799 (class 2606 OID 33849)
-- Name: partner partner_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner
    ADD CONSTRAINT partner_pkey PRIMARY KEY (id);


--
-- TOC entry 4775 (class 2606 OID 33785)
-- Name: partner_type partner_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_type
    ADD CONSTRAINT partner_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4777 (class 2606 OID 33787)
-- Name: partner_type partner_type_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_type
    ADD CONSTRAINT partner_type_type_name_key UNIQUE (type_name);


--
-- TOC entry 4803 (class 2606 OID 33882)
-- Name: product product_article_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_article_key UNIQUE (article);


--
-- TOC entry 4807 (class 2606 OID 33895)
-- Name: product_cost_history product_cost_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_cost_history
    ADD CONSTRAINT product_cost_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4809 (class 2606 OID 33905)
-- Name: product_material product_material_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_material
    ADD CONSTRAINT product_material_pkey PRIMARY KEY (product_id, material_id);


--
-- TOC entry 4805 (class 2606 OID 33880)
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (id);


--
-- TOC entry 4779 (class 2606 OID 33794)
-- Name: product_type product_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_type
    ADD CONSTRAINT product_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4781 (class 2606 OID 33796)
-- Name: product_type product_type_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_type
    ADD CONSTRAINT product_type_type_name_key UNIQUE (type_name);


--
-- TOC entry 4813 (class 2606 OID 33942)
-- Name: request request_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.request
    ADD CONSTRAINT request_pkey PRIMARY KEY (id);


--
-- TOC entry 4815 (class 2606 OID 33960)
-- Name: request_product request_product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.request_product
    ADD CONSTRAINT request_product_pkey PRIMARY KEY (id);


--
-- TOC entry 4793 (class 2606 OID 33834)
-- Name: staff staff_login_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_login_key UNIQUE (login);


--
-- TOC entry 4795 (class 2606 OID 33832)
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (id);


--
-- TOC entry 4787 (class 2606 OID 33812)
-- Name: staff_position staff_position_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_position
    ADD CONSTRAINT staff_position_pkey PRIMARY KEY (id);


--
-- TOC entry 4789 (class 2606 OID 33814)
-- Name: staff_position staff_position_position_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_position
    ADD CONSTRAINT staff_position_position_name_key UNIQUE (position_name);


--
-- TOC entry 4791 (class 2606 OID 33823)
-- Name: supplier supplier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supplier
    ADD CONSTRAINT supplier_pkey PRIMARY KEY (id);


--
-- TOC entry 4833 (class 2620 OID 33986)
-- Name: material_supply_history insert_material_history_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER insert_material_history_trigger AFTER INSERT ON public.material_supply_history FOR EACH ROW EXECUTE FUNCTION public.trg_update_material_stock();


--
-- TOC entry 4832 (class 2620 OID 33985)
-- Name: product update_product_cost_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_product_cost_trigger AFTER UPDATE ON public.product FOR EACH ROW EXECUTE FUNCTION public.trg_product_log_cost_change();


--
-- TOC entry 4831 (class 2606 OID 33980)
-- Name: access_log access_log_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_log
    ADD CONSTRAINT access_log_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id) ON DELETE CASCADE;


--
-- TOC entry 4820 (class 2606 OID 33867)
-- Name: material material_material_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material
    ADD CONSTRAINT material_material_type_id_fkey FOREIGN KEY (material_type_id) REFERENCES public.material_type(id) ON DELETE RESTRICT;


--
-- TOC entry 4825 (class 2606 OID 33924)
-- Name: material_supply_history material_supply_history_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_supply_history
    ADD CONSTRAINT material_supply_history_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.material(id) ON DELETE CASCADE;


--
-- TOC entry 4826 (class 2606 OID 33929)
-- Name: material_supply_history material_supply_history_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_supply_history
    ADD CONSTRAINT material_supply_history_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(id) ON DELETE SET NULL;


--
-- TOC entry 4819 (class 2606 OID 33852)
-- Name: partner partner_partner_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner
    ADD CONSTRAINT partner_partner_type_id_fkey FOREIGN KEY (partner_type_id) REFERENCES public.partner_type(id) ON DELETE RESTRICT;


--
-- TOC entry 4822 (class 2606 OID 33896)
-- Name: product_cost_history product_cost_history_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_cost_history
    ADD CONSTRAINT product_cost_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(id) ON DELETE CASCADE;


--
-- TOC entry 4823 (class 2606 OID 33911)
-- Name: product_material product_material_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_material
    ADD CONSTRAINT product_material_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.material(id) ON DELETE RESTRICT;


--
-- TOC entry 4824 (class 2606 OID 33906)
-- Name: product_material product_material_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_material
    ADD CONSTRAINT product_material_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(id) ON DELETE CASCADE;


--
-- TOC entry 4821 (class 2606 OID 33883)
-- Name: product product_product_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_product_type_id_fkey FOREIGN KEY (product_type_id) REFERENCES public.product_type(id) ON DELETE RESTRICT;


--
-- TOC entry 4827 (class 2606 OID 33948)
-- Name: request request_manager_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.request
    ADD CONSTRAINT request_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES public.staff(id) ON DELETE SET NULL;


--
-- TOC entry 4828 (class 2606 OID 33943)
-- Name: request request_partner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.request
    ADD CONSTRAINT request_partner_id_fkey FOREIGN KEY (partner_id) REFERENCES public.partner(id) ON DELETE CASCADE;


--
-- TOC entry 4829 (class 2606 OID 33966)
-- Name: request_product request_product_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.request_product
    ADD CONSTRAINT request_product_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(id) ON DELETE RESTRICT;


--
-- TOC entry 4830 (class 2606 OID 33961)
-- Name: request_product request_product_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.request_product
    ADD CONSTRAINT request_product_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.request(id) ON DELETE CASCADE;


--
-- TOC entry 4818 (class 2606 OID 33835)
-- Name: staff staff_position_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_position_id_fkey FOREIGN KEY (position_id) REFERENCES public.staff_position(id) ON DELETE RESTRICT;


-- Completed on 2025-11-27 14:33:19

--
-- PostgreSQL database dump complete
--

