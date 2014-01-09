use slic;

-- TABLES

-- vertices

/*
	P (detected)
	D (detected)
	H (detected)
	K (detected)
	L ()
	C (engaged, node_id, internal_id)
	S (high, low, off)
	A ()
*/

DROP TABLE IF EXISTS vp;
DROP TABLE IF EXISTS vd;
DROP TABLE IF EXISTS vh;
DROP TABLE IF EXISTS vk;
DROP TABLE IF EXISTS vl;
DROP TABLE IF EXISTS vc;
DROP TABLE IF EXISTS vs;
DROP TABLE IF EXISTS va;

CREATE TABLE vp (
	id SMALLINT PRIMARY KEY,
	detected BOOL
);
CREATE TABLE vd (
	id SMALLINT PRIMARY KEY,
	detected BOOL
);
CREATE TABLE vh (
	id SMALLINT PRIMARY KEY,
	day BOOL
);
CREATE TABLE vk (
	id SMALLINT PRIMARY KEY,
	detected BOOL
);
CREATE TABLE vl (
	id SMALLINT PRIMARY KEY
);
CREATE TABLE vc (
	id SMALLINT PRIMARY KEY,
	engaded BOOL
);
CREATE TABLE vs (
	id SMALLINT PRIMARY KEY,
	high BOOL,
	low BOOL,
	off BOOL
);
CREATE TABLE va (
	id SMALLINT PRIMARY KEY
);

-- edges
/*
	P -> S (l)
	A -> S
	K -> S
	H -> S
	D -> S (l)
	S -> C (l)
	C -> L (l)
*/

DROP TABLE IF EXISTS eps;
DROP TABLE IF EXISTS eas;
DROP TABLE IF EXISTS eks;
DROP TABLE IF EXISTS ehs;
DROP TABLE IF EXISTS eds;
DROP TABLE IF EXISTS esc;
DROP TABLE IF EXISTS ecl;

CREATE TABLE eps (
	f SMALLINT,
	t SMALLINT,
	l char(10),
	PRIMARY KEY(f, t)
);
CREATE TABLE eas (
	f SMALLINT,
	t SMALLINT,
	PRIMARY KEY(f, t)
);
CREATE TABLE eks (
	f SMALLINT,
	t SMALLINT,
	PRIMARY KEY(f, t)
);
CREATE TABLE ehs (
	f SMALLINT,
	t SMALLINT,
	PRIMARY KEY(f, t)
);
CREATE TABLE eds (
	f SMALLINT,
	t SMALLINT,
	l char(10),
	PRIMARY KEY(f, t)
);
CREATE TABLE esc (
	f SMALLINT,
	t SMALLINT,
	l char(10),
	PRIMARY KEY(f, t)
);
CREATE TABLE ecl (
	f SMALLINT,
	t SMALLINT,
	l char(10),
	PRIMARY KEY(f, t)
);

-- results

DROP TABLE IF EXISTS res;
CREATE TABLE res (
	l_id INT,
	l_label char(10),
	new_c bool,
	PRIMARY KEY(l_id, l_label)
);

-- INDEXES

CREATE INDEX eps_f ON eps(f);
CREATE INDEX eps_t ON eps(t);
CREATE INDEX eps_l ON eps(l);

CREATE INDEX eas_f ON eas(f);
CREATE INDEX eas_t ON eas(t);

CREATE INDEX eks_f ON eks(f);
CREATE INDEX eks_t ON eks(t);

CREATE INDEX ehs_f ON ehs(f);
CREATE INDEX ehs_t ON ehs(t);

CREATE INDEX eds_f ON eds(f);
CREATE INDEX eds_t ON eds(t);
CREATE INDEX eds_l ON eds(l);

CREATE INDEX esc_f ON esc(f);
CREATE INDEX esc_t ON esc(t);
CREATE INDEX esc_l ON esc(l);

CREATE INDEX ecl_f ON ecl(f);
CREATE INDEX ecl_t ON ecl(t);
CREATE INDEX ecl_l ON ecl(l);

-- INSERTS

-- inserts.sql

-- UPDATES PROCEDURES

