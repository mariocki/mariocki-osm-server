SET session_replication_role = 'replica';
begin transaction;

SELECT * INTO TEMP _C FROM public.CHANGESETS WHERE USER_ID = 2 AND CREATED_AT > '2021-08-15';

SELECT N.* INTO TEMP _N FROM public.NODES N INNER JOIN _C ON N.CHANGESET_ID = _c.id;
SELECT NT.* INTO TEMP _NT FROM public.NODE_TAGS NT INNER JOIN _N ON _N.NODE_ID = NT.NODE_ID;

SELECT w.* INTO TEMP _w FROM public.ways w INNER JOIN _C ON w.CHANGESET_ID = _C.ID;
SELECT wT.* INTO TEMP _wT FROM public.way_TAGS wT INNER JOIN _w ON _w.way_id = wt.way_ID and _w.version = wt.version;
SELECT wn.* INTO TEMP _wn FROM public.way_nodes wn INNER JOIN _w ON _w.way_id = wn.way_ID and _w.version = wn.version;

SELECT r.* INTO TEMP _r FROM public.relations r INNER JOIN _c ON r.changeset_id = _c.id;
SELECT rt.* INTO TEMP _rt FROM public.relation_tags rt INNER JOIN _r ON _r.relation_id = rt.relation_id and _r.version = rt.version;
SELECT rm.* INTO TEMP _rm FROM public.relation_members rm INNER JOIN _r ON _r.relation_id = rm.relation_id and _r.version = rm.version;

SELECT cw.* INTO TEMP _cw FROM public.current_ways cw INNER JOIN _C ON cw.CHANGESET_ID = _C.ID; 
SELECT cwT.* INTO TEMP _cwT FROM public.current_way_TAGS cwT INNER JOIN _cw ON _cw.id = cwt.way_ID;
SELECT cwn.* INTO TEMP _cwn FROM public.current_way_nodes cwn INNER JOIN _cw ON _cw.id = cwn.way_ID;

SELECT cN.* INTO TEMP _cN FROM public.current_NODES cN INNER JOIN _C ON cN.CHANGESET_ID = _C.ID; 
SELECT cNT.* INTO TEMP _cNT FROM public.current_NODE_TAGS cNT INNER JOIN _cN ON _cN.id= cNT.NODE_ID;

SELECT cr.* INTO TEMP _cr FROM public.current_relations cr INNER JOIN _c ON cr.changeset_id = _c.id;
SELECT crt.* INTO TEMP _crt FROM public.current_relation_tags crt INNER JOIN _cr ON _cr.id= crt.relation_id;
SELECT crm.* INTO TEMP _crm FROM public.current_relation_members crm INNER JOIN _cr ON _cr.id= crm.relation_id;

insert into local_changes.changesets select * from _c ON CONFLICT DO NOTHING;
insert into local_changes.nodes select * from _N ON CONFLICT DO NOTHING;
insert into local_changes.node_tags select * from _NT ON CONFLICT DO NOTHING;
insert into local_changes.ways select * from _w ON CONFLICT DO NOTHING;
insert into local_changes.way_tags select * from _wT ON CONFLICT DO NOTHING;
insert into local_changes.way_nodes select * from _wn ON CONFLICT DO NOTHING;
insert into local_changes.relations select * from _r ON CONFLICT DO NOTHING;
insert into local_changes.relation_tags select * from _rt ON CONFLICT DO NOTHING;
insert into local_changes.relation_members select relation_id, member_type::text::local_changes.nwr_enum, member_id, member_role, version, sequence_id from _rm ON CONFLICT DO NOTHING;
insert into local_changes.current_ways select * from _cw ON CONFLICT DO NOTHING;
insert into local_changes.current_way_tags select * from _cwT ON CONFLICT DO NOTHING;
insert into local_changes.current_nodes select * from _cN ON CONFLICT DO NOTHING;
insert into local_changes.current_node_tags select * from _cNT ON CONFLICT DO NOTHING;
insert into local_changes.current_way_nodes select * from _cwn ON CONFLICT DO NOTHING;
insert into local_changes.current_relations select * from _cr ON CONFLICT DO NOTHING;
insert into local_changes.current_relation_tags select * from _crt ON CONFLICT DO NOTHING;
insert into local_changes.current_relation_members select relation_id, member_type::text::local_changes.nwr_enum, member_id, member_role, sequence_id from _crm ON CONFLICT DO NOTHING;

commit;

SET session_replication_role = 'origin';
