-- DROP SCHEMA schema_kurs;

CREATE SCHEMA schema_kurs AUTHORIZATION postgres;
-- schema_kurs.course definition

-- Drop table

-- DROP TABLE schema_kurs.course;

CREATE TABLE schema_kurs.course (
	course_code varchar(30) NOT NULL,
	course_name varchar(30) NULL,
	start_date date NULL,
	end_date date NULL,
	course_cost int4 NULL,
	CONSTRAINT course_check CHECK ((end_date > start_date)),
	CONSTRAINT course_pkey PRIMARY KEY (course_code)
);

-- Table Triggers

create trigger tr_course_del_before before
delete
    on
    schema_kurs.course for each row execute function schema_kurs.trigger_course_before_del();

-- Permissions

ALTER TABLE schema_kurs.course OWNER TO postgres;
GRANT ALL ON TABLE schema_kurs.course TO postgres;


-- schema_kurs.days definition

-- Drop table

-- DROP TABLE schema_kurs.days;

CREATE TABLE schema_kurs.days (
	number_day varchar(30) NOT NULL,
	name_day varchar(30) NULL,
	CONSTRAINT days_pkey PRIMARY KEY (number_day)
);

-- Permissions

ALTER TABLE schema_kurs.days OWNER TO postgres;
GRANT ALL ON TABLE schema_kurs.days TO postgres;


-- schema_kurs.educator definition

-- Drop table

-- DROP TABLE schema_kurs.educator;

CREATE TABLE schema_kurs.educator (
	employee_number varchar(30) NOT NULL,
	full_name_educator varchar(30) NULL,
	birthday_educator date NULL,
	number_passport_educator varchar(10) NULL,
	education varchar(30) NULL,
	number_phone_educator varchar(11) NULL,
	email varchar(30) NULL,
	pay int4 NULL,
	CONSTRAINT educator_pkey PRIMARY KEY (employee_number)
);

-- Table Triggers

create trigger tr_educator_del_before before
delete
    on
    schema_kurs.educator for each row execute function schema_kurs.trigger_educator_before_del();

-- Permissions

ALTER TABLE schema_kurs.educator OWNER TO postgres;
GRANT ALL ON TABLE schema_kurs.educator TO postgres;


-- schema_kurs.pairs definition

-- Drop table

-- DROP TABLE schema_kurs.pairs;

CREATE TABLE schema_kurs.pairs (
	number_pairs varchar(30) NOT NULL,
	start_pairs varchar(30) NULL,
	end_pairs varchar(30) NULL,
	CONSTRAINT pairs_pkey PRIMARY KEY (number_pairs)
);

-- Permissions

ALTER TABLE schema_kurs.pairs OWNER TO postgres;
GRANT ALL ON TABLE schema_kurs.pairs TO postgres;


-- schema_kurs.weeks definition

-- Drop table

-- DROP TABLE schema_kurs.weeks;

CREATE TABLE schema_kurs.weeks (
	number_week varchar(30) NOT NULL,
	CONSTRAINT weeks_pkey PRIMARY KEY (number_week)
);

-- Permissions

ALTER TABLE schema_kurs.weeks OWNER TO postgres;
GRANT ALL ON TABLE schema_kurs.weeks TO postgres;


-- schema_kurs.training_group definition

-- Drop table

-- DROP TABLE schema_kurs.training_group;

CREATE TABLE schema_kurs.training_group (
	number_group varchar(30) NOT NULL,
	course_code varchar(30) NULL,
	CONSTRAINT training_group_pkey PRIMARY KEY (number_group),
	CONSTRAINT training_group_course_code_fkey FOREIGN KEY (course_code) REFERENCES schema_kurs.course(course_code)
);

-- Table Triggers

create trigger tr_group_del_before before
delete
    on
    schema_kurs.training_group for each row execute function schema_kurs.trigger_group_before_del();
create trigger tr_group_del_before_st before
delete
    on
    schema_kurs.training_group for each row execute function schema_kurs.trigger_group_before_del_for_student();

-- Permissions

ALTER TABLE schema_kurs.training_group OWNER TO postgres;
GRANT ALL ON TABLE schema_kurs.training_group TO postgres;


-- schema_kurs.student definition

-- Drop table

-- DROP TABLE schema_kurs.student;

CREATE TABLE schema_kurs.student (
	number_student varchar(30) NOT NULL,
	full_name_student varchar(30) NULL,
	number_phone_student varchar(11) NULL,
	email varchar(30) NULL,
	number_group varchar(30) NULL,
	number_passport_student varchar(10) NULL,
	CONSTRAINT student_pkey PRIMARY KEY (number_student),
	CONSTRAINT student_number_group_fkey FOREIGN KEY (number_group) REFERENCES schema_kurs.training_group(number_group)
);

-- Permissions

ALTER TABLE schema_kurs.student OWNER TO postgres;
GRANT ALL ON TABLE schema_kurs.student TO postgres;


-- schema_kurs.timetable definition

