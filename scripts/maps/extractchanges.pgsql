SELECT * INTO TEMP _C FROM CHANGESETS WHERE USER_ID = 2 AND CREATED_AT > '2021-08-15';

SELECT N.* INTO TEMP _N FROM NODES N INNER JOIN _C ON N.CHANGESET_ID = _c.id;
SELECT NT.* INTO TEMP _NT FROM NODE_TAGS NT INNER JOIN _N ON _N.NODE_ID = NT.NODE_ID;

SELECT w.* INTO TEMP _w FROM ways w INNER JOIN _C ON w.CHANGESET_ID = _C.ID;
SELECT wT.* INTO TEMP _wT FROM way_TAGS wT INNER JOIN _w ON _w.way_id = wt.way_ID and _w.version = wt.version;
SELECT wn.* INTO TEMP _wn FROM way_nodes wn INNER JOIN _w ON _w.way_id = wn.way_ID and _w.version = wn.version;

SELECT r.* INTO TEMP _r FROM relations r INNER JOIN _c ON r.changeset_id = _c.id;
SELECT rt.* INTO TEMP _rt FROM relation_tags rt INNER JOIN _r ON _r.relation_id = rt.relation_id and _r.version = rt.version;
SELECT rm.* INTO TEMP _rm FROM relation_members rm INNER JOIN _r ON _r.relation_id = rm.relation_id and _r.version = rm.version;

SELECT cw.* INTO TEMP _cw FROM current_ways cw INNER JOIN _C ON cw.CHANGESET_ID = _C.ID; 
SELECT cwT.* INTO TEMP _cwT FROM current_way_TAGS cwT INNER JOIN _cw ON _cw.id = cwt.way_ID;
SELECT cwn.* INTO TEMP _cwn FROM current_way_nodes cwn INNER JOIN _cw ON _cw.id = cwn.way_ID;

SELECT cN.* INTO TEMP _cN FROM current_NODES cN INNER JOIN _C ON cN.CHANGESET_ID = _C.ID; 
SELECT cNT.* INTO TEMP _cNT FROM current_NODE_TAGS cNT INNER JOIN _cN ON _cN.id= cNT.NODE_ID;

SELECT cr.* INTO TEMP _cr FROM current_relations cr INNER JOIN _c ON cr.changeset_id = _c.id;
SELECT crt.* INTO TEMP _crt FROM current_relation_tags crt INNER JOIN _cr ON _cr.id= crt.relation_id;
SELECT crm.* INTO TEMP _crm FROM current_relation_members crm INNER JOIN _cr ON _cr.id= crm.relation_id;

\copy (select * from _c) to 'c.csv' with (format csv, header, delimiter ',');
\copy (select * from _n) to 'n.csv' with (format csv, header, delimiter ',');
\copy (select * from _nt) to 'nt.csv' with (format csv, header, delimiter ',');
\copy (select * from _w) to 'w.csv' with (format csv, header, delimiter ',');
\copy (select * from _wt) to 'wt.csv' with (format csv, header, delimiter ',');
\copy (select * from _wn) to 'wn.csv' with (format csv, header, delimiter ',');
\copy (select * from _r) to 'r.csv' with (format csv, header, delimiter ',');
\copy (select * from _rt) to 'rt.csv' with (format csv, header, delimiter ',');
\copy (select * from _rm) to 'rm.csv' with (format csv, header, delimiter ',');
\copy (select * from _cw) to 'cw.csv' with (format csv, header, delimiter ',');
\copy (select * from _cwt) to 'cwt.csv' with (format csv, header, delimiter ',');
\copy (select * from _cwn) to 'cwn.csv' with (format csv, header, delimiter ',');
\copy (select * from _cn) to 'cn.csv' with (format csv, header, delimiter ',');
\copy (select * from _cnt) to 'cnt.csv' with (format csv, header, delimiter ',');
\copy (select * from _cr) to 'cr.csv' with (format csv, header, delimiter ',');
\copy (select * from _crt) to 'crt.csv' with (format csv, header, delimiter ',');
\copy (select * from _crm) to 'crm.csv' with (format csv, header, delimiter ',');