DELIMITER //
SET NAMES 'utf8' //

DROP PROCEDURE IF EXISTS label_c //

CREATE PROCEDURE label_c(in id SMALLINT, in node SMALLINT, in internal SMALLINT) 
BEGIN
	UPDATE vc
	SET vc.node_id = node, vc.internal_id = internal
	WHERE vc.id = id;
END;
//

-- RULES

/*
r('1a1b') :- 
    v(k,L,false),
    e(k,L,s,J),
    \+ v(s,J,off),
    e(s,J,c,_,_),  
    then,
    vla(s,J,off).
*/

DROP PROCEDURE IF EXISTS rule_1 //

CREATE PROCEDURE rule_1()
BEGIN
	UPDATE vs
	SET off = true
	WHERE vs.id in (
		select distinct esc.f from vk 
		join eks on vk.id = eks.f
		join esc on eks.t = esc.f
			where vk.detected = false
	) and vs.off = false;
END;
//

/*
r('2a2b') :- 
    v(k,L,true),
    v(p,M,false),
    e(p,M,s,J,in),
    \+ v(s,J,low),
    e(k,L,s,J),
    e(s,J,c,_,low),
    then,
    vla(s,J,low).
*/

DROP PROCEDURE IF EXISTS rule_2 //

CREATE PROCEDURE rule_2()
BEGIN
	UPDATE vs
	SET low = true
	WHERE vs.id in (
		select distinct esc.f from vk
		cross join vp
		join eps on vp.id = eps.f
		join eks on vk.id = eks.f and eps.t = eks.t
		join esc on eks.t = esc.f
			where vk.detected = true and vp.detected = false and eps.l = 'in' and esc.l = 'low'
	) and vs.low = false;
END;
//

/*
	r('3a3b') :-
	v(k,L,true),
	v(p,M,true),
	e(p,M,s,J,in),
	\+ v(s,J,high),
	e(k,L,s,J),
	e(s,J,c,_,high),
	then,
	vla(s,J,high).
*/

DROP PROCEDURE IF EXISTS rule_3 //

CREATE PROCEDURE rule_3()
BEGIN
	UPDATE vs
	SET high = true
	WHERE vs.id in (
		select distinct esc.f from vk
		cross join vp
		join eps on vp.id = eps.f
	  	join eks on eks.f = vk.id and eks.t = eps.t
	  	join esc on esc.f = eks.t
			where eps.l = 'in' and esc.l = 'high' and vk.detected = true and vp.detected = true
	) and vs.high = false;
END;
//

/*
r('4a'):-
	v(k,L,true),
	v(h,1,day),
	v(d,I,true),
	e(d,I,s,J,dir_day), \+ v(s,J,high),
	e(k,L,s,J),
	e(h,1,s,J),
	e(s,J,c,_,high),
	then,
	vla(s,J,high).
*/

DROP PROCEDURE IF EXISTS rule_4a //

CREATE PROCEDURE rule_4a()
BEGIN
	UPDATE vs
	SET high = true
	WHERE vs.id in (
		select distinct esc.f from vk
		cross join vh
		cross join vd
		join eds on eds.f = vd.id
		join eks on eks.f = vk.id and eks.t = eds.t
		join ehs on ehs.f = vh.id and ehs.t = eks.t
		join esc on esc.f = ehs.t
			where vk.detected = true and vh.day = true and vd.detected = true and eds.l = 'dir_day' and esc.l = 'high'
	) and vs.high = false;
END;
//

/*
r('4b'):-
	v(h,1,night),
	v(k,L,true),
	v(d,I,true),
	e(d,I,s,J,dir_night), \+ v(s,J,high),
	e(k,L,s,J),
	e(h,1,s,J),
	e(s,J,c,_,high),
	then,
	vla(s,J,high).
*/

DROP PROCEDURE IF EXISTS rule_4b //

