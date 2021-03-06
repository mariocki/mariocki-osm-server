--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4 (Debian 13.4-1.pgdg100+1)
-- Dumped by pg_dump version 13.4 (Debian 13.4-2)

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
-- Name: local_changes; Type: SCHEMA; Schema: -; Owner: renderer
--

CREATE SCHEMA local_changes;


ALTER SCHEMA local_changes OWNER TO renderer;

--
-- Name: format_enum; Type: TYPE; Schema: local_changes; Owner: openstreetmap
--

CREATE TYPE local_changes.format_enum AS ENUM (
    'html',
    'markdown',
    'text'
);


ALTER TYPE local_changes.format_enum OWNER TO openstreetmap;

--
-- Name: gpx_visibility_enum; Type: TYPE; Schema: local_changes; Owner: openstreetmap
--

CREATE TYPE local_changes.gpx_visibility_enum AS ENUM (
    'private',
    'public',
    'trackable',
    'identifiable'
);


ALTER TYPE local_changes.gpx_visibility_enum OWNER TO openstreetmap;

--
-- Name: issue_status_enum; Type: TYPE; Schema: local_changes; Owner: openstreetmap
--

CREATE TYPE local_changes.issue_status_enum AS ENUM (
    'open',
    'ignored',
    'resolved'
);


ALTER TYPE local_changes.issue_status_enum OWNER TO openstreetmap;

--
-- Name: note_event_enum; Type: TYPE; Schema: local_changes; Owner: openstreetmap
--

CREATE TYPE local_changes.note_event_enum AS ENUM (
    'opened',
    'closed',
    'reopened',
    'commented',
    'hidden'
);


ALTER TYPE local_changes.note_event_enum OWNER TO openstreetmap;

--
-- Name: note_status_enum; Type: TYPE; Schema: local_changes; Owner: openstreetmap
--

CREATE TYPE local_changes.note_status_enum AS ENUM (
    'open',
    'closed',
    'hidden'
);


ALTER TYPE local_changes.note_status_enum OWNER TO openstreetmap;

--
-- Name: nwr_enum; Type: TYPE; Schema: local_changes; Owner: openstreetmap
--

CREATE TYPE local_changes.nwr_enum AS ENUM (
    'Node',
    'Way',
    'Relation'
);


ALTER TYPE local_changes.nwr_enum OWNER TO openstreetmap;

--
-- Name: user_role_enum; Type: TYPE; Schema: local_changes; Owner: openstreetmap
--

CREATE TYPE local_changes.user_role_enum AS ENUM (
    'administrator',
    'moderator'
);


ALTER TYPE local_changes.user_role_enum OWNER TO openstreetmap;

--
-- Name: user_status_enum; Type: TYPE; Schema: local_changes; Owner: openstreetmap
--

CREATE TYPE local_changes.user_status_enum AS ENUM (
    'pending',
    'active',
    'confirmed',
    'suspended',
    'deleted'
);


ALTER TYPE local_changes.user_status_enum OWNER TO openstreetmap;

--
-- Name: tile_for_point(integer, integer); Type: FUNCTION; Schema: local_changes; Owner: renderer
--

CREATE FUNCTION local_changes.tile_for_point(scaled_lat integer, scaled_lon integer) RETURNS bigint
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


ALTER FUNCTION local_changes.tile_for_point(scaled_lat integer, scaled_lon integer) OWNER TO renderer;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: acls; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.acls (
    id bigint NOT NULL,
    address inet,
    k character varying NOT NULL,
    v character varying,
    domain character varying,
    mx character varying
);


ALTER TABLE local_changes.acls OWNER TO openstreetmap;

--
-- Name: acls_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.acls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.acls_id_seq OWNER TO openstreetmap;

--
-- Name: acls_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.acls_id_seq OWNED BY local_changes.acls.id;


--
-- Name: active_storage_attachments; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE local_changes.active_storage_attachments OWNER TO openstreetmap;

--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.active_storage_attachments_id_seq OWNER TO openstreetmap;

