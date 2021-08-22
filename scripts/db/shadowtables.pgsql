--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4 (Debian 13.4-1.pgdg100+1)
-- Dumped by pg_dump version 13.3

-- Started on 2021-08-22 13:22:26 UTC

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
-- TOC entry 4018 (class 1262 OID 4514751)
-- Name: openstreetmap; Type: DATABASE; Schema: -; Owner: openstreetmap
--

CREATE DATABASE local_changes WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';


ALTER DATABASE local_changes OWNER TO openstreetmap;

\connect local_changes

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
-- TOC entry 3 (class 3079 OID 4514880)
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- TOC entry 4020 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- TOC entry 2 (class 3079 OID 4514753)
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- TOC entry 4021 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- TOC entry 1176 (class 1247 OID 4546772)
-- Name: format_enum; Type: TYPE; Schema: public; Owner: openstreetmap
--

CREATE TYPE public.format_enum AS ENUM (
    'html',
    'markdown',
    'text'
);


ALTER TYPE public.format_enum OWNER TO openstreetmap;

--
-- TOC entry 1130 (class 1247 OID 4546543)
-- Name: gpx_visibility_enum; Type: TYPE; Schema: public; Owner: openstreetmap
--

CREATE TYPE public.gpx_visibility_enum AS ENUM (
    'private',
    'public',
    'trackable',
    'identifiable'
);


ALTER TYPE public.gpx_visibility_enum OWNER TO openstreetmap;

--
-- TOC entry 1193 (class 1247 OID 4546879)
-- Name: issue_status_enum; Type: TYPE; Schema: public; Owner: openstreetmap
--

CREATE TYPE public.issue_status_enum AS ENUM (
    'open',
    'ignored',
    'resolved'
);


ALTER TYPE public.issue_status_enum OWNER TO openstreetmap;

--
-- TOC entry 1165 (class 1247 OID 4546752)
-- Name: note_event_enum; Type: TYPE; Schema: public; Owner: openstreetmap
--

CREATE TYPE public.note_event_enum AS ENUM (
    'opened',
    'closed',
    'reopened',
    'commented',
    'hidden'
);


ALTER TYPE public.note_event_enum OWNER TO openstreetmap;

--
-- TOC entry 1162 (class 1247 OID 4546688)
-- Name: note_status_enum; Type: TYPE; Schema: public; Owner: openstreetmap
--

CREATE TYPE public.note_status_enum AS ENUM (
    'open',
    'closed',
    'hidden'
);


ALTER TYPE public.note_status_enum OWNER TO openstreetmap;

--
-- TOC entry 1068 (class 1247 OID 4546165)
-- Name: nwr_enum; Type: TYPE; Schema: public; Owner: openstreetmap
--

CREATE TYPE public.nwr_enum AS ENUM (
    'Node',
    'Way',
    'Relation'
);


ALTER TYPE public.nwr_enum OWNER TO openstreetmap;

--
-- TOC entry 1146 (class 1247 OID 4546614)
-- Name: user_role_enum; Type: TYPE; Schema: public; Owner: openstreetmap
--

CREATE TYPE public.user_role_enum AS ENUM (
    'administrator',
    'moderator'
);


ALTER TYPE public.user_role_enum OWNER TO openstreetmap;

--
-- TOC entry 1158 (class 1247 OID 4546674)
-- Name: user_status_enum; Type: TYPE; Schema: public; Owner: openstreetmap
--

CREATE TYPE public.user_status_enum AS ENUM (
    'pending',
    'active',
    'confirmed',
    'suspended',
    'deleted'
);


ALTER TYPE public.user_status_enum OWNER TO openstreetmap;

--
-- TOC entry 564 (class 1255 OID 5414284)
-- Name: extractmychanges(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.extractmychanges()
    LANGUAGE sql
    AS $$
INSERT INTO MyTagChanges 
select _.way_id, _.version, wt.k, wt.v
from (
    select
        w1.way_id,
        w1.version,
        rank() OVER (partition by w1.way_id ORDER BY w1.timestamp DESC) as rank
    from
        ways as w1
    inner join changesets as c1 on w1.changeset_id = c1.id and c1.created_at > '2021-08-15'
    where 
        c1.user_id = 2
) _
inner join way_tags wt on wt.way_id = _.way_id and wt.version = _.version
where
    rank = 1
and wt.k in ('name', 'railway', 'usage', 'abandoned:railway', 'service', 'razed:railway', 'disused:railway')
ON CONFLICT DO NOTHING
$$;


ALTER PROCEDURE public.extractmychanges() OWNER TO postgres;

--
-- TOC entry 563 (class 1255 OID 4515503)
-- Name: tile_for_point(integer, integer); Type: FUNCTION; Schema: public; Owner: renderer
--

CREATE FUNCTION public.tile_for_point(scaled_lat integer, scaled_lon integer) RETURNS bigint
    LANGUAGE plpgsql IMMUTABLE
    AS $$
  DECLARE
    x int8; -- quantized x from lon,
    y int8; -- quantized y from lat,
  BEGIN
    x := round(((scaled_lon / 10000000.0) + 180.0) * 65535.0 / 360.0);
    y := round(((scaled_lat / 10000000.0) +  90.0) * 65535.0 / 180.0);

    -- these bit-masks are special numbers used in the bit interleaving algorithm.
    -- see https://graphics.stanford.edu/~seander/bithacks.html#InterleaveBMN
    -- for the original algorithm and more details.
    x := (x | (x << 8)) &   16711935; -- 0x00FF00FF
    x := (x | (x << 4)) &  252645135; -- 0x0F0F0F0F
    x := (x | (x << 2)) &  858993459; -- 0x33333333
    x := (x | (x << 1)) & 1431655765; -- 0x55555555

    y := (y | (y << 8)) &   16711935; -- 0x00FF00FF
    y := (y | (y << 4)) &  252645135; -- 0x0F0F0F0F
    y := (y | (y << 2)) &  858993459; -- 0x33333333
    y := (y | (y << 1)) & 1431655765; -- 0x55555555

    RETURN (x << 1) | y;
  END;
  $$;


ALTER FUNCTION public.tile_for_point(scaled_lat integer, scaled_lon integer) OWNER TO renderer;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 266 (class 1259 OID 4546272)
-- Name: acls; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.acls (
    id bigint NOT NULL,
    address inet,
    k character varying NOT NULL,
    v character varying,
    domain character varying,
    mx character varying
);


ALTER TABLE public.acls OWNER TO openstreetmap;

--
-- TOC entry 265 (class 1259 OID 4546270)
-- Name: acls_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.acls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.acls_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4022 (class 0 OID 0)
-- Dependencies: 265
-- Name: acls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.acls_id_seq OWNED BY public.acls.id;


--
-- TOC entry 304 (class 1259 OID 4547014)
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.active_storage_attachments OWNER TO openstreetmap;

--
-- TOC entry 303 (class 1259 OID 4547012)
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.active_storage_attachments_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4023 (class 0 OID 0)
-- Dependencies: 303
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- TOC entry 302 (class 1259 OID 4547002)
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    byte_size bigint NOT NULL,
    checksum character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    service_name character varying NOT NULL
);


ALTER TABLE public.active_storage_blobs OWNER TO openstreetmap;

--
-- TOC entry 301 (class 1259 OID 4547000)
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.active_storage_blobs_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4024 (class 0 OID 0)
-- Dependencies: 301
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- TOC entry 312 (class 1259 OID 4547117)
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


ALTER TABLE public.active_storage_variant_records OWNER TO openstreetmap;

--
-- TOC entry 311 (class 1259 OID 4547115)
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.active_storage_variant_records_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4025 (class 0 OID 0)
-- Dependencies: 311
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- TOC entry 229 (class 1259 OID 4545831)
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.ar_internal_metadata OWNER TO openstreetmap;

--
-- TOC entry 290 (class 1259 OID 4546835)
-- Name: changeset_comments; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.changeset_comments (
    id integer NOT NULL,
    changeset_id bigint NOT NULL,
    author_id bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    visible boolean NOT NULL
);


ALTER TABLE public.changeset_comments OWNER TO openstreetmap;

--
-- TOC entry 289 (class 1259 OID 4546833)
-- Name: changeset_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.changeset_comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.changeset_comments_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4026 (class 0 OID 0)
-- Dependencies: 289
-- Name: changeset_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.changeset_comments_id_seq OWNED BY public.changeset_comments.id;