CREATE PROCEDURE rule_4b()
BEGIN
	UPDATE vs
	SET high = true
	WHERE vs.id in (
		select distinct esc.f from vk
		cross join vh
		cross join vd
		join eds on eds.f = vd.id
		join eks on eks.f = vk.id and eks.t = eds.t
		join ehs on ehs.f = vh.id and ehs.t = eks.t
		join esc on esc.f = ehs.t
			where vk.detected = true and vh.day = false and vd.detected = true and eds.l = 'dir_day' and esc.l = 'high'
	) and vs.high = false;
END;
//

/*
r('5a'):-
	v(k,L,true),
	v(h,1,day),
	e(d,I,s,J,dir_day),  \+ v(s,J,off),
	v(d,I,false),
	e(k,L,s,J),   
	e(h,1,s,J),
	e(s,J,c,_,high),
	then,
	vla(s,J,off).
*/

DROP PROCEDURE IF EXISTS rule_5a //

CREATE PROCEDURE rule_5a()
BEGIN
	UPDATE vs
	SET off = true
	WHERE vs.id in (
		select distinct esc.f from vk
		cross join vh
		cross join eds
		join vd on vd.id = eds.f
		join eks on eks.f = vk.id and eks.t = eds.t
		join ehs on ehs.f = vh.id and ehs.t = eks.t
		join esc on esc.f = ehs.t
			where vk.detected = true and vh.day = true and eds.l = 'dir_day' and vd.detected = false and esc.l = 'high'
	) and vs.off = false;
END;
//

/*
r('5b'):-
	v(k,L,true),
	v(h,1,night),
	e(d,I,s,J,dir_night), \+ v(s,J,off),
	v(d,I,false), 
	e(k,L,s,J),
	e(h,1,s,J),
	e(s,J,c,_,high),
	then,
	vla(s,J,off).
*/

DROP PROCEDURE IF EXISTS rule_5b //

CREATE PROCEDURE rule_5b()
BEGIN
	UPDATE vs
	SET off = true
	WHERE vs.id in (
		select distinct esc.f from vk
		cross join vh
		cross join eds
		join vd on vd.id = eds.f
		join eks on eks.f = vk.id and eks.t = eds.t
		join ehs on ehs.f = vh.id and ehs.t = eks.t
		join esc on esc.f = ehs.t
			where vk.detected = true and vh.day = false and eds.l = 'dir_night' and vd.detected = false and esc.l = 'high'
	) and vs.off = false;
END;
//

/*
r(6) :-
	v(h,1,day),
	v(d,I,true),
	e(d,I,s,J,interior),
	e(h,1,s,J),
	\+ v(s,J,high),
	e(s,J,c,_,high),
	then,
	vla(s,J,high).
*/

DROP PROCEDURE IF EXISTS rule_6 //

CREATE PROCEDURE rule_6()
BEGIN
	UPDATE vs
	SET high = true
	WHERE vs.id in (
		select distinct esc.f from vh
		cross join vd
		join eds on eds.f = vd.id
		join ehs on ehs.f = vh.id and ehs.t = eds.t
		join esc on esc.f = ehs.t
			where vh.day = true and vd.detected = true and eds.l = 'interior' and esc.l = 'high'
	) and vs.high = false;
END;
//

/*
r(7) :-
	v(h,1,day),
	e(d,I,s,J,interior),  \+ v(s,J,off),
	v(d,I,false),
	e(s,J,c,_,high),
	e(h,1,s,J),  
	then,
	vla(s,J,off).
*/

DROP PROCEDURE IF EXISTS rule_7 //

CREATE PROCEDURE rule_7()
BEGIN
	UPDATE vs
	SET off = true
	WHERE vs.id in (
		select distinct ehs.t from vh	
		cross join eds
		join vd on vd.id = eds.f
		join esc on esc.f = eds.t
		join ehs on ehs.f = vh.id and ehs.t = esc.f
			where vh.day = true and eds.l = 'interior' and vd.detected = false and esc.l = 'high'
	) and vs.off = false;
END;
//


-- profile precedence resolution

/*
p(high) :-
	v(s,I,high),
	e(s,I,c,K,high),
	then,
	vlc(s,I,_),
	forall(e(s,I,c,J,_),(vlr(c,J,_),vla(c,J,off))),
	vlr(c,K,_),
	vla(c,K,on).
*/