--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.active_storage_attachments_id_seq OWNED BY local_changes.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.active_storage_blobs (
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


ALTER TABLE local_changes.active_storage_blobs OWNER TO openstreetmap;

--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.active_storage_blobs_id_seq OWNER TO openstreetmap;

--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.active_storage_blobs_id_seq OWNED BY local_changes.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


ALTER TABLE local_changes.active_storage_variant_records OWNER TO openstreetmap;

--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.active_storage_variant_records_id_seq OWNER TO openstreetmap;

--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.active_storage_variant_records_id_seq OWNED BY local_changes.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE local_changes.ar_internal_metadata OWNER TO openstreetmap;

--
-- Name: changeset_comments; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.changeset_comments (
    id integer NOT NULL,
    changeset_id bigint NOT NULL,
    author_id bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    visible boolean NOT NULL
);


ALTER TABLE local_changes.changeset_comments OWNER TO openstreetmap;

--
-- Name: changeset_comments_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.changeset_comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.changeset_comments_id_seq OWNER TO openstreetmap;

--
-- Name: changeset_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.changeset_comments_id_seq OWNED BY local_changes.changeset_comments.id;


--
-- Name: changeset_tags; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.changeset_tags (
    changeset_id bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE local_changes.changeset_tags OWNER TO openstreetmap;

--
-- Name: changesets; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.changesets (
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


ALTER TABLE local_changes.changesets OWNER TO openstreetmap;

--
-- Name: changesets_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.changesets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.changesets_id_seq OWNER TO openstreetmap;

--
-- Name: changesets_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.changesets_id_seq OWNED BY local_changes.changesets.id;


--
-- Name: changesets_subscribers; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.changesets_subscribers (
    subscriber_id bigint NOT NULL,
    changeset_id bigint NOT NULL
);


ALTER TABLE local_changes.changesets_subscribers OWNER TO openstreetmap;

--
-- Name: client_applications; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.client_applications (
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


ALTER TABLE local_changes.client_applications OWNER TO openstreetmap;

--
-- Name: client_applications_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.client_applications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.client_applications_id_seq OWNER TO openstreetmap;

--
-- Name: client_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.client_applications_id_seq OWNED BY local_changes.client_applications.id;


--
-- Name: current_node_tags; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.current_node_tags (
    node_id bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE local_changes.current_node_tags OWNER TO openstreetmap;

--
-- Name: current_nodes; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.current_nodes (
    id bigint NOT NULL,
    latitude integer NOT NULL,
    longitude integer NOT NULL,
    changeset_id bigint NOT NULL,
    visible boolean NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    tile bigint NOT NULL,
    version bigint NOT NULL
);


ALTER TABLE local_changes.current_nodes OWNER TO openstreetmap;

--
-- Name: current_nodes_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.current_nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.current_nodes_id_seq OWNER TO openstreetmap;

--
-- Name: current_nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.current_nodes_id_seq OWNED BY local_changes.current_nodes.id;


--
-- Name: current_relation_members; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.current_relation_members (
    relation_id bigint NOT NULL,
    member_type local_changes.nwr_enum NOT NULL,
    member_id bigint NOT NULL,
    member_role character varying NOT NULL,
    sequence_id integer DEFAULT 0 NOT NULL
);


ALTER TABLE local_changes.current_relation_members OWNER TO openstreetmap;

--
-- Name: current_relation_tags; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.current_relation_tags (
    relation_id bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE local_changes.current_relation_tags OWNER TO openstreetmap;

--
-- Name: current_relations; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.current_relations (
    id bigint NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    visible boolean NOT NULL,
    version bigint NOT NULL
);


ALTER TABLE local_changes.current_relations OWNER TO openstreetmap;

--
-- Name: current_relations_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.current_relations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.current_relations_id_seq OWNER TO openstreetmap;

--
-- Name: current_relations_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.current_relations_id_seq OWNED BY local_changes.current_relations.id;


--
-- Name: current_way_nodes; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.current_way_nodes (
    way_id bigint NOT NULL,
    node_id bigint NOT NULL,
    sequence_id bigint NOT NULL
);


ALTER TABLE local_changes.current_way_nodes OWNER TO openstreetmap;

--
-- Name: current_way_tags; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.current_way_tags (
    way_id bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE local_changes.current_way_tags OWNER TO openstreetmap;

--
-- Name: current_ways; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.current_ways (
    id bigint NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    visible boolean NOT NULL,
    version bigint NOT NULL
);


ALTER TABLE local_changes.current_ways OWNER TO openstreetmap;

--
-- Name: current_ways_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.current_ways_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.current_ways_id_seq OWNER TO openstreetmap;

--
-- Name: current_ways_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.current_ways_id_seq OWNED BY local_changes.current_ways.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.delayed_jobs (
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


ALTER TABLE local_changes.delayed_jobs OWNER TO openstreetmap;

--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.delayed_jobs_id_seq OWNER TO openstreetmap;

--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.delayed_jobs_id_seq OWNED BY local_changes.delayed_jobs.id;


--
-- Name: diary_comments; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.diary_comments (
    id bigint NOT NULL,
    diary_entry_id bigint NOT NULL,
    user_id bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    body_format local_changes.format_enum DEFAULT 'markdown'::local_changes.format_enum NOT NULL
);


ALTER TABLE local_changes.diary_comments OWNER TO openstreetmap;

--
-- Name: diary_comments_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.diary_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.diary_comments_id_seq OWNER TO openstreetmap;

--
-- Name: diary_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.diary_comments_id_seq OWNED BY local_changes.diary_comments.id;


--
-- Name: diary_entries; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.diary_entries (
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
    body_format local_changes.format_enum DEFAULT 'markdown'::local_changes.format_enum NOT NULL
);


ALTER TABLE local_changes.diary_entries OWNER TO openstreetmap;

--
-- Name: diary_entries_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.diary_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.diary_entries_id_seq OWNER TO openstreetmap;

--
-- Name: diary_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.diary_entries_id_seq OWNED BY local_changes.diary_entries.id;


--
-- Name: diary_entry_subscriptions; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.diary_entry_subscriptions (
    user_id bigint NOT NULL,
    diary_entry_id bigint NOT NULL
);


ALTER TABLE local_changes.diary_entry_subscriptions OWNER TO openstreetmap;

--
-- Name: friends; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.friends (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    friend_user_id bigint NOT NULL,
    created_at timestamp without time zone
);


ALTER TABLE local_changes.friends OWNER TO openstreetmap;

--
-- Name: friends_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.friends_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.friends_id_seq OWNER TO openstreetmap;

--
-- Name: friends_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.friends_id_seq OWNED BY local_changes.friends.id;


--
-- Name: gps_points; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.gps_points (
    altitude double precision,
    trackid integer NOT NULL,
    latitude integer NOT NULL,
    longitude integer NOT NULL,
    gpx_id bigint NOT NULL,
    "timestamp" timestamp without time zone,
    tile bigint
);


ALTER TABLE local_changes.gps_points OWNER TO openstreetmap;

--
-- Name: gpx_file_tags; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.gpx_file_tags (
    gpx_id bigint DEFAULT 0 NOT NULL,
    tag character varying NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE local_changes.gpx_file_tags OWNER TO openstreetmap;

--
-- Name: gpx_file_tags_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.gpx_file_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.gpx_file_tags_id_seq OWNER TO openstreetmap;

--
-- Name: gpx_file_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.gpx_file_tags_id_seq OWNED BY local_changes.gpx_file_tags.id;


--
-- Name: gpx_files; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.gpx_files (
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
    visibility local_changes.gpx_visibility_enum DEFAULT 'public'::local_changes.gpx_visibility_enum NOT NULL
);


ALTER TABLE local_changes.gpx_files OWNER TO openstreetmap;

--
-- Name: gpx_files_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.gpx_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.gpx_files_id_seq OWNER TO openstreetmap;

--
-- Name: gpx_files_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.gpx_files_id_seq OWNED BY local_changes.gpx_files.id;


--
-- Name: issue_comments; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.issue_comments (
    id integer NOT NULL,
    issue_id integer NOT NULL,
    user_id integer NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE local_changes.issue_comments OWNER TO openstreetmap;

--
-- Name: issue_comments_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.issue_comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.issue_comments_id_seq OWNER TO openstreetmap;

--
-- Name: issue_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.issue_comments_id_seq OWNED BY local_changes.issue_comments.id;


--
-- Name: issues; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.issues (
    id integer NOT NULL,
    reportable_type character varying NOT NULL,
    reportable_id integer NOT NULL,
    reported_user_id integer,
    status local_changes.issue_status_enum DEFAULT 'open'::local_changes.issue_status_enum NOT NULL,
    assigned_role local_changes.user_role_enum NOT NULL,
    resolved_at timestamp without time zone,
    resolved_by integer,
    updated_by integer,
    reports_count integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE local_changes.issues OWNER TO openstreetmap;

--
-- Name: issues_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.issues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.issues_id_seq OWNER TO openstreetmap;

--
-- Name: issues_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.issues_id_seq OWNED BY local_changes.issues.id;


--
-- Name: languages; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.languages (
    code character varying NOT NULL,
    english_name character varying NOT NULL,
    native_name character varying
);


ALTER TABLE local_changes.languages OWNER TO openstreetmap;

--
-- Name: messages; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.messages (
    id bigint NOT NULL,
    from_user_id bigint NOT NULL,
    title character varying NOT NULL,
    body text NOT NULL,
    sent_on timestamp without time zone NOT NULL,
    message_read boolean DEFAULT false NOT NULL,
    to_user_id bigint NOT NULL,
    to_user_visible boolean DEFAULT true NOT NULL,
    from_user_visible boolean DEFAULT true NOT NULL,
    body_format local_changes.format_enum DEFAULT 'markdown'::local_changes.format_enum NOT NULL
);


ALTER TABLE local_changes.messages OWNER TO openstreetmap;

--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.messages_id_seq OWNER TO openstreetmap;

--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.messages_id_seq OWNED BY local_changes.messages.id;


--
-- Name: node_tags; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.node_tags (
    node_id bigint NOT NULL,
    version bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE local_changes.node_tags OWNER TO openstreetmap;

--
-- Name: nodes; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.nodes (
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


ALTER TABLE local_changes.nodes OWNER TO openstreetmap;

--
-- Name: note_comments; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.note_comments (
    id bigint NOT NULL,
    note_id bigint NOT NULL,
    visible boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    author_ip inet,
    author_id bigint,
    body text,
    event local_changes.note_event_enum
);


ALTER TABLE local_changes.note_comments OWNER TO openstreetmap;

--
-- Name: note_comments_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.note_comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.note_comments_id_seq OWNER TO openstreetmap;

--
-- Name: note_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.note_comments_id_seq OWNED BY local_changes.note_comments.id;


--
-- Name: notes; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.notes (
    id bigint NOT NULL,
    latitude integer NOT NULL,
    longitude integer NOT NULL,
    tile bigint NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    status local_changes.note_status_enum NOT NULL,
    closed_at timestamp without time zone
);


ALTER TABLE local_changes.notes OWNER TO openstreetmap;

--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.notes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.notes_id_seq OWNER TO openstreetmap;

--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.notes_id_seq OWNED BY local_changes.notes.id;


--
-- Name: oauth_access_grants; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.oauth_access_grants (
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


ALTER TABLE local_changes.oauth_access_grants OWNER TO openstreetmap;

--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.oauth_access_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.oauth_access_grants_id_seq OWNER TO openstreetmap;

--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.oauth_access_grants_id_seq OWNED BY local_changes.oauth_access_grants.id;


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.oauth_access_tokens (
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


ALTER TABLE local_changes.oauth_access_tokens OWNER TO openstreetmap;

--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.oauth_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.oauth_access_tokens_id_seq OWNER TO openstreetmap;

--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.oauth_access_tokens_id_seq OWNED BY local_changes.oauth_access_tokens.id;


--
-- Name: oauth_applications; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.oauth_applications (
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


ALTER TABLE local_changes.oauth_applications OWNER TO openstreetmap;

--
-- Name: oauth_applications_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.oauth_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.oauth_applications_id_seq OWNER TO openstreetmap;

--
-- Name: oauth_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.oauth_applications_id_seq OWNED BY local_changes.oauth_applications.id;


--
-- Name: oauth_nonces; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.oauth_nonces (
    id bigint NOT NULL,
    nonce character varying,
    "timestamp" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE local_changes.oauth_nonces OWNER TO openstreetmap;

--
-- Name: oauth_nonces_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.oauth_nonces_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.oauth_nonces_id_seq OWNER TO openstreetmap;

--
-- Name: oauth_nonces_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.oauth_nonces_id_seq OWNED BY local_changes.oauth_nonces.id;


--
-- Name: oauth_tokens; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.oauth_tokens (
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


ALTER TABLE local_changes.oauth_tokens OWNER TO openstreetmap;

--
-- Name: oauth_tokens_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.oauth_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.oauth_tokens_id_seq OWNER TO openstreetmap;

--
-- Name: oauth_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.oauth_tokens_id_seq OWNED BY local_changes.oauth_tokens.id;


--
-- Name: redactions; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.redactions (
    id integer NOT NULL,
    title character varying,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id bigint NOT NULL,
    description_format local_changes.format_enum DEFAULT 'markdown'::local_changes.format_enum NOT NULL
);


ALTER TABLE local_changes.redactions OWNER TO openstreetmap;

--
-- Name: redactions_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.redactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.redactions_id_seq OWNER TO openstreetmap;

--
-- Name: redactions_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.redactions_id_seq OWNED BY local_changes.redactions.id;


--
-- Name: relation_members; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.relation_members (
    relation_id bigint DEFAULT 0 NOT NULL,
    member_type local_changes.nwr_enum NOT NULL,
    member_id bigint NOT NULL,
    member_role character varying NOT NULL,
    version bigint DEFAULT 0 NOT NULL,
    sequence_id integer DEFAULT 0 NOT NULL
);


ALTER TABLE local_changes.relation_members OWNER TO openstreetmap;

--
-- Name: relation_tags; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.relation_tags (
    relation_id bigint DEFAULT 0 NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL,
    version bigint NOT NULL
);


ALTER TABLE local_changes.relation_tags OWNER TO openstreetmap;

--
-- Name: relations; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.relations (
    relation_id bigint DEFAULT 0 NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    version bigint NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    redaction_id integer,
    x integer
);


ALTER TABLE local_changes.relations OWNER TO openstreetmap;

--
-- Name: reports; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.reports (
    id integer NOT NULL,
    issue_id integer NOT NULL,
    user_id integer NOT NULL,
    details text NOT NULL,
    category character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE local_changes.reports OWNER TO openstreetmap;

--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.reports_id_seq OWNER TO openstreetmap;

--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.reports_id_seq OWNED BY local_changes.reports.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.schema_migrations (
    version character varying NOT NULL
);


ALTER TABLE local_changes.schema_migrations OWNER TO openstreetmap;

--
-- Name: user_blocks; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.user_blocks (
    id integer NOT NULL,
    user_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    reason text NOT NULL,
    ends_at timestamp without time zone NOT NULL,
    needs_view boolean DEFAULT false NOT NULL,
    revoker_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    reason_format local_changes.format_enum DEFAULT 'markdown'::local_changes.format_enum NOT NULL
);


ALTER TABLE local_changes.user_blocks OWNER TO openstreetmap;

--
-- Name: user_blocks_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.user_blocks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.user_blocks_id_seq OWNER TO openstreetmap;

--
-- Name: user_blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.user_blocks_id_seq OWNED BY local_changes.user_blocks.id;


--
-- Name: user_preferences; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.user_preferences (
    user_id bigint NOT NULL,
    k character varying NOT NULL,
    v character varying NOT NULL
);


ALTER TABLE local_changes.user_preferences OWNER TO openstreetmap;

--
-- Name: user_roles; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.user_roles (
    id integer NOT NULL,
    user_id bigint NOT NULL,
    role local_changes.user_role_enum NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    granter_id bigint NOT NULL
);


ALTER TABLE local_changes.user_roles OWNER TO openstreetmap;

--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.user_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.user_roles_id_seq OWNER TO openstreetmap;

--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.user_roles_id_seq OWNED BY local_changes.user_roles.id;


--
-- Name: user_tokens; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.user_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token character varying NOT NULL,
    expiry timestamp without time zone NOT NULL,
    referer text
);


ALTER TABLE local_changes.user_tokens OWNER TO openstreetmap;

--
-- Name: user_tokens_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.user_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.user_tokens_id_seq OWNER TO openstreetmap;

--
-- Name: user_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.user_tokens_id_seq OWNED BY local_changes.user_tokens.id;


--
-- Name: users; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.users (
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
    status local_changes.user_status_enum DEFAULT 'pending'::local_changes.user_status_enum NOT NULL,
    terms_agreed timestamp without time zone,
    consider_pd boolean DEFAULT false NOT NULL,
    auth_uid character varying,
    preferred_editor character varying,
    terms_seen boolean DEFAULT false NOT NULL,
    description_format local_changes.format_enum DEFAULT 'markdown'::local_changes.format_enum NOT NULL,
    changesets_count integer DEFAULT 0 NOT NULL,
    traces_count integer DEFAULT 0 NOT NULL,
    diary_entries_count integer DEFAULT 0 NOT NULL,
    image_use_gravatar boolean DEFAULT false NOT NULL,
    auth_provider character varying,
    home_tile bigint,
    tou_agreed timestamp without time zone
);


ALTER TABLE local_changes.users OWNER TO openstreetmap;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: local_changes; Owner: openstreetmap
--

CREATE SEQUENCE local_changes.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_changes.users_id_seq OWNER TO openstreetmap;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: local_changes; Owner: openstreetmap
--

ALTER SEQUENCE local_changes.users_id_seq OWNED BY local_changes.users.id;


--
-- Name: way_nodes; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.way_nodes (
    way_id bigint NOT NULL,
    node_id bigint NOT NULL,
    version bigint NOT NULL,
    sequence_id bigint NOT NULL
);


ALTER TABLE local_changes.way_nodes OWNER TO openstreetmap;

--
-- Name: way_tags; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.way_tags (
    way_id bigint DEFAULT 0 NOT NULL,
    k character varying NOT NULL,
    v character varying NOT NULL,
    version bigint NOT NULL
);


ALTER TABLE local_changes.way_tags OWNER TO openstreetmap;

--
-- Name: ways; Type: TABLE; Schema: local_changes; Owner: openstreetmap
--

CREATE TABLE local_changes.ways (
    way_id bigint DEFAULT 0 NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    version bigint NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    redaction_id integer
);


ALTER TABLE local_changes.ways OWNER TO openstreetmap;

--
-- Name: acls id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.acls ALTER COLUMN id SET DEFAULT nextval('local_changes.acls_id_seq'::regclass);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('local_changes.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('local_changes.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('local_changes.active_storage_variant_records_id_seq'::regclass);


--
-- Name: changeset_comments id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.changeset_comments ALTER COLUMN id SET DEFAULT nextval('local_changes.changeset_comments_id_seq'::regclass);


--
-- Name: changesets id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.changesets ALTER COLUMN id SET DEFAULT nextval('local_changes.changesets_id_seq'::regclass);


--
-- Name: client_applications id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.client_applications ALTER COLUMN id SET DEFAULT nextval('local_changes.client_applications_id_seq'::regclass);


--
-- Name: current_nodes id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_nodes ALTER COLUMN id SET DEFAULT nextval('local_changes.current_nodes_id_seq'::regclass);


--
-- Name: current_relations id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_relations ALTER COLUMN id SET DEFAULT nextval('local_changes.current_relations_id_seq'::regclass);


--
-- Name: current_ways id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_ways ALTER COLUMN id SET DEFAULT nextval('local_changes.current_ways_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('local_changes.delayed_jobs_id_seq'::regclass);


--
-- Name: diary_comments id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.diary_comments ALTER COLUMN id SET DEFAULT nextval('local_changes.diary_comments_id_seq'::regclass);


--
-- Name: diary_entries id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.diary_entries ALTER COLUMN id SET DEFAULT nextval('local_changes.diary_entries_id_seq'::regclass);


--
-- Name: friends id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.friends ALTER COLUMN id SET DEFAULT nextval('local_changes.friends_id_seq'::regclass);


--
-- Name: gpx_file_tags id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.gpx_file_tags ALTER COLUMN id SET DEFAULT nextval('local_changes.gpx_file_tags_id_seq'::regclass);


--
-- Name: gpx_files id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.gpx_files ALTER COLUMN id SET DEFAULT nextval('local_changes.gpx_files_id_seq'::regclass);


--
-- Name: issue_comments id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.issue_comments ALTER COLUMN id SET DEFAULT nextval('local_changes.issue_comments_id_seq'::regclass);


--
-- Name: issues id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.issues ALTER COLUMN id SET DEFAULT nextval('local_changes.issues_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.messages ALTER COLUMN id SET DEFAULT nextval('local_changes.messages_id_seq'::regclass);


--
-- Name: note_comments id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.note_comments ALTER COLUMN id SET DEFAULT nextval('local_changes.note_comments_id_seq'::regclass);


--
-- Name: notes id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.notes ALTER COLUMN id SET DEFAULT nextval('local_changes.notes_id_seq'::regclass);


--
-- Name: oauth_access_grants id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_access_grants ALTER COLUMN id SET DEFAULT nextval('local_changes.oauth_access_grants_id_seq'::regclass);


--
-- Name: oauth_access_tokens id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_access_tokens ALTER COLUMN id SET DEFAULT nextval('local_changes.oauth_access_tokens_id_seq'::regclass);


--
-- Name: oauth_applications id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_applications ALTER COLUMN id SET DEFAULT nextval('local_changes.oauth_applications_id_seq'::regclass);


--
-- Name: oauth_nonces id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_nonces ALTER COLUMN id SET DEFAULT nextval('local_changes.oauth_nonces_id_seq'::regclass);


--
-- Name: oauth_tokens id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_tokens ALTER COLUMN id SET DEFAULT nextval('local_changes.oauth_tokens_id_seq'::regclass);


--
-- Name: redactions id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.redactions ALTER COLUMN id SET DEFAULT nextval('local_changes.redactions_id_seq'::regclass);


--
-- Name: reports id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.reports ALTER COLUMN id SET DEFAULT nextval('local_changes.reports_id_seq'::regclass);


--
-- Name: user_blocks id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.user_blocks ALTER COLUMN id SET DEFAULT nextval('local_changes.user_blocks_id_seq'::regclass);


--
-- Name: user_roles id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.user_roles ALTER COLUMN id SET DEFAULT nextval('local_changes.user_roles_id_seq'::regclass);


--
-- Name: user_tokens id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.user_tokens ALTER COLUMN id SET DEFAULT nextval('local_changes.user_tokens_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.users ALTER COLUMN id SET DEFAULT nextval('local_changes.users_id_seq'::regclass);


--
-- Name: acls_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.acls_id_seq', 1, false);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.active_storage_attachments_id_seq', 1, false);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.active_storage_blobs_id_seq', 1, false);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.active_storage_variant_records_id_seq', 1, false);


--
-- Name: changeset_comments_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.changeset_comments_id_seq', 1, false);


--
-- Name: changesets_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.changesets_id_seq', 1, false);


--
-- Name: client_applications_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.client_applications_id_seq', 1, false);


--
-- Name: current_nodes_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.current_nodes_id_seq', 1, false);


--
-- Name: current_relations_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.current_relations_id_seq', 1, false);


--
-- Name: current_ways_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.current_ways_id_seq', 1, false);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.delayed_jobs_id_seq', 1, false);


--
-- Name: diary_comments_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.diary_comments_id_seq', 1, false);


--
-- Name: diary_entries_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.diary_entries_id_seq', 1, false);


--
-- Name: friends_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.friends_id_seq', 1, false);


--
-- Name: gpx_file_tags_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.gpx_file_tags_id_seq', 1, false);


--
-- Name: gpx_files_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.gpx_files_id_seq', 1, false);


--
-- Name: issue_comments_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.issue_comments_id_seq', 1, false);


--
-- Name: issues_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.issues_id_seq', 1, false);


--
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.messages_id_seq', 1, false);


--
-- Name: note_comments_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.note_comments_id_seq', 1, false);


--
-- Name: notes_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.notes_id_seq', 1, false);


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.oauth_access_grants_id_seq', 1, false);


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.oauth_access_tokens_id_seq', 1, false);


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.oauth_applications_id_seq', 1, false);


--
-- Name: oauth_nonces_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.oauth_nonces_id_seq', 1, false);


--
-- Name: oauth_tokens_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.oauth_tokens_id_seq', 1, false);


--
-- Name: redactions_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.redactions_id_seq', 1, false);


--
-- Name: reports_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.reports_id_seq', 1, false);


--
-- Name: user_blocks_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.user_blocks_id_seq', 1, false);


--
-- Name: user_roles_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.user_roles_id_seq', 1, false);


--
-- Name: user_tokens_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.user_tokens_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: local_changes; Owner: openstreetmap
--

SELECT pg_catalog.setval('local_changes.users_id_seq', 1, false);


--
-- Name: acls acls_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.acls
    ADD CONSTRAINT acls_pkey PRIMARY KEY (id);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: changeset_comments changeset_comments_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.changeset_comments
    ADD CONSTRAINT changeset_comments_pkey PRIMARY KEY (id);


--
-- Name: changesets changesets_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.changesets
    ADD CONSTRAINT changesets_pkey PRIMARY KEY (id);


--
-- Name: client_applications client_applications_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.client_applications
    ADD CONSTRAINT client_applications_pkey PRIMARY KEY (id);


--
-- Name: current_node_tags current_node_tags_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_node_tags
    ADD CONSTRAINT current_node_tags_pkey PRIMARY KEY (node_id, k);


--
-- Name: current_nodes current_nodes_pkey1; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_nodes
    ADD CONSTRAINT current_nodes_pkey1 PRIMARY KEY (id);


--
-- Name: current_relation_members current_relation_members_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_relation_members
    ADD CONSTRAINT current_relation_members_pkey PRIMARY KEY (relation_id, member_type, member_id, member_role, sequence_id);


--
-- Name: current_relation_tags current_relation_tags_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_relation_tags
    ADD CONSTRAINT current_relation_tags_pkey PRIMARY KEY (relation_id, k);


--
-- Name: current_relations current_relations_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_relations
    ADD CONSTRAINT current_relations_pkey PRIMARY KEY (id);


--
-- Name: current_way_nodes current_way_nodes_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_way_nodes
    ADD CONSTRAINT current_way_nodes_pkey PRIMARY KEY (way_id, sequence_id);


--
-- Name: current_way_tags current_way_tags_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_way_tags
    ADD CONSTRAINT current_way_tags_pkey PRIMARY KEY (way_id, k);


--
-- Name: current_ways current_ways_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_ways
    ADD CONSTRAINT current_ways_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: diary_comments diary_comments_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.diary_comments
    ADD CONSTRAINT diary_comments_pkey PRIMARY KEY (id);


--
-- Name: diary_entries diary_entries_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.diary_entries
    ADD CONSTRAINT diary_entries_pkey PRIMARY KEY (id);


--
-- Name: diary_entry_subscriptions diary_entry_subscriptions_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.diary_entry_subscriptions
    ADD CONSTRAINT diary_entry_subscriptions_pkey PRIMARY KEY (user_id, diary_entry_id);


--
-- Name: friends friends_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.friends
    ADD CONSTRAINT friends_pkey PRIMARY KEY (id);


--
-- Name: gpx_file_tags gpx_file_tags_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.gpx_file_tags
    ADD CONSTRAINT gpx_file_tags_pkey PRIMARY KEY (id);


--
-- Name: gpx_files gpx_files_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.gpx_files
    ADD CONSTRAINT gpx_files_pkey PRIMARY KEY (id);


--
-- Name: issue_comments issue_comments_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.issue_comments
    ADD CONSTRAINT issue_comments_pkey PRIMARY KEY (id);


--
-- Name: issues issues_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);


--
-- Name: languages languages_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (code);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: node_tags node_tags_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.node_tags
    ADD CONSTRAINT node_tags_pkey PRIMARY KEY (node_id, version, k);


--
-- Name: nodes nodes_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.nodes
    ADD CONSTRAINT nodes_pkey PRIMARY KEY (node_id, version);


--
-- Name: note_comments note_comments_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.note_comments
    ADD CONSTRAINT note_comments_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_grants oauth_access_grants_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_access_grants
    ADD CONSTRAINT oauth_access_grants_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth_applications oauth_applications_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_applications
    ADD CONSTRAINT oauth_applications_pkey PRIMARY KEY (id);


--
-- Name: oauth_nonces oauth_nonces_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_nonces
    ADD CONSTRAINT oauth_nonces_pkey PRIMARY KEY (id);


--
-- Name: oauth_tokens oauth_tokens_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_tokens
    ADD CONSTRAINT oauth_tokens_pkey PRIMARY KEY (id);


--
-- Name: redactions redactions_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.redactions
    ADD CONSTRAINT redactions_pkey PRIMARY KEY (id);


--
-- Name: relation_members relation_members_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.relation_members
    ADD CONSTRAINT relation_members_pkey PRIMARY KEY (relation_id, version, member_type, member_id, member_role, sequence_id);


--
-- Name: relation_tags relation_tags_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.relation_tags
    ADD CONSTRAINT relation_tags_pkey PRIMARY KEY (relation_id, version, k);


--
-- Name: relations relations_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.relations
    ADD CONSTRAINT relations_pkey PRIMARY KEY (relation_id, version);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: user_blocks user_blocks_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.user_blocks
    ADD CONSTRAINT user_blocks_pkey PRIMARY KEY (id);


--
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (user_id, k);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_tokens user_tokens_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: way_nodes way_nodes_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.way_nodes
    ADD CONSTRAINT way_nodes_pkey PRIMARY KEY (way_id, version, sequence_id);


--
-- Name: way_tags way_tags_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.way_tags
    ADD CONSTRAINT way_tags_pkey PRIMARY KEY (way_id, version, k);


--
-- Name: ways ways_pkey; Type: CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.ways
    ADD CONSTRAINT ways_pkey PRIMARY KEY (way_id, version);


--
-- Name: acls_k_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX acls_k_idx ON local_changes.acls USING btree (k);


--
-- Name: changeset_tags_id_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX changeset_tags_id_idx ON local_changes.changeset_tags USING btree (changeset_id);


--
-- Name: changesets_bbox_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX changesets_bbox_idx ON local_changes.changesets USING gist (min_lat, max_lat, min_lon, max_lon);


--
-- Name: changesets_closed_at_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX changesets_closed_at_idx ON local_changes.changesets USING btree (closed_at);


--
-- Name: changesets_created_at_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX changesets_created_at_idx ON local_changes.changesets USING btree (created_at);


--
-- Name: changesets_user_id_created_at_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX changesets_user_id_created_at_idx ON local_changes.changesets USING btree (user_id, created_at);


--
-- Name: changesets_user_id_id_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX changesets_user_id_id_idx ON local_changes.changesets USING btree (user_id, id);


--
-- Name: current_nodes_tile_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX current_nodes_tile_idx ON local_changes.current_nodes USING btree (tile);


--
-- Name: current_nodes_timestamp_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX current_nodes_timestamp_idx ON local_changes.current_nodes USING btree ("timestamp");


--
-- Name: current_relation_members_member_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX current_relation_members_member_idx ON local_changes.current_relation_members USING btree (member_type, member_id);


--
-- Name: current_relations_timestamp_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX current_relations_timestamp_idx ON local_changes.current_relations USING btree ("timestamp");


--
-- Name: current_way_nodes_node_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX current_way_nodes_node_idx ON local_changes.current_way_nodes USING btree (node_id);


--
-- Name: current_ways_timestamp_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX current_ways_timestamp_idx ON local_changes.current_ways USING btree ("timestamp");


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX delayed_jobs_priority ON local_changes.delayed_jobs USING btree (priority, run_at);


--
-- Name: diary_comment_user_id_created_at_index; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX diary_comment_user_id_created_at_index ON local_changes.diary_comments USING btree (user_id, created_at);


--
-- Name: diary_comments_entry_id_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX diary_comments_entry_id_idx ON local_changes.diary_comments USING btree (diary_entry_id, id);


--
-- Name: diary_entry_created_at_index; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX diary_entry_created_at_index ON local_changes.diary_entries USING btree (created_at);


--
-- Name: diary_entry_language_code_created_at_index; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX diary_entry_language_code_created_at_index ON local_changes.diary_entries USING btree (language_code, created_at);


--
-- Name: diary_entry_user_id_created_at_index; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX diary_entry_user_id_created_at_index ON local_changes.diary_entries USING btree (user_id, created_at);


--
-- Name: gpx_file_tags_gpxid_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX gpx_file_tags_gpxid_idx ON local_changes.gpx_file_tags USING btree (gpx_id);


--
-- Name: gpx_file_tags_tag_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX gpx_file_tags_tag_idx ON local_changes.gpx_file_tags USING btree (tag);


--
-- Name: gpx_files_timestamp_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX gpx_files_timestamp_idx ON local_changes.gpx_files USING btree ("timestamp");


--
-- Name: gpx_files_user_id_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX gpx_files_user_id_idx ON local_changes.gpx_files USING btree (user_id);


--
-- Name: gpx_files_visible_visibility_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX gpx_files_visible_visibility_idx ON local_changes.gpx_files USING btree (visible, visibility);


--
-- Name: index_acls_on_address; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_acls_on_address ON local_changes.acls USING gist (address inet_ops);


--
-- Name: index_acls_on_domain; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_acls_on_domain ON local_changes.acls USING btree (domain);


--
-- Name: index_acls_on_mx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_acls_on_mx ON local_changes.acls USING btree (mx);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON local_changes.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON local_changes.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON local_changes.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON local_changes.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_changeset_comments_on_changeset_id_and_created_at; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_changeset_comments_on_changeset_id_and_created_at ON local_changes.changeset_comments USING btree (changeset_id, created_at);


--
-- Name: index_changeset_comments_on_created_at; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_changeset_comments_on_created_at ON local_changes.changeset_comments USING btree (created_at);


--
-- Name: index_changesets_subscribers_on_changeset_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_changesets_subscribers_on_changeset_id ON local_changes.changesets_subscribers USING btree (changeset_id);


--
-- Name: index_changesets_subscribers_on_subscriber_id_and_changeset_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_changesets_subscribers_on_subscriber_id_and_changeset_id ON local_changes.changesets_subscribers USING btree (subscriber_id, changeset_id);


--
-- Name: index_client_applications_on_key; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_client_applications_on_key ON local_changes.client_applications USING btree (key);


--
-- Name: index_client_applications_on_user_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_client_applications_on_user_id ON local_changes.client_applications USING btree (user_id);


--
-- Name: index_diary_entry_subscriptions_on_diary_entry_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_diary_entry_subscriptions_on_diary_entry_id ON local_changes.diary_entry_subscriptions USING btree (diary_entry_id);


--
-- Name: index_friends_on_user_id_and_created_at; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_friends_on_user_id_and_created_at ON local_changes.friends USING btree (user_id, created_at);


--
-- Name: index_issue_comments_on_issue_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_issue_comments_on_issue_id ON local_changes.issue_comments USING btree (issue_id);


--
-- Name: index_issue_comments_on_user_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_issue_comments_on_user_id ON local_changes.issue_comments USING btree (user_id);


--
-- Name: index_issues_on_assigned_role; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_issues_on_assigned_role ON local_changes.issues USING btree (assigned_role);


--
-- Name: index_issues_on_reportable_type_and_reportable_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_issues_on_reportable_type_and_reportable_id ON local_changes.issues USING btree (reportable_type, reportable_id);


--
-- Name: index_issues_on_reported_user_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_issues_on_reported_user_id ON local_changes.issues USING btree (reported_user_id);


--
-- Name: index_issues_on_status; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_issues_on_status ON local_changes.issues USING btree (status);


--
-- Name: index_issues_on_updated_by; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_issues_on_updated_by ON local_changes.issues USING btree (updated_by);


--
-- Name: index_note_comments_on_body; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_note_comments_on_body ON local_changes.note_comments USING gin (to_tsvector('english'::regconfig, body));


--
-- Name: index_note_comments_on_created_at; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_note_comments_on_created_at ON local_changes.note_comments USING btree (created_at);


--
-- Name: index_oauth_access_grants_on_application_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_oauth_access_grants_on_application_id ON local_changes.oauth_access_grants USING btree (application_id);


--
-- Name: index_oauth_access_grants_on_resource_owner_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_oauth_access_grants_on_resource_owner_id ON local_changes.oauth_access_grants USING btree (resource_owner_id);


--
-- Name: index_oauth_access_grants_on_token; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_oauth_access_grants_on_token ON local_changes.oauth_access_grants USING btree (token);


--
-- Name: index_oauth_access_tokens_on_application_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_oauth_access_tokens_on_application_id ON local_changes.oauth_access_tokens USING btree (application_id);


--
-- Name: index_oauth_access_tokens_on_refresh_token; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_refresh_token ON local_changes.oauth_access_tokens USING btree (refresh_token);


--
-- Name: index_oauth_access_tokens_on_resource_owner_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_oauth_access_tokens_on_resource_owner_id ON local_changes.oauth_access_tokens USING btree (resource_owner_id);


--
-- Name: index_oauth_access_tokens_on_token; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_token ON local_changes.oauth_access_tokens USING btree (token);


--
-- Name: index_oauth_applications_on_owner_type_and_owner_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_oauth_applications_on_owner_type_and_owner_id ON local_changes.oauth_applications USING btree (owner_type, owner_id);


--
-- Name: index_oauth_applications_on_uid; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_oauth_applications_on_uid ON local_changes.oauth_applications USING btree (uid);


--
-- Name: index_oauth_nonces_on_nonce_and_timestamp; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_oauth_nonces_on_nonce_and_timestamp ON local_changes.oauth_nonces USING btree (nonce, "timestamp");


--
-- Name: index_oauth_tokens_on_token; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX index_oauth_tokens_on_token ON local_changes.oauth_tokens USING btree (token);


--
-- Name: index_oauth_tokens_on_user_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_oauth_tokens_on_user_id ON local_changes.oauth_tokens USING btree (user_id);


--
-- Name: index_reports_on_issue_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_reports_on_issue_id ON local_changes.reports USING btree (issue_id);


--
-- Name: index_reports_on_user_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_reports_on_user_id ON local_changes.reports USING btree (user_id);


--
-- Name: index_user_blocks_on_user_id; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX index_user_blocks_on_user_id ON local_changes.user_blocks USING btree (user_id);


--
-- Name: messages_from_user_id_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX messages_from_user_id_idx ON local_changes.messages USING btree (from_user_id);


--
-- Name: messages_to_user_id_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX messages_to_user_id_idx ON local_changes.messages USING btree (to_user_id);


--
-- Name: nodes_changeset_id_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX nodes_changeset_id_idx ON local_changes.nodes USING btree (changeset_id);


--
-- Name: nodes_tile_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX nodes_tile_idx ON local_changes.nodes USING btree (tile);


--
-- Name: nodes_timestamp_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX nodes_timestamp_idx ON local_changes.nodes USING btree ("timestamp");


--
-- Name: note_comments_note_id_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX note_comments_note_id_idx ON local_changes.note_comments USING btree (note_id);


--
-- Name: notes_created_at_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX notes_created_at_idx ON local_changes.notes USING btree (created_at);


--
-- Name: notes_tile_status_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX notes_tile_status_idx ON local_changes.notes USING btree (tile, status);


--
-- Name: notes_updated_at_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX notes_updated_at_idx ON local_changes.notes USING btree (updated_at);


--
-- Name: points_gpxid_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX points_gpxid_idx ON local_changes.gps_points USING btree (gpx_id);


--
-- Name: points_tile_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX points_tile_idx ON local_changes.gps_points USING btree (tile);


--
-- Name: relation_members_member_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX relation_members_member_idx ON local_changes.relation_members USING btree (member_type, member_id);


--
-- Name: relations_changeset_id_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX relations_changeset_id_idx ON local_changes.relations USING btree (changeset_id);


--
-- Name: relations_timestamp_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX relations_timestamp_idx ON local_changes.relations USING btree ("timestamp");


--
-- Name: user_id_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX user_id_idx ON local_changes.friends USING btree (friend_user_id);


--
-- Name: user_roles_id_role_unique; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX user_roles_id_role_unique ON local_changes.user_roles USING btree (user_id, role);


--
-- Name: user_tokens_token_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX user_tokens_token_idx ON local_changes.user_tokens USING btree (token);


--
-- Name: user_tokens_user_id_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX user_tokens_user_id_idx ON local_changes.user_tokens USING btree (user_id);


--
-- Name: users_auth_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX users_auth_idx ON local_changes.users USING btree (auth_provider, auth_uid);


--
-- Name: users_display_name_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX users_display_name_idx ON local_changes.users USING btree (display_name);


--
-- Name: users_display_name_lower_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX users_display_name_lower_idx ON local_changes.users USING btree (lower((display_name)::text));


--
-- Name: users_email_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE UNIQUE INDEX users_email_idx ON local_changes.users USING btree (email);


--
-- Name: users_email_lower_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX users_email_lower_idx ON local_changes.users USING btree (lower((email)::text));


--
-- Name: users_home_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX users_home_idx ON local_changes.users USING btree (home_tile);


--
-- Name: way_nodes_node_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX way_nodes_node_idx ON local_changes.way_nodes USING btree (node_id);


--
-- Name: ways_changeset_id_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX ways_changeset_id_idx ON local_changes.ways USING btree (changeset_id);


--
-- Name: ways_timestamp_idx; Type: INDEX; Schema: local_changes; Owner: openstreetmap
--

CREATE INDEX ways_timestamp_idx ON local_changes.ways USING btree ("timestamp");


--
-- Name: changeset_comments changeset_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.changeset_comments
    ADD CONSTRAINT changeset_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES local_changes.users(id);


--
-- Name: changeset_comments changeset_comments_changeset_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.changeset_comments
    ADD CONSTRAINT changeset_comments_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES local_changes.changesets(id);


--
-- Name: changeset_tags changeset_tags_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.changeset_tags
    ADD CONSTRAINT changeset_tags_id_fkey FOREIGN KEY (changeset_id) REFERENCES local_changes.changesets(id);


--
-- Name: changesets_subscribers changesets_subscribers_changeset_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.changesets_subscribers
    ADD CONSTRAINT changesets_subscribers_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES local_changes.changesets(id);


--
-- Name: changesets_subscribers changesets_subscribers_subscriber_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.changesets_subscribers
    ADD CONSTRAINT changesets_subscribers_subscriber_id_fkey FOREIGN KEY (subscriber_id) REFERENCES local_changes.users(id);


--
-- Name: changesets changesets_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.changesets
    ADD CONSTRAINT changesets_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: client_applications client_applications_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.client_applications
    ADD CONSTRAINT client_applications_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: current_node_tags current_node_tags_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_node_tags
    ADD CONSTRAINT current_node_tags_id_fkey FOREIGN KEY (node_id) REFERENCES local_changes.current_nodes(id);


--
-- Name: current_nodes current_nodes_changeset_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_nodes
    ADD CONSTRAINT current_nodes_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES local_changes.changesets(id);


--
-- Name: current_relation_members current_relation_members_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_relation_members
    ADD CONSTRAINT current_relation_members_id_fkey FOREIGN KEY (relation_id) REFERENCES local_changes.current_relations(id);


--
-- Name: current_relation_tags current_relation_tags_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_relation_tags
    ADD CONSTRAINT current_relation_tags_id_fkey FOREIGN KEY (relation_id) REFERENCES local_changes.current_relations(id);


--
-- Name: current_relations current_relations_changeset_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_relations
    ADD CONSTRAINT current_relations_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES local_changes.changesets(id);


--
-- Name: current_way_tags current_way_tags_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_way_tags
    ADD CONSTRAINT current_way_tags_id_fkey FOREIGN KEY (way_id) REFERENCES local_changes.current_ways(id);


--
-- Name: current_ways current_ways_changeset_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.current_ways
    ADD CONSTRAINT current_ways_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES local_changes.changesets(id);


--
-- Name: diary_comments diary_comments_diary_entry_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.diary_comments
    ADD CONSTRAINT diary_comments_diary_entry_id_fkey FOREIGN KEY (diary_entry_id) REFERENCES local_changes.diary_entries(id);


--
-- Name: diary_comments diary_comments_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.diary_comments
    ADD CONSTRAINT diary_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: diary_entries diary_entries_language_code_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.diary_entries
    ADD CONSTRAINT diary_entries_language_code_fkey FOREIGN KEY (language_code) REFERENCES local_changes.languages(code);


--
-- Name: diary_entries diary_entries_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.diary_entries
    ADD CONSTRAINT diary_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: diary_entry_subscriptions diary_entry_subscriptions_diary_entry_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.diary_entry_subscriptions
    ADD CONSTRAINT diary_entry_subscriptions_diary_entry_id_fkey FOREIGN KEY (diary_entry_id) REFERENCES local_changes.diary_entries(id);


--
-- Name: diary_entry_subscriptions diary_entry_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.diary_entry_subscriptions
    ADD CONSTRAINT diary_entry_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: oauth_access_grants fk_rails_330c32d8d9; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_access_grants
    ADD CONSTRAINT fk_rails_330c32d8d9 FOREIGN KEY (resource_owner_id) REFERENCES local_changes.users(id) NOT VALID;


--
-- Name: oauth_access_tokens fk_rails_732cb83ab7; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_access_tokens
    ADD CONSTRAINT fk_rails_732cb83ab7 FOREIGN KEY (application_id) REFERENCES local_changes.oauth_applications(id) NOT VALID;


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES local_changes.active_storage_blobs(id);


--
-- Name: oauth_access_grants fk_rails_b4b53e07b8; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_access_grants
    ADD CONSTRAINT fk_rails_b4b53e07b8 FOREIGN KEY (application_id) REFERENCES local_changes.oauth_applications(id) NOT VALID;


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES local_changes.active_storage_blobs(id);


--
-- Name: oauth_applications fk_rails_cc886e315a; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_applications
    ADD CONSTRAINT fk_rails_cc886e315a FOREIGN KEY (owner_id) REFERENCES local_changes.users(id) NOT VALID;


--
-- Name: oauth_access_tokens fk_rails_ee63f25419; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_access_tokens
    ADD CONSTRAINT fk_rails_ee63f25419 FOREIGN KEY (resource_owner_id) REFERENCES local_changes.users(id) NOT VALID;


--
-- Name: friends friends_friend_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.friends
    ADD CONSTRAINT friends_friend_user_id_fkey FOREIGN KEY (friend_user_id) REFERENCES local_changes.users(id);


--
-- Name: friends friends_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.friends
    ADD CONSTRAINT friends_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: gps_points gps_points_gpx_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.gps_points
    ADD CONSTRAINT gps_points_gpx_id_fkey FOREIGN KEY (gpx_id) REFERENCES local_changes.gpx_files(id);


--
-- Name: gpx_file_tags gpx_file_tags_gpx_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.gpx_file_tags
    ADD CONSTRAINT gpx_file_tags_gpx_id_fkey FOREIGN KEY (gpx_id) REFERENCES local_changes.gpx_files(id);


--
-- Name: gpx_files gpx_files_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.gpx_files
    ADD CONSTRAINT gpx_files_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: issue_comments issue_comments_issue_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.issue_comments
    ADD CONSTRAINT issue_comments_issue_id_fkey FOREIGN KEY (issue_id) REFERENCES local_changes.issues(id);


--
-- Name: issue_comments issue_comments_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.issue_comments
    ADD CONSTRAINT issue_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: issues issues_reported_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.issues
    ADD CONSTRAINT issues_reported_user_id_fkey FOREIGN KEY (reported_user_id) REFERENCES local_changes.users(id);


--
-- Name: issues issues_resolved_by_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.issues
    ADD CONSTRAINT issues_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES local_changes.users(id);


--
-- Name: issues issues_updated_by_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.issues
    ADD CONSTRAINT issues_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES local_changes.users(id);


--
-- Name: messages messages_from_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.messages
    ADD CONSTRAINT messages_from_user_id_fkey FOREIGN KEY (from_user_id) REFERENCES local_changes.users(id);


--
-- Name: messages messages_to_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.messages
    ADD CONSTRAINT messages_to_user_id_fkey FOREIGN KEY (to_user_id) REFERENCES local_changes.users(id);


--
-- Name: node_tags node_tags_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.node_tags
    ADD CONSTRAINT node_tags_id_fkey FOREIGN KEY (node_id, version) REFERENCES local_changes.nodes(node_id, version);


--
-- Name: nodes nodes_changeset_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.nodes
    ADD CONSTRAINT nodes_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES local_changes.changesets(id);


--
-- Name: nodes nodes_redaction_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.nodes
    ADD CONSTRAINT nodes_redaction_id_fkey FOREIGN KEY (redaction_id) REFERENCES local_changes.redactions(id);


--
-- Name: note_comments note_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.note_comments
    ADD CONSTRAINT note_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES local_changes.users(id);


--
-- Name: note_comments note_comments_note_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.note_comments
    ADD CONSTRAINT note_comments_note_id_fkey FOREIGN KEY (note_id) REFERENCES local_changes.notes(id);


--
-- Name: oauth_tokens oauth_tokens_client_application_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_tokens
    ADD CONSTRAINT oauth_tokens_client_application_id_fkey FOREIGN KEY (client_application_id) REFERENCES local_changes.client_applications(id);


--
-- Name: oauth_tokens oauth_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.oauth_tokens
    ADD CONSTRAINT oauth_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: redactions redactions_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.redactions
    ADD CONSTRAINT redactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: relations relations_changeset_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.relations
    ADD CONSTRAINT relations_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES local_changes.changesets(id);


--
-- Name: relations relations_redaction_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.relations
    ADD CONSTRAINT relations_redaction_id_fkey FOREIGN KEY (redaction_id) REFERENCES local_changes.redactions(id);


--
-- Name: reports reports_issue_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.reports
    ADD CONSTRAINT reports_issue_id_fkey FOREIGN KEY (issue_id) REFERENCES local_changes.issues(id);


--
-- Name: reports reports_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.reports
    ADD CONSTRAINT reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: user_blocks user_blocks_moderator_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.user_blocks
    ADD CONSTRAINT user_blocks_moderator_id_fkey FOREIGN KEY (creator_id) REFERENCES local_changes.users(id);


--
-- Name: user_blocks user_blocks_revoker_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.user_blocks
    ADD CONSTRAINT user_blocks_revoker_id_fkey FOREIGN KEY (revoker_id) REFERENCES local_changes.users(id);


--
-- Name: user_blocks user_blocks_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.user_blocks
    ADD CONSTRAINT user_blocks_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: user_preferences user_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.user_preferences
    ADD CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: user_roles user_roles_granter_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.user_roles
    ADD CONSTRAINT user_roles_granter_id_fkey FOREIGN KEY (granter_id) REFERENCES local_changes.users(id);


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: user_tokens user_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.user_tokens
    ADD CONSTRAINT user_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES local_changes.users(id);


--
-- Name: way_nodes way_nodes_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.way_nodes
    ADD CONSTRAINT way_nodes_id_fkey FOREIGN KEY (way_id, version) REFERENCES local_changes.ways(way_id, version);


--
-- Name: way_tags way_tags_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.way_tags
    ADD CONSTRAINT way_tags_id_fkey FOREIGN KEY (way_id, version) REFERENCES local_changes.ways(way_id, version);


--
-- Name: ways ways_changeset_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.ways
    ADD CONSTRAINT ways_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES local_changes.changesets(id);


--
-- Name: ways ways_redaction_id_fkey; Type: FK CONSTRAINT; Schema: local_changes; Owner: openstreetmap
--

ALTER TABLE ONLY local_changes.ways
    ADD CONSTRAINT ways_redaction_id_fkey FOREIGN KEY (redaction_id) REFERENCES local_changes.redactions(id);


--
-- Name: SCHEMA local_changes; Type: ACL; Schema: -; Owner: renderer
--

REVOKE ALL ON SCHEMA local_changes FROM renderer;
GRANT ALL ON SCHEMA local_changes TO openstreetmap;


--
-- PostgreSQL database dump complete
--