-- Drop table

-- DROP TABLE schema_kurs.timetable;

CREATE TABLE schema_kurs.timetable (
	number_group varchar(30) NULL,
	employee_number varchar(30) NULL,
	number_day varchar(30) NULL,
	number_week varchar(30) NULL,
	number_pairs varchar(30) NULL,
	classroom varchar(30) NULL,
	CONSTRAINT timetable_number_day_number_week_number_pairs_classroom_key UNIQUE (number_day, number_week, number_pairs, classroom),
	CONSTRAINT timetable_number_day_number_week_number_pairs_employee_numb_key UNIQUE (number_day, number_week, number_pairs, employee_number),
	CONSTRAINT timetable_employee_number_fkey FOREIGN KEY (employee_number) REFERENCES schema_kurs.educator(employee_number),
	CONSTRAINT timetable_number_day_fkey FOREIGN KEY (number_day) REFERENCES schema_kurs.days(number_day),
	CONSTRAINT timetable_number_group_fkey FOREIGN KEY (number_group) REFERENCES schema_kurs.training_group(number_group),
	CONSTRAINT timetable_number_pairs_fkey FOREIGN KEY (number_pairs) REFERENCES schema_kurs.pairs(number_pairs),
	CONSTRAINT timetable_number_week_fkey FOREIGN KEY (number_week) REFERENCES schema_kurs.weeks(number_week)
);

-- Table Triggers

create trigger tr_pay_ed after
insert
    on
    schema_kurs.timetable for each row execute function schema_kurs.profit_educator();
create trigger tr_altpay_ed after
delete
    on
    schema_kurs.timetable for each row execute function schema_kurs.alterprofit_educator();

-- Permissions

ALTER TABLE schema_kurs.timetable OWNER TO postgres;
GRANT ALL ON TABLE schema_kurs.timetable TO postgres;



CREATE OR REPLACE FUNCTION schema_kurs.alterprofit_educator()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
	update schema_kurs.educator
	set pay = pay - 1500
	where employee_number=old.employee_number;
	return old;
end
$function$
;

-- Permissions

ALTER FUNCTION schema_kurs.alterprofit_educator() OWNER TO postgres;
GRANT ALL ON FUNCTION schema_kurs.alterprofit_educator() TO postgres;

CREATE OR REPLACE FUNCTION schema_kurs.profit_educator()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
	update schema_kurs.educator
	set pay = pay + 1500
	where employee_number=new.employee_number;
	return new;
end
$function$
;

-- Permissions

ALTER FUNCTION schema_kurs.profit_educator() OWNER TO postgres;
GRANT ALL ON FUNCTION schema_kurs.profit_educator() TO postgres;

CREATE OR REPLACE FUNCTION schema_kurs.trigger_course_before_del()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
if (select count(*) from training_group a where trim(a.course_code)=trim(OLD.course_code))>0
then delete from training_group where trim(training_group.course_code)=trim(OLD.course_code);
end if;
return OLD;
END;
$function$
;

-- Permissions

ALTER FUNCTION schema_kurs.trigger_course_before_del() OWNER TO postgres;
GRANT ALL ON FUNCTION schema_kurs.trigger_course_before_del() TO postgres;

CREATE OR REPLACE FUNCTION schema_kurs.trigger_educator_before_del()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
if (select count(*) from timetable a where trim(a.employee_number)=trim(OLD.employee_number))>0
then delete from timetable where trim(timetable.employee_number)=trim(OLD.employee_number);
end if;
return OLD;
END;
$function$
;

-- Permissions

ALTER FUNCTION schema_kurs.trigger_educator_before_del() OWNER TO postgres;
GRANT ALL ON FUNCTION schema_kurs.trigger_educator_before_del() TO postgres;

CREATE OR REPLACE FUNCTION schema_kurs.trigger_group_before_del()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
--if (select count(*) from spj a where trim(a.ns)=trim(OLD.ns))>0
if (select count(*) from timetable a where trim(a.number_group)=trim(OLD.number_group))>0
then delete from timetable where trim(timetable.number_group)=trim(OLD.number_group);
end if;
return OLD;
END;
$function$
;

-- Permissions

ALTER FUNCTION schema_kurs.trigger_group_before_del() OWNER TO postgres;
GRANT ALL ON FUNCTION schema_kurs.trigger_group_before_del() TO postgres;

CREATE OR REPLACE FUNCTION schema_kurs.trigger_group_before_del_for_student()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
if (select count(*) from student a where trim(a.number_group)=trim(OLD.number_group))>0
then delete from student where trim(student.number_group)=trim(OLD.number_group);
end if;
return OLD;
END;
$function$
;

-- Permissions

ALTER FUNCTION schema_kurs.trigger_group_before_del_for_student() OWNER TO postgres;
GRANT ALL ON FUNCTION schema_kurs.trigger_group_before_del_for_student() TO postgres;


-- Permissions

GRANT ALL ON SCHEMA schema_kurs TO postgres;