DROP PROCEDURE IF EXISTS rule_phigh //

CREATE PROCEDURE rule_phigh()
BEGIN
	INSERT INTO res (l_id, l_label, new_c)
	SELECT ecl.t, ecl.l, false
	FROM (vs
	  JOIN esc ON esc.f = vs.id
	  JOIN ecl ON ecl.f = esc.t)
	WHERE vs.high = true
	ON DUPLICATE KEY UPDATE new_c = false;

	UPDATE vc
	SET engaded = false
	WHERE vc.id in (
		select esc.t from esc
		join vs on vs.id = esc.f
		where vs.high = true
	);

	INSERT INTO res (l_id, l_label, new_c)
	SELECT ecl.t, ecl.l, true
	FROM (vs
	  JOIN esc ON esc.f = vs.id
	  JOIN ecl ON ecl.f = esc.t)
	WHERE vs.high = true and esc.l = 'high'
	ON DUPLICATE KEY UPDATE new_c = true;

	UPDATE vc
	SET engaded = true
	WHERE vc.id in (
		select esc.t from esc
		join vs on vs.id = esc.f
		where vs.high = true and esc.l = 'high'
	);

	UPDATE vs
	SET high = false, low = false, off = false
	WHERE vs.id in (
		select esc.f from esc
		where esc.f = vs.id and vs.high = true and esc.l = 'high'
	);

END;
//

/*
p(low) :-
	v(s,I,low),
	\+ v(s,I,high),
	e(s,I,c,K,low),
	then,
	vlc(s,I,_),
	forall(e(s,I,c,J,_),(vlr(c,J,_),vla(c,J,off))),
	vlr(c,K,_),
	vla(c,K,on).
*/

DROP PROCEDURE IF EXISTS rule_plow //

CREATE PROCEDURE rule_plow()
BEGIN
	INSERT INTO res (l_id, l_label, new_c)
	SELECT ecl.t, ecl.l, false
	FROM (vs
	  JOIN esc ON esc.f = vs.id
	  JOIN ecl ON ecl.f = esc.t)
	WHERE vs.low = true and vs.high = false
	ON DUPLICATE KEY UPDATE new_c = false;

	UPDATE vc
	SET engaded = false
	WHERE vc.id in (
		select esc.t from esc
		join vs on vs.id = esc.f
		where vs.low = true and vs.high = false
	);

	INSERT INTO res (l_id, l_label, new_c)
	SELECT ecl.t, ecl.l, true
	FROM (vs
	  JOIN esc ON esc.f = vs.id
	  JOIN ecl ON ecl.f = esc.t)
	WHERE vs.low = true and vs.high = false and esc.l = 'low'
	ON DUPLICATE KEY UPDATE new_c = true;

	UPDATE vc
	SET engaded = true
	WHERE vc.id in (
		select esc.t from esc
		join vs on vs.id = esc.f
		where vs.low = true and vs.high = false and esc.l = 'low'
	);

	UPDATE vs
	SET high = false, low = false, off = false
	WHERE vs.id in (
		select esc.f from esc
		where esc.f = vs.id and vs.low = true and vs.high = false and esc.l = 'low'
	);

END;
//

/*
p(off) :-
	v(s,I,off),
	\+ v(s,I,high),
	\+ v(s,I,low),
	then,
	vlc(s,I,_),
	forall(e(s,I,c,J,_),(vlr(c,J,_),vla(c,J,off))).
*/

DROP PROCEDURE IF EXISTS rule_poff //

CREATE PROCEDURE rule_poff()
BEGIN
	INSERT INTO res (l_id, l_label, new_c)
	SELECT ecl.t, ecl.l, false
	FROM (vs
	  JOIN esc ON esc.f = vs.id
	  JOIN ecl ON ecl.f = esc.t)
	WHERE vs.off = true and vs.high = false and vs.low = false
	ON DUPLICATE KEY UPDATE new_c = false;

	UPDATE vc
	SET engaded = false
	WHERE vc.id in (
		select esc.t from esc
		join vs on vs.id = esc.f
		where vs.off = true and vs.high = false and vs.low = false
	);

	UPDATE vs
	SET high = false, low = false, off = false
	WHERE off = true and high = false and low = false;