--
-- TOC entry 271 (class 1259 OID 4546388)
-- Name: changeset_tags; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.changeset_tags (
    changeset_id bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.changeset_tags OWNER TO openstreetmap;

--
-- TOC entry 270 (class 1259 OID 4546381)
-- Name: changesets; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.changesets (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    min_lat integer,
    max_lat integer,
    min_lon integer,
    max_lon integer,
    closed_at timestamp without time zone NOT NULL,
    num_changes integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.changesets OWNER TO openstreetmap;

--
-- TOC entry 269 (class 1259 OID 4546379)
-- Name: changesets_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.changesets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.changesets_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4027 (class 0 OID 0)
-- Dependencies: 269
-- Name: changesets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.changesets_id_seq OWNED BY public.changesets.id;


--
-- TOC entry 291 (class 1259 OID 4546855)
-- Name: changesets_subscribers; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.changesets_subscribers (
    subscriber_id bigint NOT NULL,
    changeset_id bigint NOT NULL
);


ALTER TABLE public.changesets_subscribers OWNER TO openstreetmap;

--
-- TOC entry 274 (class 1259 OID 4546555)
-- Name: client_applications; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.client_applications (
    id integer NOT NULL,
    name character varying,
    url character varying,
    support_url character varying,
    callback_url character varying,
    key character varying(50),
    secret character varying(50),
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    allow_read_prefs boolean DEFAULT false NOT NULL,
    allow_write_prefs boolean DEFAULT false NOT NULL,
    allow_write_diary boolean DEFAULT false NOT NULL,
    allow_write_api boolean DEFAULT false NOT NULL,
    allow_read_gpx boolean DEFAULT false NOT NULL,
    allow_write_gpx boolean DEFAULT false NOT NULL,
    allow_write_notes boolean DEFAULT false NOT NULL
);


ALTER TABLE public.client_applications OWNER TO openstreetmap;

--
-- TOC entry 273 (class 1259 OID 4546553)
-- Name: client_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.client_applications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.client_applications_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4028 (class 0 OID 0)
-- Dependencies: 273
-- Name: client_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.client_applications_id_seq OWNED BY public.client_applications.id;


--
-- TOC entry 267 (class 1259 OID 4546290)
-- Name: current_node_tags; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.current_node_tags (
    node_id bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.current_node_tags OWNER TO openstreetmap;

--
-- TOC entry 252 (class 1259 OID 4546122)
-- Name: current_nodes; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.current_nodes (
    id bigint NOT NULL,
    latitude integer NOT NULL,
    longitude integer NOT NULL,
    changeset_id bigint NOT NULL,
    visible boolean NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    tile bigint NOT NULL,
    version bigint NOT NULL
);


ALTER TABLE public.current_nodes OWNER TO openstreetmap;

--
-- TOC entry 251 (class 1259 OID 4546120)
-- Name: current_nodes_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.current_nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.current_nodes_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4029 (class 0 OID 0)
-- Dependencies: 251
-- Name: current_nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.current_nodes_id_seq OWNED BY public.current_nodes.id;


--
-- TOC entry 254 (class 1259 OID 4546171)
-- Name: current_relation_members; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.current_relation_members (
    relation_id bigint NOT NULL,
    member_type public.nwr_enum NOT NULL,
    member_id bigint NOT NULL,
    member_role character varying NOT NULL,
    sequence_id integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.current_relation_members OWNER TO openstreetmap;

--
-- TOC entry 255 (class 1259 OID 4546180)
-- Name: current_relation_tags; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.current_relation_tags (
    relation_id bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.current_relation_tags OWNER TO openstreetmap;

--
-- TOC entry 257 (class 1259 OID 4546192)
-- Name: current_relations; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.current_relations (
    id bigint NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    visible boolean NOT NULL,
    version bigint NOT NULL
);


ALTER TABLE public.current_relations OWNER TO openstreetmap;

--
-- TOC entry 256 (class 1259 OID 4546190)
-- Name: current_relations_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.current_relations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.current_relations_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4030 (class 0 OID 0)
-- Dependencies: 256
-- Name: current_relations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.current_relations_id_seq OWNED BY public.current_relations.id;


--
-- TOC entry 262 (class 1259 OID 4546232)
-- Name: current_way_nodes; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.current_way_nodes (
    way_id bigint NOT NULL,
    node_id bigint NOT NULL,
    sequence_id bigint NOT NULL
);


ALTER TABLE public.current_way_nodes OWNER TO openstreetmap;

--
-- TOC entry 230 (class 1259 OID 4545864)
-- Name: current_way_tags; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.current_way_tags (
    way_id bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.current_way_tags OWNER TO openstreetmap;

--
-- TOC entry 232 (class 1259 OID 4545876)
-- Name: current_ways; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.current_ways (
    id bigint NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    visible boolean NOT NULL,
    version bigint NOT NULL
);


ALTER TABLE public.current_ways OWNER TO openstreetmap;

--
-- TOC entry 231 (class 1259 OID 4545874)
-- Name: current_ways_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.current_ways_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.current_ways_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4031 (class 0 OID 0)
-- Dependencies: 231
-- Name: current_ways_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.current_ways_id_seq OWNED BY public.current_ways.id;


--
-- TOC entry 300 (class 1259 OID 4546985)
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.delayed_jobs (
    id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.delayed_jobs OWNER TO openstreetmap;

--
-- TOC entry 299 (class 1259 OID 4546983)
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delayed_jobs_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4032 (class 0 OID 0)
-- Dependencies: 299
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.delayed_jobs_id_seq OWNED BY public.delayed_jobs.id;


--
-- TOC entry 264 (class 1259 OID 4546255)
-- Name: diary_comments; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.diary_comments (
    id bigint NOT NULL,
    diary_entry_id bigint NOT NULL,
    user_id bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    body_format public.format_enum DEFAULT 'markdown'::public.format_enum NOT NULL
);


ALTER TABLE public.diary_comments OWNER TO openstreetmap;

--
-- TOC entry 263 (class 1259 OID 4546253)
-- Name: diary_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.diary_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.diary_comments_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4033 (class 0 OID 0)
-- Dependencies: 263
-- Name: diary_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.diary_comments_id_seq OWNED BY public.diary_comments.id;


--
-- TOC entry 234 (class 1259 OID 4545884)
-- Name: diary_entries; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.diary_entries (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    title character varying NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    latitude double precision,
    longitude double precision,
    language_code character varying DEFAULT 'en'::character varying NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    body_format public.format_enum DEFAULT 'markdown'::public.format_enum NOT NULL
);


ALTER TABLE public.diary_entries OWNER TO openstreetmap;

--
-- TOC entry 233 (class 1259 OID 4545882)
-- Name: diary_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.diary_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.diary_entries_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4034 (class 0 OID 0)
-- Dependencies: 233
-- Name: diary_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.diary_entries_id_seq OWNED BY public.diary_entries.id;


--
-- TOC entry 298 (class 1259 OID 4546964)
-- Name: diary_entry_subscriptions; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.diary_entry_subscriptions (
    user_id bigint NOT NULL,
    diary_entry_id bigint NOT NULL
);


ALTER TABLE public.diary_entry_subscriptions OWNER TO openstreetmap;

--
-- TOC entry 236 (class 1259 OID 4545895)
-- Name: friends; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.friends (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    friend_user_id bigint NOT NULL,
    created_at timestamp without time zone
);


ALTER TABLE public.friends OWNER TO openstreetmap;

--
-- TOC entry 235 (class 1259 OID 4545893)
-- Name: friends_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.friends_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.friends_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4035 (class 0 OID 0)
-- Dependencies: 235
-- Name: friends_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.friends_id_seq OWNED BY public.friends.id;


--
-- TOC entry 237 (class 1259 OID 4545902)
-- Name: gps_points; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.gps_points (
    altitude double precision,
    trackid integer NOT NULL,
    latitude integer NOT NULL,
    longitude integer NOT NULL,
    gpx_id bigint NOT NULL,
    "timestamp" timestamp without time zone,
    tile bigint
);


ALTER TABLE public.gps_points OWNER TO openstreetmap;

--
-- TOC entry 239 (class 1259 OID 4545910)
-- Name: gpx_file_tags; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.gpx_file_tags (
    gpx_id bigint DEFAULT 0 NOT NULL,
    tag character varying NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE public.gpx_file_tags OWNER TO openstreetmap;

--
-- TOC entry 238 (class 1259 OID 4545908)
-- Name: gpx_file_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.gpx_file_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gpx_file_tags_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4036 (class 0 OID 0)
-- Dependencies: 238
-- Name: gpx_file_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.gpx_file_tags_id_seq OWNED BY public.gpx_file_tags.id;


--
-- TOC entry 241 (class 1259 OID 4545923)
-- Name: gpx_files; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.gpx_files (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    size bigint,
    latitude double precision,
    longitude double precision,
    "timestamp" timestamp without time zone NOT NULL,
    description character varying DEFAULT ''::character varying NOT NULL,
    inserted boolean NOT NULL,
    visibility public.gpx_visibility_enum DEFAULT 'public'::public.gpx_visibility_enum NOT NULL
);


ALTER TABLE public.gpx_files OWNER TO openstreetmap;

--
-- TOC entry 240 (class 1259 OID 4545921)
-- Name: gpx_files_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.gpx_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gpx_files_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4037 (class 0 OID 0)
-- Dependencies: 240
-- Name: gpx_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.gpx_files_id_seq OWNED BY public.gpx_files.id;


--
-- TOC entry 297 (class 1259 OID 4546943)
-- Name: issue_comments; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.issue_comments (
    id integer NOT NULL,
    issue_id integer NOT NULL,
    user_id integer NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.issue_comments OWNER TO openstreetmap;

--
-- TOC entry 296 (class 1259 OID 4546941)
-- Name: issue_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.issue_comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.issue_comments_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4038 (class 0 OID 0)
-- Dependencies: 296
-- Name: issue_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.issue_comments_id_seq OWNED BY public.issue_comments.id;


--
-- TOC entry 293 (class 1259 OID 4546887)
-- Name: issues; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.issues (
    id integer NOT NULL,
    reportable_type character varying NOT NULL,
    reportable_id integer NOT NULL,
    reported_user_id integer,
    status public.issue_status_enum DEFAULT 'open'::public.issue_status_enum NOT NULL,
    assigned_role public.user_role_enum NOT NULL,
    resolved_at timestamp without time zone,
    resolved_by integer,
    updated_by integer,
    reports_count integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.issues OWNER TO openstreetmap;

--
-- TOC entry 292 (class 1259 OID 4546885)
-- Name: issues_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.issues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.issues_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4039 (class 0 OID 0)
-- Dependencies: 292
-- Name: issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.issues_id_seq OWNED BY public.issues.id;


--
-- TOC entry 272 (class 1259 OID 4546521)
-- Name: languages; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.languages (
    code character varying NOT NULL,
    english_name character varying NOT NULL,
    native_name character varying
);


ALTER TABLE public.languages OWNER TO openstreetmap;

--
-- TOC entry 243 (class 1259 OID 4545946)
-- Name: messages; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    from_user_id bigint NOT NULL,
    title character varying NOT NULL,
    body text NOT NULL,
    sent_on timestamp without time zone NOT NULL,
    message_read boolean DEFAULT false NOT NULL,
    to_user_id bigint NOT NULL,
    to_user_visible boolean DEFAULT true NOT NULL,
    from_user_visible boolean DEFAULT true NOT NULL,
    body_format public.format_enum DEFAULT 'markdown'::public.format_enum NOT NULL
);


ALTER TABLE public.messages OWNER TO openstreetmap;

--
-- TOC entry 242 (class 1259 OID 4545944)
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.messages_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4040 (class 0 OID 0)
-- Dependencies: 242
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- TOC entry 313 (class 1259 OID 5413957)
-- Name: mytagchanges; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mytagchanges (
    way_id bigint,
    version bigint,
    k character varying,
    v character varying
);


ALTER TABLE public.mytagchanges OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 4546298)
-- Name: node_tags; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.node_tags (
    node_id bigint NOT NULL,
    version bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.node_tags OWNER TO openstreetmap;

--
-- TOC entry 253 (class 1259 OID 4546144)
-- Name: nodes; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.nodes (
    node_id bigint NOT NULL,
    latitude integer NOT NULL,
    longitude integer NOT NULL,
    changeset_id bigint NOT NULL,
    visible boolean NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    tile bigint NOT NULL,
    version bigint NOT NULL,
    redaction_id integer
);


ALTER TABLE public.nodes OWNER TO openstreetmap;

--
-- TOC entry 286 (class 1259 OID 4546721)
-- Name: note_comments; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.note_comments (
    id bigint NOT NULL,
    note_id bigint NOT NULL,
    visible boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    author_ip inet,
    author_id bigint,
    body text,
    event public.note_event_enum
);


ALTER TABLE public.note_comments OWNER TO openstreetmap;

--
-- TOC entry 285 (class 1259 OID 4546719)
-- Name: note_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.note_comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.note_comments_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4041 (class 0 OID 0)
-- Dependencies: 285
-- Name: note_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.note_comments_id_seq OWNED BY public.note_comments.id;


--
-- TOC entry 284 (class 1259 OID 4546697)
-- Name: notes; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.notes (
    id bigint NOT NULL,
    latitude integer NOT NULL,
    longitude integer NOT NULL,
    tile bigint NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    status public.note_status_enum NOT NULL,
    closed_at timestamp without time zone
);


ALTER TABLE public.notes OWNER TO openstreetmap;

--
-- TOC entry 283 (class 1259 OID 4546695)
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.notes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notes_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4042 (class 0 OID 0)
-- Dependencies: 283
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;


--
-- TOC entry 308 (class 1259 OID 4547052)
-- Name: oauth_access_grants; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.oauth_access_grants (
    id bigint NOT NULL,
    resource_owner_id bigint NOT NULL,
    application_id bigint NOT NULL,
    token character varying NOT NULL,
    expires_in integer NOT NULL,
    redirect_uri text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    revoked_at timestamp without time zone,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    code_challenge character varying,
    code_challenge_method character varying
);


ALTER TABLE public.oauth_access_grants OWNER TO openstreetmap;

--
-- TOC entry 307 (class 1259 OID 4547050)
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.oauth_access_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.oauth_access_grants_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4043 (class 0 OID 0)
-- Dependencies: 307
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.oauth_access_grants_id_seq OWNED BY public.oauth_access_grants.id;


--
-- TOC entry 310 (class 1259 OID 4547077)
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.oauth_access_tokens (
    id bigint NOT NULL,
    resource_owner_id bigint,
    application_id bigint NOT NULL,
    token character varying NOT NULL,
    refresh_token character varying,
    expires_in integer,
    revoked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    scopes character varying,
    previous_refresh_token character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.oauth_access_tokens OWNER TO openstreetmap;

--
-- TOC entry 309 (class 1259 OID 4547075)
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.oauth_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.oauth_access_tokens_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4044 (class 0 OID 0)
-- Dependencies: 309
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.oauth_access_tokens_id_seq OWNED BY public.oauth_access_tokens.id;


--
-- TOC entry 306 (class 1259 OID 4547032)
-- Name: oauth_applications; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.oauth_applications (
    id bigint NOT NULL,
    owner_type character varying NOT NULL,
    owner_id bigint NOT NULL,
    name character varying NOT NULL,
    uid character varying NOT NULL,
    secret character varying NOT NULL,
    redirect_uri text NOT NULL,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    confidential boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.oauth_applications OWNER TO openstreetmap;

--
-- TOC entry 305 (class 1259 OID 4547030)
-- Name: oauth_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.oauth_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.oauth_applications_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4045 (class 0 OID 0)
-- Dependencies: 305
-- Name: oauth_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.oauth_applications_id_seq OWNED BY public.oauth_applications.id;


--
-- TOC entry 278 (class 1259 OID 4546576)
-- Name: oauth_nonces; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.oauth_nonces (
    id bigint NOT NULL,
    nonce character varying,
    "timestamp" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.oauth_nonces OWNER TO openstreetmap;

--
-- TOC entry 277 (class 1259 OID 4546574)
-- Name: oauth_nonces_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.oauth_nonces_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.oauth_nonces_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4046 (class 0 OID 0)
-- Dependencies: 277
-- Name: oauth_nonces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.oauth_nonces_id_seq OWNED BY public.oauth_nonces.id;


--
-- TOC entry 276 (class 1259 OID 4546567)
-- Name: oauth_tokens; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.oauth_tokens (
    id integer NOT NULL,
    user_id integer,
    type character varying(20),
    client_application_id integer,
    token character varying(50),
    secret character varying(50),
    authorized_at timestamp without time zone,
    invalidated_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    allow_read_prefs boolean DEFAULT false NOT NULL,
    allow_write_prefs boolean DEFAULT false NOT NULL,
    allow_write_diary boolean DEFAULT false NOT NULL,
    allow_write_api boolean DEFAULT false NOT NULL,
    allow_read_gpx boolean DEFAULT false NOT NULL,
    allow_write_gpx boolean DEFAULT false NOT NULL,
    callback_url character varying,
    verifier character varying(20),
    scope character varying,
    valid_to timestamp without time zone,
    allow_write_notes boolean DEFAULT false NOT NULL
);


ALTER TABLE public.oauth_tokens OWNER TO openstreetmap;

--
-- TOC entry 275 (class 1259 OID 4546565)
-- Name: oauth_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.oauth_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.oauth_tokens_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4047 (class 0 OID 0)
-- Dependencies: 275
-- Name: oauth_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.oauth_tokens_id_seq OWNED BY public.oauth_tokens.id;


--
-- TOC entry 288 (class 1259 OID 4546786)
-- Name: redactions; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.redactions (
    id integer NOT NULL,
    title character varying,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id bigint NOT NULL,
    description_format public.format_enum DEFAULT 'markdown'::public.format_enum NOT NULL
);


ALTER TABLE public.redactions OWNER TO openstreetmap;

--
-- TOC entry 287 (class 1259 OID 4546784)
-- Name: redactions_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.redactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.redactions_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4048 (class 0 OID 0)
-- Dependencies: 287
-- Name: redactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.redactions_id_seq OWNED BY public.redactions.id;


--
-- TOC entry 258 (class 1259 OID 4546198)
-- Name: relation_members; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.relation_members (
    relation_id bigint DEFAULT 0 NOT NULL,
    member_type public.nwr_enum NOT NULL,
    member_id bigint NOT NULL,
    member_role character varying NOT NULL,
    version bigint DEFAULT 0 NOT NULL,
    sequence_id integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.relation_members OWNER TO openstreetmap;

--
-- TOC entry 259 (class 1259 OID 4546209)
-- Name: relation_tags; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.relation_tags (
    relation_id bigint DEFAULT 0 NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL,
    version bigint NOT NULL
);


ALTER TABLE public.relation_tags OWNER TO openstreetmap;

--
-- TOC entry 260 (class 1259 OID 4546219)
-- Name: relations; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.relations (
    relation_id bigint DEFAULT 0 NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    version bigint NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    redaction_id integer,
    x integer
);


ALTER TABLE public.relations OWNER TO openstreetmap;

--
-- TOC entry 295 (class 1259 OID 4546920)
-- Name: reports; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.reports (
    id integer NOT NULL,
    issue_id integer NOT NULL,
    user_id integer NOT NULL,
    details text NOT NULL,
    category character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.reports OWNER TO openstreetmap;

--
-- TOC entry 294 (class 1259 OID 4546918)
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.reports_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4049 (class 0 OID 0)
-- Dependencies: 294
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.reports_id_seq OWNED BY public.reports.id;


--
-- TOC entry 228 (class 1259 OID 4545823)
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO openstreetmap;

--
-- TOC entry 282 (class 1259 OID 4546634)
-- Name: user_blocks; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.user_blocks (
    id integer NOT NULL,
    user_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    reason text NOT NULL,
    ends_at timestamp without time zone NOT NULL,
    needs_view boolean DEFAULT false NOT NULL,
    revoker_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    reason_format public.format_enum DEFAULT 'markdown'::public.format_enum NOT NULL
);


ALTER TABLE public.user_blocks OWNER TO openstreetmap;

--
-- TOC entry 281 (class 1259 OID 4546632)
-- Name: user_blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.user_blocks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_blocks_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4050 (class 0 OID 0)
-- Dependencies: 281
-- Name: user_blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.user_blocks_id_seq OWNED BY public.user_blocks.id;


--
-- TOC entry 248 (class 1259 OID 4546097)
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.user_preferences (
    user_id bigint NOT NULL,
    k character varying NOT NULL,
    v character varying NOT NULL
);


ALTER TABLE public.user_preferences OWNER TO openstreetmap;

--
-- TOC entry 280 (class 1259 OID 4546621)
-- Name: user_roles; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.user_roles (
    id integer NOT NULL,
    user_id bigint NOT NULL,
    role public.user_role_enum NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    granter_id bigint NOT NULL
);


ALTER TABLE public.user_roles OWNER TO openstreetmap;

--
-- TOC entry 279 (class 1259 OID 4546619)
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.user_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_roles_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4051 (class 0 OID 0)
-- Dependencies: 279
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.user_roles_id_seq OWNED BY public.user_roles.id;


--
-- TOC entry 250 (class 1259 OID 4546107)
-- Name: user_tokens; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.user_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token character varying NOT NULL,
    expiry timestamp without time zone NOT NULL,
    referer text
);


ALTER TABLE public.user_tokens OWNER TO openstreetmap;

--
-- TOC entry 249 (class 1259 OID 4546105)
-- Name: user_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.user_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_tokens_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4052 (class 0 OID 0)
-- Dependencies: 249
-- Name: user_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.user_tokens_id_seq OWNED BY public.user_tokens.id;


--
-- TOC entry 245 (class 1259 OID 4545987)
-- Name: users; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.users (
    email character varying NOT NULL,
    id bigint NOT NULL,
    pass_crypt character varying NOT NULL,
    creation_time timestamp without time zone NOT NULL,
    display_name character varying DEFAULT ''::character varying NOT NULL,
    data_public boolean DEFAULT false NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    home_lat double precision,
    home_lon double precision,
    home_zoom smallint DEFAULT 3,
    pass_salt character varying,
    email_valid boolean DEFAULT false NOT NULL,
    new_email character varying,
    creation_ip character varying,
    languages character varying,
    status public.user_status_enum DEFAULT 'pending'::public.user_status_enum NOT NULL,
    terms_agreed timestamp without time zone,
    consider_pd boolean DEFAULT false NOT NULL,
    auth_uid character varying,
    preferred_editor character varying,
    terms_seen boolean DEFAULT false NOT NULL,
    description_format public.format_enum DEFAULT 'markdown'::public.format_enum NOT NULL,
    changesets_count integer DEFAULT 0 NOT NULL,
    traces_count integer DEFAULT 0 NOT NULL,
    diary_entries_count integer DEFAULT 0 NOT NULL,
    image_use_gravatar boolean DEFAULT false NOT NULL,
    auth_provider character varying,
    home_tile bigint,
    tou_agreed timestamp without time zone
);


ALTER TABLE public.users OWNER TO openstreetmap;

--
-- TOC entry 244 (class 1259 OID 4545985)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: openstreetmap
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO openstreetmap;

--
-- TOC entry 4053 (class 0 OID 0)
-- Dependencies: 244
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openstreetmap
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 261 (class 1259 OID 4546227)
-- Name: way_nodes; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.way_nodes (
    way_id bigint NOT NULL,
    node_id bigint NOT NULL,
    version bigint NOT NULL,
    sequence_id bigint NOT NULL
);


ALTER TABLE public.way_nodes OWNER TO openstreetmap;

--
-- TOC entry 246 (class 1259 OID 4546012)
-- Name: way_tags; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.way_tags (
    way_id bigint DEFAULT 0 NOT NULL,
    k character varying NOT NULL,
    v character varying NOT NULL,
    version bigint NOT NULL
);


ALTER TABLE public.way_tags OWNER TO openstreetmap;

--
-- TOC entry 247 (class 1259 OID 4546020)
-- Name: ways; Type: TABLE; Schema: public; Owner: openstreetmap
--

CREATE TABLE public.ways (
    way_id bigint DEFAULT 0 NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    version bigint NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    redaction_id integer
);


ALTER TABLE public.ways OWNER TO openstreetmap;

--
-- TOC entry 3578 (class 2604 OID 4546275)
-- Name: acls id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.acls ALTER COLUMN id SET DEFAULT nextval('public.acls_id_seq'::regclass);


--
-- TOC entry 3622 (class 2604 OID 4547017)
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- TOC entry 3621 (class 2604 OID 4547005)
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- TOC entry 3630 (class 2604 OID 4547120)
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- TOC entry 3612 (class 2604 OID 4546838)
-- Name: changeset_comments id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.changeset_comments ALTER COLUMN id SET DEFAULT nextval('public.changeset_comments_id_seq'::regclass);


--
-- TOC entry 3583 (class 2604 OID 4546384)
-- Name: changesets id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.changesets ALTER COLUMN id SET DEFAULT nextval('public.changesets_id_seq'::regclass);


--
-- TOC entry 3587 (class 2604 OID 4546558)
-- Name: client_applications id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.client_applications ALTER COLUMN id SET DEFAULT nextval('public.client_applications_id_seq'::regclass);


--
-- TOC entry 3562 (class 2604 OID 4546125)
-- Name: current_nodes id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_nodes ALTER COLUMN id SET DEFAULT nextval('public.current_nodes_id_seq'::regclass);


--
-- TOC entry 3566 (class 2604 OID 4546195)
-- Name: current_relations id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_relations ALTER COLUMN id SET DEFAULT nextval('public.current_relations_id_seq'::regclass);


--
-- TOC entry 3526 (class 2604 OID 4545879)
-- Name: current_ways id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_ways ALTER COLUMN id SET DEFAULT nextval('public.current_ways_id_seq'::regclass);


--
-- TOC entry 3618 (class 2604 OID 4546988)
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- TOC entry 3575 (class 2604 OID 4546258)
-- Name: diary_comments id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.diary_comments ALTER COLUMN id SET DEFAULT nextval('public.diary_comments_id_seq'::regclass);


--
-- TOC entry 3527 (class 2604 OID 4545887)
-- Name: diary_entries id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.diary_entries ALTER COLUMN id SET DEFAULT nextval('public.diary_entries_id_seq'::regclass);


--
-- TOC entry 3531 (class 2604 OID 4545898)
-- Name: friends id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.friends ALTER COLUMN id SET DEFAULT nextval('public.friends_id_seq'::regclass);


--
-- TOC entry 3533 (class 2604 OID 4545914)
-- Name: gpx_file_tags id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.gpx_file_tags ALTER COLUMN id SET DEFAULT nextval('public.gpx_file_tags_id_seq'::regclass);


--
-- TOC entry 3534 (class 2604 OID 4545926)
-- Name: gpx_files id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.gpx_files ALTER COLUMN id SET DEFAULT nextval('public.gpx_files_id_seq'::regclass);


--
-- TOC entry 3617 (class 2604 OID 4546946)
-- Name: issue_comments id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.issue_comments ALTER COLUMN id SET DEFAULT nextval('public.issue_comments_id_seq'::regclass);


--
-- TOC entry 3613 (class 2604 OID 4546890)
-- Name: issues id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.issues ALTER COLUMN id SET DEFAULT nextval('public.issues_id_seq'::regclass);


--
-- TOC entry 3539 (class 2604 OID 4545949)
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- TOC entry 3609 (class 2604 OID 4546730)
-- Name: note_comments id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.note_comments ALTER COLUMN id SET DEFAULT nextval('public.note_comments_id_seq'::regclass);


--
-- TOC entry 3608 (class 2604 OID 4546706)
-- Name: notes id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);


--
-- TOC entry 3626 (class 2604 OID 4547055)
-- Name: oauth_access_grants id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_access_grants ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_grants_id_seq'::regclass);


--
-- TOC entry 3628 (class 2604 OID 4547080)
-- Name: oauth_access_tokens id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_tokens_id_seq'::regclass);


--
-- TOC entry 3623 (class 2604 OID 4547035)
-- Name: oauth_applications id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_applications ALTER COLUMN id SET DEFAULT nextval('public.oauth_applications_id_seq'::regclass);


--
-- TOC entry 3603 (class 2604 OID 4547103)
-- Name: oauth_nonces id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_nonces ALTER COLUMN id SET DEFAULT nextval('public.oauth_nonces_id_seq'::regclass);


--
-- TOC entry 3595 (class 2604 OID 4546570)
-- Name: oauth_tokens id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_tokens ALTER COLUMN id SET DEFAULT nextval('public.oauth_tokens_id_seq'::regclass);


--
-- TOC entry 3610 (class 2604 OID 4546789)
-- Name: redactions id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.redactions ALTER COLUMN id SET DEFAULT nextval('public.redactions_id_seq'::regclass);


--
-- TOC entry 3616 (class 2604 OID 4546923)
-- Name: reports id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.reports ALTER COLUMN id SET DEFAULT nextval('public.reports_id_seq'::regclass);


--
-- TOC entry 3605 (class 2604 OID 4546637)
-- Name: user_blocks id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.user_blocks ALTER COLUMN id SET DEFAULT nextval('public.user_blocks_id_seq'::regclass);


--
-- TOC entry 3604 (class 2604 OID 4546624)
-- Name: user_roles id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN id SET DEFAULT nextval('public.user_roles_id_seq'::regclass);


--
-- TOC entry 3561 (class 2604 OID 4546110)
-- Name: user_tokens id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.user_tokens ALTER COLUMN id SET DEFAULT nextval('public.user_tokens_id_seq'::regclass);


--
-- TOC entry 3544 (class 2604 OID 4545990)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 3722 (class 2606 OID 4546280)
-- Name: acls acls_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.acls
    ADD CONSTRAINT acls_pkey PRIMARY KEY (id);


--
-- TOC entry 3800 (class 2606 OID 4547022)
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- TOC entry 3797 (class 2606 OID 4547010)
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- TOC entry 3819 (class 2606 OID 4547125)
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- TOC entry 3634 (class 2606 OID 4545838)
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- TOC entry 3770 (class 2606 OID 4546843)
-- Name: changeset_comments changeset_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.changeset_comments
    ADD CONSTRAINT changeset_comments_pkey PRIMARY KEY (id);


--
-- TOC entry 3734 (class 2606 OID 4546387)
-- Name: changesets changesets_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.changesets
    ADD CONSTRAINT changesets_pkey PRIMARY KEY (id);


--
-- TOC entry 3741 (class 2606 OID 4546563)
-- Name: client_applications client_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.client_applications
    ADD CONSTRAINT client_applications_pkey PRIMARY KEY (id);


--
-- TOC entry 3727 (class 2606 OID 4546311)
-- Name: current_node_tags current_node_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_node_tags
    ADD CONSTRAINT current_node_tags_pkey PRIMARY KEY (node_id, k);


--
-- TOC entry 3685 (class 2606 OID 4546131)
-- Name: current_nodes current_nodes_pkey1; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_nodes
    ADD CONSTRAINT current_nodes_pkey1 PRIMARY KEY (id);


--
-- TOC entry 3695 (class 2606 OID 4546432)
-- Name: current_relation_members current_relation_members_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_relation_members
    ADD CONSTRAINT current_relation_members_pkey PRIMARY KEY (relation_id, member_type, member_id, member_role, sequence_id);


--
-- TOC entry 3697 (class 2606 OID 4546315)
-- Name: current_relation_tags current_relation_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_relation_tags
    ADD CONSTRAINT current_relation_tags_pkey PRIMARY KEY (relation_id, k);


--
-- TOC entry 3699 (class 2606 OID 4546197)
-- Name: current_relations current_relations_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_relations
    ADD CONSTRAINT current_relations_pkey PRIMARY KEY (id);


--
-- TOC entry 3715 (class 2606 OID 4546236)
-- Name: current_way_nodes current_way_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_way_nodes
    ADD CONSTRAINT current_way_nodes_pkey PRIMARY KEY (way_id, sequence_id);


--
-- TOC entry 3636 (class 2606 OID 4546313)
-- Name: current_way_tags current_way_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_way_tags
    ADD CONSTRAINT current_way_tags_pkey PRIMARY KEY (way_id, k);


--
-- TOC entry 3638 (class 2606 OID 4545881)
-- Name: current_ways current_ways_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_ways
    ADD CONSTRAINT current_ways_pkey PRIMARY KEY (id);


--
-- TOC entry 3794 (class 2606 OID 4546995)
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 3719 (class 2606 OID 4546263)
-- Name: diary_comments diary_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.diary_comments
    ADD CONSTRAINT diary_comments_pkey PRIMARY KEY (id);


--
-- TOC entry 3641 (class 2606 OID 4545892)
-- Name: diary_entries diary_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.diary_entries
    ADD CONSTRAINT diary_entries_pkey PRIMARY KEY (id);


--
-- TOC entry 3791 (class 2606 OID 4546968)
-- Name: diary_entry_subscriptions diary_entry_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.diary_entry_subscriptions
    ADD CONSTRAINT diary_entry_subscriptions_pkey PRIMARY KEY (user_id, diary_entry_id);


--
-- TOC entry 3646 (class 2606 OID 4545900)
-- Name: friends friends_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.friends
    ADD CONSTRAINT friends_pkey PRIMARY KEY (id);


--
-- TOC entry 3653 (class 2606 OID 4545919)
-- Name: gpx_file_tags gpx_file_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.gpx_file_tags
    ADD CONSTRAINT gpx_file_tags_pkey PRIMARY KEY (id);


--
-- TOC entry 3656 (class 2606 OID 4545935)
-- Name: gpx_files gpx_files_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.gpx_files
    ADD CONSTRAINT gpx_files_pkey PRIMARY KEY (id);


--
-- TOC entry 3789 (class 2606 OID 4546951)
-- Name: issue_comments issue_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.issue_comments
    ADD CONSTRAINT issue_comments_pkey PRIMARY KEY (id);


--
-- TOC entry 3781 (class 2606 OID 4546897)
-- Name: issues issues_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);


--
-- TOC entry 3739 (class 2606 OID 4546528)
-- Name: languages languages_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (code);


--
-- TOC entry 3662 (class 2606 OID 4545956)
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- TOC entry 3729 (class 2606 OID 4546317)
-- Name: node_tags node_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.node_tags
    ADD CONSTRAINT node_tags_pkey PRIMARY KEY (node_id, version, k);


--
-- TOC entry 3690 (class 2606 OID 4546323)
-- Name: nodes nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.nodes
    ADD CONSTRAINT nodes_pkey PRIMARY KEY (node_id, version);


--
-- TOC entry 3766 (class 2606 OID 4546732)
-- Name: note_comments note_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.note_comments
    ADD CONSTRAINT note_comments_pkey PRIMARY KEY (id);


--
-- TOC entry 3759 (class 2606 OID 4546708)
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- TOC entry 3811 (class 2606 OID 4547061)
-- Name: oauth_access_grants oauth_access_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT oauth_access_grants_pkey PRIMARY KEY (id);


--
-- TOC entry 3817 (class 2606 OID 4547086)
-- Name: oauth_access_tokens oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 3806 (class 2606 OID 4547042)
-- Name: oauth_applications oauth_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_applications
    ADD CONSTRAINT oauth_applications_pkey PRIMARY KEY (id);


--
-- TOC entry 3750 (class 2606 OID 4547105)
-- Name: oauth_nonces oauth_nonces_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_nonces
    ADD CONSTRAINT oauth_nonces_pkey PRIMARY KEY (id);


--
-- TOC entry 3747 (class 2606 OID 4546572)
-- Name: oauth_tokens oauth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 3768 (class 2606 OID 4546794)
-- Name: redactions redactions_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.redactions
    ADD CONSTRAINT redactions_pkey PRIMARY KEY (id);


--
-- TOC entry 3703 (class 2606 OID 4546429)
-- Name: relation_members relation_members_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.relation_members
    ADD CONSTRAINT relation_members_pkey PRIMARY KEY (relation_id, version, member_type, member_id, member_role, sequence_id);


--
-- TOC entry 3705 (class 2606 OID 4546321)
-- Name: relation_tags relation_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.relation_tags
    ADD CONSTRAINT relation_tags_pkey PRIMARY KEY (relation_id, version, k);


--
-- TOC entry 3708 (class 2606 OID 4547313)
-- Name: relations relations_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.relations
    ADD CONSTRAINT relations_pkey PRIMARY KEY (relation_id, version);


--
-- TOC entry 3785 (class 2606 OID 4546928)
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- TOC entry 3632 (class 2606 OID 4545830)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- TOC entry 3756 (class 2606 OID 4546643)
-- Name: user_blocks user_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT user_blocks_pkey PRIMARY KEY (id);


--
-- TOC entry 3679 (class 2606 OID 4546104)
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (user_id, k);


--
-- TOC entry 3753 (class 2606 OID 4546626)
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 3681 (class 2606 OID 4546115)
-- Name: user_tokens user_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 3671 (class 2606 OID 4546002)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3712 (class 2606 OID 4546231)
-- Name: way_nodes way_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.way_nodes
    ADD CONSTRAINT way_nodes_pkey PRIMARY KEY (way_id, version, sequence_id);


--
-- TOC entry 3673 (class 2606 OID 4546319)
-- Name: way_tags way_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.way_tags
    ADD CONSTRAINT way_tags_pkey PRIMARY KEY (way_id, version, k);


--
-- TOC entry 3676 (class 2606 OID 4546307)
-- Name: ways ways_pkey; Type: CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.ways
    ADD CONSTRAINT ways_pkey PRIMARY KEY (way_id, version);


--
-- TOC entry 3720 (class 1259 OID 4546281)
-- Name: acls_k_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX acls_k_idx ON public.acls USING btree (k);


--
-- TOC entry 3737 (class 1259 OID 4546396)
-- Name: changeset_tags_id_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX changeset_tags_id_idx ON public.changeset_tags USING btree (changeset_id);


--
-- TOC entry 3730 (class 1259 OID 4546440)
-- Name: changesets_bbox_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX changesets_bbox_idx ON public.changesets USING gist (min_lat, max_lat, min_lon, max_lon);


--
-- TOC entry 3731 (class 1259 OID 4546439)
-- Name: changesets_closed_at_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX changesets_closed_at_idx ON public.changesets USING btree (closed_at);


--
-- TOC entry 3732 (class 1259 OID 4546438)
-- Name: changesets_created_at_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX changesets_created_at_idx ON public.changesets USING btree (created_at);


--
-- TOC entry 3735 (class 1259 OID 4546763)
-- Name: changesets_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX changesets_user_id_created_at_idx ON public.changesets USING btree (user_id, created_at);


--
-- TOC entry 3736 (class 1259 OID 4546671)
-- Name: changesets_user_id_id_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX changesets_user_id_id_idx ON public.changesets USING btree (user_id, id);


--
-- TOC entry 3686 (class 1259 OID 4546134)
-- Name: current_nodes_tile_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX current_nodes_tile_idx ON public.current_nodes USING btree (tile);


--
-- TOC entry 3687 (class 1259 OID 4546132)
-- Name: current_nodes_timestamp_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX current_nodes_timestamp_idx ON public.current_nodes USING btree ("timestamp");


--
-- TOC entry 3693 (class 1259 OID 4546179)
-- Name: current_relation_members_member_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX current_relation_members_member_idx ON public.current_relation_members USING btree (member_type, member_id);


--
-- TOC entry 3700 (class 1259 OID 4546283)
-- Name: current_relations_timestamp_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX current_relations_timestamp_idx ON public.current_relations USING btree ("timestamp");


--
-- TOC entry 3713 (class 1259 OID 4546237)
-- Name: current_way_nodes_node_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX current_way_nodes_node_idx ON public.current_way_nodes USING btree (node_id);


--
-- TOC entry 3639 (class 1259 OID 4546282)
-- Name: current_ways_timestamp_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX current_ways_timestamp_idx ON public.current_ways USING btree ("timestamp");


--
-- TOC entry 3795 (class 1259 OID 4546996)
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX delayed_jobs_priority ON public.delayed_jobs USING btree (priority, run_at);


--
-- TOC entry 3716 (class 1259 OID 4546672)
-- Name: diary_comment_user_id_created_at_index; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX diary_comment_user_id_created_at_index ON public.diary_comments USING btree (user_id, created_at);


--
-- TOC entry 3717 (class 1259 OID 4546264)
-- Name: diary_comments_entry_id_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX diary_comments_entry_id_idx ON public.diary_comments USING btree (diary_entry_id, id);


--
-- TOC entry 3642 (class 1259 OID 4546668)
-- Name: diary_entry_created_at_index; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX diary_entry_created_at_index ON public.diary_entries USING btree (created_at);


--
-- TOC entry 3643 (class 1259 OID 4546670)
-- Name: diary_entry_language_code_created_at_index; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX diary_entry_language_code_created_at_index ON public.diary_entries USING btree (language_code, created_at);


--
-- TOC entry 3644 (class 1259 OID 4546669)
-- Name: diary_entry_user_id_created_at_index; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX diary_entry_user_id_created_at_index ON public.diary_entries USING btree (user_id, created_at);


--
-- TOC entry 3651 (class 1259 OID 4545920)
-- Name: gpx_file_tags_gpxid_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX gpx_file_tags_gpxid_idx ON public.gpx_file_tags USING btree (gpx_id);


--
-- TOC entry 3654 (class 1259 OID 4546269)
-- Name: gpx_file_tags_tag_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX gpx_file_tags_tag_idx ON public.gpx_file_tags USING btree (tag);


--
-- TOC entry 3657 (class 1259 OID 4546053)
-- Name: gpx_files_timestamp_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX gpx_files_timestamp_idx ON public.gpx_files USING btree ("timestamp");


--
-- TOC entry 3658 (class 1259 OID 4546268)
-- Name: gpx_files_user_id_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX gpx_files_user_id_idx ON public.gpx_files USING btree (user_id);


--
-- TOC entry 3659 (class 1259 OID 4546552)
-- Name: gpx_files_visible_visibility_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX gpx_files_visible_visibility_idx ON public.gpx_files USING btree (visible, visibility);


--
-- TOC entry 3723 (class 1259 OID 4546998)
-- Name: index_acls_on_address; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_acls_on_address ON public.acls USING gist (address inet_ops);


--
-- TOC entry 3724 (class 1259 OID 4546997)
-- Name: index_acls_on_domain; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_acls_on_domain ON public.acls USING btree (domain);


--
-- TOC entry 3725 (class 1259 OID 4546999)
-- Name: index_acls_on_mx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_acls_on_mx ON public.acls USING btree (mx);


--
-- TOC entry 3801 (class 1259 OID 4547028)
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- TOC entry 3802 (class 1259 OID 4547029)
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- TOC entry 3798 (class 1259 OID 4547011)
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- TOC entry 3820 (class 1259 OID 4547131)
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- TOC entry 3771 (class 1259 OID 4547102)
-- Name: index_changeset_comments_on_changeset_id_and_created_at; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_changeset_comments_on_changeset_id_and_created_at ON public.changeset_comments USING btree (changeset_id, created_at);


--
-- TOC entry 3772 (class 1259 OID 4546854)
-- Name: index_changeset_comments_on_created_at; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_changeset_comments_on_created_at ON public.changeset_comments USING btree (created_at);


--
-- TOC entry 3773 (class 1259 OID 4546869)
-- Name: index_changesets_subscribers_on_changeset_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_changesets_subscribers_on_changeset_id ON public.changesets_subscribers USING btree (changeset_id);


--
-- TOC entry 3774 (class 1259 OID 4546868)
-- Name: index_changesets_subscribers_on_subscriber_id_and_changeset_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_changesets_subscribers_on_subscriber_id_and_changeset_id ON public.changesets_subscribers USING btree (subscriber_id, changeset_id);


--
-- TOC entry 3742 (class 1259 OID 4546564)
-- Name: index_client_applications_on_key; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_client_applications_on_key ON public.client_applications USING btree (key);


--
-- TOC entry 3743 (class 1259 OID 4546981)
-- Name: index_client_applications_on_user_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_client_applications_on_user_id ON public.client_applications USING btree (user_id);


--
-- TOC entry 3792 (class 1259 OID 4546969)
-- Name: index_diary_entry_subscriptions_on_diary_entry_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_diary_entry_subscriptions_on_diary_entry_id ON public.diary_entry_subscriptions USING btree (diary_entry_id);


--
-- TOC entry 3647 (class 1259 OID 4547132)
-- Name: index_friends_on_user_id_and_created_at; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_friends_on_user_id_and_created_at ON public.friends USING btree (user_id, created_at);


--
-- TOC entry 3786 (class 1259 OID 4546962)
-- Name: index_issue_comments_on_issue_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_issue_comments_on_issue_id ON public.issue_comments USING btree (issue_id);


--
-- TOC entry 3787 (class 1259 OID 4546963)
-- Name: index_issue_comments_on_user_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_issue_comments_on_user_id ON public.issue_comments USING btree (user_id);


--
-- TOC entry 3775 (class 1259 OID 4546916)
-- Name: index_issues_on_assigned_role; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_issues_on_assigned_role ON public.issues USING btree (assigned_role);


--
-- TOC entry 3776 (class 1259 OID 4546913)
-- Name: index_issues_on_reportable_type_and_reportable_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_issues_on_reportable_type_and_reportable_id ON public.issues USING btree (reportable_type, reportable_id);


--
-- TOC entry 3777 (class 1259 OID 4546914)
-- Name: index_issues_on_reported_user_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_issues_on_reported_user_id ON public.issues USING btree (reported_user_id);


--
-- TOC entry 3778 (class 1259 OID 4546915)
-- Name: index_issues_on_status; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_issues_on_status ON public.issues USING btree (status);


--
-- TOC entry 3779 (class 1259 OID 4546917)
-- Name: index_issues_on_updated_by; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_issues_on_updated_by ON public.issues USING btree (updated_by);


--
-- TOC entry 3762 (class 1259 OID 4546832)
-- Name: index_note_comments_on_body; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_note_comments_on_body ON public.note_comments USING gin (to_tsvector('english'::regconfig, body));


--
-- TOC entry 3763 (class 1259 OID 4546831)
-- Name: index_note_comments_on_created_at; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_note_comments_on_created_at ON public.note_comments USING btree (created_at);


--
-- TOC entry 3807 (class 1259 OID 4547063)
-- Name: index_oauth_access_grants_on_application_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_oauth_access_grants_on_application_id ON public.oauth_access_grants USING btree (application_id);


--
-- TOC entry 3808 (class 1259 OID 4547062)
-- Name: index_oauth_access_grants_on_resource_owner_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_oauth_access_grants_on_resource_owner_id ON public.oauth_access_grants USING btree (resource_owner_id);


--
-- TOC entry 3809 (class 1259 OID 4547064)
-- Name: index_oauth_access_grants_on_token; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_oauth_access_grants_on_token ON public.oauth_access_grants USING btree (token);


--
-- TOC entry 3812 (class 1259 OID 4547088)
-- Name: index_oauth_access_tokens_on_application_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_oauth_access_tokens_on_application_id ON public.oauth_access_tokens USING btree (application_id);


--
-- TOC entry 3813 (class 1259 OID 4547090)
-- Name: index_oauth_access_tokens_on_refresh_token; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_refresh_token ON public.oauth_access_tokens USING btree (refresh_token);


--
-- TOC entry 3814 (class 1259 OID 4547087)
-- Name: index_oauth_access_tokens_on_resource_owner_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_oauth_access_tokens_on_resource_owner_id ON public.oauth_access_tokens USING btree (resource_owner_id);


--
-- TOC entry 3815 (class 1259 OID 4547089)
-- Name: index_oauth_access_tokens_on_token; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_token ON public.oauth_access_tokens USING btree (token);


--
-- TOC entry 3803 (class 1259 OID 4547043)
-- Name: index_oauth_applications_on_owner_type_and_owner_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_oauth_applications_on_owner_type_and_owner_id ON public.oauth_applications USING btree (owner_type, owner_id);


--
-- TOC entry 3804 (class 1259 OID 4547044)
-- Name: index_oauth_applications_on_uid; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_oauth_applications_on_uid ON public.oauth_applications USING btree (uid);


--
-- TOC entry 3748 (class 1259 OID 4546585)
-- Name: index_oauth_nonces_on_nonce_and_timestamp; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_oauth_nonces_on_nonce_and_timestamp ON public.oauth_nonces USING btree (nonce, "timestamp");


--
-- TOC entry 3744 (class 1259 OID 4546573)
-- Name: index_oauth_tokens_on_token; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_oauth_tokens_on_token ON public.oauth_tokens USING btree (token);


--
-- TOC entry 3745 (class 1259 OID 4546980)
-- Name: index_oauth_tokens_on_user_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_oauth_tokens_on_user_id ON public.oauth_tokens USING btree (user_id);


--
-- TOC entry 3782 (class 1259 OID 4546939)
-- Name: index_reports_on_issue_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_reports_on_issue_id ON public.reports USING btree (issue_id);


--
-- TOC entry 3783 (class 1259 OID 4546940)
-- Name: index_reports_on_user_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_reports_on_user_id ON public.reports USING btree (user_id);


--
-- TOC entry 3754 (class 1259 OID 4546659)
-- Name: index_user_blocks_on_user_id; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX index_user_blocks_on_user_id ON public.user_blocks USING btree (user_id);


--
-- TOC entry 3660 (class 1259 OID 4546541)
-- Name: messages_from_user_id_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX messages_from_user_id_idx ON public.messages USING btree (from_user_id);


--
-- TOC entry 3663 (class 1259 OID 4546058)
-- Name: messages_to_user_id_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX messages_to_user_id_idx ON public.messages USING btree (to_user_id);


--
-- TOC entry 3688 (class 1259 OID 4546435)
-- Name: nodes_changeset_id_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX nodes_changeset_id_idx ON public.nodes USING btree (changeset_id);


--
-- TOC entry 3691 (class 1259 OID 4546154)
-- Name: nodes_tile_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX nodes_tile_idx ON public.nodes USING btree (tile);


--
-- TOC entry 3692 (class 1259 OID 4546152)
-- Name: nodes_timestamp_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX nodes_timestamp_idx ON public.nodes USING btree ("timestamp");


--
-- TOC entry 3764 (class 1259 OID 4546740)
-- Name: note_comments_note_id_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX note_comments_note_id_idx ON public.note_comments USING btree (note_id);


--
-- TOC entry 3757 (class 1259 OID 4546718)
-- Name: notes_created_at_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX notes_created_at_idx ON public.notes USING btree (created_at);


--
-- TOC entry 3760 (class 1259 OID 4546716)
-- Name: notes_tile_status_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX notes_tile_status_idx ON public.notes USING btree (tile, status);


--
-- TOC entry 3761 (class 1259 OID 4546717)
-- Name: notes_updated_at_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX notes_updated_at_idx ON public.notes USING btree (updated_at);


--
-- TOC entry 3649 (class 1259 OID 4546047)
-- Name: points_gpxid_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX points_gpxid_idx ON public.gps_points USING btree (gpx_id);


--
-- TOC entry 3650 (class 1259 OID 4546119)
-- Name: points_tile_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX points_tile_idx ON public.gps_points USING btree (tile);


--
-- TOC entry 3701 (class 1259 OID 4546208)
-- Name: relation_members_member_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX relation_members_member_idx ON public.relation_members USING btree (member_type, member_id);


--
-- TOC entry 3706 (class 1259 OID 4546437)
-- Name: relations_changeset_id_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX relations_changeset_id_idx ON public.relations USING btree (changeset_id);


--
-- TOC entry 3709 (class 1259 OID 4546226)
-- Name: relations_timestamp_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX relations_timestamp_idx ON public.relations USING btree ("timestamp");


--
-- TOC entry 3648 (class 1259 OID 4545901)
-- Name: user_id_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX user_id_idx ON public.friends USING btree (friend_user_id);


--
-- TOC entry 3751 (class 1259 OID 4546665)
-- Name: user_roles_id_role_unique; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX user_roles_id_role_unique ON public.user_roles USING btree (user_id, role);


--
-- TOC entry 3682 (class 1259 OID 4546116)
-- Name: user_tokens_token_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX user_tokens_token_idx ON public.user_tokens USING btree (token);


--
-- TOC entry 3683 (class 1259 OID 4546117)
-- Name: user_tokens_user_id_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX user_tokens_user_id_idx ON public.user_tokens USING btree (user_id);


--
-- TOC entry 3664 (class 1259 OID 4546875)
-- Name: users_auth_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX users_auth_idx ON public.users USING btree (auth_provider, auth_uid);


--
-- TOC entry 3665 (class 1259 OID 4546076)
-- Name: users_display_name_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX users_display_name_idx ON public.users USING btree (display_name);


--
-- TOC entry 3666 (class 1259 OID 4546769)
-- Name: users_display_name_lower_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX users_display_name_lower_idx ON public.users USING btree (lower((display_name)::text));


--
-- TOC entry 3667 (class 1259 OID 4546075)
-- Name: users_email_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE UNIQUE INDEX users_email_idx ON public.users USING btree (email);


--
-- TOC entry 3668 (class 1259 OID 4546770)
-- Name: users_email_lower_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX users_email_lower_idx ON public.users USING btree (lower((email)::text));


--
-- TOC entry 3669 (class 1259 OID 4546982)
-- Name: users_home_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX users_home_idx ON public.users USING btree (home_tile);


--
-- TOC entry 3710 (class 1259 OID 4546252)
-- Name: way_nodes_node_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX way_nodes_node_idx ON public.way_nodes USING btree (node_id);


--
-- TOC entry 3674 (class 1259 OID 4546436)
-- Name: ways_changeset_id_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX ways_changeset_id_idx ON public.ways USING btree (changeset_id);


--
-- TOC entry 3677 (class 1259 OID 4546084)
-- Name: ways_timestamp_idx; Type: INDEX; Schema: public; Owner: openstreetmap
--

CREATE INDEX ways_timestamp_idx ON public.ways USING btree ("timestamp");


--
-- TOC entry 3863 (class 2606 OID 4546849)
-- Name: changeset_comments changeset_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.changeset_comments
    ADD CONSTRAINT changeset_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- TOC entry 3864 (class 2606 OID 4546844)
-- Name: changeset_comments changeset_comments_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.changeset_comments
    ADD CONSTRAINT changeset_comments_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- TOC entry 3851 (class 2606 OID 4546491)
-- Name: changeset_tags changeset_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.changeset_tags
    ADD CONSTRAINT changeset_tags_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- TOC entry 3865 (class 2606 OID 4546863)
-- Name: changesets_subscribers changesets_subscribers_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.changesets_subscribers
    ADD CONSTRAINT changesets_subscribers_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- TOC entry 3866 (class 2606 OID 4546858)
-- Name: changesets_subscribers changesets_subscribers_subscriber_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.changesets_subscribers
    ADD CONSTRAINT changesets_subscribers_subscriber_id_fkey FOREIGN KEY (subscriber_id) REFERENCES public.users(id);


--
-- TOC entry 3850 (class 2606 OID 4546441)
-- Name: changesets changesets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.changesets
    ADD CONSTRAINT changesets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3852 (class 2606 OID 4546608)
-- Name: client_applications client_applications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.client_applications
    ADD CONSTRAINT client_applications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3848 (class 2606 OID 4546324)
-- Name: current_node_tags current_node_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_node_tags
    ADD CONSTRAINT current_node_tags_id_fkey FOREIGN KEY (node_id) REFERENCES public.current_nodes(id);


--
-- TOC entry 3837 (class 2606 OID 4546397)
-- Name: current_nodes current_nodes_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_nodes
    ADD CONSTRAINT current_nodes_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- TOC entry 3840 (class 2606 OID 4546359)
-- Name: current_relation_members current_relation_members_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_relation_members
    ADD CONSTRAINT current_relation_members_id_fkey FOREIGN KEY (relation_id) REFERENCES public.current_relations(id);


--
-- TOC entry 3841 (class 2606 OID 4546354)
-- Name: current_relation_tags current_relation_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_relation_tags
    ADD CONSTRAINT current_relation_tags_id_fkey FOREIGN KEY (relation_id) REFERENCES public.current_relations(id);


--
-- TOC entry 3842 (class 2606 OID 4546402)
-- Name: current_relations current_relations_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_relations
    ADD CONSTRAINT current_relations_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- TOC entry 3821 (class 2606 OID 4546334)
-- Name: current_way_tags current_way_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_way_tags
    ADD CONSTRAINT current_way_tags_id_fkey FOREIGN KEY (way_id) REFERENCES public.current_ways(id);


--
-- TOC entry 3822 (class 2606 OID 4546407)
-- Name: current_ways current_ways_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.current_ways
    ADD CONSTRAINT current_ways_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- TOC entry 3846 (class 2606 OID 4546496)
-- Name: diary_comments diary_comments_diary_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.diary_comments
    ADD CONSTRAINT diary_comments_diary_entry_id_fkey FOREIGN KEY (diary_entry_id) REFERENCES public.diary_entries(id);


--
-- TOC entry 3847 (class 2606 OID 4546446)
-- Name: diary_comments diary_comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.diary_comments
    ADD CONSTRAINT diary_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3823 (class 2606 OID 4546534)
-- Name: diary_entries diary_entries_language_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.diary_entries
    ADD CONSTRAINT diary_entries_language_code_fkey FOREIGN KEY (language_code) REFERENCES public.languages(code);


--
-- TOC entry 3824 (class 2606 OID 4546451)
-- Name: diary_entries diary_entries_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.diary_entries
    ADD CONSTRAINT diary_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3874 (class 2606 OID 4546970)
-- Name: diary_entry_subscriptions diary_entry_subscriptions_diary_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.diary_entry_subscriptions
    ADD CONSTRAINT diary_entry_subscriptions_diary_entry_id_fkey FOREIGN KEY (diary_entry_id) REFERENCES public.diary_entries(id);


--
-- TOC entry 3875 (class 2606 OID 4546975)
-- Name: diary_entry_subscriptions diary_entry_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.diary_entry_subscriptions
    ADD CONSTRAINT diary_entry_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3878 (class 2606 OID 4547065)
-- Name: oauth_access_grants fk_rails_330c32d8d9; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT fk_rails_330c32d8d9 FOREIGN KEY (resource_owner_id) REFERENCES public.users(id) NOT VALID;


--
-- TOC entry 3880 (class 2606 OID 4547096)
-- Name: oauth_access_tokens fk_rails_732cb83ab7; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT fk_rails_732cb83ab7 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id) NOT VALID;


--
-- TOC entry 3882 (class 2606 OID 4547126)
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- TOC entry 3879 (class 2606 OID 4547070)
-- Name: oauth_access_grants fk_rails_b4b53e07b8; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT fk_rails_b4b53e07b8 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id) NOT VALID;


--
-- TOC entry 3876 (class 2606 OID 4547023)
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- TOC entry 3877 (class 2606 OID 4547045)
-- Name: oauth_applications fk_rails_cc886e315a; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_applications
    ADD CONSTRAINT fk_rails_cc886e315a FOREIGN KEY (owner_id) REFERENCES public.users(id) NOT VALID;


--
-- TOC entry 3881 (class 2606 OID 4547091)
-- Name: oauth_access_tokens fk_rails_ee63f25419; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT fk_rails_ee63f25419 FOREIGN KEY (resource_owner_id) REFERENCES public.users(id) NOT VALID;


--
-- TOC entry 3825 (class 2606 OID 4546461)
-- Name: friends friends_friend_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.friends
    ADD CONSTRAINT friends_friend_user_id_fkey FOREIGN KEY (friend_user_id) REFERENCES public.users(id);


--
-- TOC entry 3826 (class 2606 OID 4546456)
-- Name: friends friends_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.friends
    ADD CONSTRAINT friends_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3827 (class 2606 OID 4546501)
-- Name: gps_points gps_points_gpx_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.gps_points
    ADD CONSTRAINT gps_points_gpx_id_fkey FOREIGN KEY (gpx_id) REFERENCES public.gpx_files(id);


--
-- TOC entry 3828 (class 2606 OID 4546506)
-- Name: gpx_file_tags gpx_file_tags_gpx_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.gpx_file_tags
    ADD CONSTRAINT gpx_file_tags_gpx_id_fkey FOREIGN KEY (gpx_id) REFERENCES public.gpx_files(id);


--
-- TOC entry 3829 (class 2606 OID 4546466)
-- Name: gpx_files gpx_files_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.gpx_files
    ADD CONSTRAINT gpx_files_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3872 (class 2606 OID 4546952)
-- Name: issue_comments issue_comments_issue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.issue_comments
    ADD CONSTRAINT issue_comments_issue_id_fkey FOREIGN KEY (issue_id) REFERENCES public.issues(id);


--
-- TOC entry 3873 (class 2606 OID 4546957)
-- Name: issue_comments issue_comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.issue_comments
    ADD CONSTRAINT issue_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3867 (class 2606 OID 4546898)
-- Name: issues issues_reported_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_reported_user_id_fkey FOREIGN KEY (reported_user_id) REFERENCES public.users(id);


--
-- TOC entry 3868 (class 2606 OID 4546903)
-- Name: issues issues_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.users(id);


--
-- TOC entry 3869 (class 2606 OID 4546908)
-- Name: issues issues_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 3830 (class 2606 OID 4546471)
-- Name: messages messages_from_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_from_user_id_fkey FOREIGN KEY (from_user_id) REFERENCES public.users(id);


--
-- TOC entry 3831 (class 2606 OID 4546476)
-- Name: messages messages_to_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_to_user_id_fkey FOREIGN KEY (to_user_id) REFERENCES public.users(id);


--
-- TOC entry 3849 (class 2606 OID 4546329)
-- Name: node_tags node_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.node_tags
    ADD CONSTRAINT node_tags_id_fkey FOREIGN KEY (node_id, version) REFERENCES public.nodes(node_id, version);


--
-- TOC entry 3838 (class 2606 OID 4546412)
-- Name: nodes nodes_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.nodes
    ADD CONSTRAINT nodes_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- TOC entry 3839 (class 2606 OID 4546795)
-- Name: nodes nodes_redaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.nodes
    ADD CONSTRAINT nodes_redaction_id_fkey FOREIGN KEY (redaction_id) REFERENCES public.redactions(id);


--
-- TOC entry 3860 (class 2606 OID 4546746)
-- Name: note_comments note_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.note_comments
    ADD CONSTRAINT note_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- TOC entry 3861 (class 2606 OID 4546741)
-- Name: note_comments note_comments_note_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.note_comments
    ADD CONSTRAINT note_comments_note_id_fkey FOREIGN KEY (note_id) REFERENCES public.notes(id);


--
-- TOC entry 3853 (class 2606 OID 4546603)
-- Name: oauth_tokens oauth_tokens_client_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_client_application_id_fkey FOREIGN KEY (client_application_id) REFERENCES public.client_applications(id);


--
-- TOC entry 3854 (class 2606 OID 4546598)
-- Name: oauth_tokens oauth_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3862 (class 2606 OID 4546811)
-- Name: redactions redactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.redactions
    ADD CONSTRAINT redactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3843 (class 2606 OID 4546417)
-- Name: relations relations_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.relations
    ADD CONSTRAINT relations_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- TOC entry 3844 (class 2606 OID 4546805)
-- Name: relations relations_redaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.relations
    ADD CONSTRAINT relations_redaction_id_fkey FOREIGN KEY (redaction_id) REFERENCES public.redactions(id);


--
-- TOC entry 3870 (class 2606 OID 4546929)
-- Name: reports reports_issue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_issue_id_fkey FOREIGN KEY (issue_id) REFERENCES public.issues(id);


--
-- TOC entry 3871 (class 2606 OID 4546934)
-- Name: reports reports_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3857 (class 2606 OID 4546649)
-- Name: user_blocks user_blocks_moderator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT user_blocks_moderator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- TOC entry 3858 (class 2606 OID 4546654)
-- Name: user_blocks user_blocks_revoker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT user_blocks_revoker_id_fkey FOREIGN KEY (revoker_id) REFERENCES public.users(id);


--
-- TOC entry 3859 (class 2606 OID 4546644)
-- Name: user_blocks user_blocks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT user_blocks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3835 (class 2606 OID 4546481)
-- Name: user_preferences user_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3855 (class 2606 OID 4546660)
-- Name: user_roles user_roles_granter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_granter_id_fkey FOREIGN KEY (granter_id) REFERENCES public.users(id);


--
-- TOC entry 3856 (class 2606 OID 4546627)
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3836 (class 2606 OID 4546486)
-- Name: user_tokens user_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.user_tokens
    ADD CONSTRAINT user_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3845 (class 2606 OID 4546349)
-- Name: way_nodes way_nodes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.way_nodes
    ADD CONSTRAINT way_nodes_id_fkey FOREIGN KEY (way_id, version) REFERENCES public.ways(way_id, version);


--
-- TOC entry 3832 (class 2606 OID 4546344)
-- Name: way_tags way_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.way_tags
    ADD CONSTRAINT way_tags_id_fkey FOREIGN KEY (way_id, version) REFERENCES public.ways(way_id, version);


--
-- TOC entry 3833 (class 2606 OID 4546422)
-- Name: ways ways_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.ways
    ADD CONSTRAINT ways_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- TOC entry 3834 (class 2606 OID 4546800)
-- Name: ways ways_redaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openstreetmap
--

ALTER TABLE ONLY public.ways
    ADD CONSTRAINT ways_redaction_id_fkey FOREIGN KEY (redaction_id) REFERENCES public.redactions(id);


--
-- TOC entry 4019 (class 0 OID 0)
-- Dependencies: 7
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: openstreetmap
--

REVOKE ALL ON SCHEMA public FROM renderer;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO openstreetmap;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2021-08-22 13:22:27 UTC

--
-- PostgreSQL database dump complete
--

