CREATE SCHEMA schema_kurs;

-- tables
-- Table: customers
CREATE TABLE customers (
    customerid int  NOT NULL,
    Name_c varchar(30)  NOT NULL,
    Surname varchar(30)  NOT NULL,
    Phone varchar(11)  NOT NULL,
    CONSTRAINT customers_pk PRIMARY KEY (customerid)
);

-- Table: departments 
CREATE TABLE departments  (
    departmentID  int  NOT NULL,
    departmentName  varchar(30)  NOT NULL,
    CONSTRAINT departments_pk PRIMARY KEY (departmentID )
);

-- Table: employees
CREATE TABLE employees (
    employeeID int  NOT NULL,
    Name_e varchar(30)  NOT NULL,
    Surname varchar(30)  NOT NULL,
    Birthday date  NOT NULL,
    Address varchar(30)  NOT NULL,
    Phone varchar(11)  NOT NULL,
    position_e int  NOT NULL,
    CONSTRAINT employees_pk PRIMARY KEY (employeeID)
);

-- Table: orders
CREATE TABLE orders (
    orderID int  NOT NULL,
    datetime_order timestamp  NOT NULL,
    carwasher int  NOT NULL,
    customerid int  NOT NULL,
    service int  NOT NULL,
    CONSTRAINT orders_pk PRIMARY KEY (orderID)
);

-- Table: positions
CREATE TABLE positions (
    positionID int  NOT NULL,
    title varchar(30)  NOT NULL,
    salary money  NOT NULL,
    department int  NOT NULL,
    CONSTRAINT positions_pk PRIMARY KEY (positionID)
);

-- Table: services
CREATE TABLE services (
    serviceID int  NOT NULL,
    serviceName varchar(30)  NOT NULL,
    price money  NOT NULL,
    CONSTRAINT services_pk PRIMARY KEY (serviceID)
);

-- foreign keys
-- Reference: employees_positions (table: employees)
ALTER TABLE employees ADD CONSTRAINT employees_positions
    FOREIGN KEY (position_e)
    REFERENCES positions (positionID)
    ON DELETE  CASCADE 
    ON UPDATE  CASCADE 
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: Order_customers (table: orders)
ALTER TABLE orders ADD CONSTRAINT Order_customers
    FOREIGN KEY (customerid)
    REFERENCES customers (customerid)
    ON DELETE  CASCADE 
    ON UPDATE  CASCADE 
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: Order_employees (table: orders)
ALTER TABLE orders ADD CONSTRAINT Order_employees
    FOREIGN KEY (carwasher)
    REFERENCES employees (employeeID)
    ON DELETE  CASCADE 
    ON UPDATE  CASCADE 
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: Order_services (table: orders)
ALTER TABLE orders ADD CONSTRAINT Order_services
    FOREIGN KEY (service)
    REFERENCES services (serviceID)
    ON DELETE  CASCADE 
    ON UPDATE  CASCADE 
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: positions_departments  (table: positions)
ALTER TABLE positions ADD CONSTRAINT positions_departments 
    FOREIGN KEY (department)
    REFERENCES departments  (departmentID )
    ON DELETE  CASCADE 
    ON UPDATE  CASCADE 
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;




-----------------

select  course.course_name, count(student.number_student), sum(course.course_cost) 
from student
inner join training_group on student.number_group = training_group.number_group
inner join course on training_group.course_code = course.course_code
group by course.course_name


select customers.name_c, customers.surname, sum(services.price)
from customers
inner join orders on orders.customerid = customers.customerid 
inner join services on services.serviceid = orders.service 
group by customers.name_c, customers.surname


select employees.name_e, employees.surname, count(orders.orderid)
from employees
inner join orders on orders.carwasher = employees.employeeid 
group by employees.name_e, employees.surname 


select orders.datetime_order,  sum(services.price)
from orders
inner join services on services.serviceid = orders.service  
group by orders.datetime_order 


select departments.departmentname, count(employees.employeeid)
from departments
inner join positions on positions.department = departments.departmentid 
inner join employees on employees.position_e = positions.positionid 
group by departments.departmentname 
-------------------------------------

-- триггер на удаление расписания при удалении преподавателя
CREATE FUNCTION trigger_educator_before_del () RETURNS trigger AS '
BEGIN
if (select count(*) from timetable a where trim(a.employee_number)=trim(OLD.employee_number))>0
then delete from timetable where trim(timetable.employee_number)=trim(OLD.employee_number);
end if;
return OLD;
END;
' LANGUAGE  plpgsql;
--
CREATE TRIGGER tr_educator_del_before
BEFORE DELETE ON educator FOR EACH row
EXECUTE PROCEDURE trigger_educator_before_del();

-- триггер на удаление расписания при удалении группы 
CREATE FUNCTION trigger_group_before_del () RETURNS trigger AS '
BEGIN
if (select count(*) from timetable a where trim(a.number_group)=trim(OLD.number_group))>0
then delete from timetable where trim(timetable.number_group)=trim(OLD.number_group);
end if;
return OLD;
END;
' LANGUAGE  plpgsql;
--
CREATE TRIGGER tr_group_del_before
BEFORE DELETE ON training_group FOR EACH row
EXECUTE PROCEDURE trigger_group_before_del();

-- триггер на удаление группы при удалении курса 
CREATE FUNCTION trigger_course_before_del () RETURNS trigger AS '
BEGIN
if (select count(*) from training_group a where trim(a.course_code)=trim(OLD.course_code))>0
then delete from training_group where trim(training_group.course_code)=trim(OLD.course_code);
end if;
return OLD;
END;
' LANGUAGE  plpgsql;
--
CREATE TRIGGER tr_course_del_before
BEFORE DELETE ON course FOR EACH row
EXECUTE PROCEDURE trigger_course_before_del();


-- триггер на удаление студента при удалении группы 
CREATE FUNCTION trigger_group_before_del_for_student () RETURNS trigger AS '
BEGIN
if (select count(*) from student a where trim(a.number_group)=trim(OLD.number_group))>0
then delete from student where trim(student.number_group)=trim(OLD.number_group);
end if;
return OLD;
END;
' LANGUAGE  plpgsql;
---
CREATE TRIGGER tr_group_del_before_st
BEFORE DELETE ON training_group FOR EACH row
EXECUTE PROCEDURE trigger_group_before_del_for_student();


--триггер обновляющий плату преподавателю при добавлении ему занятий
create or replace function profit_educator()
returns trigger as
$$
begin
	update schema_kurs.educator
	set pay = pay + 1500
	where employee_number=new.employee_number;
	return new;
end
$$
language 'plpgsql';
---
create or replace trigger tr_pay_ed
after insert on timetable
for each row
execute function  profit_educator();

--триггер обновляющий плату преподавателю при удалении занятий с ним
create or replace function alterprofit_educator()
returns trigger as
$$
begin
	update schema_kurs.educator
	set pay = pay - 1500
	where employee_number=old.employee_number;
	return old;
end
$$
language 'plpgsql';
---
create or replace trigger tr_altpay_ed
after delete  on timetable
for each row
execute function  alterprofit_educator();



--- чек на то, что дата начала курса раньнше конца
alter table course add check ( end_date > start_date);
ALTER TABLE timetable ADD UNIQUE (number_day, number_week, number_pairs, employee_number)
ALTER TABLE timetable ADD UNIQUE (number_day, number_week, number_pairs, classroom)


select * from information_schema.triggers;