END;
//

-- INSERTS PROCEDURES
SET NAMES 'utf8' //

DROP PROCEDURE IF EXISTS add_vertex //

CREATE PROCEDURE add_vertex(in t CHAR, in id SMALLINT)
BEGIN
	CASE t
		WHEN 'p' THEN INSERT INTO vp VALUES (id, false);
		WHEN 'd' THEN INSERT INTO vd VALUES (id, false);
		WHEN 'h' THEN INSERT INTO vh VALUES (id, false);
		WHEN 'k' THEN INSERT INTO vk VALUES (id, false);
		WHEN 'l' THEN INSERT INTO vl VALUES (id);
		WHEN 'c' THEN INSERT INTO vc VALUES (id, false);
		WHEN 's' THEN INSERT INTO vs VALUES (id, false, false, false);
		WHEN 'a' THEN INSERT INTO va VALUES (id);
	END CASE;
END;
//

DROP PROCEDURE IF EXISTS add_edge //

CREATE PROCEDURE add_edge(in e CHAR(2), in f SMALLINT, in t SMALLINT)
BEGIN
	CASE e
		WHEN 'as' THEN INSERT INTO eas VALUES (f, t);
		WHEN 'ks' THEN INSERT INTO eks VALUES (f, t);
		WHEN 'hs' THEN INSERT INTO ehs VALUES (f, t);
	END CASE;
END;
//

DROP PROCEDURE IF EXISTS add_edge_label //

CREATE PROCEDURE add_edge_label(in e CHAR(2), in f SMALLINT, in t SMALLINT, in l char(10))
BEGIN
	CASE e
		WHEN 'ps' THEN INSERT INTO eps VALUES (f, t, l);
		WHEN 'ds' THEN INSERT INTO eds VALUES (f, t, l);
		WHEN 'sc' THEN INSERT INTO esc VALUES (f, t, l);
		WHEN 'cl' THEN INSERT INTO ecl VALUES (f, t, l);
	END CASE;
END;
//

-- EXPERIMENTS

DROP PROCEDURE IF EXISTS rule_all //

CREATE PROCEDURE rule_all()
BEGIN
	CALL rule_1();
	CALL rule_2();
	CALL rule_3();
	CALL rule_4a();
	CALL rule_4b();
	CALL rule_5a();
	CALL rule_5b();
	CALL rule_6();
	CALL rule_7();

	CALL rule_phigh();
	CALL rule_plow();
	CALL rule_poff();
END;
//

-- EXes

DROP PROCEDURE IF EXISTS ex //

CREATE PROCEDURE ex(in num SMALLINT)
BEGIN
	START TRANSACTION;
	CASE num
		WHEN 0 THEN UPDATE vk SET detected = true WHERE id = 1; UPDATE vh SET day = true; UPDATE vc SET engaded = false; UPDATE vp SET detected = false; UPDATE vd SET detected = false;
		WHEN 1 THEN UPDATE vk SET detected = true WHERE id = 1; CALL rule_all();
		WHEN 2 THEN UPDATE vp SET detected = true WHERE id = 1; CALL rule_all();
		WHEN 3 THEN UPDATE vp SET detected = true WHERE id = 6; CALL rule_all();
		WHEN 4 THEN UPDATE vd SET detected = true WHERE id = 1; CALL rule_all();
		WHEN 5 THEN UPDATE vd SET detected = true WHERE id = 8; CALL rule_all();
		WHEN 6 THEN UPDATE vd SET detected = false WHERE id = 1; CALL rule_all();
		WHEN 7 THEN UPDATE vp SET detected = false WHERE id = 1; CALL rule_all();
		WHEN 8 THEN UPDATE vd SET detected = false WHERE id = 8; CALL rule_all();
		WHEN 9 THEN UPDATE vp SET detected = false WHERE id = 6; CALL rule_all();
	END CASE;
	SELECT * FROM res;
	DELETE FROM res;
	COMMIT;
END;
//

DELIMITER ;


